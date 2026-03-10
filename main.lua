-- ╔══════════════════════════════════════════════════════════╗
-- ║  EXE.HUB  |  main.lua  —  Drawing API build (Matcha)    ║
-- ║  Redesign complet — v2.0                                 ║
-- ╚══════════════════════════════════════════════════════════╝

local BASE       = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"
local CACHE_BUST = "?t=" .. tostring(math.floor(tick()))

print("[EXE.HUB] === DEMARRAGE ===")

-- ============================================================
-- UTILS
-- ============================================================
local Utils = {}
do
    local P = "[EXE.HUB]"
    function Utils.Log(m)   print(P .. " " .. tostring(m)) end
    function Utils.Warn(m)  warn(P .. " WARN: " .. tostring(m)) end
    function Utils.Error(m) warn(P .. " ERR: " .. tostring(m)) end
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
            module  = "games/bizarre_lineage.lua"
        },
    }
    function Registry.GetGame(id)     return games[id] or nil end
    function Registry.IsSupported(id) return games[id] ~= nil end
end
print("[EXE.HUB] registry OK")

-- ============================================================
-- STATE GLOBAL  (partagé entre UI et Loader)
-- ============================================================
local HubState = {
    gameName    = "—",
    gameVersion = "—",
    logs        = {},
}

-- ============================================================
-- UI — Drawing API (Matcha, 100 % sans Instance.new)
-- ============================================================
local UI = {}
do
    -- ─── résolution écran ────────────────────────────────────
    local SW, SH = 1920, 1080
    pcall(function()
        SW = workspace.CurrentCamera.ViewportSize.X
        SH = workspace.CurrentCamera.ViewportSize.Y
    end)

    -- ─── couleurs par défaut (thème sakura) ──────────────────
    local Themes = {
        sakura = {
            accent   = Color3.fromRGB(220, 80, 140),
            accentHi = Color3.fromRGB(255,130,180),
            glow     = Color3.fromRGB(255,100,160),
        },
        blue = {
            accent   = Color3.fromRGB(60, 130, 255),
            accentHi = Color3.fromRGB(120,180,255),
            glow     = Color3.fromRGB(80,150,255),
        },
        green = {
            accent   = Color3.fromRGB(60, 210, 130),
            accentHi = Color3.fromRGB(120,240,170),
            glow     = Color3.fromRGB(80,220,140),
        },
        red = {
            accent   = Color3.fromRGB(230, 60, 60),
            accentHi = Color3.fromRGB(255,110,110),
            glow     = Color3.fromRGB(240,80,80),
        },
    }
    local currentTheme = "sakura"

    local C = {
        bg      = Color3.fromRGB(12, 12, 20),
        panel   = Color3.fromRGB(18, 18, 28),
        titleBg = Color3.fromRGB(10,  8, 18),
        tabBg   = Color3.fromRGB(22, 18, 32),
        tabSel  = Color3.fromRGB(30, 22, 42),
        border  = Color3.fromRGB(38, 28, 55),
        white   = Color3.fromRGB(235,235,248),
        muted   = Color3.fromRGB(130,100,145),
        green   = Color3.fromRGB(90, 210,130),
        yellow  = Color3.fromRGB(250,195, 75),
        red     = Color3.fromRGB(250, 85, 85),
        notifBg = Color3.fromRGB(14, 10, 22),
        petal   = Color3.fromRGB(255,175,205),
    }
    local function accent()   return Themes[currentTheme].accent   end
    local function accentHi() return Themes[currentTheme].accentHi end
    local function glow()     return Themes[currentTheme].glow     end

    -- ─── dimensions ──────────────────────────────────────────
    -- Fenêtre : ~1/6 de l'écran, portrait (taller than wide)
    local WW = math.floor(SW / 6)
    local WH = math.floor(SH / 3.2)
    WW = math.max(WW, 240)
    WH = math.max(WH, 400)
    local WX = math.floor(SW / 2 - WW / 2)
    local WY = math.floor(SH / 2 - WH / 2)

    local TITLE_H = 38
    local TAB_H   = 30
    local CONTENT_Y = TITLE_H + TAB_H  -- y dans la fenêtre où commence le contenu

    local TABS = {"Main","Items","Teleport","Settings","Credits","Logs"}
    local TAB_W = math.floor(WW / #TABS)

    -- notifs
    local NW, NH  = 280, 58
    local NX, NY0 = 12, 70
    local NGAP    = 8
    local NDUR    = 4.0

    -- pétales
    local PMAX, PFRQ = 8, 6
    local petalCount = 0

    -- ─── état interne ─────────────────────────────────────────
    local allObjs    = {}   -- tous les Drawing (pour cleanup)
    local winObjs    = {}   -- objets de la fenêtre principale
    local notifs     = {}
    local uiVisible  = true
    local uiReady    = false
    local activeTab  = 1
    local tabObjs    = {}   -- {[tabIndex] = {list of Drawing objs}}
    local tabButtons = {}   -- {[tabIndex] = {bg, label}}
    local clickZones = {}
    local toggleKey  = Enum.KeyCode.F1

    -- labels dynamiques
    local lblGameName, lblGameVer
    -- glow state
    local glowLines  = {}

    -- ─── helpers Drawing ──────────────────────────────────────
    local function D(cls)
        local o = Drawing.new(cls)
        table.insert(allObjs, o)
        return o
    end

    local function sq(x,y,w,h,col,filled,thick,z)
        local s = D("Square")
        s.Position     = Vector2.new(x,y)
        s.Size         = Vector2.new(w,h)
        s.Color        = col
        s.Filled       = filled ~= false
        s.Thickness    = thick or 1
        s.Transparency = 1
        s.ZIndex       = z or 1
        s.Visible      = false
        return s
    end

    local function tx(x,y,str,col,sz,z,center)
        local t = D("Text")
        t.Position = Vector2.new(x,y)
        t.Text     = str
        t.Color    = col
        t.Size     = sz or 13
        t.ZIndex   = z or 3
        t.Outline  = false
        t.Center   = center or false
        t.Visible  = false
        return t
    end

    local function ln(x1,y1,x2,y2,col,thick,z)
        local l = D("Line")
        l.From        = Vector2.new(x1,y1)
        l.To          = Vector2.new(x2,y2)
        l.Color       = col
        l.Thickness   = thick or 1
        l.Transparency = 1
        l.ZIndex      = z or 2
        l.Visible     = false
        return l
    end

    local function setVis(group, v)
        for _,o in ipairs(group) do pcall(function() o.Visible = v end) end
    end

    local function destroyGroup(group)
        for _,o in ipairs(group) do
            pcall(function() o:Remove() end)
            for i,a in ipairs(allObjs) do
                if a == o then table.remove(allObjs,i) break end
            end
        end
        table.clear(group)
    end

    -- ─── zones cliquables ─────────────────────────────────────
    local function hit(x,y,w,h,fn)
        table.insert(clickZones,{x=x,y=y,w=w,h=h,fn=fn})
        return #clickZones
    end
    local function removeHit(id)
        if id and clickZones[id] then clickZones[id]=nil end
    end

    -- ─── drag state ───────────────────────────────────────────
    local dragActive  = false
    local dragOffX, dragOffY = 0, 0

    -- ─── input loop ───────────────────────────────────────────
    task.spawn(function()
        local UIS = UserInputService
        local prevLMB = false
        local prevKeys = {}

        while true do
            task.wait(0.033)
            if not uiReady then continue end

            -- souris
            local mx, my = 0, 0
            pcall(function()
                local pos = UIS:GetMouseLocation()
                mx, my = pos.X, pos.Y
            end)

            local lmb = false
            pcall(function()
                lmb = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            end)

            -- drag
            if dragActive then
                if lmb then
                    local nx = math.floor(mx - dragOffX)
                    local ny = math.floor(my - dragOffY)
                    local dx, dy = nx - WX, ny - WY
                    if dx ~= 0 or dy ~= 0 then
                        WX, WY = nx, ny
                        -- déplace tous les objets de la fenêtre
                        for _, o in ipairs(winObjs) do
                            pcall(function()
                                if o.Position then
                                    o.Position = Vector2.new(o.Position.X+dx, o.Position.Y+dy)
                                elseif o.From then
                                    o.From = Vector2.new(o.From.X+dx, o.From.Y+dy)
                                    o.To   = Vector2.new(o.To.X+dx,   o.To.Y+dy)
                                end
                            end)
                        end
                        -- déplace aussi les zones cliquables
                        for _, z in ipairs(clickZones) do
                            if z then z.x = z.x+dx z.y = z.y+dy end
                        end
                    end
                else
                    dragActive = false
                end
            end

            -- clic
            if lmb and not prevLMB then
                -- zone drag = barre de titre
                if uiVisible and
                   mx >= WX and mx <= WX+WW and
                   my >= WY and my <= WY+TITLE_H then
                    dragActive = true
                    dragOffX   = mx - WX
                    dragOffY   = my - WY
                end
                -- zones cliquables
                for _, z in ipairs(clickZones) do
                    if z and mx >= z.x and mx <= z.x+z.w and my >= z.y and my <= z.y+z.h then
                        pcall(z.fn)
                    end
                end
            end
            prevLMB = lmb

            -- touches
            for _, kc in ipairs({toggleKey}) do
                local down = false
                pcall(function() down = UIS:IsKeyDown(kc) end)
                local key = tostring(kc)
                if down and not prevKeys[key] then
                    uiVisible = not uiVisible
                    setVis(winObjs, uiVisible)
                end
                prevKeys[key] = down
            end
        end
    end)

    -- ─── construction de la fenêtre ───────────────────────────
    local function buildWin()
        table.clear(winObjs)
        table.clear(clickZones)
        table.clear(tabObjs)
        table.clear(tabButtons)
        table.clear(glowLines)

        local x, y = WX, WY

        -- ── fond principal ──
        local bg = sq(x,y,WW,WH,C.bg,true,1,1)
        table.insert(winObjs, bg)

        -- ── contour fixe (bord sombre) ──
        local border = sq(x,y,WW,WH,C.border,false,1.5,2)
        table.insert(winObjs, border)

        -- ── barre de titre ──
        local tb = sq(x,y,WW,TITLE_H,C.titleBg,true,1,2)
        table.insert(winObjs, tb)

        -- "exe.hub"
        local lblHub = tx(x+12, y+TITLE_H/2-7, "exe.hub", accentHi(), 15, 4)
        table.insert(winObjs, lblHub)

        -- game name (dynamique)
        lblGameName = tx(x+82, y+TITLE_H/2-6, HubState.gameName, C.muted, 12, 4)
        table.insert(winObjs, lblGameName)

        -- version (dynamique)
        lblGameVer = tx(x+WW-10, y+TITLE_H/2-5, HubState.gameVersion, C.muted, 10, 4)
        lblGameVer.Center = false
        -- on va l'aligner à droite manuellement
        table.insert(winObjs, lblGameVer)

        -- ── barre onglets ──
        for i, name in ipairs(TABS) do
            local tx0 = x + (i-1)*TAB_W
            local ty0 = y + TITLE_H
            local col = (i == activeTab) and C.tabSel or C.tabBg
            local tbg = sq(tx0, ty0, TAB_W, TAB_H, col, true, 1, 2)
            table.insert(winObjs, tbg)
            -- séparateur vertical fin entre onglets
            if i > 1 then
                local sep = ln(tx0, ty0+4, tx0, ty0+TAB_H-4, C.border, 1, 3)
                table.insert(winObjs, sep)
            end
            local tcol = (i == activeTab) and accentHi() or C.muted
            local tlbl = tx(tx0 + TAB_W/2, ty0 + TAB_H/2 - 6, name, tcol, 10, 4, true)
            table.insert(winObjs, tlbl)
            -- soulignement onglet actif
            local tul = ln(tx0+2, ty0+TAB_H-1, tx0+TAB_W-2, ty0+TAB_H-1, accent(), 1.5, 3)
            tul.Visible = (i == activeTab)
            table.insert(winObjs, tul)

            tabButtons[i] = {bg=tbg, label=tlbl, underline=tul}

            local ci = i
            hit(tx0, ty0, TAB_W, TAB_H, function()
                -- désactive ancien onglet
                tabButtons[activeTab].bg.Color    = C.tabBg
                tabButtons[activeTab].label.Color = C.muted
                tabButtons[activeTab].underline.Visible = false
                if tabObjs[activeTab] then setVis(tabObjs[activeTab], false) end
                -- active nouveau
                activeTab = ci
                tabButtons[activeTab].bg.Color    = C.tabSel
                tabButtons[activeTab].label.Color = accentHi()
                tabButtons[activeTab].underline.Visible = uiVisible
                if tabObjs[activeTab] then setVis(tabObjs[activeTab], uiVisible) end
            end)
        end

        -- ── contenu par onglet ──
        local cx = x + 10
        local cy = y + CONTENT_Y + 10
        local cw = WW - 20
        -- Fond zone contenu
        local contentBg = sq(x, y+CONTENT_Y, WW, WH-CONTENT_Y, C.panel, true, 1, 1)
        table.insert(winObjs, contentBg)

        -- ── Tab 1 : Main ──
        do
            local objs = {}
            table.insert(objs, tx(cx, cy,      "Statut",       C.muted,   10, 4))
            table.insert(objs, tx(cx, cy+16,   "En attente...",accentHi(),12, 4))
            table.insert(objs, tx(cx, cy+38,   "Jeu",          C.muted,   10, 4))
            table.insert(objs, tx(cx, cy+54,   HubState.gameName, C.white, 12, 4))
            table.insert(objs, tx(cx, cy+76,   "Version",      C.muted,   10, 4))
            table.insert(objs, tx(cx, cy+92,   HubState.gameVersion, C.white, 12, 4))
            tabObjs[1] = objs
        end

        -- ── Tab 2 : Items ──
        do
            local objs = {}
            table.insert(objs, tx(cx, cy, "Items — bientot disponible", C.muted, 11, 4))
            tabObjs[2] = objs
        end

        -- ── Tab 3 : Teleport ──
        do
            local objs = {}
            table.insert(objs, tx(cx, cy, "Teleport — bientot disponible", C.muted, 11, 4))
            tabObjs[3] = objs
        end

        -- ── Tab 4 : Settings ──
        do
            local objs = {}
            local sy = cy

            table.insert(objs, tx(cx, sy, "Theme / couleur accent", C.white, 11, 4))
            sy = sy + 18

            local themeNames = {"sakura","blue","green","red"}
            local themeColors = {
                Color3.fromRGB(220,80,140),
                Color3.fromRGB(60,130,255),
                Color3.fromRGB(60,210,130),
                Color3.fromRGB(230,60,60),
            }
            for ti, tname in ipairs(themeNames) do
                local bx = cx + (ti-1)*(cw/4+2)
                local btn = sq(bx, sy, cw/4-2, 20, themeColors[ti], true, 1, 4)
                table.insert(objs, btn)
                local blbl = tx(bx + (cw/4-2)/2, sy+4, tname, C.white, 9, 5, true)
                table.insert(objs, blbl)
                local tni = tname
                local btni = btn
                hit(bx, sy, cw/4-2, 20, function()
                    currentTheme = tni
                    -- met à jour les couleurs dynamiques
                    lblHub.Color      = accentHi()
                    tabButtons[activeTab].label.Color = accentHi()
                    tabButtons[activeTab].underline.Color = accent()
                end)
            end
            sy = sy + 30

            table.insert(objs, tx(cx, sy, "Touche d'affichage (defaut: F1)", C.white, 11, 4))
            sy = sy + 16
            local keyNames = {"F1","F2","F3","Insert","RightShift"}
            local keyCodes = {
                Enum.KeyCode.F1,
                Enum.KeyCode.F2,
                Enum.KeyCode.F3,
                Enum.KeyCode.Insert,
                Enum.KeyCode.RightShift,
            }
            for ki, kname in ipairs(keyNames) do
                local bx = cx + (ki-1)*(cw/#keyNames+1)
                local isActive = (keyCodes[ki] == toggleKey)
                local btn = sq(bx, sy, cw/#keyNames-1, 20,
                    isActive and C.tabSel or C.tabBg, true, 1, 4)
                table.insert(objs, btn)
                local blbl = tx(bx+(cw/#keyNames-1)/2, sy+4, kname,
                    isActive and accentHi() or C.muted, 9, 5, true)
                table.insert(objs, blbl)
                local kci = ki
                hit(bx, sy, cw/#keyNames-1, 20, function()
                    toggleKey = keyCodes[kci]
                    -- update visuel
                    for ii, b_obj in ipairs(objs) do
                        -- pas de ref directe facile, simple notification
                    end
                    blbl.Color = accentHi()
                    btn.Color  = C.tabSel
                    Utils.Log("Toggle key: "..kname)
                end)
            end

            tabObjs[4] = objs
        end

        -- ── Tab 5 : Credits ──
        do
            local objs = {}
            local sy = cy
            table.insert(objs, tx(cx, sy,    "exe.hub",           accentHi(), 15, 4))
            table.insert(objs, tx(cx, sy+22, "Script hub pour Roblox", C.muted, 11, 4))
            table.insert(objs, tx(cx, sy+44, "Dev : mattheube",   C.white,    11, 4))
            table.insert(objs, tx(cx, sy+60, "github.com/mattheube/EXE.HUB", C.muted, 10, 4))
            tabObjs[5] = objs
        end

        -- ── Tab 6 : Logs ──
        do
            local objs = {}
            local sy = cy
            table.insert(objs, tx(cx, sy, "Logs / Updates", C.white, 11, 4))
            sy = sy + 18
            for i = math.max(1,#HubState.logs-8), #HubState.logs do
                if HubState.logs[i] then
                    table.insert(objs, tx(cx, sy, HubState.logs[i], C.muted, 10, 4))
                    sy = sy + 14
                end
            end
            tabObjs[6] = objs
        end

        -- ── glow animé (4 lignes = 4 bords) ──
        -- on stocke des références pour les animer
        glowLines[1] = ln(x,   y,   x+WW, y,      glow(), 1.5, 3)  -- top
        glowLines[2] = ln(x+WW,y,   x+WW, y+WH,   glow(), 1.5, 3)  -- right
        glowLines[3] = ln(x+WW,y+WH,x,    y+WH,   glow(), 1.5, 3)  -- bottom
        glowLines[4] = ln(x,   y+WH,x,    y,      glow(), 1.5, 3)  -- left
        for _, gl in ipairs(glowLines) do
            table.insert(winObjs, gl)
        end

        -- affiche l'onglet actif
        for i = 1, #TABS do
            if tabObjs[i] then
                for _, o in ipairs(tabObjs[i]) do
                    table.insert(winObjs, o)
                end
                setVis(tabObjs[i], i == activeTab)
            end
        end
    end

    -- ─── glow animé ───────────────────────────────────────────
    task.spawn(function()
        local t = 0
        while true do
            task.wait(0.05)
            if not uiReady or not uiVisible then continue end
            t = t + 0.07
            -- pulsation de l'épaisseur et transparence
            local pulse = 0.5 + 0.5 * math.sin(t)
            local thick = 1 + pulse * 2.5
            -- couleur qui tourne légèrement en teinte (on interpole entre accent et blanc)
            local gc = glow()
            for _, gl in ipairs(glowLines) do
                pcall(function()
                    gl.Thickness = thick
                    gl.Color = gc
                    gl.Transparency = 0.4 + 0.5 * (1 - pulse)
                end)
            end
        end
    end)

    -- ─── pétales ──────────────────────────────────────────────
    local function spawnPetal()
        if petalCount >= PMAX then return end
        petalCount = petalCount + 1
        local sz = math.random(3,7)
        local px = WX + math.random(4, WW-4)
        local p  = Drawing.new("Circle")
        p.Position     = Vector2.new(px, WY - sz)
        p.Radius       = sz
        p.Color        = C.petal
        p.Filled       = true
        p.Transparency = math.random(35,65)/100
        p.ZIndex       = 0
        p.Visible      = false
        table.insert(allObjs, p)

        local totalSteps = math.random(80,160)
        local dy  = WH / totalSteps
        local dx  = math.random(-20,20) / totalSteps
        local dA  = (p.Transparency - 0.92) / totalSteps

        task.spawn(function()
            for _ = 1, totalSteps do
                task.wait(0.05)
                if not uiReady then break end
                pcall(function()
                    if uiVisible then p.Visible = true end
                    p.Position     = Vector2.new(p.Position.X + dx, p.Position.Y + dy)
                    p.Transparency = math.min(1, p.Transparency + dA)
                end)
            end
            pcall(function() p:Remove() end)
            for i,a in ipairs(allObjs) do
                if a==p then table.remove(allObjs,i) break end
            end
            petalCount = petalCount - 1
        end)
    end

    -- ─── notifications ────────────────────────────────────────
    local function reposNotifs()
        for i, nd in ipairs(notifs) do
            local ty = NY0 + (i-1)*(NH+NGAP)
            local diff = ty - nd.y
            if diff ~= 0 then
                for _, o in ipairs(nd.objs) do
                    pcall(function()
                        if o.Position then
                            o.Position = Vector2.new(o.Position.X, o.Position.Y+diff)
                        end
                    end)
                end
                nd.y = ty
            end
        end
    end

    local function notify(title, msg, acCol, icon)
        local nObjs = {}
        local nd = {objs=nObjs, y=NY0}
        table.insert(notifs, nd)
        reposNotifs()

        local idx = #notifs
        local nx  = SW - NW - NX
        local ny  = NY0 + (idx-1)*(NH+NGAP)
        nd.y = ny

        local function a(o) table.insert(nObjs,o) end

        a(sq(nx, ny, NW, NH, C.notifBg, true,  1, 20))
        a(sq(nx, ny, NW, NH, acCol,     false, 1.2, 21))
        a(sq(nx+5, ny+5, 3, NH-10, acCol, true, 1, 21))
        a(tx(nx+13, ny+NH/2-9, icon or "+", acCol, 14, 22))
        a(tx(nx+28, ny+9, title, C.white, 12, 22))
        a(tx(nx+28, ny+26, msg, C.muted, 11, 22))

        setVis(nObjs, true)

        task.delay(NDUR, function()
            -- slide vers la droite
            local steps = 12
            local startX = nx
            for i = 1, steps do
                task.wait(0.025)
                local ox = startX + i*(NW+NX+20)/steps
                for _, o in ipairs(nObjs) do
                    pcall(function()
                        if o.Position then
                            o.Position = Vector2.new(ox, o.Position.Y)
                        end
                    end)
                end
            end
            destroyGroup(nObjs)
            for i2, n2 in ipairs(notifs) do
                if n2 == nd then table.remove(notifs,i2) break end
            end
            reposNotifs()
        end)
    end

    -- ─── API publique ─────────────────────────────────────────
    function UI.Init()
        task.spawn(function()
            buildWin()
            setVis(winObjs, true)
            uiReady   = true
            uiVisible = true
            print("[EXE.HUB] UI.Init() OK")
            if UI._onReady then UI._onReady() end
            -- boucle pétales
            task.spawn(function()
                while uiReady do
                    pcall(spawnPetal)
                    task.wait(PFRQ + math.random(0,4))
                end
            end)
        end)
    end

    local _queue = {}
    UI._onReady = function()
        UI._onReady = nil
        for _, fn in ipairs(_queue) do pcall(fn) end
        _queue = {}
    end
    local function defer(fn)
        if uiReady then pcall(fn)
        else table.insert(_queue, fn) end
    end

    -- Met à jour les labels dynamiques de la fenêtre
    local function refreshDynLabels()
        if lblGameName then pcall(function() lblGameName.Text = HubState.gameName  end) end
        if lblGameVer  then pcall(function() lblGameVer.Text  = HubState.gameVersion end) end
        -- met à jour aussi le tab Main si construit
        if tabObjs[1] then
            pcall(function()
                -- index 4 = label nom jeu, index 6 = label version (selon buildWin)
                if tabObjs[1][4] then tabObjs[1][4].Text = HubState.gameName    end
                if tabObjs[1][6] then tabObjs[1][6].Text = HubState.gameVersion end
            end)
        end
    end

    local function addLog(msg)
        table.insert(HubState.logs, msg)
        if #HubState.logs > 50 then table.remove(HubState.logs,1) end
    end

    function UI.ShowWelcome()
        defer(function()
            notify("Bienvenue", "exe.hub est actif", accent(), "+")
            addLog("Hub demarre")
        end)
    end

    function UI.ShowGameDetected(n, ver)
        HubState.gameName    = n   or "—"
        HubState.gameVersion = ver or "—"
        defer(function()
            refreshDynLabels()
            notify("Jeu detecte", n, C.green, ">")
            addLog("Jeu : "..n)
        end)
    end

    function UI.ShowGameLoaded(n, ver)
        HubState.gameName    = n   or HubState.gameName
        HubState.gameVersion = ver or HubState.gameVersion
        defer(function()
            refreshDynLabels()
            notify("Module charge", n.." "..HubState.gameVersion.." pret", C.green, "v")
            -- met à jour le statut tab Main
            if tabObjs[1] and tabObjs[1][2] then
                pcall(function() tabObjs[1][2].Text = "Actif" end)
            end
            addLog("Module charge : "..n.." "..HubState.gameVersion)
        end)
    end

    function UI.ShowNotSupported(id)
        defer(function()
            notify("Non supporte", "PlaceId: "..tostring(id), C.yellow, "!")
            addLog("Jeu non supporte : "..tostring(id))
        end)
    end

    function UI.ShowLoadError(n)
        defer(function()
            notify("Erreur", tostring(n), C.red, "x")
            addLog("Erreur : "..tostring(n))
        end)
    end

    function UI.Notify(title, msg, t)
        defer(function()
            local a, i = accent(), "+"
            if     t=="success" then a=C.green  i="v"
            elseif t=="warning" then a=C.yellow i="!"
            elseif t=="error"   then a=C.red    i="x" end
            notify(title, msg, a, i)
        end)
    end

    function UI.SetStatus(s)
        defer(function()
            if tabObjs[1] and tabObjs[1][2] then
                pcall(function() tabObjs[1][2].Text = tostring(s) end)
            end
        end)
    end

    function UI.Destroy()
        uiReady = false
        table.clear(clickZones)
        for _, o in ipairs(allObjs) do pcall(function() o:Remove() end) end
        table.clear(allObjs)
        table.clear(winObjs)
        table.clear(notifs)
        table.clear(glowLines)
    end
end
print("[EXE.HUB] ui OK")

-- ============================================================
-- LOADER
-- ============================================================
local Loader = {}
do
    function Loader.LoadGame(gameInfo, loadModule, ui, utils)
        if not gameInfo or not gameInfo.module then
            utils.Error("gameInfo invalide") return
        end
        utils.Log("Chargement : "..gameInfo.module)
        local gm = loadModule(gameInfo.module)
        if not gm then ui.ShowLoadError(gameInfo.name) return end
        if type(gm.Init) ~= "function" then
            ui.ShowLoadError(gameInfo.name.." (Init manquant)") return
        end
        local ok, err = pcall(function() gm.Init({UI=ui, Utils=utils}) end)
        if ok then
            ui.ShowGameLoaded(gameInfo.name, gameInfo.version)
        else
            ui.ShowLoadError(gameInfo.name)
            utils.Error(tostring(err))
        end
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

local placeId  = game.PlaceId
print("[EXE.HUB] PlaceId = "..tostring(placeId))

local gameInfo = Registry.GetGame(placeId)
if gameInfo then
    print("[EXE.HUB] Jeu reconnu : "..gameInfo.name)
    UI.ShowGameDetected(gameInfo.name, gameInfo.version)
    Loader.LoadGame(gameInfo, loadModule, UI, Utils)
else
    print("[EXE.HUB] Jeu non supporte : "..tostring(placeId))
    UI.ShowNotSupported(placeId)
end

print("[EXE.HUB] === PRET ===")
