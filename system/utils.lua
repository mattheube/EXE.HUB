-- EXE.HUB | system/utils.lua
-- Utilitaires generaux. Sans annotations de type (compat loadstring).

local Utils = {}

local PREFIX = "[EXE.HUB]"

function Utils.Log(msg)
    print(PREFIX .. " " .. tostring(msg))
end

function Utils.Warn(msg)
    warn(PREFIX .. " WARN : " .. tostring(msg))
end

function Utils.Error(msg)
    warn(PREFIX .. " ERREUR : " .. tostring(msg))
end

function Utils.SafeCall(fn, label)
    local ok, err = pcall(fn)
    if not ok then
        warn(PREFIX .. " SafeCall [" .. tostring(label) .. "] : " .. tostring(err))
    end
end

return Utils