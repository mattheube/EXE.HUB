-- ============================================================
--  EXE.HUB | system/utils.lua
--  Utilitaires généraux du hub.
--  Fonctions de log, de formatage, et helpers réutilisables
--  dans tous les autres modules.
-- ============================================================

local Utils = {}

-- ============================================================
-- CONSTANTES
-- ============================================================

local HUB_NAME    = "EXE.HUB"
local HUB_VERSION = "1.0.0"

-- ============================================================
-- LOGGING
-- Affiche un message formaté dans la console Roblox.
-- Tous les messages du hub sont préfixés par [EXE.HUB].
-- ============================================================

function Utils.Log(message: string)
    print(string.format("[%s] %s", HUB_NAME, tostring(message)))
end

function Utils.Warn(message: string)
    warn(string.format("[%s] ⚠ %s", HUB_NAME, tostring(message)))
end

function Utils.Error(message: string)
    warn(string.format("[%s] ✖ ERREUR : %s", HUB_NAME, tostring(message)))
end

-- ============================================================
-- INFORMATIONS DU HUB
-- ============================================================

function Utils.GetVersion(): string
    return HUB_VERSION
end

function Utils.GetName(): string
    return HUB_NAME
end

-- ============================================================
-- FORMATAGE TEMPOREL
-- Retourne l'heure actuelle formatée (tick depuis le lancement)
-- Roblox n'expose pas os.date côté client, on utilise tick().
-- ============================================================

function Utils.GetTimestamp(): string
    return string.format("%.2f", tick())
end

-- ============================================================
-- SAFE CALL
-- Exécute une fonction de manière sécurisée.
-- Affiche l'erreur proprement si elle échoue.
-- ============================================================

function Utils.SafeCall(fn: () -> (), label: string?)
    local tag = label or "SafeCall"
    local success, err = pcall(fn)
    if not success then
        Utils.Error(string.format("[%s] %s", tag, tostring(err)))
    end
end

-- ============================================================
-- WAIT UTILITAIRE
-- Encapsule task.wait pour centraliser les pauses.
-- ============================================================

function Utils.Wait(duration: number)
    task.wait(duration)
end

-- ============================================================
-- VÉRIFICATION DE TYPE SIMPLE
-- Vérifie qu'une valeur est non-nil et du bon type.
-- ============================================================

function Utils.Expect(value: any, expectedType: string, label: string?): boolean
    local tag = label or "Expect"
    if value == nil then
        Utils.Error(string.format("[%s] Valeur nil inattendue.", tag))
        return false
    end
    if typeof(value) ~= expectedType then
        Utils.Error(string.format(
            "[%s] Type attendu : %s, reçu : %s",
            tag, expectedType, typeof(value)
        ))
        return false
    end
    return true
end

return Utils