ccbit = bit32

ccNES = {}
ccNES.width = 256
ccNES.height = 240

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
    dofile(path)
end

ccNES.loadlib "nes"
ccNES.loadlib "libs/json"

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
