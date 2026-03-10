-- EXE.HUB | main.lua
-- Point d'entree principal. Compatible loadstring/executeurs Roblox.
-- IMPORTANT : Aucune annotation de type LuaU ici (non supportees par loadstring)

local BASE = "https://raw.githubusercontent.com/mattheube/EXE.HUB/refs/heads/main/"

-- Charge un module distant depuis GitHub
local function loadModule(path)
    local url = BASE .. path
    print("[EXE.HUB] Chargement : " .. url)

    -- Etape 1 : telechargement
    local ok1, raw = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not ok1 or not raw or raw == "" then
        warn("[EXE.HUB] ECHEC HTTP : " .. path .. " | " .. tostring(raw))
        return nil
    end
    print("[EXE.HUB] HTTP OK (" .. #raw .. " chars) : " .. path)

    -- Etape 2 : compilation
    local ok2, fn = pcall(loadstring, raw)
    if not ok2 or type(fn) ~= "function" then
        warn("[EXE.HUB] ECHEC COMPILE : " .. path .. " | " .. tostring(fn))
        return nil
    end
    print("[EXE.HUB] Compile OK : " .. path)

    -- Etape 3 : execution
    local ok3, result = pcall(fn)
    if not ok3 then
        warn("[EXE.HUB] ECHEC EXEC : " .. path .. " | " .. tostring(result))
        return nil
    end
    print("[EXE.HUB] Module OK : " .. path)
    return result
end

print("[EXE.HUB] === DEMARRAGE ===")

local Utils = loadModule("system/utils.lua")
if not Utils then warn("[EXE.HUB] ARRET : utils.lua") return end

local Registry = loadModule("system/registry.lua")
if not Registry then warn("[EXE.HUB] ARRET : registry.lua") return end

local UI = loadModule("system/ui.lua")
if not UI then warn("[EXE.HUB] ARRET : ui.lua") return end

local Loader = loadModule("system/loader.lua")
if not Loader then warn("[EXE.HUB] ARRET : loader.lua") return end

print("[EXE.HUB] Tous les modules charges.")

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