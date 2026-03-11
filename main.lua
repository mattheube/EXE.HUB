-- ╔══════════════════════════════════════════════════════════╗
-- ║         EXE.HUB  v3.0  —  Drawing API  (Matcha)        ║
-- ╚══════════════════════════════════════════════════════════╝
-- Moteur : task.spawn + task.wait (Heartbeat mort sur Matcha)
-- Input  : ismouse1pressed() polling LMB
--          game:GetService("UserInputService"):IsKeyDown() toggle
-- Fixes  : zones par onglet, underline fixe, notifs animées,
--          color picker lisse, keybind dynamique, logs hub

local BASE = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"

-- ============================================================
-- SERVICES
-- ============================================================
local RealUIS = game:GetService("UserInputService")

-- ============================================================
-- UTILS
-- ============================================================
local Utils = {}
do
    local P = "[EXE.HUB]"
    function Utils.Log(m)   print(P.." "..tostring(m)) end
    function Utils.Error(m) warn(P.." ERR: "..tostring(m)) end
    function Utils.SafeCall(fn,lbl)
        local ok,e = pcall(fn)
        if not ok then warn(P.." ["..tostring(lbl).."] "..tostring(e)) end
    end
end

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

-- ============================================================
-- DRAW
-- ============================================================
local Draw = {}
do
    local pool = {}
    local function reg(o) pool[#pool+1]=o return o end

    function Draw.Rect(x,y,w,h,col,z)
        local o=reg(Drawing.new("Square"))
        o.Position=Vector2.new(x,y) o.Size=Vector2.new(w,h)
        o.Color=col o.Filled=true o.Transparency=1
        o.Thickness=1 o.ZIndex=z or 1 o.Visible=false
        return o
    end
    function Draw.Outline(x,y,w,h,col,thick,z)
        local o=reg(Drawing.new("Square"))
        o.Position=Vector2.new(x,y) o.Size=Vector2.new(w,h)
        o.Color=col o.Filled=false o.Thickness=thick or 1.5
        o.Transparency=1 o.ZIndex=z or 2 o.Visible=false
        return o
    end
    function Draw.Text(x,y,str,col,sz,z)
        local o=reg(Drawing.new("Text"))
        o.Position=Vector2.new(x,y) o.Text=str o.Color=col
        o.Size=sz or 13 o.ZIndex=z or 3
        o.Outline=false o.Center=false o.Visible=false
        return o
    end
    function Draw.Line(x1,y1,x2,y2,col,thick,z)
        local o=reg(Drawing.new("Line"))
        o.From=Vector2.new(x1,y1) o.To=Vector2.new(x2,y2)
        o.Color=col o.Thickness=thick or 1
        o.Transparency=1 o.ZIndex=z or 2 o.Visible=false
        return o
    end
    function Draw.SetVisible(list,v)
        for _,o in ipairs(list) do pcall(function() o.Visible=v end) end
    end
    function Draw.Destroy(list)
        for _,o in ipairs(list) do
            pcall(function() o:Remove() end)
            for i,p in ipairs(pool) do
                if p==o then table.remove(pool,i) break end
            end
        end
        table.clear(list)
    end
    function Draw.Move(list,dx,dy)
        for _,o in ipairs(list) do pcall(function()
            if o.Position then
                o.Position=Vector2.new(o.Position.X+dx,o.Position.Y+dy)
            end
            if o.From then
                o.From=Vector2.new(o.From.X+dx,o.From.Y+dy)
                o.To  =Vector2.new(o.To.X+dx,  o.To.Y+dy)
            end
        end) end
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
    -- ── screen ───────────────────────────────────────────────
    local SW,SH = 1920,1080
    pcall(function()
        SW = workspace.CurrentCamera.ViewportSize.X
        SH = workspace.CurrentCamera.ViewportSize.Y
    end)

    -- ── mouse / LMB ──────────────────────────────────────────
    local mouse = Players.LocalPlayer:GetMouse()
    local function MX() return mouse.X end
    local function MY() return mouse.Y end
    local function LMB() return (ismouse1pressed()) end

    -- ── toggle key (keybind dynamique) ───────────────────────
    -- L'utilisateur appuie sur une touche pour la définir.
    -- On poll RealUIS:IsKeyDown sur le Enum.KeyCode choisi.
    local toggleKC      = Enum.KeyCode.H   -- défaut
    local toggleLabel   = "H"
    local bindingMode   = false            -- true = attend prochain keypress
    local bindLblObj    = nil              -- ref label affiché dans settings

    -- Liste de tous les Enum.KeyCode testables pour le keybind
    local BINDABLE_KEYS = {
        {kc=Enum.KeyCode.A,  l="A"}, {kc=Enum.KeyCode.B,  l="B"},
        {kc=Enum.KeyCode.C,  l="C"}, {kc=Enum.KeyCode.D,  l="D"},
        {kc=Enum.KeyCode.E,  l="E"}, {kc=Enum.KeyCode.F,  l="F"},
        {kc=Enum.KeyCode.G,  l="G"}, {kc=Enum.KeyCode.H,  l="H"},
        {kc=Enum.KeyCode.I,  l="I"}, {kc=Enum.KeyCode.J,  l="J"},
        {kc=Enum.KeyCode.K,  l="K"}, {kc=Enum.KeyCode.L,  l="L"},
        {kc=Enum.KeyCode.M,  l="M"}, {kc=Enum.KeyCode.N,  l="N"},
        {kc=Enum.KeyCode.O,  l="O"}, {kc=Enum.KeyCode.P,  l="P"},
        {kc=Enum.KeyCode.Q,  l="Q"}, {kc=Enum.KeyCode.R,  l="R"},
        {kc=Enum.KeyCode.S,  l="S"}, {kc=Enum.KeyCode.T,  l="T"},
        {kc=Enum.KeyCode.U,  l="U"}, {kc=Enum.KeyCode.V,  l="V"},
        {kc=Enum.KeyCode.W,  l="W"}, {kc=Enum.KeyCode.X,  l="X"},
        {kc=Enum.KeyCode.Y,  l="Y"}, {kc=Enum.KeyCode.Z,  l="Z"},
    }
    local function isToggleDown()
        if bindingMode then return false end
        local ok,r = pcall(function() return RealUIS:IsKeyDown(toggleKC) end)
        return ok and r or false
    end
    -- Détection keybind : scan toutes les touches BINDABLE chaque frame
    local function scanForNewBind()
        for _,k in ipairs(BINDABLE_KEYS) do
            local ok,r = pcall(function() return RealUIS:IsKeyDown(k.kc) end)
            if ok and r then
                toggleKC    = k.kc
                toggleLabel = k.l
                bindingMode = false
                if bindLblObj then
                    pcall(function() bindLblObj.Text = "Touche : [ "..toggleLabel.." ]" end)
                end
                return
            end
        end
    end

    -- ── thème ────────────────────────────────────────────────
    local accentH,accentS,accentV = 330/360, 0.65, 0.95
    local function AC()
        return Color3.fromHSV(accentH, accentS, accentV)
    end
    local function ACH()
        return Color3.fromHSV(accentH, accentS*0.65, 1.0)
    end
    local function petalColor()
        return Color3.fromHSV(accentH, accentS*0.45, 1.0)
    end

    local PRESETS = {
        {l="Sakura", h=330/360, s=0.65, v=0.95},
        {l="Blue",   h=220/360, s=0.75, v=1.00},
        {l="Green",  h=145/360, s=0.70, v=0.85},
        {l="Red",    h=  0/360, s=0.75, v=0.95},
        {l="Purple", h=270/360, s=0.70, v=0.90},
        {l="Orange", h= 25/360, s=0.80, v=1.00},
        {l="Cyan",   h=185/360, s=0.80, v=0.90},
        {l="Gold",   h= 45/360, s=0.85, v=1.00},
    }
    local dropdownOpen = false
    local dropdownObjs = {}

    -- ── palette fixe ─────────────────────────────────────────
    local C = {
        bg      = Color3.fromRGB(12,11,18),
        panel   = Color3.fromRGB(17,16,26),
        titleBg = Color3.fromRGB(9,7,16),
        tabBg   = Color3.fromRGB(19,17,28),
        tabSel  = Color3.fromRGB(30,24,44),
        border  = Color3.fromRGB(40,28,55),
        white   = Color3.fromRGB(230,230,245),
        muted   = Color3.fromRGB(115,90,132),
        dimmed  = Color3.fromRGB(65,55,82),
        green   = Color3.fromRGB(85,205,125),
        yellow  = Color3.fromRGB(245,190,70),
        red     = Color3.fromRGB(245,80,80),
        notifBg = Color3.fromRGB(12,10,20),
    }

    -- ── dimensions ───────────────────────────────────────────
    local WW     = math.max(280, math.floor(SW/5.5))
    local WH     = math.max(440, math.floor(SH/2.8))
    local WX     = math.floor(SW/2 - WW/2)
    local WY     = math.floor(SH/2 - WH/2)
    local TH     = 36
    local TABH   = 28
    local CONTY  = TH + TABH
    local PAD    = 14

    -- ── state ────────────────────────────────────────────────
    local uiReady   = false
    local uiVisible = true
    local activeTab = 1
    local currentTabs = {}

    local baseObjs      = {}   -- chrome de la fenêtre (fond, titre, tabs bar)
    local glowLines     = {}   -- 4 lignes de bord pulsées
    local tabBtnData    = {}   -- [i] = {bg,lbl,ul}
    -- [FIX-OVERLAP] zones séparées par onglet + zones globales (tab bar)
    local tabZones      = {}   -- tabZones[i] = liste de zones de l'onglet i
    local globalZones   = {}   -- tab bar, toujours actives
    local tabContent    = {}   -- [i] = liste d'objets Drawing du contenu
    local petalObjs     = {}
    local accentObjs    = {}   -- {obj, role="ac"|"ach"}

    local dynName = "—"
    local dynVer  = "—"
    local lblTitleGame, lblTitleVer

    -- Logs hub (pas génériques)
    local HUB_CHANGELOG = {
        "v3.0  — Refonte UI complète, keybind dynamique",
        "v2.4  — Fix drag/click (Heartbeat→task.wait)",
        "v2.3  — Color picker HSV, notifs animées",
        "v2.2  — Fix toggle, thème live, underline fix",
        "v2.1  — Drawing API, pétales, thème Sakura",
        "v2.0  — Migration Matcha executor",
        "v1.0  — Version initiale",
    }
    local gameChangelog = {}  -- rempli par le module

    -- color picker state
    local pickerObjs   = {}
    local pickerActive = false
    local swatchRef    = nil

    -- forward decl
    local buildWindow, applyTheme, destroyDropdown, destroyPicker

    -- ── zone helpers ─────────────────────────────────────────
    -- [FIX-OVERLAP] addZone prend un tabIndex (nil = global)
    local function addZone(x,y,w,h,fn,tabIdx)
        local z = {x=x,y=y,w=w,h=h,fn=fn}
        if tabIdx then
            tabZones[tabIdx] = tabZones[tabIdx] or {}
            table.insert(tabZones[tabIdx], z)
        else
            table.insert(globalZones, z)
        end
    end

    local function clearAllZones()
        table.clear(globalZones)
        table.clear(tabZones)
    end

    -- hitTest : global zones TOUJOURS + zones de l'onglet actif UNIQUEMENT
    local function hitTest(mx,my)
        local snap = {}
        -- global (tab bar)
        for _,z in ipairs(globalZones) do snap[#snap+1]=z end
        -- onglet actif seulement [FIX-OVERLAP]
        if tabZones[activeTab] then
            for _,z in ipairs(tabZones[activeTab]) do snap[#snap+1]=z end
        end
        for _,z in ipairs(snap) do
            if mx>=z.x and mx<=z.x+z.w and my>=z.y and my<=z.y+z.h then
                pcall(z.fn) return
            end
        end
    end

    -- ── accent tracking ──────────────────────────────────────
    local function regAC(o)  accentObjs[#accentObjs+1]={obj=o,role="ac"}  return o end
    local function regACH(o) accentObjs[#accentObjs+1]={obj=o,role="ach"} return o end

    applyTheme = function()
        local ac,ach = AC(),ACH()
        for _,e in ipairs(accentObjs) do pcall(function()
            e.obj.Color = (e.role=="ach") and ach or ac
        end) end
        for _,gl in ipairs(glowLines) do pcall(function() gl.Color=ac end) end
        -- underline : toujours visible sur l'onglet actif [FIX-UL]
        for i,bd in pairs(tabBtnData) do pcall(function()
            bd.ul.Color   = ac
            bd.ul.Visible = (i == activeTab)  -- jamais masqué sauf si pas actif
        end) end
        for _,p in ipairs(petalObjs) do pcall(function() p.Color=petalColor() end) end
        if swatchRef then pcall(function() swatchRef.Color=ac end) end
    end

    -- ── color picker (lisse, dégradé par triangles) ──────────
    local PICK_W = WW - PAD*2
    local PICK_H = 80
    local VSL_H  = 14

    destroyPicker = function()
        Draw.Destroy(pickerObjs)
        pickerActive = false
    end

    local function buildPicker(cx,cy,swatch)
        destroyPicker()
        pickerActive = true
        swatchRef    = swatch

        -- grille H×S plus fine (48×12 cellules) pour rendu lisse
        local hS,sS = 48,12
        local cw2 = math.floor(PICK_W/hS)
        local ch2 = math.floor(PICK_H/sS)
        for hi=0,hS-1 do
            for si=0,sS-1 do
                local h = hi/hS
                local s = 1 - si/sS
                local sq = Draw.Rect(cx+hi*cw2, cy+si*ch2, cw2+1, ch2+1,
                    Color3.fromHSV(h,s,accentV), 30)
                sq.Visible = true
                pickerObjs[#pickerObjs+1] = sq
            end
        end

        -- slider brightness (24 steps)
        local vy = cy + PICK_H + 4
        local vS = 24
        local vsw = math.floor(PICK_W/vS)
        for vi=0,vS-1 do
            local v = (vi+1)/vS
            local sq = Draw.Rect(cx+vi*vsw, vy, vsw+1, VSL_H,
                Color3.fromHSV(accentH,accentS,v), 30)
            sq.Visible = true
            pickerObjs[#pickerObjs+1] = sq
        end

        -- curseur H×S
        local cur = Draw.Outline(
            cx + math.floor(accentH*PICK_W) - 4,
            cy + math.floor((1-accentS)*PICK_H) - 4,
            8, 8, C.white, 1.5, 32)
        cur.Visible = true
        pickerObjs[#pickerObjs+1] = cur

        -- bordure
        local brd = Draw.Outline(cx,cy,PICK_W,PICK_H+4+VSL_H,C.border,1.5,31)
        brd.Visible = true
        pickerObjs[#pickerObjs+1] = brd

        -- zones picker (toujours globales car picker est overlay)
        addZone(cx,cy,PICK_W,PICK_H,function()
            local mx,my = MX(),MY()
            accentH = math.max(0,math.min(0.9999,(mx-cx)/PICK_W))
            accentS = math.max(0.01,math.min(1,1-(my-cy)/PICK_H))
            pcall(function()
                cur.Position = Vector2.new(
                    cx+math.floor(accentH*PICK_W)-4,
                    cy+math.floor((1-accentS)*PICK_H)-4)
            end)
            applyTheme()
        end,nil)
        addZone(cx,vy,PICK_W,VSL_H,function()
            local mx = MX()
            accentV = math.max(0.05,math.min(1,(mx-cx+1)/PICK_W))
            applyTheme()
        end,nil)
    end

    -- ── dropdown thème ───────────────────────────────────────
    destroyDropdown = function()
        Draw.Destroy(dropdownObjs)
        dropdownOpen = false
    end

    local function buildDropdown(cx,cy,cw,tabIdx)
        destroyDropdown()
        dropdownOpen = true
        local itemH = 22
        for i,pr in ipairs(PRESETS) do
            local iy = cy + (i-1)*itemH
            local bg = Draw.Rect(cx,iy,cw,itemH,C.tabBg,35)
            bg.Visible = true
            dropdownObjs[#dropdownObjs+1] = bg

            local dot = Draw.Rect(cx+6,iy+6,10,10,
                Color3.fromHSV(pr.h,pr.s,pr.v), 36)
            dot.Visible = true
            dropdownObjs[#dropdownObjs+1] = dot

            local lbl = Draw.Text(cx+22,iy+5,pr.l,C.white,10,36)
            lbl.Visible = true
            dropdownObjs[#dropdownObjs+1] = lbl

            -- bordure bas
            local sep = Draw.Line(cx,iy+itemH-1,cx+cw,iy+itemH-1,C.border,1,36)
            sep.Visible = true
            dropdownObjs[#dropdownObjs+1] = sep

            local pii = i
            addZone(cx,iy,cw,itemH,function()
                local pr2 = PRESETS[pii]
                accentH,accentS,accentV = pr2.h,pr2.s,pr2.v
                destroyDropdown()
                destroyPicker()
                applyTheme()
                buildWindow()
                Draw.SetVisible(baseObjs,uiVisible)
            end,nil)  -- global zone (overlay)
        end
        -- bordure extérieure
        local brd = Draw.Outline(cx,cy,cw,#PRESETS*itemH,C.border,1.5,36)
        brd.Visible = true
        dropdownObjs[#dropdownObjs+1] = brd
    end

    -- ── tab switch ───────────────────────────────────────────
    local function switchTab(idx)
        if not currentTabs[idx] then return end
        -- cacher ancien contenu
        if tabContent[activeTab] then
            Draw.SetVisible(tabContent[activeTab], false)
        end
        -- réinitialiser ancien bouton (mais garder son UL invisible)
        local old = tabBtnData[activeTab]
        if old then
            old.bg.Color  = C.tabBg
            old.lbl.Color = C.muted
            old.ul.Visible = false  -- masqué car plus actif
        end
        destroyPicker()
        destroyDropdown()
        activeTab = idx

        -- construire contenu si première visite
        if not tabContent[activeTab] then
            tabContent[activeTab] = {}
            tabZones[activeTab]   = {}
            local tab = currentTabs[activeTab]
            if tab and type(tab.buildFn)=="function" then
                pcall(function()
                    tab.buildFn({
                        cx=WX+PAD, cy=WY+CONTY+PAD,
                        cw=WW-PAD*2, ch=WH-CONTY-PAD*2,
                        C=C, AC=AC, ACH=ACH, PAD=PAD,
                        Draw=Draw,
                        objs=tabContent[activeTab],
                        addZone=function(x,y,w,h,fn)
                            addZone(x,y,w,h,fn,activeTab)
                        end,
                        buildPicker=buildPicker,
                        buildDropdown=function(cx,cy,cw)
                            buildDropdown(cx,cy,cw,activeTab)
                        end,
                        regAC=regAC, regACH=regACH,
                        WX=function()return WX end,
                        WY=function()return WY end,
                        WW=WW, WH=WH,
                    })
                end)
                for _,o in ipairs(tabContent[activeTab]) do
                    baseObjs[#baseObjs+1] = o
                end
            end
        end

        Draw.SetVisible(tabContent[activeTab], uiVisible)

        -- activer nouveau bouton
        local nw = tabBtnData[activeTab]
        if nw then
            nw.bg.Color  = C.tabSel
            nw.lbl.Color = ACH()
            nw.ul.Color  = AC()
            nw.ul.Visible = true  -- [FIX-UL] toujours visible sur l'actif
        end
    end

    -- ── buildWindow ──────────────────────────────────────────
    buildWindow = function()
        destroyPicker()
        destroyDropdown()
        for _,o in ipairs(baseObjs) do pcall(function() o:Remove() end) end
        table.clear(baseObjs)
        table.clear(glowLines)
        table.clear(tabBtnData)
        table.clear(accentObjs)
        for _,tc in pairs(tabContent) do
            for _,o in ipairs(tc) do pcall(function() o:Remove() end) end
        end
        table.clear(tabContent)
        clearAllZones()
        swatchRef   = nil
        bindLblObj  = nil

        local x,y = WX,WY
        local ac  = AC()

        -- fond
        baseObjs[#baseObjs+1] = Draw.Rect(x,y,WW,WH,C.bg,1)

        -- title bar
        baseObjs[#baseObjs+1] = Draw.Rect(x,y,WW,TH,C.titleBg,2)
        local hub = regACH(Draw.Text(x+PAD,y+11,"EXE.HUB",ACH(),14,5))
        baseObjs[#baseObjs+1] = hub
        baseObjs[#baseObjs+1] = Draw.Line(x+90,y+8,x+90,y+TH-8,C.border,1,4)
        lblTitleGame = Draw.Text(x+98,y+12,dynName,C.muted,11,5)
        baseObjs[#baseObjs+1] = lblTitleGame
        lblTitleVer  = Draw.Text(x+WW-60,y+13,dynVer,C.dimmed,10,5)
        baseObjs[#baseObjs+1] = lblTitleVer
        baseObjs[#baseObjs+1] = Draw.Line(x,y+TH,x+WW,y+TH,C.border,1,3)

        -- tab bar
        local nT   = #currentTabs
        local tabW = math.floor(WW / math.max(nT,1))
        local tabY = y + TH
        for i,tab in ipairs(currentTabs) do
            local tx    = x + (i-1)*tabW
            local isSel = (i == activeTab)
            local tbg   = Draw.Rect(tx,tabY,tabW,TABH,
                isSel and C.tabSel or C.tabBg, 2)
            baseObjs[#baseObjs+1] = tbg
            if i > 1 then
                baseObjs[#baseObjs+1] = Draw.Line(
                    tx,tabY+5,tx,tabY+TABH-5, C.border,1,3)
            end
            local lx   = tx + math.floor(tabW/2) - math.floor(#tab.name*3.2)
            local tlbl = Draw.Text(lx,tabY+9,tab.name,
                isSel and ACH() or C.muted, 10, 4)
            if isSel then regACH(tlbl) end
            baseObjs[#baseObjs+1] = tlbl

            -- [FIX-UL] underline : visible SI ET SEULEMENT SI actif
            local tul = Draw.Line(
                tx+3, tabY+TABH-2, tx+tabW-3, tabY+TABH-2,
                ac, 2, 4)
            tul.Visible = isSel
            baseObjs[#baseObjs+1] = tul
            tabBtnData[i] = {bg=tbg, lbl=tlbl, ul=tul}

            local ci = i
            -- zones tab bar = globales (toujours actives)
            addZone(tx,tabY,tabW,TABH, function() switchTab(ci) end, nil)
        end

        -- contenu
        baseObjs[#baseObjs+1] = Draw.Line(x,y+CONTY,x+WW,y+CONTY,C.border,1,3)
        baseObjs[#baseObjs+1] = Draw.Rect(x,y+CONTY,WW,WH-CONTY,C.panel,1)

        -- bordure + glow
        baseObjs[#baseObjs+1] = Draw.Outline(x,y,WW,WH,C.border,1,3)
        local function gl(x1,y1,x2,y2)
            local l = Draw.Line(x1,y1,x2,y2,ac,1.5,4)
            l.Transparency = 0.7
            baseObjs[#baseObjs+1] = l
            glowLines[#glowLines+1] = l
        end
        gl(x,y,      x+WW,y     )
        gl(x+WW,y,   x+WW,y+WH )
        gl(x+WW,y+WH,x,   y+WH )
        gl(x,y+WH,   x,   y    )

        -- construire onglet actif
        tabContent[activeTab] = {}
        tabZones[activeTab]   = {}
        local tab = currentTabs[activeTab]
        if tab and type(tab.buildFn)=="function" then
            pcall(function()
                tab.buildFn({
                    cx=WX+PAD, cy=WY+CONTY+PAD,
                    cw=WW-PAD*2, ch=WH-CONTY-PAD*2,
                    C=C, AC=AC, ACH=ACH, PAD=PAD,
                    Draw=Draw,
                    objs=tabContent[activeTab],
                    addZone=function(x2,y2,w2,h2,fn2)
                        addZone(x2,y2,w2,h2,fn2,activeTab)
                    end,
                    buildPicker=buildPicker,
                    buildDropdown=function(cx2,cy2,cw2)
                        buildDropdown(cx2,cy2,cw2,activeTab)
                    end,
                    regAC=regAC, regACH=regACH,
                    WX=function()return WX end,
                    WY=function()return WY end,
                    WW=WW, WH=WH,
                })
            end)
            for _,o in ipairs(tabContent[activeTab]) do
                baseObjs[#baseObjs+1] = o
            end
        end
    end

    -- ── default tabs ─────────────────────────────────────────
    local function makeDefaultTabs()
        currentTabs = {

            -- 1. Main
            {name="Main", buildFn=function(ctx)
                local o,cx,cy = ctx.objs,ctx.cx,ctx.cy
                local D = ctx.Draw
                o[#o+1] = D.Text(cx,cy,   "STATUT",     ctx.C.muted,10,4)
                local s  = ctx.regACH(D.Text(cx,cy+16,"En attente…",ctx.ACH(),13,4))
                o[#o+1] = s
                o[#o+1] = D.Line(cx,cy+38,cx+ctx.cw,cy+38,ctx.C.border,1,4)
                o[#o+1] = D.Text(cx,cy+50,"JEU",        ctx.C.muted,10,4)
                o[#o+1] = D.Text(cx,cy+66, dynName,     ctx.C.white,13,4)
                o[#o+1] = D.Text(cx,cy+92,"VERSION",    ctx.C.muted,10,4)
                local v  = ctx.regACH(D.Text(cx,cy+108,dynVer,ctx.ACH(),12,4))
                o[#o+1] = v
            end},

            -- 2. Settings
            {name="Settings", buildFn=function(ctx)
                local o,cx,cy,cw = ctx.objs,ctx.cx,ctx.cy,ctx.cw
                local D = ctx.Draw
                local sy = cy

                -- ── Thème : dropdown ──────────────────────
                o[#o+1] = D.Text(cx,sy,"THÈME",ctx.C.muted,10,4)
                sy = sy + 16

                -- Swatch / bouton dropdown
                local swH = 24
                local swatch = ctx.regAC(D.Rect(cx,sy,cw,swH,ctx.AC(),4))
                swatchRef = swatch
                o[#o+1] = swatch
                local ddLbl = D.Text(cx+10,sy+5,
                    "▼  Choisir un thème preset",ctx.C.white,10,5)
                o[#o+1] = ddLbl
                ctx.addZone(cx,sy,cw,swH,function()
                    if dropdownOpen then
                        destroyDropdown()
                    else
                        ctx.buildDropdown(cx,sy+swH+2,cw)
                    end
                end)
                sy = sy + swH + 8

                -- Ouvrir le color picker
                o[#o+1] = D.Text(cx,sy,"COULEUR PERSONNALISÉE",ctx.C.muted,10,4)
                sy = sy + 14
                local cpBtn = D.Rect(cx,sy,cw,22,ctx.C.tabBg,4)
                o[#o+1] = cpBtn
                o[#o+1] = D.Outline(cx,sy,cw,22,ctx.C.border,1,4)
                o[#o+1] = D.Text(cx+10,sy+5,"Ouvrir le sélecteur HSV",ctx.C.white,10,5)
                ctx.addZone(cx,sy,cw,22,function()
                    if pickerActive then
                        destroyPicker()
                    else
                        buildPicker(cx,sy+26,swatch)
                    end
                end)
                sy = sy + 32

                -- ── Touche toggle (keybind dynamique) ─────
                o[#o+1] = D.Text(cx,sy,"TOUCHE TOGGLE",ctx.C.muted,10,4)
                sy = sy + 14

                local bndH = 30
                local bndBg  = D.Rect(cx,sy,cw,bndH,ctx.C.tabBg,4)
                o[#o+1] = bndBg
                local bndOut = ctx.regAC(D.Outline(cx,sy,cw,bndH,ctx.AC(),1.5,5))
                o[#o+1] = bndOut
                local bndLbl = ctx.regACH(
                    D.Text(cx+10,sy+8,"Touche : [ "..toggleLabel.." ]",ctx.ACH(),12,5))
                o[#o+1] = bndLbl
                bindLblObj = bndLbl  -- ref globale pour mise à jour live

                local hint = D.Text(cx+10,sy+bndH+4,
                    "Cliquer puis appuyer une touche pour changer",
                    ctx.C.dimmed,9,4)
                o[#o+1] = hint

                ctx.addZone(cx,sy,cw,bndH,function()
                    if bindingMode then
                        bindingMode = false
                        pcall(function()
                            bndLbl.Text  = "Touche : [ "..toggleLabel.." ]"
                            bndLbl.Color = ctx.ACH()
                            hint.Text    = "Cliquer puis appuyer une touche pour changer"
                        end)
                    else
                        bindingMode = true
                        pcall(function()
                            bndLbl.Text  = "En attente d'une touche…"
                            bndLbl.Color = ctx.C.yellow
                            hint.Text    = "Appuie sur la touche souhaitée maintenant"
                        end)
                    end
                end)
            end},

            -- 3. Credits
            {name="Credits", buildFn=function(ctx)
                local o,cx,cy,cw = ctx.objs,ctx.cx,ctx.cy,ctx.cw
                local D = ctx.Draw
                local sy = cy
                o[#o+1] = ctx.regACH(D.Text(cx,sy,"EXE.HUB",ctx.ACH(),18,5))
                o[#o+1] = D.Text(cx,sy+26,"Script hub pour Roblox",ctx.C.muted,11,4)
                o[#o+1] = D.Text(cx,sy+48,"Dev : mattheube",ctx.C.white,12,4)
                o[#o+1] = D.Text(cx,sy+66,
                    "github.com/mattheube/EXE.HUB",ctx.C.muted,10,4)
                o[#o+1] = D.Line(cx,sy+86,cx+cw,sy+86,ctx.C.border,1,4)
                o[#o+1] = D.Text(cx,sy+96,"Version hub : v3.0",ctx.C.dimmed,10,4)
            end},

            -- 4. Logs (changelog hub + module)
            {name="Logs", buildFn=function(ctx)
                local o,cx,cy = ctx.objs,ctx.cx,ctx.cy
                local D = ctx.Draw
                local sy = cy

                o[#o+1] = D.Text(cx,sy,"HUB CHANGELOG",ctx.C.muted,10,4)
                sy = sy + 16
                for _,line in ipairs(HUB_CHANGELOG) do
                    o[#o+1] = D.Text(cx,sy,line,ctx.C.white,10,4)
                    sy = sy + 14
                end

                if #gameChangelog > 0 then
                    sy = sy + 6
                    o[#o+1] = D.Line(cx,sy,cx+ctx.cw,sy,ctx.C.border,1,4)
                    sy = sy + 8
                    o[#o+1] = D.Text(cx,sy,"MODULE CHANGELOG",ctx.C.muted,10,4)
                    sy = sy + 16
                    for _,line in ipairs(gameChangelog) do
                        o[#o+1] = D.Text(cx,sy,line,ctx.ACH(),10,4)
                        sy = sy + 14
                    end
                end
            end},
        }
    end

    -- ── GLOW LOOP ────────────────────────────────────────────
    task.spawn(function()
        local t = 0
        while true do
            task.wait(0.05)
            if not uiReady or not uiVisible then continue end
            t = t + 0.09
            local pulse  = 0.5 + 0.5*math.sin(t)
            local thick  = 1 + pulse*2.5
            local transp = 0.22 + 0.72*(1-pulse)
            local col    = AC()
            for _,gl in ipairs(glowLines) do pcall(function()
                gl.Thickness    = thick
                gl.Transparency = transp
                gl.Color        = col
            end) end
        end
    end)

    -- ── PETALS ───────────────────────────────────────────────
    local PMAX       = 20
    local petalCount = 0

    local function spawnPetal()
        if petalCount >= PMAX or not uiReady then return end
        petalCount = petalCount + 1
        local sz = math.random(2,7)
        local p  = Drawing.new("Circle")
        p.Position    = Vector2.new(WX+math.random(sz,WW-sz), WY+CONTY+sz)
        p.Radius      = sz
        p.Color       = petalColor()
        p.Filled      = true
        p.Transparency= math.random(25,60)/100
        p.ZIndex      = 2
        p.Visible     = false
        petalObjs[#petalObjs+1] = p

        local steps = math.random(80,220)
        local dy    = (WY+WH-2-(WY+CONTY)) / steps
        local dx    = math.random(-16,16)/steps
        local dA    = (p.Transparency-0.97)/steps
        local phase = math.random()*math.pi*2
        local amp   = math.random(2,8)/steps

        task.spawn(function()
            for s=1,steps do
                task.wait(0.05)
                if not uiReady then break end
                pcall(function()
                    p.Visible      = uiVisible
                    p.Color        = petalColor()
                    p.Position     = Vector2.new(
                        p.Position.X + dx + math.sin(phase+s*0.14)*amp,
                        p.Position.Y + dy)
                    p.Transparency = math.min(1, p.Transparency+dA)
                end)
            end
            pcall(function() p:Remove() end)
            for i,a in ipairs(petalObjs) do
                if a==p then table.remove(petalObjs,i) break end
            end
            petalCount = petalCount - 1
        end)
    end

    task.spawn(function()
        while true do
            task.wait(1.0 + math.random()*2.0)
            if uiReady then pcall(spawnPetal) end
            if math.random() < 0.5 then
                task.wait(0.2)
                if uiReady then pcall(spawnPetal) end
            end
        end
    end)

    -- ── NOTIFICATIONS v3 ─────────────────────────────────────
    -- Seulement 2 notifs : Welcome et Game Detected
    -- Animation : slide depuis le bas → coin haut-droit
    -- Après 10s : slide vers la droite et disparaît
    -- Petites particules (étoiles) à l'intérieur
    local NW   = math.max(240, math.floor(SW/5.8))
    local NH   = 68
    local NX   = SW - NW - 16  -- X final (coin haut-droit)
    local NY   = 72             -- Y final
    local NDUR = 10             -- secondes avant slide-out

    local notifQueue   = {}   -- {title,msg,col} en attente
    local notifBusy    = false

    local function showNextNotif()
        if notifBusy or #notifQueue == 0 then return end
        notifBusy = true
        local n   = table.remove(notifQueue, 1)
        local objs= {}

        -- position de départ : sous l'écran
        local startY = SH + 10
        local endY   = NY

        local bg  = Draw.Rect   (NX,startY,NW,NH,   C.notifBg, 50)
        local brd = Draw.Outline(NX,startY,NW,NH,   n.col,1.5, 51)
        local bar = Draw.Rect   (NX+4,startY+6,3,NH-12,n.col,  51)
        local t1  = Draw.Text   (NX+14,startY+14,n.title,C.white,13,52)
        local t2  = Draw.Text   (NX+14,startY+32,n.msg,  C.muted,10,52)
        objs = {bg,brd,bar,t1,t2}

        -- étoiles/particules dans la notif
        local stars = {}
        for _=1,5 do
            local s = Draw.Rect(
                NX + math.random(8,NW-8),
                startY + math.random(4,NH-4),
                2,2, n.col, 53)
            s.Transparent = 0.3
            objs[#objs+1] = s
            stars[#stars+1] = {obj=s, ox=s.Position.X, oy=s.Position.Y, t=math.random()*math.pi*2}
        end

        Draw.SetVisible(objs, true)

        local function setY(ny2)
            local dy = ny2 - bg.Position.Y
            for _,o in ipairs(objs) do pcall(function()
                if o.Position then
                    o.Position = Vector2.new(o.Position.X, o.Position.Y+dy)
                end
            end) end
            for _,st in ipairs(stars) do
                st.oy = st.oy + dy
            end
        end

        task.spawn(function()
            -- slide in depuis le bas (20 steps)
            local steps = 20
            for i=1,steps do
                task.wait(0.025)
                local prog  = i/steps
                local ease  = 1-(1-prog)^3  -- ease-out cubic
                local curY  = startY + (endY-startY)*ease
                setY(curY)
            end
            setY(endY)

            -- animation étoiles pendant durée
            local elapsed = 0
            while elapsed < NDUR do
                task.wait(0.05)
                elapsed = elapsed + 0.05
                local t3 = elapsed * 2
                for _,st in ipairs(stars) do
                    pcall(function()
                        st.obj.Position = Vector2.new(
                            st.ox + math.sin(t3+st.t)*4,
                            st.oy + math.cos(t3*0.7+st.t)*2)
                    end)
                end
            end

            -- slide out vers la droite (16 steps)
            local curX = NX
            for i=1,16 do
                task.wait(0.025)
                local ox = curX + i*(NW+60)/16
                for _,o in ipairs(objs) do pcall(function()
                    if o.Position then
                        o.Position = Vector2.new(ox, o.Position.Y)
                    end
                end) end
            end

            Draw.Destroy(objs)
            notifBusy = false
            task.wait(0.3)
            showNextNotif()
        end)
    end

    local function queueNotif(title, msg, col)
        notifQueue[#notifQueue+1] = {title=title, msg=msg, col=col}
        showNextNotif()
    end

    -- ── INPUT LOOP ───────────────────────────────────────────
    task.spawn(function()
        local prevLMB    = false
        local prevToggle = false
        local dragActive = false
        local dragOX,dragOY = 0,0
        local targetWX,targetWY = WX,WY

        while true do
            task.wait(0.033)
            if not uiReady then continue end

            local mx,my      = MX(),MY()
            local lmb        = LMB()
            local toggleDown = isToggleDown()

            -- keybind mode
            if bindingMode then
                scanForNewBind()
            end

            -- toggle (front montant)
            if toggleDown and not prevToggle and not bindingMode then
                uiVisible = not uiVisible
                Draw.SetVisible(baseObjs, uiVisible)
                Draw.SetVisible(pickerObjs, uiVisible and pickerActive)
                Draw.SetVisible(dropdownObjs, uiVisible and dropdownOpen)
                for _,p in ipairs(petalObjs) do
                    pcall(function() p.Visible = uiVisible end)
                end
                -- [FIX-UL] restaurer l'underline de l'onglet actif
                local bd = tabBtnData[activeTab]
                if bd then bd.ul.Visible = uiVisible end
            end
            prevToggle = toggleDown

            -- drag
            if dragActive then
                if lmb then
                    targetWX = mx - dragOX
                    targetWY = my - dragOY
                    local dx = math.floor((targetWX-WX)*0.6)
                    local dy = math.floor((targetWY-WY)*0.6)
                    if math.abs(dx)+math.abs(dy) > 0 then
                        WX=WX+dx WY=WY+dy
                        Draw.Move(baseObjs,dx,dy)
                        Draw.Move(pickerObjs,dx,dy)
                        Draw.Move(dropdownObjs,dx,dy)
                        -- déplacer toutes les zones
                        for _,z in ipairs(globalZones) do
                            z.x=z.x+dx z.y=z.y+dy
                        end
                        for _,tzl in pairs(tabZones) do
                            for _,z in ipairs(tzl) do
                                z.x=z.x+dx z.y=z.y+dy
                            end
                        end
                    end
                else
                    dragActive = false
                end
            end

            -- click (front montant)
            if lmb and not prevLMB and uiVisible then
                -- fermer dropdown/picker si clic hors d'eux
                if dropdownOpen then
                    -- hitTest gérera la zone dropdown si dans les zones
                    -- sinon on ferme
                end
                if mx>=WX and mx<=WX+WW and my>=WY and my<=WY+TH then
                    dragActive = true
                    dragOX = mx-WX
                    dragOY = my-WY
                    targetWX,targetWY = WX,WY
                else
                    hitTest(mx,my)
                end
            end
            prevLMB = lmb
        end
    end)

    -- ── PUBLIC API ───────────────────────────────────────────
    function UI.Init()
        task.spawn(function()
            makeDefaultTabs()
            buildWindow()
            Draw.SetVisible(baseObjs, true)
            uiReady   = true
            uiVisible = true
            if UI._onReady then UI._onReady() end
        end)
    end

    local _q = {}
    UI._onReady = function()
        UI._onReady = nil
        for _,f in ipairs(_q) do pcall(f) end
        table.clear(_q)
    end
    local function defer(fn)
        if uiReady then pcall(fn) else _q[#_q+1]=fn end
    end

    function UI.LoadGameModule(gm)
        defer(function()
            dynName = gm.Name    or dynName
            dynVer  = gm.Version or dynVer
            if lblTitleGame then pcall(function() lblTitleGame.Text=dynName end) end
            if lblTitleVer  then pcall(function() lblTitleVer.Text=dynVer   end) end
            -- changelog du module
            if gm.Changelog then
                table.clear(gameChangelog)
                for _,l in ipairs(gm.Changelog) do
                    gameChangelog[#gameChangelog+1] = l
                end
            end
            local newTabs = {}
            if gm.Tabs and #gm.Tabs>0 then
                for _,t in ipairs(gm.Tabs) do newTabs[#newTabs+1]=t end
            end
            for _,t in ipairs(currentTabs) do
                if t.name=="Settings" or t.name=="Credits" or t.name=="Logs" then
                    newTabs[#newTabs+1] = t
                end
            end
            activeTab    = 1
            currentTabs  = newTabs
            buildWindow()
            Draw.SetVisible(baseObjs, uiVisible)
        end)
    end

    function UI.ShowWelcome()
        defer(function()
            queueNotif("EXE.HUB", "ExeHub est actif", AC())
        end)
    end

    function UI.ShowGameDetected(n)
        defer(function()
            queueNotif("Jeu détecté", n, C.green)
        end)
    end

    function UI.ShowGameLoaded(n,ver)
        dynName = n or dynName
        dynVer  = ver or dynVer
        defer(function()
            if lblTitleGame then pcall(function() lblTitleGame.Text=dynName end) end
            if lblTitleVer  then pcall(function() lblTitleVer.Text=dynVer   end) end
        end)
    end

    function UI.ShowNotSupported(id)
        defer(function()
            queueNotif("Non supporté", "PlaceId: "..tostring(id), C.yellow)
        end)
    end

    function UI.ShowLoadError(n)
        defer(function()
            queueNotif("Erreur", tostring(n), C.red)
        end)
    end

    function UI.Notify(title,msg,t)
        defer(function()
            local col = AC()
            if t=="success" then col=C.green
            elseif t=="warning" then col=C.yellow
            elseif t=="error"   then col=C.red end
            queueNotif(title,msg,col)
        end)
    end

    function UI.Destroy()
        uiReady = false
        Draw.DestroyAll()
        table.clear(baseObjs) table.clear(glowLines) table.clear(accentObjs)
        table.clear(petalObjs) clearAllZones()
    end
end

-- ============================================================
-- LOADER
-- ============================================================
local Loader = {}
do
    function Loader.LoadGame(info,loadFn,ui,utils)
        if not info or not info.module then
            utils.Error("gameInfo invalide") return
        end
        ui.ShowGameDetected(info.name)
        local gm = loadFn(info.module)
        if not gm then ui.ShowLoadError(info.name) return end
        gm.Name    = gm.Name    or info.name
        gm.Version = gm.Version or info.version
        if type(gm.Init)=="function" then
            local ok,err = pcall(function() gm.Init({UI=ui,Utils=utils}) end)
            if not ok then
                ui.ShowLoadError(info.name)
                utils.Error(tostring(err))
                return
            end
        end
        ui.ShowGameLoaded(gm.Name, gm.Version)
        ui.LoadGameModule(gm)
    end
end

-- ============================================================
-- MODULE LOADER
-- ============================================================
_G.__EXE_HUB_MODULES = {}
local function loadModule(path)
    local url = BASE..path.."?t="..tostring(math.floor(tick()))
    local raw
    pcall(function() raw = game:HttpGet(url,true) end)
    if not raw or raw=="" then Utils.Error("HTTP: "..path) return nil end
    local fn,e = loadstring(raw)
    if not fn then Utils.Error("Compile: "..path.." "..tostring(e)) return nil end
    local ok,r = pcall(fn)
    if not ok then Utils.Error("Exec: "..path.." "..tostring(r)) return nil end
    if r ~= nil then return r end
    local key = path:match("([^/]+)%.lua$")
    if key and _G.__EXE_HUB_MODULES[key] then
        local m = _G.__EXE_HUB_MODULES[key]
        _G.__EXE_HUB_MODULES[key] = nil
        return m
    end
    Utils.Error("NIL: "..path)
    return nil
end

-- ============================================================
-- LAUNCH
-- ============================================================
UI.Init()
UI.ShowWelcome()
local placeId  = game.PlaceId
local gameInfo = Registry.GetGame(placeId)
if gameInfo then
    Loader.LoadGame(gameInfo, loadModule, UI, Utils)
else
    UI.ShowNotSupported(placeId)
end