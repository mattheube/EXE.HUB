-- ============================================================
--  EXE.HUB | main.lua
--  Point d'entrée principal du hub.
--  Charge les modules système, détecte le jeu et initialise
--  le module correspondant.
-- ============================================================

-- URL de base du dépôt GitHub (raw)
-- ⚠ Remplace USERNAME par ton nom d'utilisateur GitHub
local REPO_BASE = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"

-- ============================================================
-- UTILITAIRE DE CHARGEMENT DISTANT
-- Roblox ne supporte pas require() sur des URLs distantes.
-- On utilise HttpGet + loadstring pour simuler un système
-- de modules distants tout en gardant une architecture propre.
-- ============================================================

local function loadModule(path: string): any
    local url = REPO_BASE .. path
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url, true))()
    end)
    if success then
        return result
    else
        warn("[EXE.HUB] Échec du chargement du module : " .. path)
        warn("[EXE.HUB] Erreur : " .. tostring(result))
        return nil
    end
end

-- ============================================================
-- CHARGEMENT DES MODULES SYSTÈME
-- On charge dans l'ordre : utils → registry → ui → loader
-- ============================================================

local Utils    = loadModule("system/utils.lua")
local Registry = loadModule("system/registry.lua")
local UI       = loadModule("system/ui.lua")
local Loader   = loadModule("system/loader.lua")

-- Vérifie que tous les modules système sont chargés
if not Utils or not Registry or not UI or not Loader then
    warn("[EXE.HUB] Un ou plusieurs modules système n'ont pas pu être chargés. Arrêt.")
    return
end

-- ============================================================
-- INITIALISATION DU HUB
-- ============================================================

Utils.Log("EXE.HUB initialisation...")

-- Affiche la fenêtre principale et le message de bienvenue
UI.Init()
UI.ShowWelcome()

-- ============================================================
-- DÉTECTION DU JEU ACTUEL
-- ============================================================

local placeId: number = game.PlaceId
Utils.Log("PlaceId détecté : " .. tostring(placeId))

local gameInfo = Registry.GetGame(placeId)

-- ============================================================
-- CHARGEMENT DU MODULE DE JEU
-- ============================================================

if gameInfo then
    -- Jeu supporté : on notifie et on charge le module
    Utils.Log("Jeu reconnu : " .. gameInfo.name)
    UI.ShowGameDetected(gameInfo.name)

    -- On passe les dépendances au loader pour qu'il charge
    -- le module du jeu depuis GitHub
    Loader.LoadGame(gameInfo, loadModule, UI, Utils)
else
    -- Jeu non supporté : on affiche un message clair
    Utils.Log("Jeu non supporté (PlaceId: " .. tostring(placeId) .. ")")
    UI.ShowNotSupported(placeId)
end

-- ============================================================
-- FIN D'INITIALISATION
-- ============================================================

Utils.Log("EXE.HUB prêt.")