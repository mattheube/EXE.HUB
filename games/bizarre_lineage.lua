-- EXE.HUB | games/bizarre_lineage.lua
-- Module jeu : Bizarre Lineage
-- Sans annotations de type (compat loadstring)

local BizarreLineage = {}

BizarreLineage.Name    = "Bizarre Lineage"
BizarreLineage.Version = "1.0.0"

function BizarreLineage.Init(deps)
    local UI    = deps.UI
    local Utils = deps.Utils

    Utils.Log("Bizarre Lineage module charge v" .. BizarreLineage.Version)
    UI.Notify("Bizarre Lineage", "Module v" .. BizarreLineage.Version .. " charge", "success")

    -- Ajouter les features ici plus tard
end

return BizarreLineage