-- EXE.HUB | system/registry.lua
-- Registre des jeux supportes. Sans annotations de type (compat loadstring).

local Registry = {}

-- Table des jeux supportes : [PlaceId] = { name, module }
local games = {
    [14890802310] = {
        name   = "Bizarre Lineage",
        module = "games/bizarre_lineage.lua"
    },
    -- Ajouter d'autres jeux ici :
    -- [PLACEID] = { name = "Nom du jeu", module = "games/fichier.lua" },
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

return Registry