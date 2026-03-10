-- ============================================================
--  EXE.HUB | system/registry.lua
--  Registre centralisé des jeux supportés.
--  Associe chaque PlaceId à un nom de jeu et au chemin
--  de son module dans le dépôt GitHub.
--  Pour ajouter un jeu : ajoute une entrée dans la table
--  supportedGames avec le bon PlaceId.
-- ============================================================

local Registry = {}

-- ============================================================
-- TABLE DES JEUX SUPPORTÉS
-- Format :
--   [PlaceId] = {
--       name   = "Nom affiché du jeu",
--       module = "chemin/relatif/depuis/repo.lua"
--   }
-- ============================================================

local supportedGames: {[number]: {name: string, module: string}} = {

    -- ✅ Bizarre Lineage
    [14890802310] = {
        name   = "Bizarre Lineage",
        module = "games/bizarre_lineage.lua"
    }
}

-- ============================================================
-- FONCTION : Récupère les informations d'un jeu par PlaceId
-- Retourne la table du jeu si supporté, nil sinon.
-- ============================================================

function Registry.GetGame(placeId: number): {name: string, module: string}?
    return supportedGames[placeId] or nil
end

-- ============================================================
-- FONCTION : Retourne tous les jeux supportés
-- Utile pour afficher une liste ou faire du debug.
-- ============================================================

function Registry.GetAll(): {[number]: {name: string, module: string}}
    return supportedGames
end

-- ============================================================
-- FONCTION : Vérifie si un PlaceId est supporté
-- ============================================================

function Registry.IsSupported(placeId: number): boolean
    return supportedGames[placeId] ~= nil
end

return Registry