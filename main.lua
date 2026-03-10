-- ============================================================
--  EXE.HUB | main.lua
--  Point d'entrée principal du hub.
-- ============================================================

-- URL de base — format "refs/heads/main" plus fiable
-- sur les exécuteurs comme Matcha, Synapse, etc.
local REPO_BASE = "https://raw.githubusercontent.com/mattheube/EXE.HUB/refs/heads/main/"

-- ============================================================
-- UTILITAIRE DE CHARGEMENT DISTANT
-- Décomposé en 3 étapes pour identifier précisément
-- quelle étape échoue en cas de problème :
--   1. HttpGet  (réseau)
--   2. loadstring (compilation LuaU)
--   3. Appel fn  (exécution du module)
-- ============================================================

local function loadModule(path: string): any
    local url = REPO_BASE .. path
    print("[EXE.HUB] >> Chargement : " .. url)

    -- Étape 1 : réseau
    local httpOk, rawContent = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not httpOk then
        warn("[EXE.HUB] ERREUR RÉSEAU pour : " .. path)
        warn("[EXE.HUB] Détail : " .. tostring(rawContent))
        return nil
    end
    if not rawContent or rawContent == "" then
        warn("[EXE.HUB] CONTENU VIDE pour : " .. path)
        return nil
    end
    print("[EXE.HUB] HTTP OK — " .. #rawContent .. " chars pour : " .. path)

    -- Étape 2 : compilation
    local compileOk, fn = pcall(loadstring, rawContent)
    if not compileOk or type(fn) ~= "function" then
        warn("[EXE.HUB] ERREUR COMPILATION pour : " .. path)
        warn("[EXE.HUB] Détail : " .. tostring(fn))
        return nil
    end
    print("[EXE.HUB] Compilation OK pour : " .. path)

    -- Étape 3 : exécution
    local execOk, result = pcall(fn)
    if not execOk then
        warn("[EXE.HUB] ERREUR EXÉCUTION pour : " .. path)
        warn("[EXE.HUB] Détail : " .. tostring(result))
        return nil
    end
    print("[EXE.HUB] Module OK : " .. path)
    return result
end

-- ============================================================
-- CHARGEMENT DES MODULES SYSTÈME
-- ============================================================

print("[EXE.HUB] ════════════════════════════════")
print("[EXE.HUB]   Démarrage EXE.HUB")
print("[EXE.HUB] ════════════════════════════════")

local Utils = loadModule("system/utils.lua")
if not Utils then warn("[EXE.HUB] ARRÊT — utils.lua introuvable.") return end
print("[EXE.HUB] utils.lua ✔")

local Registry = loadModule("system/registry.lua")
if not Registry then warn("[EXE.HUB] ARRÊT — registry.lua introuvable.") return end
print("[EXE.HUB] registry.lua ✔")

local UI = loadModule("system/ui.lua")
if not UI then warn("[EXE.HUB] ARRÊT — ui.lua introuvable.") return end
print("[EXE.HUB] ui.lua ✔")

local Loader = loadModule("system/loader.lua")
if not Loader then warn("[EXE.HUB] ARRÊT — loader.lua introuvable.") return end
print("[EXE.HUB] loader.lua ✔")

-- ============================================================
-- INITIALISATION DU HUB
-- ============================================================

Utils.Log("Initialisation...")
UI.Init()
UI.ShowWelcome()

-- ============================================================
-- DÉTECTION ET CHARGEMENT DU JEU
-- ============================================================

local placeId: number = game.PlaceId
Utils.Log("PlaceId détecté : " .. tostring(placeId))

local gameInfo = Registry.GetGame(placeId)

if gameInfo then
    Utils.Log("Jeu reconnu : " .. gameInfo.name)
    UI.ShowGameDetected(gameInfo.name)
    Loader.LoadGame(gameInfo, loadModule, UI, Utils)
else
    Utils.Log("Jeu non supporté (PlaceId: " .. tostring(placeId) .. ")")
    UI.ShowNotSupported(placeId)
end

Utils.Log("EXE.HUB prêt.")