-- EXE.HUB | main.lua
-- Anti-cache : timestamp dans l'URL pour forcer GitHub a servir la derniere version

local BASE = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"

-- Timestamp unique a chaque execution = contourne le cache GitHub/executeur
local CACHE_BUST = "?t=" .. tostring(math.floor(tick()))

_G.__EXE_HUB_MODULES = {}

local function loadModule(path)
    local url = BASE .. path .. CACHE_BUST
    print("[EXE.HUB] >> " .. url)

    local raw
    pcall(function() raw = game:HttpGet(url, true) end)
    if not raw or raw == "" then
        warn("[EXE.HUB] ECHEC HTTP : " .. path)
        return nil
    end
    print("[EXE.HUB] HTTP OK (" .. #raw .. " chars) : " .. path)

    local fn, compileErr = loadstring(raw)
    if not fn then
        warn("[EXE.HUB] ECHEC COMPILE : " .. path .. " | " .. tostring(compileErr))
        return nil
    end
    print("[EXE.HUB] Compile OK : " .. path)

    local ok, result = pcall(fn)
    if not ok then
        warn("[EXE.HUB] ECHEC EXEC : " .. path .. " | " .. tostring(result))
        return nil
    end
    print("[EXE.HUB] Exec OK : " .. path)

    -- Priorite 1 : return direct
    if result ~= nil then
        print("[EXE.HUB] Charge via return : " .. path)
        return result
    end

    -- Priorite 2 : depot dans _G (fallback executeurs Matcha/etc.)
    local key = path:match("([^/]+)%.lua$")
    if key and _G.__EXE_HUB_MODULES[key] then
        print("[EXE.HUB] Charge via _G : " .. path)
        local mod = _G.__EXE_HUB_MODULES[key]
        _G.__EXE_HUB_MODULES[key] = nil
        return mod
    end

    warn("[EXE.HUB] NIL apres exec : " .. path)
    return nil
end

print("[EXE.HUB] === DEMARRAGE v" .. tostring(math.floor(tick())) .. " ===")

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