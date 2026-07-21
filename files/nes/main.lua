ccNES = {}

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

function ccNES.loadlib(name)
    print("ccNES loadlib> ", name)
    local path = "Scripts/ccNES/" .. name .. ".lua"
    dofile("$CONTENT_DATA/" .. path)
end

function ccNES.open(path, mode)
    mode = mode or "r"
    return fs
end

ccNES.loadlib "nes"
ccNES.loadlib "libs/json"

