ccNES = {}
ccNES.width = 256
ccNES.height = 240

function ccNES.mt_hook(mt)
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
    local path = "/nes/libs/" .. name .. ".lua"
    dofile(path)
end

ccNES.loadlib "nes"
ccNES.loadlib "libs/json"

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
