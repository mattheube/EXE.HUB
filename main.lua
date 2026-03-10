-- EXE.HUB | main.lua
-- Compatible tous executeurs Roblox (Matcha, Synapse, etc.)

local BASE = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"

-- Table partagee globale : les modules y deposent leur resultat
-- au lieu de faire "return". Contourne les bugs de loadstring
-- sur certains executeurs ou le retour est perdu.
_G.__EXE_HUB_MODULES = {}

local function loadModule(path)
    local url = BASE .. path
    print("[EXE.HUB] Chargement : " .. url)

    -- HTTP
    local raw
    pcall(function() raw = game:HttpGet(url, true) end)
    if not raw or raw == "" then
        warn("[EXE.HUB] ECHEC HTTP : " .. path)
        return nil
    end
    print("[EXE.HUB] HTTP OK (" .. #raw .. " chars)")

    -- Compilation
    local fn, err = loadstring(raw)
    if not fn then
        warn("[EXE.HUB] ECHEC COMPILE : " .. path .. " | " .. tostring(err))
        return nil
    end
    print("[EXE.HUB] Compile OK : " .. path)

    -- Execution
    local ok, result = pcall(fn)
    if not ok then
        warn("[EXE.HUB] ECHEC EXEC : " .. path .. " | " .. tostring(result))
        return nil
    end
    print("[EXE.HUB] Exec OK : " .. path)

    -- Priorite 1 : valeur retournee directement (result non nil)
    if result ~= nil then
        print("[EXE.HUB] Module charge via return : " .. path)
        return result
    end

    -- Priorite 2 : module depose dans _G.__EXE_HUB_MODULES
    local key = path:match("([^/]+)%.lua$")
    if key and _G.__EXE_HUB_MODULES[key] then
        print("[EXE.HUB] Module charge via _G : " .. path)
        local mod = _G.__EXE_HUB_MODULES[key]
        _G.__EXE_HUB_MODULES[key] = nil
        return mod
    end

    warn("[EXE.HUB] MODULE NIL apres exec : " .. path)
    return nil
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