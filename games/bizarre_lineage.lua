-- EXE.HUB | games/bizarre_lineage.lua

local BizarreLineage = {}

BizarreLineage.Name    = "Bizarre Lineage"
BizarreLineage.Version = "1.0.0"

function BizarreLineage.Init(deps)
    local UI    = deps.UI
    local Utils = deps.Utils
    Utils.Log("Bizarre Lineage v" .. BizarreLineage.Version .. " charge.")
    UI.Notify("Bizarre Lineage", "Module v" .. BizarreLineage.Version .. " charge", "success")
end

if _G.__EXE_HUB_MODULES then
    _G.__EXE_HUB_MODULES["bizarre_lineage"] = BizarreLineage
end

return BizarreLineage