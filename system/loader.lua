-- EXE.HUB | system/loader.lua

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
        Utils.Log("Init() OK : " .. gameInfo.name)
        UI.ShowGameLoaded(gameInfo.name)
    else
        Utils.Error("Init() echoue : " .. tostring(err))
        UI.ShowLoadError(gameInfo.name)
    end
end

if _G.__EXE_HUB_MODULES then
    _G.__EXE_HUB_MODULES["loader"] = Loader
end

return Loader