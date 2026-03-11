-- EXE.HUB | games/bizarre_lineage.lua
-- Chaque module définit ses propres tabs.
-- Le hub injecte automatiquement Settings, Credits, Logs.
local BizarreLineage = {}
BizarreLineage.Name    = "Bizarre Lineage"
BizarreLineage.Version = "v1.0.0"
-- ── Tabs fournis par ce module ────────────────────────────
-- ctx = { cx, cy, cw, COL, AC, ACH, PADDING, LINE_H,
--         Draw, objs, addZone, WX, WY }
BizarreLineage.Tabs = {
    {
        name = "Main",
        buildFn = function(ctx)
            local o,cx,cy = ctx.objs, ctx.cx, ctx.cy
            local Draw = ctx.Draw
            -- Statut
            table.insert(o, Draw.Text(cx, cy,    "STATUT",  ctx.COL.muted,  9, 4))
            table.insert(o, Draw.Text(cx, cy+14, "Actif",   ctx.ACH(),     12, 4))
            -- Séparateur
            cy = cy + 36
            table.insert(o, Draw.Line(cx, cy, cx+ctx.cw, cy, ctx.COL.border, 1, 4))
            cy = cy + 8
            -- Infos jeu
            table.insert(o, Draw.Text(cx, cy,    "JEU",             ctx.COL.muted,  9, 4))
            table.insert(o, Draw.Text(cx, cy+14, "Bizarre Lineage", ctx.COL.white, 11, 4))
            cy = cy + 34
            table.insert(o, Draw.Text(cx, cy,    "MODULE",          ctx.COL.muted,  9, 4))
            table.insert(o, Draw.Text(cx, cy+14, "v1.0.0",          ctx.ACH(),     10, 4))
        end
    },
    {
        name = "Items",
        buildFn = function(ctx)
            local o,cx,cy = ctx.objs, ctx.cx, ctx.cy
            local Draw = ctx.Draw
            table.insert(o, Draw.Text(cx, cy, "ITEMS", ctx.COL.muted, 9, 4))
            cy = cy + 18
            -- Placeholder — à remplir plus tard
            local items = {
                "Fruit auto-collect",
                "Drop all items",
                "Lock inventory",
            }
            for _,item in ipairs(items) do
                table.insert(o, Draw.Rect(cx, cy, ctx.cw, 22, ctx.COL.tabBg, 4))
                table.insert(o, Draw.Outline(cx, cy, ctx.cw, 22, ctx.COL.border, 1, 4))
                table.insert(o, Draw.Text(cx+8, cy+5, item, ctx.COL.white, 10, 5))
                table.insert(o, Draw.Text(cx+ctx.cw-36, cy+6, "[ OFF ]", ctx.COL.muted, 9, 5))
                cy = cy + 26
            end
        end
    },
    {
        name = "Teleport",
        buildFn = function(ctx)
            local o,cx,cy = ctx.objs, ctx.cx, ctx.cy
            local Draw = ctx.Draw
            table.insert(o, Draw.Text(cx, cy, "TELEPORT", ctx.COL.muted, 9, 4))
            cy = cy + 18
            local locations = {
                "Spawn",
                "Arbre du Fruit",
                "Boss Room",
                "Safe Zone",
            }
            for _,loc in ipairs(locations) do
                local btn = Draw.Rect(cx, cy, ctx.cw, 24, ctx.COL.tabBg, 4)
                table.insert(o, btn)
                table.insert(o, Draw.Outline(cx, cy, ctx.cw, 24, ctx.COL.border, 1, 4))
                table.insert(o, Draw.Text(cx+8, cy+6, loc, ctx.COL.white, 10, 5))
                -- Arrow indicator
                table.insert(o, Draw.Text(cx+ctx.cw-18, cy+6, ">", ctx.ACH(), 10, 5))
                local lcy = cy
                ctx.addZone(cx, lcy, ctx.cw, 24, function()
                    -- tp logic ici
                    print("[BL] Teleport vers : "..loc)
                end)
                cy = cy + 28
            end
        end
    },
}
-- ── Init : appelé au chargement ───────────────────────────
function BizarreLineage.Init(deps)
    local Utils = deps.Utils
    Utils.Log("Bizarre Lineage "..BizarreLineage.Version.." charge.")
    deps.UI.Notify("Bizarre Lineage", "Module "..BizarreLineage.Version.." charge", "success")
end
-- Export
if _G.__EXE_HUB_MODULES then
    _G.__EXE_HUB_MODULES["bizarre_lineage"] = BizarreLineage
end
return BizarreLineage
