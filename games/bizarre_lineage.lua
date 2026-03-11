-- EXE.HUB | games/bizarre_lineage.lua  v1.0.1
local BizarreLineage = {}
BizarreLineage.Name    = "Bizarre Lineage"
BizarreLineage.Version = "v1.0.1"

-- Changelog affiché dans l'onglet Logs
BizarreLineage.Changelog = {
    "v1.0.1  — Fix zones overlap, ctx.C corrigé",
    "v1.0.0  — Version initiale (Main, Items, Teleport)",
}

BizarreLineage.Tabs = {

    {name="Main", buildFn=function(ctx)
        local o,cx,cy = ctx.objs,ctx.cx,ctx.cy
        local D = ctx.Draw
        o[#o+1] = D.Text(cx,cy,    "STATUT",         ctx.C.muted,10,4)
        local a  = ctx.regACH(D.Text(cx,cy+16,"Actif",ctx.ACH(),13,4))
        o[#o+1] = a
        cy = cy + 40
        o[#o+1] = D.Line(cx,cy,cx+ctx.cw,cy,ctx.C.border,1,4)
        cy = cy + 10
        o[#o+1] = D.Text(cx,cy,    "JEU",            ctx.C.muted,10,4)
        o[#o+1] = D.Text(cx,cy+16,"Bizarre Lineage", ctx.C.white,13,4)
        cy = cy + 40
        o[#o+1] = D.Text(cx,cy,    "MODULE",         ctx.C.muted,10,4)
        local v  = ctx.regACH(D.Text(cx,cy+16,"v1.0.1",ctx.ACH(),12,4))
        o[#o+1] = v
    end},

    {name="Items", buildFn=function(ctx)
        local o,cx,cy = ctx.objs,ctx.cx,ctx.cy
        local D = ctx.Draw
        o[#o+1] = D.Text(cx,cy,"ITEMS",ctx.C.muted,10,4)
        cy = cy + 20
        local items = {"Fruit auto-collect","Drop all items","Lock inventory"}
        for _,item in ipairs(items) do
            o[#o+1] = D.Rect(cx,cy,ctx.cw,24,ctx.C.tabBg,4)
            o[#o+1] = D.Outline(cx,cy,ctx.cw,24,ctx.C.border,1,4)
            o[#o+1] = D.Text(cx+10,cy+6, item,    ctx.C.white,11,5)
            o[#o+1] = D.Text(cx+ctx.cw-44,cy+7,"[ OFF ]",ctx.C.muted,10,5)
            cy = cy + 28
        end
    end},

    {name="Teleport", buildFn=function(ctx)
        local o,cx,cy = ctx.objs,ctx.cx,ctx.cy
        local D = ctx.Draw
        o[#o+1] = D.Text(cx,cy,"TELEPORT",ctx.C.muted,10,4)
        cy = cy + 20
        local locs = {"Spawn","Arbre du Fruit","Boss Room","Safe Zone"}
        for _,loc in ipairs(locs) do
            o[#o+1] = D.Rect(cx,cy,ctx.cw,26,ctx.C.tabBg,4)
            o[#o+1] = D.Outline(cx,cy,ctx.cw,26,ctx.C.border,1,4)
            o[#o+1] = D.Text(cx+10,cy+7,loc,ctx.C.white,11,5)
            local arr = ctx.regACH(D.Text(cx+ctx.cw-18,cy+7,">",ctx.ACH(),11,5))
            o[#o+1] = arr
            local lcy = cy
            ctx.addZone(cx,lcy,ctx.cw,26,function()
                print("[BL] Teleport: "..loc)
            end)
            cy = cy + 30
        end
    end},
}

function BizarreLineage.Init(deps)
    deps.Utils.Log("Bizarre Lineage "..BizarreLineage.Version.." chargé.")
    deps.UI.Notify("Bizarre Lineage","Module "..BizarreLineage.Version.." chargé","success")
end

if _G.__EXE_HUB_MODULES then
    _G.__EXE_HUB_MODULES["bizarre_lineage"] = BizarreLineage
end
return BizarreLineage