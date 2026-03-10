-- EXE.HUB | main.lua
-- Point d'entree principal. Compatible loadstring/executeurs Roblox.

local BASE = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"

local function loadModule(path)
    local url = BASE .. path
    print("[EXE.HUB] Chargement : " .. url)

    -- Etape 1 : telechargement HTTP
    local raw
    local ok1, err1 = pcall(function()
        raw = game:HttpGet(url, true)
    end)
    if not ok1 then
        warn("[EXE.HUB] ECHEC HTTP : " .. path)
        warn("[EXE.HUB] Detail : " .. tostring(err1))
        return nil
    end
    if not raw or raw == "" then
        warn("[EXE.HUB] CONTENU VIDE : " .. path)
        return nil
    end
    print("[EXE.HUB] HTTP OK (" .. #raw .. " chars) : " .. path)

    -- Etape 2 : compilation
    -- On appelle loadstring directement (pas via pcall)
    -- car pcall(loadstring, raw) pose probleme sur certains executeurs
    local fn, compileErr = loadstring(raw)
    if not fn then
        warn("[EXE.HUB] ECHEC COMPILE : " .. path)
        warn("[EXE.HUB] Detail : " .. tostring(compileErr))
        return nil
    end
    print("[EXE.HUB] Compile OK : " .. path)

    -- Etape 3 : execution du module
    local ok3, result = pcall(fn)
    if not ok3 then
        warn("[EXE.HUB] ECHEC EXEC : " .. path)
        warn("[EXE.HUB] Detail : " .. tostring(result))
        return nil
    end
    if result == nil then
        warn("[EXE.HUB] MODULE RETOURNE NIL : " .. path .. " (manque 'return' a la fin ?)")
        return nil
    end
    print("[EXE.HUB] Module OK : " .. path)
    return result
end

print("[EXE.HUB] === DEMARRAGE ===")

local Utils = loadModule("system/utils.lua")
if not Utils then warn("[EXE.HUB] ARRET : utils.lua") return end
print("[EXE.HUB] utils OK")

local Registry = loadModule("system/registry.lua")
if not Registry then warn("[EXE.HUB] ARRET : registry.lua") return end
print("[EXE.HUB] registry OK")

local UI = loadModule("system/ui.lua")
if not UI then warn("[EXE.HUB] ARRET : ui.lua") return end
print("[EXE.HUB] ui OK")

local Loader = loadModule("system/loader.lua")
if not Loader then warn("[EXE.HUB] ARRET : loader.lua") return end
print("[EXE.HUB] loader OK")

print("[EXE.HUB] Tous les modules charges. Lancement UI...")

UI.Init()
UI.ShowWelcome()

local placeId = game.PlaceId
print("[EXE.HUB] PlaceId = " .. tostring(placeId))

local gameInfo = Registry.GetGame(placeId)

if gameInfo then
    print("[EXE.HUB] Jeu reconnu : " .. gameInfo.name)
    UI.ShowGameDetected(gameInfo.name)
    Loader.LoadGame(gameInfo, loadModule, UI, Utils)
else
    print("[EXE.HUB] Jeu non supporte : " .. tostring(placeId))
    UI.ShowNotSupported(placeId)
end

print("[EXE.HUB] === PRET ===")