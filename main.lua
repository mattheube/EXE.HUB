-- ╔══════════════════════════════════════════════════════════╗
-- ║  EXE.HUB  |  main.lua  v2.3  —  Drawing API (Matcha)   ║
-- ╚══════════════════════════════════════════════════════════╝
--
-- INPUT API confirmée sur Matcha :
--   mouse.X / mouse.Y  via  Players.LocalPlayer:GetMouse()
--   ismouse1pressed()  →  boolean LMB
--   game:GetService("RunService").RenderStepped  →  per-frame hook
--   InputBegan sur Matcha = bruit (mouvements souris), pas fiable
--   → toggle clavier via polling RunService + IsKeyDown du vrai UIS Roblox

local BASE       = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"
local CACHE_BUST = "?t=" .. tostring(math.floor(tick()))

-- ============================================================
-- SERVICES
-- ============================================================
local RunService = game:GetService("RunService")
-- On récupère le VRAI UserInputService Roblox (pas le mock Matcha)
local RealUIS
pcall(function() RealUIS = game:GetService("UserInputService") end)

-- ============================================================
-- UTILS
-- ============================================================
local Utils = {}
do
    local P = "[EXE.HUB]"
    function Utils.Log(m)   print(P.." "..tostring(m)) end
    function Utils.Warn(m)  warn(P.." WARN: "..tostring(m)) end
    function Utils.Error(m) warn(P.." ERR: "..tostring(m)) end
    function Utils.SafeCall(fn,lbl)
        local ok,e=pcall(fn)
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
-- DRAW  (thin wrapper autour de Drawing API)
-- ============================================================
local Draw = {}
do
    local pool = {}
    local function reg(o) table.insert(pool,o) return o end

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
        o.Size=sz or 13 o.ZIndex=z or 3 o.Outline=false
        o.Center=false o.Visible=false
        return o
    end
    function Draw.Line(x1,y1,x2,y2,col,thick,z)
        local o=reg(Drawing.new("Line"))
        o.From=Vector2.new(x1,y1) o.To=Vector2.new(x2,y2)
        o.Color=col o.Thickness=thick or 1 o.Transparency=1
        o.ZIndex=z or 2 o.Visible=false
        return o
    end
    function Draw.Circle(x,y,r,col,z)
        local o=reg(Drawing.new("Circle"))
        o.Position=Vector2.new(x,y) o.Radius=r
        o.Color=col o.Filled=true o.Transparency=0.5
        o.ZIndex=z or 1 o.Visible=false
        return o
    end
    function Draw.SetVisible(g,v)
        for _,o in ipairs(g) do pcall(function() o.Visible=v end) end
    end
    function Draw.Destroy(g)
        for _,o in ipairs(g) do
            pcall(function() o:Remove() end)
            for i,p in ipairs(pool) do if p==o then table.remove(pool,i) break end end
        end
        table.clear(g)
    end
    function Draw.Move(g,dx,dy)
        for _,o in ipairs(g) do pcall(function()
            if o.Position then o.Position=Vector2.new(o.Position.X+dx,o.Position.Y+dy) end
            if o.From     then
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
    -- ── screen ──────────────────────────────────────────────
    local SW,SH=1920,1080
    pcall(function()
        SW=workspace.CurrentCamera.ViewportSize.X
        SH=workspace.CurrentCamera.ViewportSize.Y
    end)

    -- ── mouse ────────────────────────────────────────────────
    local mouse = Players.LocalPlayer:GetMouse()
    local function MX() return mouse.X end
    local function MY() return mouse.Y end
    local function LMB() local ok,r=pcall(ismouse1pressed) return ok and r end

    -- ── toggle key ───────────────────────────────────────────
    -- Matcha intercepte F1–F4 et les touches système.
    -- On utilise le vrai UIS Roblox + IsKeyDown en polling.
    -- Touches disponibles : lettres uniquement sur Matcha.
    -- On offre H / J / K / L / P comme options de toggle.
    local TOGGLE_OPTIONS = {
        {label="H", kc=Enum.KeyCode.H},
        {label="J", kc=Enum.KeyCode.J},
        {label="K", kc=Enum.KeyCode.K},
        {label="L", kc=Enum.KeyCode.L},
        {label="P", kc=Enum.KeyCode.P},
    }
    local toggleIdx = 1  -- défaut = H
    local function getToggleKC() return TOGGLE_OPTIONS[toggleIdx].kc end
    local function isToggleDown()
        if not RealUIS then return false end
        local ok,r=pcall(function() return RealUIS:IsKeyDown(getToggleKC()) end)
        return ok and r or false
    end

    -- ── thème ─────────────────────────────────────────────
    -- Couleur accent stockée comme HSV pour le color picker
    local accentH, accentS, accentV = 330/360, 0.65, 0.95  -- sakura par défaut
    local function accentColor()
        return Color3.fromHSV(accentH, accentS, accentV)
    end
    local function accentHiColor()
        return Color3.fromHSV(accentH, accentS*0.7, 1.0)
    end
    local AC  = accentColor
    local ACH = accentHiColor

    -- presets
    local PRESETS = {
        {label="Sakura", h=330/360, s=0.65, v=0.95},
        {label="Blue",   h=220/360, s=0.75, v=1.00},
        {label="Green",  h=145/360, s=0.70, v=0.85},
        {label="Red",    h=  0/360, s=0.75, v=0.95},
        {label="Purple", h=270/360, s=0.70, v=0.90},
        {label="Orange", h= 25/360, s=0.80, v=1.00},
    }

    -- petal color tracks accent
    local function petalColor()
        return Color3.fromHSV(accentH, accentS*0.5, 1.0)
    end

    -- ── palette ──────────────────────────────────────────────
    local C={
        bg      =Color3.fromRGB(13,12,20),
        panel   =Color3.fromRGB(18,17,28),
        titleBg =Color3.fromRGB(10,8,18),
        tabBg   =Color3.fromRGB(20,18,30),
        tabSel  =Color3.fromRGB(32,26,46),
        border  =Color3.fromRGB(42,30,58),
        white   =Color3.fromRGB(235,235,248),
        muted   =Color3.fromRGB(120,95,138),
        dimmed  =Color3.fromRGB(70,58,90),
        green   =Color3.fromRGB(90,210,130),
        yellow  =Color3.fromRGB(250,195,75),
        red     =Color3.fromRGB(250,85,85),
        notifBg =Color3.fromRGB(14,11,22),
    }

    -- ── dimensions ───────────────────────────────────────────
    local WW     = math.max(280, math.floor(SW/5.5))
    local WH     = math.max(440, math.floor(SH/2.8))
    local WX     = math.floor(SW/2-WW/2)
    local WY     = math.floor(SH/2-WH/2)
    local TH     = 36    -- title height
    local TABH   = 28    -- tab bar height
    local CONTY  = TH+TABH
    local PAD    = 14
    local LNHGT  = 22    -- line height in content

    -- ── state ────────────────────────────────────────────────
    local uiReady   = false
    local uiVisible = true
    local activeTab = 1
    local currentTabs = {}

    local baseObjs   = {}   -- ALL window drawing objects
    local glowLines  = {}
    local tabBtnData = {}   -- [i] = {bg,lbl,ul}
    local tabContent = {}   -- [i] = list of Drawing objs for that tab
    local notifList  = {}
    local petalObjs  = {}
    local zones      = {}   -- click zones {x,y,w,h,fn}

    -- dynamic title labels (refs kept for live update)
    local lblTitleGame, lblTitleVer
    local dynName = "—"
    local dynVer  = "—"
    local logLines = {}

    -- color picker state
    local pickerActive = false
    local pickerObjs   = {}

    -- ── helpers ──────────────────────────────────────────────
    local function addZone(x,y,w,h,fn)
        table.insert(zones,{x=x,y=y,w=w,h=h,fn=fn})
    end
    local function clearZones() table.clear(zones) end
    local function hitTest(mx,my)
        -- iterate copy to avoid issues if fn modifies zones
        local snap = {}
        for _,z in ipairs(zones) do table.insert(snap,z) end
        for _,z in ipairs(snap) do
            if mx>=z.x and mx<=z.x+z.w and my>=z.y and my<=z.y+z.h then
                pcall(z.fn) break  -- one click = one action
            end
        end
    end

    local function addLog(msg)
        local ts=string.format("%02d:%02d",math.floor(tick()/3600)%24,math.floor(tick()/60)%60)
        table.insert(logLines,ts.." "..msg)
        if #logLines>80 then table.remove(logLines,1) end
    end

    -- ── full UI rebuild (called on theme change, tab change, etc.) ──
    local function buildWindow()  end  -- forward decl, defined below

    -- ── apply theme instantly — recolor all live objects ────
    local function applyTheme()
        -- recolor glow lines
        local ac = AC()
        for _,gl in ipairs(glowLines) do
            pcall(function() gl.Color=ac end)
        end
        -- recolor title "EXE.HUB"  (first text in baseObjs with that text)
        for _,o in ipairs(baseObjs) do pcall(function()
            if o.Text=="EXE.HUB" then o.Color=ACH() end
        end) end
        -- recolor active tab button
        local btn=tabBtnData[activeTab]
        if btn then
            btn.lbl.Color=ACH()
            btn.ul.Color=ac
        end
        -- recolor all tab underlines: only active one visible
        for i,bd in pairs(tabBtnData) do
            bd.ul.Color = ac
            bd.ul.Visible = (i==activeTab) and uiVisible
        end
        -- petal color update (they'll use petalColor() on next spawn naturally)
        -- existing petals: recolor
        for _,p in ipairs(petalObjs) do
            pcall(function() p.Color=petalColor() end)
        end
    end

    -- ── color picker (drawn on top) ──────────────────────────
    -- Simple HSV rectangle: X=hue, Y=saturation, plus V slider
    local PICK_W = WW-PAD*2
    local PICK_H = 100
    local VSLIDE_H = 14
    local pickerX, pickerY = 0,0
    local pickerZoneId = nil

    local function destroyPicker()
        Draw.Destroy(pickerObjs)
        pickerActive = false
    end

    local function buildPicker(cx,cy)
        destroyPicker()
        pickerActive = true
        pickerX, pickerY = cx, cy

        -- hue×sat gradient approximated with colored squares
        local steps = 18
        local sw = math.floor(PICK_W/steps)
        for hi=0,steps-1 do
            local h = hi/steps
            -- sat gradient: top bright, bottom desaturated
            local satSteps = 8
            local sh = math.floor(PICK_H/satSteps)
            for si=0,satSteps-1 do
                local s = 1-(si/satSteps)
                local col=Color3.fromHSV(h,s,accentV)
                local sq=Draw.Rect(cx+hi*sw, cy+si*sh, sw+1, sh+1, col, 30)
                sq.Visible=true
                table.insert(pickerObjs,sq)
            end
        end

        -- V (brightness) slider below
        local vy = cy+PICK_H+6
        local vsteps = 20
        local vsw = math.floor(PICK_W/vsteps)
        for vi=0,vsteps-1 do
            local v=vi/vsteps
            local col=Color3.fromHSV(accentH,accentS,v)
            local sq=Draw.Rect(cx+vi*vsw,vy,vsw+1,VSLIDE_H,col,30)
            sq.Visible=true
            table.insert(pickerObjs,sq)
        end

        -- border around entire picker
        local totalH=PICK_H+6+VSLIDE_H
        local brd=Draw.Outline(cx,cy,PICK_W,totalH, C.border,1.5,31)
        brd.Visible=true
        table.insert(pickerObjs,brd)

        -- current color preview
        local prev=Draw.Rect(cx+PICK_W+4,cy,20,totalH,AC(),31)
        prev.Visible=true
        table.insert(pickerObjs,prev)

        -- click zone: hue×sat area
        addZone(cx,cy,PICK_W,PICK_H,function()
            local mx,my=MX(),MY()
            local relX=math.max(0,math.min(PICK_W,mx-cx))
            local relY=math.max(0,math.min(PICK_H,my-cy))
            accentH = relX/PICK_W
            accentS = 1-(relY/PICK_H)
            -- update preview
            prev.Color=AC()
            applyTheme()
        end)

        -- click zone: V slider
        addZone(cx,vy,PICK_W,VSLIDE_H,function()
            local mx=MX()
            local relX=math.max(0,math.min(PICK_W,mx-cx))
            accentV = relX/PICK_W
            prev.Color=AC()
            applyTheme()
        end)
    end

    -- ── tab switch ───────────────────────────────────────────
    local function switchTab(idx)
        if not currentTabs[idx] then return end
        -- hide old content
        if tabContent[activeTab] then Draw.SetVisible(tabContent[activeTab],false) end
        -- reset old button style
        local old=tabBtnData[activeTab]
        if old then old.bg.Color=C.tabBg old.lbl.Color=C.muted old.ul.Visible=false end
        -- destroy picker if switching away
        if pickerActive then destroyPicker() end
        activeTab=idx
        -- build content if not yet built
        if not tabContent[activeTab] then
            tabContent[activeTab]={}
            local tab=currentTabs[activeTab]
            if tab and type(tab.buildFn)=="function" then
                pcall(function()
                    tab.buildFn({
                        cx=WX+PAD, cy=WY+CONTY+PAD,
                        cw=WW-PAD*2, ch=WH-CONTY-PAD*2,
                        C=C, AC=AC, ACH=ACH, PAD=PAD, LNHGT=LNHGT,
                        Draw=Draw, objs=tabContent[activeTab],
                        addZone=addZone,
                        buildPicker=buildPicker,
                        WX=function()return WX end,
                        WY=function()return WY end,
                        WW=WW, WH=WH,
                    })
                end)
                for _,o in ipairs(tabContent[activeTab]) do
                    table.insert(baseObjs,o)
                end
            end
        end
        Draw.SetVisible(tabContent[activeTab], uiVisible)
        local nw=tabBtnData[activeTab]
        if nw then nw.bg.Color=C.tabSel nw.lbl.Color=ACH() nw.ul.Color=AC() nw.ul.Visible=uiVisible end
    end

    -- ── build window ─────────────────────────────────────────
    buildWindow = function()
        -- destroy existing
        destroyPicker()
        for _,o in ipairs(baseObjs) do pcall(function() o:Remove() end) end
        table.clear(baseObjs) table.clear(glowLines) table.clear(tabBtnData)
        for _,tc in pairs(tabContent) do
            for _,o in ipairs(tc) do pcall(function() o:Remove() end) end
        end
        table.clear(tabContent)
        clearZones()

        local x,y=WX,WY
        local ac=AC()

        -- ── background ──────────────────────────────────────
        table.insert(baseObjs, Draw.Rect(x,y,WW,WH,C.bg,1))

        -- ── title bar ───────────────────────────────────────
        table.insert(baseObjs, Draw.Rect(x,y,WW,TH,C.titleBg,2))
        -- "EXE.HUB" in accent
        local lHub=Draw.Text(x+PAD,y+11,"EXE.HUB",ACH(),14,5)
        table.insert(baseObjs,lHub)
        -- separator
        table.insert(baseObjs,Draw.Line(x+88,y+8,x+88,y+TH-8,C.border,1,4))
        -- game name
        lblTitleGame=Draw.Text(x+96,y+12,dynName,C.muted,11,5)
        table.insert(baseObjs,lblTitleGame)
        -- version (right-aligned approx)
        lblTitleVer=Draw.Text(x+WW-62,y+13,dynVer,C.dimmed,10,5)
        table.insert(baseObjs,lblTitleVer)
        -- title bottom line
        table.insert(baseObjs,Draw.Line(x,y+TH,x+WW,y+TH,C.border,1,3))

        -- ── tab bar ──────────────────────────────────────────
        local nTabs=#currentTabs
        local tabW=math.floor(WW/math.max(nTabs,1))
        local tabY=y+TH
        for i,tab in ipairs(currentTabs) do
            local tx=x+(i-1)*tabW
            local isSel=(i==activeTab)
            local tbg=Draw.Rect(tx,tabY,tabW,TABH,isSel and C.tabSel or C.tabBg,2)
            table.insert(baseObjs,tbg)
            if i>1 then
                table.insert(baseObjs,Draw.Line(tx,tabY+5,tx,tabY+TABH-5,C.border,1,3))
            end
            -- centered label
            local lx=tx+math.floor(tabW/2)-math.floor(#tab.name*3.2)
            local tlbl=Draw.Text(lx,tabY+9,tab.name,isSel and ACH() or C.muted,10,4)
            table.insert(baseObjs,tlbl)
            -- underline (only active)
            local tul=Draw.Line(tx+3,tabY+TABH-2,tx+tabW-3,tabY+TABH-2,ac,1.5,4)
            tul.Visible=isSel  -- only active tab shows underline
            table.insert(baseObjs,tul)
            tabBtnData[i]={bg=tbg,lbl=tlbl,ul=tul}
            local ci=i
            addZone(tx,tabY,tabW,TABH,function() switchTab(ci) end)
        end

        -- ── content area ─────────────────────────────────────
        table.insert(baseObjs,Draw.Line(x,y+CONTY,x+WW,y+CONTY,C.border,1,3))
        table.insert(baseObjs,Draw.Rect(x,y+CONTY,WW,WH-CONTY,C.panel,1))

        -- ── outer border + glow ──────────────────────────────
        table.insert(baseObjs,Draw.Outline(x,y,WW,WH,C.border,1,3))
        local function gl(x1,y1,x2,y2)
            local l=Draw.Line(x1,y1,x2,y2,ac,1.5,4)
            l.Transparency=0.7
            table.insert(baseObjs,l)
            table.insert(glowLines,l)
        end
        gl(x,y,     x+WW,y      )
        gl(x+WW,y,  x+WW,y+WH  )
        gl(x+WW,y+WH,x,  y+WH  )
        gl(x,y+WH,  x,   y     )

        -- ── build active tab ─────────────────────────────────
        tabContent[activeTab]={}
        local tab=currentTabs[activeTab]
        if tab and type(tab.buildFn)=="function" then
            pcall(function()
                tab.buildFn({
                    cx=WX+PAD, cy=WY+CONTY+PAD,
                    cw=WW-PAD*2, ch=WH-CONTY-PAD*2,
                    C=C, AC=AC, ACH=ACH, PAD=PAD, LNHGT=LNHGT,
                    Draw=Draw, objs=tabContent[activeTab],
                    addZone=addZone,
                    buildPicker=buildPicker,
                    WX=function()return WX end,
                    WY=function()return WY end,
                    WW=WW, WH=WH,
                })
            end)
            for _,o in ipairs(tabContent[activeTab]) do
                table.insert(baseObjs,o)
            end
        end
    end

    -- ── default tabs ─────────────────────────────────────────
    local function makeDefaultTabs()
        currentTabs = {
            -- Main
            {name="Main", buildFn=function(ctx)
                local o,cx,cy=ctx.objs,ctx.cx,ctx.cy
                local D=ctx.Draw
                table.insert(o,D.Text(cx,cy,   "STATUT",       ctx.C.muted, 9,4))
                table.insert(o,D.Text(cx,cy+14, "En attente…",  ctx.ACH(),  13,4))
                table.insert(o,D.Line(cx,cy+34, cx+ctx.cw,cy+34, ctx.C.border,1,4))
                table.insert(o,D.Text(cx,cy+44, "JEU",          ctx.C.muted, 9,4))
                table.insert(o,D.Text(cx,cy+58,  dynName,        ctx.C.white,13,4))
                table.insert(o,D.Text(cx,cy+80, "VERSION",       ctx.C.muted, 9,4))
                table.insert(o,D.Text(cx,cy+94,  dynVer,         ctx.ACH(),  12,4))
            end},

            -- Settings
            {name="Settings", buildFn=function(ctx)
                local o,cx,cy,cw=ctx.objs,ctx.cx,ctx.cy,ctx.cw
                local D=ctx.Draw
                local sy=cy

                -- ── Color picker ───────────────────────────
                table.insert(o,D.Text(cx,sy,"COULEUR ACCENT",ctx.C.muted,9,4))
                sy=sy+16

                -- Color preview swatch (click to open/close picker)
                local swW,swH=cw,20
                local swatch=D.Rect(cx,sy,swW,swH,ctx.AC(),4)
                table.insert(o,swatch)
                -- label inside swatch
                local swLbl=D.Text(cx+8,sy+4,"Cliquer pour choisir",ctx.C.white,10,5)
                table.insert(o,swLbl)
                ctx.addZone(cx,sy,swW,swH,function()
                    if pickerActive then
                        destroyPicker()
                        -- refresh swatch color
                        swatch.Color=AC()
                    else
                        ctx.buildPicker(cx,sy+swH+4)
                    end
                end)
                sy=sy+swH+6

                -- Presets row
                table.insert(o,D.Text(cx,sy,"PRESETS",ctx.C.muted,9,4))
                sy=sy+14
                local pw=math.floor((cw-5*4)/6)
                for pi,pr in ipairs(PRESETS) do
                    local bx=cx+(pi-1)*(pw+4)
                    local col=Color3.fromHSV(pr.h,pr.s,pr.v)
                    local pbtn=D.Rect(bx,sy,pw,22,col,4)
                    table.insert(o,pbtn)
                    local lx=bx+math.floor(pw/2)-math.floor(#pr.label*3.2)
                    table.insert(o,D.Text(lx,sy+5,pr.label,ctx.C.white,9,5))
                    local pii=pi
                    ctx.addZone(bx,sy,pw,22,function()
                        local pr2=PRESETS[pii]
                        accentH,accentS,accentV=pr2.h,pr2.s,pr2.v
                        swatch.Color=AC()
                        destroyPicker()
                        applyTheme()
                        -- rebuild window to update all static colored elements
                        buildWindow()
                        Draw.SetVisible(baseObjs,uiVisible)
                    end)
                end
                sy=sy+(22+10)

                -- ── Toggle key ─────────────────────────────
                table.insert(o,D.Text(cx,sy,"TOUCHE TOGGLE (lettre uniquement sur Matcha)",ctx.C.muted,9,4))
                sy=sy+14
                local kw=math.floor((cw-4*4)/5)
                for ki,k in ipairs(TOGGLE_OPTIONS) do
                    local bx=cx+(ki-1)*(kw+4)
                    local isSel=(ki==toggleIdx)
                    local kbg=D.Rect(bx,sy,kw,26,isSel and ctx.C.tabSel or ctx.C.tabBg,4)
                    table.insert(o,kbg)
                    if isSel then
                        table.insert(o,D.Outline(bx,sy,kw,26,ctx.AC(),1.5,5))
                    end
                    local lx=bx+math.floor(kw/2)-math.floor(#k.label*3.5)
                    table.insert(o,D.Text(lx,sy+6,k.label,isSel and ctx.ACH() or ctx.C.muted,12,5))
                    local kci=ki
                    ctx.addZone(bx,sy,kw,26,function()
                        toggleIdx=kci
                        buildWindow()
                        Draw.SetVisible(baseObjs,uiVisible)
                    end)
                end
                sy=sy+36
                table.insert(o,D.Text(cx,sy,
                    "Appuie sur la touche choisie pour masquer/afficher le hub.",
                    ctx.C.muted,9,4))
            end},

            -- Credits
            {name="Credits", buildFn=function(ctx)
                local o,cx,cy,cw=ctx.objs,ctx.cx,ctx.cy,ctx.cw
                local D=ctx.Draw
                local sy=cy
                table.insert(o,D.Text(cx,sy,    "EXE.HUB",                ctx.ACH(),16,5))
                table.insert(o,D.Text(cx,sy+22, "Script hub pour Roblox", ctx.C.muted,11,4))
                table.insert(o,D.Text(cx,sy+44, "Dev : mattheube",         ctx.C.white,12,4))
                table.insert(o,D.Text(cx,sy+62, "github.com/mattheube/EXE.HUB",ctx.C.muted,10,4))
                table.insert(o,D.Line(cx,sy+82,cx+cw,sy+82,ctx.C.border,1,4))
                table.insert(o,D.Text(cx,sy+92,"Version hub : v2.3",ctx.C.dimmed,10,4))
            end},

            -- Logs
            {name="Logs", buildFn=function(ctx)
                local o,cx,cy=ctx.objs,ctx.cx,ctx.cy
                local D=ctx.Draw
                local maxL=math.floor(ctx.ch/13)
                local sy=cy
                local start=math.max(1,#logLines-maxL+1)
                for i=start,#logLines do
                    if logLines[i] then
                        table.insert(o,D.Text(cx,sy,logLines[i],ctx.C.muted,9,4))
                        sy=sy+13
                    end
                end
                if #logLines==0 then
                    table.insert(o,D.Text(cx,sy,"Aucun log.",ctx.C.dimmed,11,4))
                end
            end},
        }
    end

    -- ── INPUT LOOP ───────────────────────────────────────────
    -- Uses RunService.Heartbeat for smooth per-frame input
    task.spawn(function()
        local prevLMB    = false
        local prevToggle = false
        local dragActive = false
        local dragOX,dragOY = 0,0
        -- smoothing: track previous window position for lerp
        local targetWX,targetWY = WX,WY

        RunService.Heartbeat:Connect(function()
            if not uiReady then return end

            local mx,my = MX(),MY()
            local lmb   = LMB()

            -- ── toggle key (letter keys work on Matcha) ───
            local toggleDown = isToggleDown()
            if toggleDown and not prevToggle then
                uiVisible = not uiVisible
                Draw.SetVisible(baseObjs, uiVisible)
                -- hide/show picker too
                if not uiVisible and pickerActive then
                    Draw.SetVisible(pickerObjs,false)
                elseif uiVisible and pickerActive then
                    Draw.SetVisible(pickerObjs,true)
                end
                for _,p in ipairs(petalObjs) do
                    pcall(function() p.Visible=uiVisible end)
                end
            end
            prevToggle = toggleDown

            -- ── drag ─────────────────────────────────────
            if dragActive then
                if lmb then
                    targetWX = math.floor(mx-dragOX)
                    targetWY = math.floor(my-dragOY)
                    -- smooth lerp
                    local dx = math.floor((targetWX-WX)*0.45)
                    local dy = math.floor((targetWY-WY)*0.45)
                    if math.abs(dx)+math.abs(dy)>0 then
                        WX=WX+dx WY=WY+dy
                        Draw.Move(baseObjs,dx,dy)
                        Draw.Move(pickerObjs,dx,dy)
                        for _,z in ipairs(zones) do z.x=z.x+dx z.y=z.y+dy end
                    end
                else
                    dragActive=false
                end
            end

            -- ── click ────────────────────────────────────
            if lmb and not prevLMB and uiVisible then
                -- drag: title bar
                if mx>=WX and mx<=WX+WW and my>=WY and my<=WY+TH then
                    dragActive=true
                    dragOX=mx-WX dragOY=my-WY
                else
                    hitTest(mx,my)
                end
            end
            prevLMB=lmb
        end)
    end)

    -- ── GLOW ANIMATION ───────────────────────────────────────
    task.spawn(function()
        local t=0
        RunService.Heartbeat:Connect(function(dt)
            if not uiReady or not uiVisible then return end
            t=t+(dt*1.8)
            local pulse=0.5+0.5*math.sin(t)
            local thick=1+pulse*2.5
            local transp=0.25+0.7*(1-pulse)
            local col=AC()
            for _,gl in ipairs(glowLines) do pcall(function()
                gl.Thickness=thick gl.Transparency=transp gl.Color=col
            end) end
        end)
    end)

    -- ── PETALS ───────────────────────────────────────────────
    local PMAX=22
    local petalCount=0

    local function spawnPetal()
        if petalCount>=PMAX or not uiReady then return end
        petalCount=petalCount+1
        local sz=math.random(2,8)
        local p=Drawing.new("Circle")
        p.Position    =Vector2.new(WX+math.random(sz,WW-sz), WY+CONTY+sz)
        p.Radius      =sz
        p.Color       =petalColor()
        p.Filled      =true
        p.Transparency=math.random(20,60)/100
        p.ZIndex      =2
        p.Visible     =false
        table.insert(petalObjs,p)

        local tgt  =WY+WH-2
        local steps=math.random(70,200)
        local dy   =(tgt-(WY+CONTY))/steps
        local dx   =math.random(-18,18)/steps
        local dA   =(p.Transparency-0.97)/steps
        local phase=math.random()*math.pi*2
        local amp  =math.random(3,8)/steps

        task.spawn(function()
            for s=1,steps do
                task.wait(0.05)
                if not uiReady then break end
                pcall(function()
                    p.Visible=uiVisible
                    p.Color  =petalColor()
                    p.Position=Vector2.new(
                        p.Position.X+dx+math.sin(phase+s*0.15)*amp,
                        p.Position.Y+dy)
                    p.Transparency=math.min(1,p.Transparency+dA)
                end)
            end
            pcall(function() p:Remove() end)
            for i,a in ipairs(petalObjs) do if a==p then table.remove(petalObjs,i) break end end
            petalCount=petalCount-1
        end)
    end

    task.spawn(function()
        while true do
            task.wait(0.8+math.random()*1.8)
            if uiReady then
                pcall(spawnPetal)
                if math.random()<0.5 then
                    task.wait(0.15+math.random()*0.3)
                    pcall(spawnPetal)
                end
                if math.random()<0.25 then
                    task.wait(0.1)
                    pcall(spawnPetal)
                end
            end
        end
    end)

    -- ── NOTIFICATIONS ────────────────────────────────────────
    local NW  = math.max(240,math.floor(SW/5.8))
    local NH  = 60
    local NX  = 14
    local NY0 = 68
    local NGAP= 8
    local NDUR= 4.2

    local function animateNotifsUp()
        -- smooth reposition of remaining notifs
        for i,nd in ipairs(notifList) do
            local targetY = NY0+(i-1)*(NH+NGAP)
            if math.abs(targetY-nd.y)>1 then
                task.spawn(function()
                    local steps=10
                    for _=1,steps do
                        task.wait(0.02)
                        local diff=targetY-nd.y
                        local step=diff*0.35
                        for _,o in ipairs(nd.objs) do pcall(function()
                            if o.Position then
                                o.Position=Vector2.new(o.Position.X,o.Position.Y+step)
                            end
                        end) end
                        nd.y=nd.y+step
                    end
                    nd.y=targetY
                end)
            end
        end
    end

    local function notify(title,msg,col,icon)
        local nObjs={}
        local nd={objs=nObjs,y=NY0}
        table.insert(notifList,nd)
        -- position this notif at end of stack
        local idx=#notifList
        local nx=SW-NW-NX
        local ny=NY0+(idx-1)*(NH+NGAP)
        nd.y=ny

        local function a(o) table.insert(nObjs,o) end
        a(Draw.Rect   (nx,ny,NW,NH,   C.notifBg,   20))
        a(Draw.Outline(nx,ny,NW,NH,   col,1.2,     21))
        a(Draw.Rect   (nx+5,ny+6,3,NH-12,col,      21))
        a(Draw.Text   (nx+14,ny+NH/2-8,icon or "+",col,13,22))
        a(Draw.Text   (nx+30,ny+11,   title,C.white,12,22))
        a(Draw.Text   (nx+30,ny+28,   msg,  C.muted,10,22))
        Draw.SetVisible(nObjs,true)

        -- slide out after NDUR
        task.delay(NDUR,function()
            -- animate slide right
            local steps=16
            local startX=SW-NW-NX
            for i=1,steps do
                task.wait(0.02)
                local ox=startX+i*(NW+NX+40)/steps
                for _,o in ipairs(nObjs) do pcall(function()
                    if o.Position then o.Position=Vector2.new(ox,o.Position.Y) end
                end) end
            end
            -- destroy
            Draw.Destroy(nObjs)
            for i2,n2 in ipairs(notifList) do
                if n2==nd then table.remove(notifList,i2) break end
            end
            -- smooth reposition remaining
            animateNotifsUp()
        end)
    end

    -- ── PUBLIC API ───────────────────────────────────────────
    function UI.Init()
        task.spawn(function()
            makeDefaultTabs()
            buildWindow()
            Draw.SetVisible(baseObjs,true)
            uiReady=true uiVisible=true
            if UI._onReady then UI._onReady() end
        end)
    end

    local _q={}
    UI._onReady=function() UI._onReady=nil for _,f in ipairs(_q) do pcall(f) end _q={} end
    local function defer(fn) if uiReady then pcall(fn) else table.insert(_q,fn) end end

    function UI.LoadGameModule(gm)
        defer(function()
            dynName=gm.Name or dynName
            dynVer =gm.Version or dynVer
            if lblTitleGame then pcall(function() lblTitleGame.Text=dynName end) end
            if lblTitleVer  then pcall(function() lblTitleVer.Text=dynVer   end) end
            addLog("Module : "..dynName.." "..dynVer)
            local newTabs={}
            if gm.Tabs and #gm.Tabs>0 then
                for _,t in ipairs(gm.Tabs) do table.insert(newTabs,t) end
            else
                table.insert(newTabs,{name="Main",buildFn=function(ctx)
                    local o,cx,cy=ctx.objs,ctx.cx,ctx.cy
                    local D=ctx.Draw
                    table.insert(o,D.Text(cx,cy,   "STATUT",ctx.C.muted,9,4))
                    table.insert(o,D.Text(cx,cy+14,"Actif",ctx.ACH(),13,4))
                    table.insert(o,D.Text(cx,cy+38,dynName,ctx.C.white,13,4))
                    table.insert(o,D.Text(cx,cy+56,dynVer, ctx.ACH(),11,4))
                end})
            end
            for _,t in ipairs(currentTabs) do
                if t.name=="Settings" or t.name=="Credits" or t.name=="Logs" then
                    table.insert(newTabs,t)
                end
            end
            activeTab=1
            currentTabs=newTabs
            buildWindow()
            Draw.SetVisible(baseObjs,uiVisible)
        end)
    end

    function UI.ShowWelcome()
        defer(function() notify("Bienvenue","EXE.HUB est actif",AC(),"+") addLog("Hub demarre") end)
    end
    function UI.ShowGameDetected(n,ver)
        dynName=n or "—" dynVer=ver or "—"
        defer(function()
            if lblTitleGame then pcall(function() lblTitleGame.Text=dynName end) end
            if lblTitleVer  then pcall(function() lblTitleVer.Text=dynVer   end) end
            notify("Jeu detecte",n,C.green,">")
            addLog("Jeu : "..n.." "..(ver or ""))
        end)
    end
    function UI.ShowGameLoaded(n,ver)
        dynName=n or dynName dynVer=ver or dynVer
        defer(function()
            if lblTitleGame then pcall(function() lblTitleGame.Text=dynName end) end
            if lblTitleVer  then pcall(function() lblTitleVer.Text=dynVer   end) end
            notify("Module charge",n.." "..(ver or "").." pret",C.green,"v")
        end)
    end
    function UI.ShowNotSupported(id)
        defer(function()
            notify("Non supporte","PlaceId: "..tostring(id),C.yellow,"!")
            addLog("Non supporte : "..tostring(id))
        end)
    end
    function UI.ShowLoadError(n)
        defer(function()
            notify("Erreur",tostring(n),C.red,"x")
            addLog("Erreur : "..tostring(n))
        end)
    end
    function UI.Notify(title,msg,t)
        defer(function()
            local c,i=AC(),"+"
            if t=="success" then c=C.green i="v"
            elseif t=="warning" then c=C.yellow i="!"
            elseif t=="error"   then c=C.red i="x" end
            notify(title,msg,c,i)
        end)
    end
    function UI.Destroy()
        uiReady=false
        Draw.DestroyAll()
        table.clear(baseObjs) table.clear(glowLines)
        table.clear(notifList) table.clear(petalObjs) table.clear(zones)
    end
end

-- ============================================================
-- LOADER
-- ============================================================
local Loader={}
do
    function Loader.LoadGame(info,loadFn,ui,utils)
        if not info or not info.module then utils.Error("gameInfo invalide") return end
        utils.Log("Chargement : "..info.module)
        ui.ShowGameDetected(info.name,info.version)
        local gm=loadFn(info.module)
        if not gm then ui.ShowLoadError(info.name) return end
        gm.Name=gm.Name or info.name
        gm.Version=gm.Version or info.version
        if type(gm.Init)=="function" then
            local ok,err=pcall(function() gm.Init({UI=ui,Utils=utils}) end)
            if not ok then ui.ShowLoadError(info.name) utils.Error(tostring(err)) return end
        end
        ui.ShowGameLoaded(gm.Name,gm.Version)
        ui.LoadGameModule(gm)
    end
end

-- ============================================================
-- MODULE LOADER
-- ============================================================
_G.__EXE_HUB_MODULES={}
local function loadModule(path)
    local url=BASE..path..CACHE_BUST
    local raw
    pcall(function() raw=game:HttpGet(url,true) end)
    if not raw or raw=="" then Utils.Error("HTTP fail: "..path) return nil end
    local fn,e=loadstring(raw)
    if not fn then Utils.Error("Compile: "..path.." "..tostring(e)) return nil end
    local ok,r=pcall(fn)
    if not ok then Utils.Error("Exec: "..path.." "..tostring(r)) return nil end
    if r~=nil then return r end
    local key=path:match("([^/]+)%.lua$")
    if key and _G.__EXE_HUB_MODULES[key] then
        local m=_G.__EXE_HUB_MODULES[key]
        _G.__EXE_HUB_MODULES[key]=nil
        return m
    end
    Utils.Error("NIL after exec: "..path)
    return nil
end

-- ============================================================
-- LAUNCH
-- ============================================================
UI.Init()
UI.ShowWelcome()
local placeId=game.PlaceId
local gameInfo=Registry.GetGame(placeId)
if gameInfo then
    Loader.LoadGame(gameInfo,loadModule,UI,Utils)
else
    UI.ShowNotSupported(placeId)
end
