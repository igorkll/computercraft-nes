--for scrapmechanic
--https://steamcommunity.com/sharedfiles/filedetails/?id=3353025650
sourceString = sourceString or [[smNES = {}
smNES.width = 256
smNES.height = 240

function smNES.mt_hook(mt)
    return setmetatable({}, mt)
end

function smNES.fckmetatable(tbl, mt)
    local old__newindex = mt.__newindex
    mt.__newindex = nil
    local newtbl = smNES.mt_hook(mt)
    for k, v in pairs(tbl) do
        newtbl[k] = v
    end
    mt.__newindex = old__newindex
    return newtbl
end

function smNES.tableClear(tbl)
    for k in pairs(tbl) do
        tbl[k] = nil
    end
end

function smNES.loadlib(name)
end

local file_mt = {
    __index = {
        read = function(self, read)
            if read == "*all" or read == "*a" then
                read = #self.buffer
            end
            local str = {}
            for i = self.offset + 1, self.offset + read do
                local byte = self.buffer[i]
                if not byte then
                    break
                end
                table.insert(str, string.char(byte))
            end
            self.offset = self.offset + read
            return table.concat(str)
        end,
        write = function(self, str)
            for i = 1, #str do
                table.insert(self.buffer, str:byte(i))
            end
        end,
        close = function(self)
            return true
        end
    }
}

function smNES.open(path, mode)
    mode = mode or "r"
    local file
    if mode:sub(1, 1) == "w" then
        return nil, "failed to write file"
        --file = smNES.mt_hook(file_mt)
        --file.write = true
        --file.buffer = {}
    else
        file = smNES.mt_hook(file_mt)
        file.buffer = path
        file.offset = 0
    end
    file.path = path
    return file
end

function smNES.new(file)
    local Nes = NES:new(
        {
            file = file,
            loglevel = 0,
            pc = nil,
            palette = PALETTE:defacto_palette()
        }
    )
    --Nes:run()
    Nes:reset()

    return Nes
end]]

local endCode = [[nesObj = smNES.new(ROMCODE)

local tpadCounter = 0
local oldPressed = {}
local tick = 0

while true do
    if threadTunnelGet(0) then
        break
    end

    local startT = os.clock()

    local pressed = json.decode(threadTunnelGet(1))
    if pressed.counter > tpadCounter then
        local keyEvents = {}
        for joystickNumber, pressed in ipairs(pressed.pressed or {}) do
            if not oldPressed[joystickNumber] then
                oldPressed[joystickNumber] = {}
            end
            for _, key in ipairs(pressed) do
                if not oldPressed[joystickNumber][key] then
                    table.insert(keyEvents, {"keydown", key, joystickNumber})
                    oldPressed[joystickNumber][key] = true
                end
            end
            for key in pairs(oldPressed[joystickNumber]) do
                local finded = false
                for _, lkey in ipairs(pressed) do
                    if lkey == key then
                        finded = true
                        break
                    end
                end
                if not finded then
                    table.insert(keyEvents, {"keyup", key, joystickNumber})
                    oldPressed[joystickNumber][key] = nil
                end
            end
        end
        for i, v in ipairs(keyEvents) do
            nesObj.pads[v[1] ](nesObj.pads, v[3], v[2])
        end
    end
    tpadCounter = pressed.counter

    nesObj:run_once()
    
    if tick % 4 == 0 then
        local pixelData = nesObj.cpu.ppu.output_pixels
        local pixelCount = smNES.width * smNES.height
        local str = {}
        local strI = 1
        for i = 1, pixelCount do
            str[strI] = string.char(pixelData[i][1])
            strI = strI + 1
            str[strI] = string.char(pixelData[i][2])
            strI = strI + 1
            str[strI] = string.char(pixelData[i][3])
            strI = strI + 1
        end
        threadTunnelSet(3, table.concat(str))
    end

    local pcm = {}
    for i = 1, 2 do
        for _, val in ipairs(nesObj.cpu.apu.output) do
            table.insert(pcm, val)
        end
    end
    local iters = 15
    local maxPcm = #pcm
    for i = 0, iters do
        local mul = i / iters
        if pcm[i] then
            pcm[i] = pcm[i] * mul
        end
        if pcm[maxPcm - i] then
            pcm[maxPcm - i] = pcm[maxPcm - i] * mul
        end
    end
    for i = 1, maxPcm do
        local byte = math.floor((pcm[i] * 255) + 0.5)
        if byte < 0 then byte = 0 elseif byte > 255 then byte = 255 end
        pcm[i] = string.char(byte)
    end
    threadTunnelSet(4, table.concat(pcm))

    local endT = os.clock()
    local sleepTime = math.floor((1000 / 60) - ((endT - startT) * 1000))
    if sleepTime < 1 then sleepTime = 1 end
    sleep(sleepTime)

    tick = tick + 1
end]]

local sourcePushs = {}
local modParams = sm.json.open("$CONTENT_DATA/description.json")
if better and better.isAvailable() then
    better.autoRegistration(modParams.name)
    if not sourceGen then
        sourceString = better.filesystem.readFile("$CONTENT_" .. modParams.localId .. "/Scripts/smNES/libs/json.lua") .. "\n" .. sourceString
    end
end

smNES = {}
smNES.width = 256
smNES.height = 240

function smNES.mt_hook(mt)
    local empty_class = class(mt)
    empty_class.__index = mt.__index
    return empty_class()
end

function smNES.fckmetatable(tbl, mt)
    local old__newindex = mt.__newindex
    mt.__newindex = nil
    local newtbl = smNES.mt_hook(mt)
    for k, v in pairs(tbl) do
        newtbl[k] = v
    end
    mt.__newindex = old__newindex
    return newtbl
end

function smNES.tableClear(tbl)
    for k in pairs(tbl) do
        tbl[k] = nil
    end
end

function smNES.loadlib(name)
    print("smNES loadlib> ", name)
    local path = "Scripts/smNES/" .. name .. ".lua"
    dofile("$CONTENT_DATA/" .. path)
    if not sourceGen and better and better.isAvailable() then
        if not sourcePushs[name] then
            sourceString = sourceString .. "\ndo\n(function(...)\n" .. better.filesystem.readFile("$CONTENT_" .. modParams.localId .. "/" .. path) .. "\nend)()\nend\n"
            sourcePushs[name] = true
        end
    end
end

local file_mt = {
    __index = {
        read = function(self, read)
            if read == "*all" or read == "*a" then
                read = #self.buffer
            end
            local str = {}
            for i = self.offset + 1, self.offset + read do
                local byte = self.buffer[i]
                if not byte then
                    break
                end
                table.insert(str, string.char(byte))
            end
            self.offset = self.offset + read
            return table.concat(str)
        end,
        write = function(self, str)
            for i = 1, #str do
                table.insert(self.buffer, str:byte(i))
            end
        end,
        close = function(self)
            if self.write then
                sm.json.save(self.buffer, self.path)
            end
            return true
        end
    }
}

function smNES.open(path, mode)
    mode = mode or "r"
    local file
    if mode:sub(1, 1) == "w" then
        return nil, "failed to write file"
        --file = smNES.mt_hook(file_mt)
        --file.write = true
        --file.buffer = {}
    else
        file = smNES.mt_hook(file_mt)
        file.buffer = sm.json.open(path)
        file.offset = 0
    end
    file.path = path
    return file
end

smNES.loadlib "nes"
smNES.loadlib "libs/json"

local function isNesFile(path)
    return path:sub(#path - 3, #path) == ".nes"
end

function smNES.new(file)
    local Nes = NES:new(
        {
            file = file,
            loglevel = 0,
            pc = nil,
            --[[
            palette = UTILS.map(
                PALETTE:defacto_palette(),
                function(c)
                    return { c[1] / 256, c[2] / 256, c[3] / 256 }
                end
            )
            ]]
            palette = PALETTE:defacto_palette()
        }
    )
    --Nes:run()
    Nes:reset()

    return Nes
end

if better and better.isAvailable() and better.thread then
    local convertedRoms = {}
    function smNES.newThread(file)
        local th
        do
            local ROMSTR
            if isNesFile(file) then
                local romStr = {}
                local romRawStr = better.filesystem.readFile(file)
                for i = 1, #romRawStr do
                    table.insert(romStr, romRawStr:byte(i))
                    if i ~= #romRawStr then
                        table.insert(romStr, ",")
                    end
                end
                ROMSTR = table.concat(romStr)
            elseif not convertedRoms[file] then
                local romStr = {}
                local romTbl = sm.json.open(file)
                for i = 1, #romTbl do
                    table.insert(romStr, romTbl[i])
                    if i ~= #romTbl then
                        table.insert(romStr, ",")
                    end
                end
                ROMSTR = table.concat(romStr)
                convertedRoms[file] = ROMSTR
            else
                ROMSTR = convertedRoms[file]
            end
            
            local threadCode = "local ROMCODE = {" .. ROMSTR .. "}\n" .. sourceString .. "\n" .. endCode
            --better.filesystem.writeFile("/nes_debug_thread.lua", threadCode)
            --better.filesystem.show()
            th = better.thread.new(threadCode)
        end

        local tpadCounter = 0
        local displayCounter = 0

        local stopped = false
        local nesErr
        local function stopCheck()
            local _stopped, _nesErr = th:result()
            if _stopped then
                stopped = true
                nesErr = _nesErr
                return true
            end
        end

        local obj = {
            tnes_stop = function()
                if stopped or stopCheck() then return end
                th:threadTunnelSet(0, true)
                local startTime = os.clock()
                while true do
                    local threadEnd, err = th:result()
                    if threadEnd then
                        if err then
                            print("smNES.newThread error on stop: ", err)
                        end
                        th:free()
                        break
                    end

                    if os.clock() - startTime > 2 then
                        print("smNES.newThread failed to stop")
                        break
                    end
                end
                stopped = true
            end,
            tnes_tick = function()
                if stopped or stopCheck() then return end
                local ok, err = th:result()
                if ok then
                    if err then
                        print("smNES.newThread error: ", err)
                    end
                    th:free()
                end
            end,
            tnes_pad = function(pressed)
                if stopped or stopCheck() then return end
                tpadCounter = tpadCounter + 1
                local nPressed = {}
                for num, data in pairs(pressed) do
                    nPressed[num] = {}
                    for key in pairs(data) do
                        table.insert(nPressed[num], key)
                    end
                end
                th:threadTunnelSet(1, json.encode({pressed = nPressed, counter = tpadCounter}))
            end,
            tnes_display = function(pressed)
                if stopped or stopCheck() then return end
                return th:threadTunnelGet(3)
            end,
            tnes_pcm = function()
                if stopped or stopCheck() then return "" end
                return th:threadTunnelGet(4) or ""
            end,
            tnes_getError = function()
                if stopped and stopCheck() then
                    return nesErr
                end
            end
        }
        return obj
    end
end

sourceGen = true