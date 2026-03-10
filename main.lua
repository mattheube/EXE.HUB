-- ╔══════════════════════════════════════════════════════════╗
-- ║  EXE.HUB  |  main.lua  —  Drawing API (Matcha)  v2.1   ║
-- ╚══════════════════════════════════════════════════════════╝
--
-- ARCHITECTURE DES MODULES JEUX :
--   Chaque module jeu retourne une table avec :
--     module.Name     : string   — nom du jeu
--     module.Version  : string   — version du module
--     module.Tabs     : table    — liste de tabs { name, build(ctx) }
--     module.Init(ctx): function — appelée au chargement
--
--   Le hub lit module.Tabs pour construire les onglets dynamiquement.
--   Les tabs "Settings" et "Credits" sont toujours ajoutés par le hub.
--   Cette approche est scalable : chaque jeu définit ses propres tabs.

local BASE       = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"
local CACHE_BUST = "?t=" .. tostring(math.floor(tick()))

print("[EXE.HUB] === DEMARRAGE ===")

-- ============================================================
-- UTILS
-- ============================================================
local Utils = {}
do
    local P = "[EXE.HUB]"
    function Utils.Log(m)   print(P.." "..tostring(m)) end
    function Utils.Warn(m)  warn(P.." WARN: "..tostring(m)) end
    function Utils.Error(m) warn(P.." ERR: "..tostring(m)) end
    function Utils.SafeCall(fn, lbl)
        local ok, e = pcall(fn)
        if not ok then warn(P.." ["..tostring(lbl).."] "..tostring(e)) end
    end
end
print("[EXE.HUB] utils OK")

-- ============================================================
-- REGISTRY
-- ============================================================
local Registry = {}
do
    local games = {
        [14890802310] = {
            name    = "Bizarre Lineage",
            version = "v1.0.0",
            module  = "games/bizarre_lineage.lua",
        },
    }
    function Registry.GetGame(id)     return games[id] or nil end
    function Registry.IsSupported(id) return games[id] ~= nil end
end
print("[EXE.HUB] registry OK")

-- ============================================================
-- DRAWING HELPERS  (standalone, utilisés par UI + modules)
-- ============================================================
local Draw = {}
do
    local pool = {}

    function Draw.new(cls)
        local o = Drawing.new(cls)
        table.insert(pool, o)
        return o
    end

    -- Carré rempli
    function Draw.Rect(x,y,w,h,col,z)
        local o = Draw.new("Square")
        o.Position     = Vector2.new(x,y)
        o.Size         = Vector2.new(w,h)
        o.Color        = col
        o.Filled       = true
        o.Transparency = 1
        o.Thickness    = 1
        o.ZIndex       = z or 1
        o.Visible      = false
        return o
    end

    -- Contour (non rempli)
    function Draw.Outline(x,y,w,h,col,thick,z)
        local o = Draw.new("Square")
        o.Position     = Vector2.new(x,y)
        o.Size         = Vector2.new(w,h)
        o.Color        = col
        o.Filled       = false
        o.Thickness    = thick or 1.5
        o.Transparency = 1
        o.ZIndex       = z or 2
        o.Visible      = false
        return o
    end

    -- Texte
    function Draw.Text(x,y,str,col,sz,z)
        local o = Draw.new("Text")
        o.Position = Vector2.new(x,y)
        o.Text     = str
        o.Color    = col
        o.Size     = sz or 13
        o.ZIndex   = z or 3
        o.Outline  = false
        o.Center   = false
        o.Visible  = false
        return o
    end

    -- Ligne
    function Draw.Line(x1,y1,x2,y2,col,thick,z)
        local o = Draw.new("Line")
        o.From        = Vector2.new(x1,y1)
        o.To          = Vector2.new(x2,y2)
        o.Color       = col
        o.Thickness   = thick or 1
        o.Transparency = 1
        o.ZIndex      = z or 2
        o.Visible     = false
        return o
    end

    -- Affiche / cache un groupe
    function Draw.SetVisible(group, v)
        for _,o in ipairs(group) do pcall(function() o.Visible = v end) end
    end

    -- Détruit un groupe et le vide
    function Draw.Destroy(group)
        for _,o in ipairs(group) do pcall(function() o:Remove() end) end
        table.clear(group)
    end

    -- Déplace un groupe de (dx,dy)
    function Draw.Move(group, dx, dy)
        for _,o in ipairs(group) do
            pcall(function()
                if rawget(o,"Position") ~= nil then
                    o.Position = Vector2.new(o.Position.X+dx, o.Position.Y+dy)
                end
                if rawget(o,"From") ~= nil then
                    o.From = Vector2.new(o.From.X+dx, o.From.Y+dy)
                    o.To   = Vector2.new(o.To.X+dx,   o.To.Y+dy)
                end
            end)
        end
    end

    function Draw.DestroyAll()
        for _,o in ipairs(pool) do pcall(function() o:Remove() end) end
        table.clear(pool)
    end
end

-- ============================================================
-- UI
-- ============================================================
local UI = {}
do
    -- ── résolution ──────────────────────────────────────────
    local SW, SH = 1920, 1080
    pcall(function()
        SW = workspace.CurrentCamera.ViewportSize.X
        SH = workspace.CurrentCamera.ViewportSize.Y
    end)

    -- ── thèmes ──────────────────────────────────────────────
    local THEMES = {
        { name="Sakura", accent=Color3.fromRGB(220,80,140),  hi=Color3.fromRGB(255,130,180) },
        { name="Blue",   accent=Color3.fromRGB(60,130,255),  hi=Color3.fromRGB(120,180,255) },
        { name="Green",  accent=Color3.fromRGB(60,210,130),  hi=Color3.fromRGB(120,240,170) },
        { name="Red",    accent=Color3.fromRGB(230,60,60),   hi=Color3.fromRGB(255,110,110) },
    }
    local themeIdx = 1
    local function AC()  return THEMES[themeIdx].accent end
    local function ACH() return THEMES[themeIdx].hi     end

    -- ── palette fixe ────────────────────────────────────────
    local COL = {
        bg       = Color3.fromRGB(13,12,20),
        panel    = Color3.fromRGB(18,17,28),
        titleBg  = Color3.fromRGB(10, 8,18),
        tabBg    = Color3.fromRGB(20,18,30),
        tabHover = Color3.fromRGB(28,24,40),
        tabSel   = Color3.fromRGB(32,26,46),
        border   = Color3.fromRGB(42,30,58),
        white    = Color3.fromRGB(235,235,248),
        muted    = Color3.fromRGB(120, 95,138),
        dimmed   = Color3.fromRGB( 80, 65,100),
        green    = Color3.fromRGB(90, 210,130),
        yellow   = Color3.fromRGB(250,195, 75),
        red      = Color3.fromRGB(250, 85, 85),
        notifBg  = Color3.fromRGB(14,11,22),
        petal    = Color3.fromRGB(255,175,205),
    }

    -- ── dimensions fenêtre ──────────────────────────────────
    -- Portrait : ~SW/5.5 de large, ~SH/2.8 de haut
    local WW = math.max(260, math.floor(SW / 5.5))
    local WH = math.max(420, math.floor(SH / 2.8))
    local WX = math.floor(SW/2 - WW/2)
    local WY = math.floor(SH/2 - WH/2)

    local TITLE_H  = 36      -- hauteur barre titre
    local TAB_H    = 28      -- hauteur barre onglets
    local CONT_Y   = TITLE_H + TAB_H   -- début zone contenu (relatif à WY)
    local PADDING  = 14      -- padding intérieur
    local LINE_H   = 20      -- hauteur d'une ligne de texte

    -- ── état ────────────────────────────────────────────────
    local uiReady    = false
    local uiVisible  = true
    local activeTab  = 1
    local toggleKey  = Enum.KeyCode.F1

    -- listes d'objets Drawing
    local baseObjs   = {}    -- fond + titre + onglets (persistants)
    local glowLines  = {}    -- 4 lignes de bord animées
    local tabObjs    = {}    -- tabObjs[i] = liste d'objets du tab i
    local tabBtnObjs = {}    -- tabBtnObjs[i] = {bg, label, line}
    local notifList  = {}    -- notifications actives
    local petalObjs  = {}    -- pétales

    -- zones cliquables : liste de {x,y,w,h,fn}
    local zones      = {}

    -- onglets courants (définis par module jeu + hub)
    local currentTabs = {}   -- { name, buildFn }

    -- données dynamiques
    local dynGameName = "—"
    local dynGameVer  = "—"
    local lblTitleGame   = nil
    local lblTitleVer    = nil
    local logLines       = {}

    -- ── zone cliquable ──────────────────────────────────────
    local function addZone(x,y,w,h,fn)
        table.insert(zones, {x=x,y=y,w=w,h=h,fn=fn})
        return #zones
    end
    local function clearZones()
        table.clear(zones)
    end

    -- ── construction du contenu d'un onglet ─────────────────
    -- Retourne la liste des objets créés
    local function buildTabContent(tabIdx)
        local objs = {}
        local cx = WX + PADDING
        local cy = WY + CONT_Y + PADDING
        local cw = WW - PADDING*2

        local tab = currentTabs[tabIdx]
        if not tab then return objs end

        -- Si le tab fournit une fonction build, on l'appelle
        if type(tab.buildFn) == "function" then
            local ok, err = pcall(function()
                tab.buildFn({
                    cx=cx, cy=cy, cw=cw,
                    COL=COL, AC=AC, ACH=ACH,
                    PADDING=PADDING, LINE_H=LINE_H,
                    Draw=Draw, objs=objs,
                    addZone=addZone,
                    WX=function() return WX end,
                    WY=function() return WY end,
                })
            end)
            if not ok then
                local t = Draw.Text(cx, cy, "Erreur: "..tostring(err), COL.red, 10, 4)
                table.insert(objs, t)
            end
        end

        return objs
    end

    -- ── bascule onglet ──────────────────────────────────────
    local function switchTab(newIdx)
        if newIdx == activeTab then return end

        -- cache ancien
        if tabObjs[activeTab] then
            Draw.SetVisible(tabObjs[activeTab], false)
        end
        -- reset style ancien bouton
        local old = tabBtnObjs[activeTab]
        if old then
            old.bg.Color    = COL.tabBg
            old.label.Color = COL.muted
            old.line.Visible = false
        end

        activeTab = newIdx

        -- construit si pas encore fait
        if not tabObjs[activeTab] then
            tabObjs[activeTab] = buildTabContent(activeTab)
            -- ajoute dans baseObjs pour le déplacement
            for _, o in ipairs(tabObjs[activeTab]) do
                table.insert(baseObjs, o)
            end
        end

        Draw.SetVisible(tabObjs[activeTab], uiVisible)

        -- met en valeur nouveau bouton
        local nw = tabBtnObjs[activeTab]
        if nw then
            nw.bg.Color    = COL.tabSel
            nw.label.Color = ACH()
            nw.line.Color  = AC()
            nw.line.Visible = uiVisible
        end
    end

    -- ── construction fenêtre principale ─────────────────────
    local function buildWindow()
        clearZones()
        table.clear(baseObjs)
        table.clear(glowLines)
        table.clear(tabBtnObjs)
        table.clear(tabObjs)

        local x,y = WX,WY

        -- fond principal
        table.insert(baseObjs, Draw.Rect(x,y,WW,WH, COL.bg, 1))

        -- ── barre de titre ──────────────────────────────────
        table.insert(baseObjs, Draw.Rect(x, y, WW, TITLE_H, COL.titleBg, 2))

        -- "EXE.HUB"
        table.insert(baseObjs, Draw.Text(x+PADDING, y+10, "EXE.HUB", ACH(), 14, 5))

        -- séparateur vertical fin
        table.insert(baseObjs, Draw.Line(x+88, y+8, x+88, y+TITLE_H-8, COL.border, 1, 4))

        -- nom jeu + version (dynamiques)
        lblTitleGame = Draw.Text(x+96, y+11, dynGameName, COL.muted, 11, 5)
        table.insert(baseObjs, lblTitleGame)

        lblTitleVer = Draw.Text(x+WW-PADDING, y+11, dynGameVer, COL.dimmed, 10, 5)
        -- alignement droite approximatif : on positionne avec un offset fixe
        lblTitleVer.Position = Vector2.new(x+WW-60, y+11)
        table.insert(baseObjs, lblTitleVer)

        -- ligne de séparation titre / onglets
        table.insert(baseObjs, Draw.Line(x, y+TITLE_H, x+WW, y+TITLE_H, COL.border, 1, 3))

        -- ── barre onglets ────────────────────────────────────
        local tabY = y + TITLE_H
        local nTabs = #currentTabs
        local tabW  = math.floor(WW / math.max(nTabs, 1))

        for i, tab in ipairs(currentTabs) do
            local tx = x + (i-1)*tabW
            local isSel = (i == activeTab)

            local tbg = Draw.Rect(tx, tabY, tabW, TAB_H,
                isSel and COL.tabSel or COL.tabBg, 2)
            table.insert(baseObjs, tbg)

            -- séparateur entre onglets
            if i > 1 then
                local sep = Draw.Line(tx, tabY+4, tx, tabY+TAB_H-4, COL.border, 1, 3)
                table.insert(baseObjs, sep)
            end

            -- label centré dans l'onglet
            local labelX = tx + math.floor(tabW/2) - math.floor(#tab.name * 3)
            local tlbl = Draw.Text(labelX, tabY+8,
                tab.name,
                isSel and ACH() or COL.muted,
                10, 4)
            table.insert(baseObjs, tlbl)

            -- soulignement
            local tline = Draw.Line(tx+3, tabY+TAB_H-2, tx+tabW-3, tabY+TAB_H-2,
                AC(), 1.5, 4)
            tline.Visible = isSel
            table.insert(baseObjs, tline)

            tabBtnObjs[i] = {bg=tbg, label=tlbl, line=tline}

            -- zone cliquable
            local ci = i
            addZone(tx, tabY, tabW, TAB_H, function()
                switchTab(ci)
            end)
        end

        -- ligne de séparation onglets / contenu
        table.insert(baseObjs, Draw.Line(x, y+CONT_Y, x+WW, y+CONT_Y, COL.border, 1, 3))

        -- fond zone contenu
        table.insert(baseObjs, Draw.Rect(x, y+CONT_Y, WW, WH-CONT_Y, COL.panel, 1))

        -- ── contour + glow ───────────────────────────────────
        -- contour fixe sombre
        table.insert(baseObjs, Draw.Outline(x,y,WW,WH, COL.border, 1, 3))

        -- 4 lignes de glow animé
        local function gl(x1,y1,x2,y2)
            local l = Draw.Line(x1,y1,x2,y2, AC(), 1.5, 4)
            l.Transparency = 0.7
            table.insert(baseObjs, l)
            table.insert(glowLines, l)
            return l
        end
        gl(x,    y,    x+WW, y)        -- top
        gl(x+WW, y,    x+WW, y+WH)     -- right
        gl(x+WW, y+WH, x,    y+WH)     -- bottom
        gl(x,    y+WH, x,    y)        -- left

        -- ── construit l'onglet actif ─────────────────────────
        tabObjs[activeTab] = buildTabContent(activeTab)
        for _, o in ipairs(tabObjs[activeTab]) do
            table.insert(baseObjs, o)
        end
    end

    -- ── onglets par défaut (avant chargement d'un module) ───
    local function makeDefaultTabs()
        currentTabs = {
            {
                name = "Main",
                buildFn = function(ctx)
                    local cx,cy = ctx.cx, ctx.cy
                    local o = ctx.objs
                    table.insert(o, Draw.Text(cx, cy,    "Statut",      ctx.COL.muted,  10, 4))
                    table.insert(o, Draw.Text(cx, cy+14, "En attente...", ctx.ACH(),    12, 4))
                    table.insert(o, Draw.Text(cx, cy+38, "Jeu",          ctx.COL.muted, 10, 4))
                    table.insert(o, Draw.Text(cx, cy+52, dynGameName,    ctx.COL.white, 12, 4))
                    table.insert(o, Draw.Text(cx, cy+76, "Version",      ctx.COL.muted, 10, 4))
                    table.insert(o, Draw.Text(cx, cy+90, dynGameVer,     ctx.COL.white, 12, 4))
                end
            },
            {
                name = "Settings",
                buildFn = function(ctx)
                    local cx,cy,cw = ctx.cx, ctx.cy, ctx.cw
                    local o = ctx.objs
                    local sy = cy

                    -- ── Thème ──
                    table.insert(o, Draw.Text(cx, sy, "THEME", ctx.COL.muted, 9, 4))
                    sy = sy + 16

                    local btnW = math.floor((cw - 3*4) / 4)
                    for ti, th in ipairs(THEMES) do
                        local bx = cx + (ti-1)*(btnW+4)
                        local isSel = (ti == themeIdx)
                        local btn = Draw.Rect(bx, sy, btnW, 22, th.accent, 4)
                        btn.Transparency = isSel and 1 or 0.5
                        table.insert(o, btn)
                        local lx = bx + math.floor(btnW/2) - math.floor(#th.name*3)
                        local lbl = Draw.Text(lx, sy+5, th.name, ctx.COL.white, 9, 5)
                        table.insert(o, lbl)
                        local tii = ti
                        ctx.addZone(bx, sy, btnW, 22, function()
                            themeIdx = tii
                            -- update couleurs glow + onglet actif
                            for _, gl in ipairs(glowLines) do
                                pcall(function() gl.Color = AC() end)
                            end
                            if tabBtnObjs[activeTab] then
                                tabBtnObjs[activeTab].label.Color = ACH()
                                tabBtnObjs[activeTab].line.Color  = AC()
                            end
                        end)
                    end
                    sy = sy + 32

                    -- ── Touche toggle ──
                    table.insert(o, Draw.Text(cx, sy, "TOUCHE AFFICHAGE (actuel: "..tostring(toggleKey)..")", ctx.COL.muted, 9, 4))
                    sy = sy + 16

                    local keys = {
                        {name="F1",  code=Enum.KeyCode.F1},
                        {name="F2",  code=Enum.KeyCode.F2},
                        {name="F3",  code=Enum.KeyCode.F3},
                        {name="Ins", code=Enum.KeyCode.Insert},
                        {name="RS",  code=Enum.KeyCode.RightShift},
                    }
                    local kbtnW = math.floor((cw - 4*4) / 5)
                    for ki, k in ipairs(keys) do
                        local bx = cx + (ki-1)*(kbtnW+4)
                        local isSel = (k.code == toggleKey)
                        local kbg = Draw.Rect(bx, sy, kbtnW, 22,
                            isSel and ctx.COL.tabSel or ctx.COL.tabBg, 4)
                        table.insert(o, kbg)
                        if isSel then
                            local kb_out = Draw.Outline(bx, sy, kbtnW, 22, ctx.AC(), 1, 5)
                            table.insert(o, kb_out)
                        end
                        local lx = bx + math.floor(kbtnW/2) - math.floor(#k.name*3)
                        local klbl = Draw.Text(lx, sy+5, k.name,
                            isSel and ctx.ACH() or ctx.COL.muted, 9, 5)
                        table.insert(o, klbl)
                        local kci = ki
                        ctx.addZone(bx, sy, kbtnW, 22, function()
                            toggleKey = keys[kci].code
                            -- rebuild settings tab
                            if tabObjs[activeTab] then
                                Draw.SetVisible(tabObjs[activeTab], false)
                                Draw.Destroy(tabObjs[activeTab])
                                for _, bb in ipairs(tabObjs[activeTab]) do
                                    for i2,a in ipairs(baseObjs) do
                                        if a==bb then table.remove(baseObjs,i2) break end
                                    end
                                end
                            end
                            tabObjs[activeTab] = nil
                            -- supprimer les zones de ce tab (approximation : rebuild)
                            -- on rebuild la fenêtre entière
                            Draw.SetVisible(baseObjs, false)
                            Draw.Destroy(baseObjs)
                            buildWindow()
                            Draw.SetVisible(baseObjs, true)
                            switchTab(activeTab)
                        end)
                    end
                    sy = sy + 32

                    table.insert(o, Draw.Text(cx, sy,
                        "Appuyez sur F1 (ou la touche choisie)", ctx.COL.muted, 9, 4))
                    table.insert(o, Draw.Text(cx, sy+13,
                        "pour masquer/afficher le hub.", ctx.COL.muted, 9, 4))
                end
            },
            {
                name = "Credits",
                buildFn = function(ctx)
                    local cx,cy = ctx.cx, ctx.cy
                    local o = ctx.objs
                    local sy = cy
                    table.insert(o, Draw.Text(cx, sy,    "EXE.HUB",             ctx.ACH(), 16, 5))
                    table.insert(o, Draw.Text(cx, sy+22, "Script hub pour Roblox", ctx.COL.muted, 10, 4))
                    table.insert(o, Draw.Text(cx, sy+44, "Dev : mattheube",      ctx.COL.white, 11, 4))
                    table.insert(o, Draw.Text(cx, sy+60, "github.com/mattheube/EXE.HUB", ctx.COL.muted, 9, 4))
                    sy = sy + 82
                    table.insert(o, Draw.Line(cx, sy, cx+ctx.cw, sy, ctx.COL.border, 1, 4))
                    sy = sy + 10
                    table.insert(o, Draw.Text(cx, sy, "Version hub : v2.1", ctx.COL.dimmed, 9, 4))
                end
            },
            {
                name = "Logs",
                buildFn = function(ctx)
                    local cx,cy = ctx.cx, ctx.cy
                    local o = ctx.objs
                    local sy = cy
                    local maxLines = math.floor((WH - CONT_Y - PADDING*2) / 14)
                    local start = math.max(1, #logLines - maxLines + 1)
                    for i = start, #logLines do
                        if logLines[i] then
                            table.insert(o, Draw.Text(cx, sy, logLines[i], ctx.COL.muted, 9, 4))
                            sy = sy + 14
                        end
                    end
                    if #logLines == 0 then
                        table.insert(o, Draw.Text(cx, sy, "Aucun log.", ctx.COL.dimmed, 10, 4))
                    end
                end
            },
        }
    end

    -- ── update labels titre ──────────────────────────────────
    local function refreshTitle()
        if lblTitleGame then
            pcall(function() lblTitleGame.Text = dynGameName end)
        end
        if lblTitleVer then
            pcall(function() lblTitleVer.Text = dynGameVer end)
        end
    end

    -- ── log interne ──────────────────────────────────────────
    local function addLog(msg)
        local ts = string.format("[%02d:%02d]",
            math.floor(tick()/3600)%24,
            math.floor(tick()/60)%60)
        table.insert(logLines, ts.." "..tostring(msg))
        if #logLines > 60 then table.remove(logLines,1) end
    end

    -- ── input loop ───────────────────────────────────────────
    task.spawn(function()
        local UIS = UserInputService
        local prevLMB  = false
        local prevKeys = {}
        local dragActive = false
        local dragOX, dragOY = 0,0

        while true do
            task.wait(0.033)
            if not uiReady then continue end

            local mx, my = 0,0
            pcall(function()
                local p = UIS:GetMouseLocation()
                mx,my = p.X, p.Y
            end)

            local lmb = false
            pcall(function()
                lmb = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            end)

            -- ── drag ──
            if dragActive then
                if lmb then
                    local nx = math.floor(mx - dragOX)
                    local ny = math.floor(my - dragOY)
                    local dx, dy = nx-WX, ny-WY
                    if dx ~= 0 or dy ~= 0 then
                        WX, WY = nx, ny
                        Draw.Move(baseObjs, dx, dy)
                        -- déplace aussi les zones cliquables
                        for _,z in ipairs(zones) do
                            z.x = z.x+dx
                            z.y = z.y+dy
                        end
                        -- déplace les pétales ne dépasse pas — ils restent dans la même zone
                    end
                else
                    dragActive = false
                end
            end

            -- ── clic ──
            if lmb and not prevLMB then
                -- drag : clic dans la barre de titre
                if uiVisible and
                   mx >= WX and mx <= WX+WW and
                   my >= WY and my <= WY+TITLE_H then
                    dragActive = true
                    dragOX = mx - WX
                    dragOY = my - WY
                end
                -- zones cliquables
                if uiVisible then
                    for _,z in ipairs(zones) do
                        if mx >= z.x and mx <= z.x+z.w and
                           my >= z.y and my <= z.y+z.h then
                            pcall(z.fn)
                        end
                    end
                end
            end
            prevLMB = lmb

            -- ── touche toggle ──
            local keyStr = tostring(toggleKey)
            local keyDown = false
            pcall(function() keyDown = UIS:IsKeyDown(toggleKey) end)
            if keyDown and not prevKeys[keyStr] then
                uiVisible = not uiVisible
                Draw.SetVisible(baseObjs, uiVisible)
                if tabObjs[activeTab] then
                    Draw.SetVisible(tabObjs[activeTab], uiVisible)
                end
                -- glow
                for _,gl in ipairs(glowLines) do
                    pcall(function() gl.Visible = uiVisible end)
                end
            end
            prevKeys[keyStr] = keyDown
        end
    end)

    -- ── glow animé ───────────────────────────────────────────
    task.spawn(function()
        local t = 0
        while true do
            task.wait(0.05)
            if not uiReady then continue end
            t = t + 0.08
            local pulse = 0.5 + 0.5*math.sin(t)
            local thick = 1 + pulse*2
            local transp = 0.35 + 0.55*(1-pulse)
            for _,gl in ipairs(glowLines) do
                pcall(function()
                    if gl.Visible then
                        gl.Thickness    = thick
                        gl.Transparency = transp
                        gl.Color        = AC()
                    end
                end)
            end
        end
    end)

    -- ── pétales ──────────────────────────────────────────────
    local PMAX = 8
    local petalCount = 0

    local function spawnPetal()
        if petalCount >= PMAX then return end
        petalCount = petalCount+1
        local sz = math.random(2,5)
        local px = WX + math.random(sz, WW-sz)
        local p  = Drawing.new("Circle")
        p.Position     = Vector2.new(px, WY+CONT_Y)
        p.Radius       = sz
        p.Color        = COL.petal
        p.Filled       = true
        p.Transparency = math.random(40,70)/100
        p.ZIndex       = 1
        p.Visible      = false
        table.insert(petalObjs, p)

        local tgt = WY + WH
        local steps = math.random(80,160)
        local dy  = (tgt - (WY+CONT_Y)) / steps
        local dx  = math.random(-15,15) / steps
        local dA  = (p.Transparency - 0.95) / steps

        task.spawn(function()
            for _ = 1, steps do
                task.wait(0.05)
                if not uiReady then break end
                pcall(function()
                    p.Visible      = uiVisible
                    p.Position     = Vector2.new(p.Position.X+dx, p.Position.Y+dy)
                    p.Transparency = math.min(1, p.Transparency+dA)
                end)
            end
            pcall(function() p:Remove() end)
            for i,a in ipairs(petalObjs) do
                if a==p then table.remove(petalObjs,i) break end
            end
            petalCount = petalCount-1
        end)
    end

    -- ── notifications ────────────────────────────────────────
    local NW,NH   = math.floor(SW/5.5), 58
    local NX,NY0  = 12, 70
    local NGAP    = 8
    local NDUR    = 4.2

    local function reposNotifs()
        for i,nd in ipairs(notifList) do
            local ty = NY0 + (i-1)*(NH+NGAP)
            local diff = ty - nd.y
            if math.abs(diff) > 0.5 then
                for _,o in ipairs(nd.objs) do
                    pcall(function()
                        if rawget(o,"Position") then
                            o.Position = Vector2.new(o.Position.X, o.Position.Y+diff)
                        end
                    end)
                end
                nd.y = ty
            end
        end
    end

    local function notify(title, msg, col, icon)
        local nObjs = {}
        local nd = {objs=nObjs, y=NY0}
        table.insert(notifList, nd)
        reposNotifs()

        local idx = #notifList
        local nx  = SW - NW - NX
        local ny  = NY0 + (idx-1)*(NH+NGAP)
        nd.y = ny

        local function a(o) table.insert(nObjs,o) end

        a(Draw.Rect   (nx,    ny,    NW,   NH,    COL.notifBg, 20))
        a(Draw.Outline(nx,    ny,    NW,   NH,    col,  1.2,   21))
        a(Draw.Rect   (nx+5,  ny+6,  3,    NH-12, col,  21))
        a(Draw.Text   (nx+14, ny+NH/2-8, icon or "+", col, 13, 22))
        a(Draw.Text   (nx+28, ny+10, title, COL.white, 12, 22))
        a(Draw.Text   (nx+28, ny+27, msg,   COL.muted, 10, 22))

        Draw.SetVisible(nObjs, true)

        task.delay(NDUR, function()
            local steps, startX = 14, nx
            for i=1,steps do
                task.wait(0.022)
                local ox = startX + i*(NW+NX+30)/steps
                for _,o in ipairs(nObjs) do
                    pcall(function()
                        if rawget(o,"Position") then
                            o.Position = Vector2.new(ox, o.Position.Y)
                        end
                    end)
                end
            end
            Draw.Destroy(nObjs)
            for i2,n2 in ipairs(notifList) do
                if n2==nd then table.remove(notifList,i2) break end
            end
            reposNotifs()
        end)
    end

    -- ── API publique ─────────────────────────────────────────
    function UI.Init()
        task.spawn(function()
            makeDefaultTabs()
            buildWindow()
            Draw.SetVisible(baseObjs, true)
            uiReady   = true
            uiVisible = true
            print("[EXE.HUB] UI.Init() OK")
            if UI._onReady then UI._onReady() end
            -- boucle pétales
            task.spawn(function()
                while uiReady do
                    pcall(spawnPetal)
                    task.wait(6+math.random(0,4))
                end
            end)
        end)
    end

    -- file d'attente
    local _queue = {}
    UI._onReady = function()
        UI._onReady = nil
        for _,fn in ipairs(_queue) do pcall(fn) end
        _queue = {}
    end
    local function defer(fn)
        if uiReady then pcall(fn) else table.insert(_queue, fn) end
    end

    -- ── chargement module jeu ────────────────────────────────
    -- Appelé par le Loader quand le module est prêt.
    -- gameModule peut fournir module.Tabs = { {name, buildFn}, ... }
    function UI.LoadGameModule(gameModule)
        defer(function()
            dynGameName = gameModule.Name    or dynGameName
            dynGameVer  = gameModule.Version or dynGameVer
            refreshTitle()
            addLog("Module charge : "..dynGameName.." "..dynGameVer)

            -- Construit les tabs : tabs jeu + Settings + Credits + Logs
            local newTabs = {}
            if gameModule.Tabs and #gameModule.Tabs > 0 then
                for _,t in ipairs(gameModule.Tabs) do
                    table.insert(newTabs, t)
                end
            else
                -- tab Main par défaut si le module n'en fournit pas
                table.insert(newTabs, {
                    name = "Main",
                    buildFn = function(ctx)
                        local o,cx,cy = ctx.objs,ctx.cx,ctx.cy
                        table.insert(o, Draw.Text(cx,cy,    "Statut", ctx.COL.muted, 10, 4))
                        table.insert(o, Draw.Text(cx,cy+14, "Actif",  ctx.ACH(),    12, 4))
                        table.insert(o, Draw.Text(cx,cy+38, dynGameName, ctx.COL.white, 12, 4))
                        table.insert(o, Draw.Text(cx,cy+56, dynGameVer,  ctx.ACH(),    10, 4))
                    end
                })
            end
            -- Ajoute toujours Settings, Credits, Logs
            for _,t in ipairs(currentTabs) do
                if t.name=="Settings" or t.name=="Credits" or t.name=="Logs" then
                    table.insert(newTabs, t)
                end
            end

            -- Reconstruit la fenêtre avec les nouveaux tabs
            activeTab = 1
            currentTabs = newTabs

            -- Nettoie les objets existants
            Draw.SetVisible(baseObjs, false)
            for _,o in ipairs(baseObjs) do pcall(function() o:Remove() end) end
            table.clear(baseObjs)
            table.clear(glowLines)
            table.clear(tabBtnObjs)
            for _,objs in pairs(tabObjs) do
                for _,o in ipairs(objs) do pcall(function() o:Remove() end) end
            end
            table.clear(tabObjs)
            clearZones()

            buildWindow()
            Draw.SetVisible(baseObjs, uiVisible)
        end)
    end

    function UI.ShowWelcome()
        defer(function()
            notify("Bienvenue", "EXE.HUB est actif", AC(), "+")
            addLog("Hub demarre")
        end)
    end

    function UI.ShowGameDetected(n, ver)
        dynGameName = n   or "—"
        dynGameVer  = ver or "—"
        defer(function()
            refreshTitle()
            notify("Jeu detecte", n, COL.green, ">")
            addLog("Jeu detecte : "..n.." "..(ver or ""))
        end)
    end

    function UI.ShowGameLoaded(n, ver)
        dynGameName = n   or dynGameName
        dynGameVer  = ver or dynGameVer
        defer(function()
            refreshTitle()
            notify("Module charge", n.." "..(ver or "").." pret", COL.green, "v")
        end)
    end

    function UI.ShowNotSupported(id)
        defer(function()
            notify("Non supporte", "PlaceId: "..tostring(id), COL.yellow, "!")
            addLog("Non supporte : "..tostring(id))
        end)
    end

    function UI.ShowLoadError(n)
        defer(function()
            notify("Erreur", tostring(n), COL.red, "x")
            addLog("Erreur : "..tostring(n))
        end)
    end

    function UI.Notify(title, msg, t)
        defer(function()
            local c,i = AC(),"+"
            if t=="success" then c=COL.green  i="v"
            elseif t=="warning" then c=COL.yellow i="!"
            elseif t=="error"   then c=COL.red    i="x" end
            notify(title, msg, c, i)
        end)
    end

    function UI.Destroy()
        uiReady = false
        Draw.DestroyAll()
        table.clear(baseObjs)
        table.clear(glowLines)
        table.clear(notifList)
        table.clear(petalObjs)
        table.clear(zones)
    end
end
print("[EXE.HUB] ui OK")

-- ============================================================
-- LOADER
-- ============================================================
local Loader = {}
do
    function Loader.LoadGame(gameInfo, loadModuleFn, ui, utils)
        if not gameInfo or not gameInfo.module then
            utils.Error("gameInfo invalide") return
        end
        utils.Log("Chargement : "..gameInfo.module)
        ui.ShowGameDetected(gameInfo.name, gameInfo.version)

        local gm = loadModuleFn(gameInfo.module)
        if not gm then ui.ShowLoadError(gameInfo.name) return end

        -- Le module peut setter ses propres Name/Version/Tabs
        gm.Name    = gm.Name    or gameInfo.name
        gm.Version = gm.Version or gameInfo.version

        -- Init du module (lui passe l'API)
        if type(gm.Init) == "function" then
            local ok, err = pcall(function() gm.Init({UI=ui, Utils=utils}) end)
            if not ok then
                ui.ShowLoadError(gameInfo.name)
                utils.Error(tostring(err))
                return
            end
        end

        -- Reconstruit l'UI avec les tabs du module
        ui.ShowGameLoaded(gm.Name, gm.Version)
        ui.LoadGameModule(gm)
    end
end
print("[EXE.HUB] loader OK")

-- ============================================================
-- CHARGEUR DE MODULES DISTANTS
-- ============================================================
_G.__EXE_HUB_MODULES = {}

local function loadModule(path)
    local url = BASE..path..CACHE_BUST
    print("[EXE.HUB] >> "..url)
    local raw
    pcall(function() raw = game:HttpGet(url, true) end)
    if not raw or raw=="" then
        warn("[EXE.HUB] ECHEC HTTP : "..path) return nil
    end
    local fn, e = loadstring(raw)
    if not fn then
        warn("[EXE.HUB] ECHEC COMPILE : "..path.." | "..tostring(e)) return nil
    end
    local ok, result = pcall(fn)
    if not ok then
        warn("[EXE.HUB] ECHEC EXEC : "..path.." | "..tostring(result)) return nil
    end
    if result ~= nil then return result end
    local key = path:match("([^/]+)%.lua$")
    if key and _G.__EXE_HUB_MODULES[key] then
        local mod = _G.__EXE_HUB_MODULES[key]
        _G.__EXE_HUB_MODULES[key] = nil
        return mod
    end
    warn("[EXE.HUB] NIL apres exec : "..path)
    return nil
end

print("[EXE.HUB] Tous les modules prets.")

-- ============================================================
-- LANCEMENT
-- ============================================================
UI.Init()
UI.ShowWelcome()

local placeId = game.PlaceId
print("[EXE.HUB] PlaceId = "..tostring(placeId))

local gameInfo = Registry.GetGame(placeId)
if gameInfo then
    print("[EXE.HUB] Jeu reconnu : "..gameInfo.name)
    Loader.LoadGame(gameInfo, loadModule, UI, Utils)
else
    print("[EXE.HUB] Jeu non supporte : "..tostring(placeId))
    UI.ShowNotSupported(placeId)
end

print("[EXE.HUB] === PRET ===")
