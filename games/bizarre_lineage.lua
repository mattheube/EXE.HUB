-- EXE.HUB | games/bizarre_lineage.lua  v1.0.0
-- Chaque module définit ses propres tabs.
-- Le hub injecte automatiquement Settings, Credits, Logs.
-- ctx keys : cx, cy, cw, ch, C (palette), AC, ACH, PAD, LNHGT,
--            Draw, objs, addZone, buildPicker, regAC, regACH, WX, WY, WW, WH

local BizarreLineage = {}
BizarreLineage.Name    = "Bizarre Lineage"
BizarreLineage.Version = "v1.0.0"

BizarreLineage.Tabs = {

    -- ── Main ─────────────────────────────────────────────────
    {
        name = "Main",
        buildFn = function(ctx)
            local o,cx,cy = ctx.objs, ctx.cx, ctx.cy
            local D = ctx.Draw

            -- Statut
            table.insert(o, D.Text(cx, cy,    "STATUT",         ctx.C.muted, 10, 4))
            local actif = D.Text(cx, cy+16,   "Actif",          ctx.ACH(),   13, 4)
            ctx.regACH(actif)
            table.insert(o, actif)

            -- Séparateur
            cy = cy + 38
            table.insert(o, D.Line(cx, cy, cx+ctx.cw, cy, ctx.C.border, 1, 4))
            cy = cy + 10

            -- Infos jeu
            table.insert(o, D.Text(cx, cy,    "JEU",            ctx.C.muted, 10, 4))
            table.insert(o, D.Text(cx, cy+16, "Bizarre Lineage",ctx.C.white, 13, 4))
            cy = cy + 40
            table.insert(o, D.Text(cx, cy,    "MODULE",         ctx.C.muted, 10, 4))
            local ver = D.Text(cx, cy+16, "v1.0.0",             ctx.ACH(),   12, 4)
            ctx.regACH(ver)
            table.insert(o, ver)
        end
    },

    -- ── Items ─────────────────────────────────────────────────
    {
        name = "Items",
        buildFn = function(ctx)
            local o,cx,cy = ctx.objs, ctx.cx, ctx.cy
            local D = ctx.Draw

            table.insert(o, D.Text(cx, cy, "ITEMS", ctx.C.muted, 10, 4))
            cy = cy + 20

            local items = {
                "Fruit auto-collect",
                "Drop all items",
                "Lock inventory",
            }

            for _,item in ipairs(items) do
                table.insert(o, D.Rect(cx, cy, ctx.cw, 24, ctx.C.tabBg, 4))
                table.insert(o, D.Outline(cx, cy, ctx.cw, 24, ctx.C.border, 1, 4))
                table.insert(o, D.Text(cx+10, cy+6,  item,    ctx.C.white, 11, 5))
                table.insert(o, D.Text(cx+ctx.cw-42, cy+7, "[ OFF ]", ctx.C.muted, 10, 5))
                cy = cy + 28
            end
        end
    },

    -- ── Teleport ──────────────────────────────────────────────
    {
        name = "Teleport",
        buildFn = function(ctx)
            local o,cx,cy = ctx.objs, ctx.cx, ctx.cy
            local D = ctx.Draw

            table.insert(o, D.Text(cx, cy, "TELEPORT", ctx.C.muted, 10, 4))
            cy = cy + 20

            local locations = {
                "Spawn",
                "Arbre du Fruit",
                "Boss Room",
                "Safe Zone",
            }

            for _,loc in ipairs(locations) do
                table.insert(o, D.Rect(cx, cy, ctx.cw, 26, ctx.C.tabBg, 4))
                table.insert(o, D.Outline(cx, cy, ctx.cw, 26, ctx.C.border, 1, 4))
                table.insert(o, D.Text(cx+10, cy+7, loc, ctx.C.white, 11, 5))
                -- flèche accent (recolorée avec le thème)
                local arrow = D.Text(cx+ctx.cw-18, cy+7, ">", ctx.ACH(), 11, 5)
                ctx.regACH(arrow)
                table.insert(o, arrow)
                local lcy = cy
                ctx.addZone(cx, lcy, ctx.cw, 26, function()
                    print("[BL] Teleport vers : "..loc)
                end)
                cy = cy + 30
            end
        end
    },
}

-- ── Init : appelé au chargement ───────────────────────────────
function BizarreLineage.Init(deps)
    deps.Utils.Log("Bizarre Lineage "..BizarreLineage.Version.." charge.")
    deps.UI.Notify("Bizarre Lineage","Module "..BizarreLineage.Version.." charge","success")
end

-- Export
if _G.__EXE_HUB_MODULES then
    _G.__EXE_HUB_MODULES["bizarre_lineage"] = BizarreLineage
end
return BizarreLineage
