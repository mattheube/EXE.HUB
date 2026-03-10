-- EXE.HUB | system/registry.lua

local Registry = {}

local games = {
    [14890802310] = {
        name   = "Bizarre Lineage",
        module = "games/bizarre_lineage.lua"
    },
}

function Registry.GetGame(placeId)
    return games[placeId] or nil
end

function Registry.IsSupported(placeId)
    return games[placeId] ~= nil
end

function Registry.GetAll()
    return games
end

if _G.__EXE_HUB_MODULES then
    _G.__EXE_HUB_MODULES["registry"] = Registry
end

return Registry