-- ============================================================
--  EXE.HUB | system/loader.lua
--  Système de chargement des modules de jeux.
--  Reçoit les informations du jeu depuis le registre,
--  charge le module distant via HttpGet + loadstring,
--  puis appelle sa fonction Init().
-- ============================================================

local Loader = {}

-- ============================================================
-- FONCTION PRINCIPALE : Charge et initialise un module de jeu
--
-- Paramètres :
--   gameInfo   : table { name: string, module: string }
--   loadModule : fonction de chargement distant (de main.lua)
--   UI         : module UI (pour notifications)
--   Utils      : module Utils (pour logs)
-- ============================================================

function Loader.LoadGame(
    gameInfo: {name: string, module: string},
    loadModule: (path: string) -> any,
    UI: any,
    Utils: any
)
    -- Validation des paramètres
    if not gameInfo or not gameInfo.name or not gameInfo.module then
        Utils.Error("LoadGame : gameInfo invalide.")
        return
    end

    Utils.Log("Chargement du module : " .. gameInfo.module)

    -- Charge le module depuis GitHub
    local gameModule = loadModule(gameInfo.module)

    if not gameModule then
        -- Échec du chargement (réseau, fichier absent, erreur de syntaxe)
        Utils.Error("Impossible de charger le module : " .. gameInfo.module)
        UI.ShowLoadError(gameInfo.name)
        return
    end

    -- Vérifie que le module expose bien une fonction Init
    if typeof(gameModule.Init) ~= "function" then
        Utils.Error("Le module '" .. gameInfo.name .. "' n'expose pas de fonction Init().")
        UI.ShowLoadError(gameInfo.name .. " (Init manquant)")
        return
    end

    Utils.Log("Module chargé, appel de Init() pour : " .. gameInfo.name)

    -- Appel sécurisé de Init() avec injection des dépendances
    -- On passe UI et Utils pour que les modules jeux puissent
    -- afficher des notifications et logger proprement.
    local success, err = pcall(function()
        gameModule.Init({
            UI    = UI,
            Utils = Utils,
        })
    end)

    if success then
        Utils.Log("Init() terminé avec succès pour : " .. gameInfo.name)
        UI.ShowGameLoaded(gameInfo.name)
    else
        Utils.Error("Erreur dans Init() de '" .. gameInfo.name .. "' : " .. tostring(err))
        UI.ShowLoadError(gameInfo.name .. " (Init a échoué)")
    end
end

return Loader