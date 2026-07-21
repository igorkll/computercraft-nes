local ccNES = {}
ccNES.width = 256
ccNES.height = 240

local env = setmetatable({
    ccbit = bit32,
    ccNES = ccNES
}, {__index = _G})

function ccNES.mt_hook(mt) --legacy for scrapmechanic nes
    return setmetatable({}, mt)
end

function ccNES.fckmetatable(tbl, mt)
    local old__newindex = mt.__newindex
    mt.__newindex = nil
    local newtbl = ccNES.mt_hook(mt)
    for k, v in pairs(tbl) do
        newtbl[k] = v
    end
    mt.__newindex = old__newindex
    return newtbl
end

function ccNES.tableClear(tbl)
    for k in pairs(tbl) do
        tbl[k] = nil
    end
end

function ccNES.print(...)
    --print(...)
end

function ccNES.loadlib(name)
    ccNES.print("ccNES loadlib> ", name)
    local path = "/nes/" .. name .. ".lua"
    loadfile(path, env)()
end

ccNES.loadlib "nes"
ccNES.loadlib "libs/json"
ccNES.NES = env.NES
ccNES.PALETTE = env.PALETTE

local file_mt = {
    __index = {
        read = function(self, read)
            if read == "*all" or read == "*a" then
                return self.file.readAll()
            end
            
            return self.file.read(read)
        end,
        write = function(self, str)
            self.file.write(str)
        end,
        close = function(self)
            self.file.close()
            return true
        end
    }
}

function ccNES.open(path, mode)
    local file = ccNES.mt_hook(file_mt)
    file.file = fs.open(path, mode or "r")
    return file
end

function ccNES.new(file)
    local Nes = ccNES.NES:new(
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
            palette = ccNES.PALETTE:defacto_palette()
        }
    )
    --Nes:run()
    Nes:reset()

    return Nes
end

function ccNES.getCallback(term, speakers)
    return function(request)
        sndplay.waitIfNeedAndPlayBufferOnSeveralSpeakers(speakers, request.pcm)

        local keyEvents = {}

        return {
            keyEvents = keyEvents
        }
    end
end

function ccNES.start(file, callback)
    local nes
    local function runNes()
        nes = ccNES.new(file)
    end

    runNes()

    local function uploadKeyEvents(keyEvents)
        for i, v in ipairs(keyEvents) do
            nes.pads[v[1]](nes.pads, v[3], v[2])
        end
    end

    while true do
        nes:run_once()

        --request
        local pcm = {}
        for _, val in ipairs(nes.cpu.apu.output) do
            table.insert(pcm, val)
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
            pcm[i] = byte - 128
        end

        local request = {
            pixels = nes.cpu.ppu.output_pixels,
            audio = pcm
        }

        --run user callback
        local response = callback(request)
        
        --process response
        if response then
            if response.keyEvents then
                uploadKeyEvents(response.keyEvents)
            end
        end
        
        sleep(1 / 60)
    end
end

return ccNES