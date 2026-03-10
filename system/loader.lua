-- EXE.HUB | system/loader.lua
-- Charge et initialise les modules de jeux. Sans annotations de type.

local Loader = {}

function Loader.LoadGame(gameInfo, loadModule, UI, Utils)
    if not gameInfo or not gameInfo.name or not gameInfo.module then
        Utils.Error("LoadGame : gameInfo invalide")
        return
    end

    Utils.Log("Chargement module jeu : " .. gameInfo.module)

    local gameModule = loadModule(gameInfo.module)

    if not gameModule then
        Utils.Error("Module introuvable : " .. gameInfo.name)
        UI.ShowLoadError(gameInfo.name)
        return
    end

    if type(gameModule.Init) ~= "function" then
        Utils.Error("Init() manquant dans : " .. gameInfo.name)
        UI.ShowLoadError(gameInfo.name .. " (Init manquant)")
        return
    end

    Utils.Log("Appel Init() pour : " .. gameInfo.name)

    local ok, err = pcall(function()
        gameModule.Init({ UI = UI, Utils = Utils })
    end)

    if ok then
        Utils.Log("Init() OK pour : " .. gameInfo.name)
        UI.ShowGameLoaded(gameInfo.name)
    else
        Utils.Error("Init() echoue pour " .. gameInfo.name .. " : " .. tostring(err))
        UI.ShowLoadError(gameInfo.name .. " (Init echoue)")
    end
end

return Loader