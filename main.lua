-- ╔══════════════════════════════════════════════════════════╗
-- ║  EXE.HUB  |  main.lua  —  Drawing API (Matcha)  v2.2   ║
-- ╚══════════════════════════════════════════════════════════╝
-- Input API Matcha :
--   mouse.X / mouse.Y          → position souris (LocalPlayer:GetMouse())
--   ismouse1pressed()          → LMB enfoncé (boolean)
--   UIS.InputBegan:Connect(fn) → fn({KeyCode=number})
--   KeyCode F1=290 F2=291 F3=292 Insert=277 RightShift=304

local BASE       = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"
local CACHE_BUST = "?t=" .. tostring(math.floor(tick()))

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
-- DRAW HELPERS
-- ============================================================
local Draw = {}
do
    local pool = {}

    local function reg(o) table.insert(pool,o) return o end

    function Draw.Rect(x,y,w,h,col,z)
        local o = reg(Drawing.new("Square"))
        o.Position=Vector2.new(x,y) o.Size=Vector2.new(w,h)
        o.Color=col o.Filled=true o.Transparency=1
        o.Thickness=1 o.ZIndex=z or 1 o.Visible=false
        return o
    end
    function Draw.Outline(x,y,w,h,col,thick,z)
        local o = reg(Drawing.new("Square"))
        o.Position=Vector2.new(x,y) o.Size=Vector2.new(w,h)
        o.Color=col o.Filled=false o.Thickness=thick or 1.5
        o.Transparency=1 o.ZIndex=z or 2 o.Visible=false
        return o
    end
    function Draw.Text(x,y,str,col,sz,z)
        local o = reg(Drawing.new("Text"))
        o.Position=Vector2.new(x,y) o.Text=str o.Color=col
        o.Size=sz or 13 o.ZIndex=z or 3 o.Outline=false
        o.Center=false o.Visible=false
        return o
    end
    function Draw.Line(x1,y1,x2,y2,col,thick,z)
        local o = reg(Drawing.new("Line"))
        o.From=Vector2.new(x1,y1) o.To=Vector2.new(x2,y2)
        o.Color=col o.Thickness=thick or 1 o.Transparency=1
        o.ZIndex=z or 2 o.Visible=false
        return o
    end
    function Draw.SetVisible(group,v)
        for _,o in ipairs(group) do pcall(function() o.Visible=v end) end
    end
    function Draw.Destroy(group)
        for _,o in ipairs(group) do
            pcall(function() o:Remove() end)
            for i,p in ipairs(pool) do
                if p==o then table.remove(pool,i) break end
            end
        end
        table.clear(group)
    end
    function Draw.Move(group,dx,dy)
        for _,o in ipairs(group) do pcall(function()
            if o.Position then
                o.Position = Vector2.new(o.Position.X+dx, o.Position.Y+dy)
            end
            if o.From then
                o.From = Vector2.new(o.From.X+dx, o.From.Y+dy)
                o.To   = Vector2.new(o.To.X+dx,   o.To.Y+dy)
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
    -- ── screen size ─────────────────────────────────────────
    local SW,SH = 1920,1080
    pcall(function()
        SW = workspace.CurrentCamera.ViewportSize.X
        SH = workspace.CurrentCamera.ViewportSize.Y
    end)

    -- ── mouse (seul API qui marche sur Matcha) ───────────────
    local mouse = Players.LocalPlayer:GetMouse()
    -- ismouse1pressed() est une global Matcha
    local function mouseX() return mouse.X end
    local function mouseY() return mouse.Y end
    local function lmbDown() local ok,r=pcall(ismouse1pressed) return ok and r or false end

    -- KeyCode numbers sur Matcha (entiers)
    -- inp.KeyCode dans InputBegan = nombre
    local KC = { F1=290, F2=291, F3=292, Insert=277, RightShift=304 }
    local toggleKeyCode = KC.F1   -- nombre, pas Enum

    -- ── thèmes ──────────────────────────────────────────────
    local THEMES = {
        {name="Sakura", accent=Color3.fromRGB(220,80,140),  hi=Color3.fromRGB(255,130,180)},
        {name="Blue",   accent=Color3.fromRGB(60,130,255),  hi=Color3.fromRGB(120,180,255)},
        {name="Green",  accent=Color3.fromRGB(60,210,130),  hi=Color3.fromRGB(120,240,170)},
        {name="Red",    accent=Color3.fromRGB(230,60,60),   hi=Color3.fromRGB(255,110,110)},
    }
    local themeIdx = 1
    local function AC()  return THEMES[themeIdx].accent end
    local function ACH() return THEMES[themeIdx].hi end

    -- ── palette ─────────────────────────────────────────────
    local C = {
        bg      = Color3.fromRGB(13,12,20),
        panel   = Color3.fromRGB(18,17,28),
        titleBg = Color3.fromRGB(10,8,18),
        tabBg   = Color3.fromRGB(20,18,30),
        tabSel  = Color3.fromRGB(32,26,46),
        border  = Color3.fromRGB(42,30,58),
        white   = Color3.fromRGB(235,235,248),
        muted   = Color3.fromRGB(120,95,138),
        dimmed  = Color3.fromRGB(80,65,100),
        green   = Color3.fromRGB(90,210,130),
        yellow  = Color3.fromRGB(250,195,75),
        red     = Color3.fromRGB(250,85,85),
        notifBg = Color3.fromRGB(14,11,22),
        petal   = Color3.fromRGB(255,175,205),
    }

    -- ── dimensions ──────────────────────────────────────────
    local WW      = math.max(260, math.floor(SW/5.5))
    local WH      = math.max(420, math.floor(SH/2.8))
    local WX      = math.floor(SW/2 - WW/2)
    local WY      = math.floor(SH/2 - WH/2)
    local TITLE_H = 36
    local TAB_H   = 28
    local CONT_Y  = TITLE_H + TAB_H
    local PAD     = 14

    -- ── state ───────────────────────────────────────────────
    local uiReady   = false
    local uiVisible = true
    local activeTab = 1
    local currentTabs = {}

    -- drawing groups
    local baseObjs   = {}
    local glowLines  = {}
    local tabBtnObjs = {}
    local tabObjs    = {}
    local notifList  = {}
    local petalObjs  = {}

    -- click zones  {x,y,w,h,fn}
    local zones = {}
    local function addZone(x,y,w,h,fn)
        table.insert(zones,{x=x,y=y,w=w,h=h,fn=fn})
    end
    local function clearZones() table.clear(zones) end
    local function hitTest(mx,my)
        for _,z in ipairs(zones) do
            if mx>=z.x and mx<=z.x+z.w and my>=z.y and my<=z.y+z.h then
                pcall(z.fn)
            end
        end
    end

    -- dynamic title labels
    local lblTitleGame, lblTitleVer
    local dynName = "—"
    local dynVer  = "—"
    local logLines = {}

    local function refreshTitle()
        if lblTitleGame then pcall(function() lblTitleGame.Text = dynName end) end
        if lblTitleVer  then pcall(function() lblTitleVer.Text  = dynVer  end) end
    end
    local function addLog(msg)
        local ts = string.format("%02d:%02d", math.floor(tick()/3600)%24, math.floor(tick()/60)%60)
        table.insert(logLines, ts.." "..tostring(msg))
        if #logLines>60 then table.remove(logLines,1) end
    end

    -- ── tab switch ──────────────────────────────────────────
    local function switchTab(idx)
        if idx==activeTab then return end
        -- hide old
        if tabObjs[activeTab] then Draw.SetVisible(tabObjs[activeTab],false) end
        local old = tabBtnObjs[activeTab]
        if old then old.bg.Color=C.tabBg old.lbl.Color=C.muted old.ul.Visible=false end
        activeTab = idx
        -- build if needed
        if not tabObjs[activeTab] then
            tabObjs[activeTab] = {}
            local tab = currentTabs[activeTab]
            if tab and type(tab.buildFn)=="function" then
                local cx = WX+PAD
                local cy = WY+CONT_Y+PAD
                local cw = WW-PAD*2
                pcall(function()
                    tab.buildFn({
                        cx=cx,cy=cy,cw=cw,
                        C=C,AC=AC,ACH=ACH,PAD=PAD,
                        Draw=Draw,objs=tabObjs[activeTab],
                        addZone=addZone,
                        WX=function()return WX end,
                        WY=function()return WY end,
                        WW=WW,WH=WH,
                    })
                end)
            end
            for _,o in ipairs(tabObjs[activeTab]) do table.insert(baseObjs,o) end
        end
        Draw.SetVisible(tabObjs[activeTab], uiVisible)
        local nw = tabBtnObjs[activeTab]
        if nw then nw.bg.Color=C.tabSel nw.lbl.Color=ACH() nw.ul.Color=AC() nw.ul.Visible=uiVisible end
    end

    -- ── rebuild window ──────────────────────────────────────
    local function buildWindow()
        -- destroy old
        for _,o in ipairs(baseObjs) do pcall(function() o:Remove() end) end
        table.clear(baseObjs)
        table.clear(glowLines)
        table.clear(tabBtnObjs)
        for _,t in pairs(tabObjs) do
            for _,o in ipairs(t) do pcall(function() o:Remove() end) end
        end
        table.clear(tabObjs)
        clearZones()

        local x,y = WX,WY

        -- background
        table.insert(baseObjs, Draw.Rect(x,y,WW,WH,C.bg,1))

        -- title bar
        table.insert(baseObjs, Draw.Rect(x,y,WW,TITLE_H,C.titleBg,2))
        table.insert(baseObjs, Draw.Text(x+PAD, y+11, "EXE.HUB", ACH(), 14, 5))
        table.insert(baseObjs, Draw.Line(x+86,y+8,x+86,y+TITLE_H-8, C.border,1,4))
        lblTitleGame = Draw.Text(x+94, y+12, dynName, C.muted, 11, 5)
        table.insert(baseObjs, lblTitleGame)
        lblTitleVer = Draw.Text(x+WW-58, y+13, dynVer, C.dimmed, 10, 5)
        table.insert(baseObjs, lblTitleVer)
        table.insert(baseObjs, Draw.Line(x,y+TITLE_H,x+WW,y+TITLE_H,C.border,1,3))

        -- tabs
        local nTabs = #currentTabs
        local tabW  = math.floor(WW/math.max(nTabs,1))
        local tabY  = y+TITLE_H
        for i,tab in ipairs(currentTabs) do
            local tx = x+(i-1)*tabW
            local isSel = (i==activeTab)
            local tbg = Draw.Rect(tx,tabY,tabW,TAB_H, isSel and C.tabSel or C.tabBg, 2)
            table.insert(baseObjs,tbg)
            if i>1 then
                table.insert(baseObjs, Draw.Line(tx,tabY+4,tx,tabY+TAB_H-4,C.border,1,3))
            end
            local lx = tx + math.floor(tabW/2) - math.floor(#tab.name*3)
            local tlbl = Draw.Text(lx, tabY+9, tab.name, isSel and ACH() or C.muted, 10, 4)
            table.insert(baseObjs,tlbl)
            local tul = Draw.Line(tx+3,tabY+TAB_H-2,tx+tabW-3,tabY+TAB_H-2, AC(),1.5,4)
            tul.Visible = isSel
            table.insert(baseObjs,tul)
            tabBtnObjs[i] = {bg=tbg, lbl=tlbl, ul=tul}
            local ci=i
            addZone(tx,tabY,tabW,TAB_H,function() switchTab(ci) end)
        end

        -- content area
        table.insert(baseObjs, Draw.Line(x,y+CONT_Y,x+WW,y+CONT_Y,C.border,1,3))
        table.insert(baseObjs, Draw.Rect(x,y+CONT_Y,WW,WH-CONT_Y,C.panel,1))

        -- outer border
        table.insert(baseObjs, Draw.Outline(x,y,WW,WH,C.border,1,3))

        -- glow lines (4 edges)
        local function gl(x1,y1,x2,y2)
            local l=Draw.Line(x1,y1,x2,y2,AC(),1.5,4)
            l.Transparency=0.7
            table.insert(baseObjs,l)
            table.insert(glowLines,l)
        end
        gl(x,y,     x+WW,y)
        gl(x+WW,y,  x+WW,y+WH)
        gl(x+WW,y+WH,x,  y+WH)
        gl(x,y+WH,  x,   y)

        -- build active tab content
        tabObjs[activeTab] = {}
        local tab = currentTabs[activeTab]
        if tab and type(tab.buildFn)=="function" then
            local cx=WX+PAD cy=WY+CONT_Y+PAD cw=WW-PAD*2
            pcall(function()
                tab.buildFn({
                    cx=cx,cy=cy,cw=cw,
                    C=C,AC=AC,ACH=ACH,PAD=PAD,
                    Draw=Draw,objs=tabObjs[activeTab],
                    addZone=addZone,
                    WX=function()return WX end,
                    WY=function()return WY end,
                    WW=WW,WH=WH,
                })
            end)
        end
        for _,o in ipairs(tabObjs[activeTab]) do table.insert(baseObjs,o) end
    end

    -- ── default tabs ────────────────────────────────────────
    local function makeDefaultTabs()
        currentTabs = {
            {
                name="Main",
                buildFn=function(ctx)
                    local o,cx,cy = ctx.objs,ctx.cx,ctx.cy
                    table.insert(o, Draw.Text(cx,cy,   "STATUT",       ctx.C.muted, 9,4))
                    table.insert(o, Draw.Text(cx,cy+14,"En attente...",ctx.ACH(),  12,4))
                    table.insert(o, Draw.Text(cx,cy+38,"JEU",          ctx.C.muted, 9,4))
                    table.insert(o, Draw.Text(cx,cy+52, dynName,       ctx.C.white,12,4))
                    table.insert(o, Draw.Text(cx,cy+76,"VERSION",      ctx.C.muted, 9,4))
                    table.insert(o, Draw.Text(cx,cy+90, dynVer,        ctx.ACH(),  10,4))
                end
            },
            {
                name="Settings",
                buildFn=function(ctx)
                    local o,cx,cy,cw=ctx.objs,ctx.cx,ctx.cy,ctx.cw
                    local sy=cy

                    -- theme
                    table.insert(o, Draw.Text(cx,sy,"THEME",ctx.C.muted,9,4))
                    sy=sy+16
                    local bw=math.floor((cw-3*4)/4)
                    for ti,th in ipairs(THEMES) do
                        local bx=cx+(ti-1)*(bw+4)
                        local isSel=(ti==themeIdx)
                        local btn=Draw.Rect(bx,sy,bw,22,th.accent,4)
                        btn.Transparency = isSel and 1 or 0.55
                        table.insert(o,btn)
                        if isSel then
                            table.insert(o,Draw.Outline(bx,sy,bw,22,ctx.C.white,1.5,5))
                        end
                        local lx=bx+math.floor(bw/2)-math.floor(#th.name*3)
                        table.insert(o,Draw.Text(lx,sy+6,th.name,ctx.C.white,9,5))
                        local tii=ti
                        ctx.addZone(bx,sy,bw,22,function()
                            themeIdx=tii
                            for _,gl in ipairs(glowLines) do
                                pcall(function() gl.Color=AC() end)
                            end
                            if tabBtnObjs[activeTab] then
                                tabBtnObjs[activeTab].lbl.Color=ACH()
                                tabBtnObjs[activeTab].ul.Color=AC()
                            end
                        end)
                    end
                    sy=sy+34

                    -- toggle key
                    table.insert(o,Draw.Text(cx,sy,"TOUCHE TOGGLE",ctx.C.muted,9,4))
                    sy=sy+16
                    local keys={{name="F1",code=KC.F1},{name="F2",code=KC.F2},
                                 {name="F3",code=KC.F3},{name="Ins",code=KC.Insert},
                                 {name="RS",code=KC.RightShift}}
                    local kw=math.floor((cw-4*4)/5)
                    for ki,k in ipairs(keys) do
                        local bx=cx+(ki-1)*(kw+4)
                        local isSel=(k.code==toggleKeyCode)
                        local kbg=Draw.Rect(bx,sy,kw,22,isSel and ctx.C.tabSel or ctx.C.tabBg,4)
                        table.insert(o,kbg)
                        if isSel then
                            table.insert(o,Draw.Outline(bx,sy,kw,22,ctx.AC(),1.5,5))
                        end
                        local lx=bx+math.floor(kw/2)-math.floor(#k.name*3)
                        table.insert(o,Draw.Text(lx,sy+6,k.name,isSel and ctx.ACH() or ctx.C.muted,9,5))
                        local kci=ki
                        ctx.addZone(bx,sy,kw,22,function()
                            toggleKeyCode=keys[kci].code
                            -- rebuild settings tab to refresh selection
                            if tabObjs[activeTab] then
                                Draw.SetVisible(tabObjs[activeTab],false)
                                local t2=tabObjs[activeTab]
                                for _,o2 in ipairs(t2) do
                                    pcall(function() o2:Remove() end)
                                    for i2,a in ipairs(baseObjs) do
                                        if a==o2 then table.remove(baseObjs,i2) break end
                                    end
                                end
                                tabObjs[activeTab]=nil
                            end
                            -- clear zones & rebuild window
                            buildWindow()
                            Draw.SetVisible(baseObjs,uiVisible)
                        end)
                    end
                    sy=sy+34
                    table.insert(o,Draw.Text(cx,sy,"Appuie sur la touche pour masquer/afficher.",ctx.C.muted,9,4))
                end
            },
            {
                name="Credits",
                buildFn=function(ctx)
                    local o,cx,cy=ctx.objs,ctx.cx,ctx.cy
                    local sy=cy
                    table.insert(o,Draw.Text(cx,sy,    "EXE.HUB",                ctx.ACH(),16,5))
                    table.insert(o,Draw.Text(cx,sy+22, "Script hub pour Roblox", ctx.C.muted,10,4))
                    table.insert(o,Draw.Text(cx,sy+42, "Dev : mattheube",         ctx.C.white,11,4))
                    table.insert(o,Draw.Text(cx,sy+58, "github.com/mattheube/EXE.HUB",ctx.C.muted,9,4))
                    table.insert(o,Draw.Line(cx,sy+78,cx+ctx.cw,sy+78,ctx.C.border,1,4))
                    table.insert(o,Draw.Text(cx,sy+88,"Version hub : v2.2",ctx.C.dimmed,9,4))
                end
            },
            {
                name="Logs",
                buildFn=function(ctx)
                    local o,cx,cy=ctx.objs,ctx.cx,ctx.cy
                    local maxL=math.floor((WH-CONT_Y-PAD*2)/14)
                    local sy=cy
                    local start=math.max(1,#logLines-maxL+1)
                    for i=start,#logLines do
                        if logLines[i] then
                            table.insert(o,Draw.Text(cx,sy,logLines[i],ctx.C.muted,9,4))
                            sy=sy+14
                        end
                    end
                    if #logLines==0 then
                        table.insert(o,Draw.Text(cx,sy,"Aucun log.",ctx.C.dimmed,10,4))
                    end
                end
            },
        }
    end

    -- ── INPUT LOOP ──────────────────────────────────────────
    -- Uses: mouse.X/Y, ismouse1pressed(), UIS.InputBegan
    task.spawn(function()
        local UIS = UserInputService
        local prevLMB    = false
        local dragActive = false
        local dragOX,dragOY = 0,0

        -- F1 toggle via InputBegan (event-driven, not polling)
        pcall(function()
            UIS.InputBegan:Connect(function(inp)
                if not uiReady then return end
                local kc = inp and inp.KeyCode
                if type(kc)~="number" then return end
                if kc == toggleKeyCode then
                    uiVisible = not uiVisible
                    Draw.SetVisible(baseObjs, uiVisible)
                end
            end)
        end)

        while true do
            task.wait(0.033) -- ~30fps
            if not uiReady then continue end

            local mx = mouseX()
            local my = mouseY()
            local lmb = lmbDown()

            -- ── drag ──────────────────────────────────────
            if dragActive then
                if lmb then
                    local nx = math.floor(mx-dragOX)
                    local ny = math.floor(my-dragOY)
                    local dx,dy = nx-WX, ny-WY
                    if math.abs(dx)+math.abs(dy) > 0 then
                        WX,WY = nx,ny
                        Draw.Move(baseObjs,dx,dy)
                        for _,z in ipairs(zones) do z.x=z.x+dx z.y=z.y+dy end
                    end
                else
                    dragActive = false
                end
            end

            -- ── click ─────────────────────────────────────
            if lmb and not prevLMB then
                if uiVisible then
                    -- start drag if in title bar
                    if mx>=WX and mx<=WX+WW and my>=WY and my<=WY+TITLE_H then
                        dragActive = true
                        dragOX = mx-WX
                        dragOY = my-WY
                    end
                    -- hit test zones
                    hitTest(mx,my)
                end
            end
            prevLMB = lmb
        end
    end)

    -- ── GLOW ANIMATION ──────────────────────────────────────
    task.spawn(function()
        local t=0
        while true do
            task.wait(0.05)
            if not uiReady or not uiVisible then continue end
            t=t+0.08
            local pulse=0.5+0.5*math.sin(t)
            for _,gl in ipairs(glowLines) do pcall(function()
                gl.Thickness    = 1+pulse*2.5
                gl.Transparency = 0.3+0.65*(1-pulse)
                gl.Color        = AC()
            end) end
        end
    end)

    -- ── PETALS ──────────────────────────────────────────────
    -- More petals, more variation, faster spawn
    local PMAX = 18
    local petalCount = 0
    local function spawnPetal()
        if petalCount>=PMAX then return end
        petalCount=petalCount+1
        local sz = math.random(2,7)               -- more size variation
        local px = WX + math.random(sz, WW-sz)
        local p  = Drawing.new("Circle")
        p.Position     = Vector2.new(px, WY+CONT_Y+2)
        p.Radius       = sz
        p.Color        = C.petal
        p.Filled       = true
        p.Transparency = math.random(25,65)/100
        p.ZIndex       = 2
        p.Visible      = false
        table.insert(petalObjs,p)

        local tgt   = WY+WH-2
        local steps = math.random(60,180)
        local dy    = (tgt-(WY+CONT_Y)) / steps
        local dx    = math.random(-20,20) / steps
        local dA    = (p.Transparency - 0.96) / steps
        local dRot  = math.random(-3,3)           -- wobble via X drift change

        task.spawn(function()
            local wobble = 0
            for i=1,steps do
                task.wait(0.05)
                if not uiReady then break end
                wobble = wobble + dRot * 0.01
                pcall(function()
                    p.Visible      = uiVisible
                    p.Position     = Vector2.new(
                        p.Position.X + dx + math.sin(wobble)*0.4,
                        p.Position.Y + dy)
                    p.Transparency = math.min(1, p.Transparency+dA)
                end)
            end
            pcall(function() p:Remove() end)
            for i,a in ipairs(petalObjs) do if a==p then table.remove(petalObjs,i) break end end
            petalCount=petalCount-1
        end)
    end

    task.spawn(function()
        while true do
            task.wait(1.5 + math.random()*2)   -- spawn toutes les 1.5–3.5s
            if uiReady then
                pcall(spawnPetal)
                -- parfois spawner 2 d'un coup
                if math.random()<0.35 then
                    task.wait(0.2+math.random()*0.4)
                    pcall(spawnPetal)
                end
            end
        end
    end)

    -- ── NOTIFICATIONS ───────────────────────────────────────
    local NW  = math.floor(SW/5.5)
    local NH  = 58
    local NX  = 12
    local NY0 = 70
    local NGAP= 8
    local NDUR= 4.0

    local function reposNotifs()
        for i,nd in ipairs(notifList) do
            local ty=NY0+(i-1)*(NH+NGAP)
            local diff=ty-nd.y
            if math.abs(diff)>0 then
                for _,o in ipairs(nd.objs) do pcall(function()
                    if o.Position then o.Position=Vector2.new(o.Position.X,o.Position.Y+diff) end
                end) end
                nd.y=ty
            end
        end
    end

    local function notify(title,msg,col,icon)
        local nObjs={}
        local nd={objs=nObjs,y=NY0}
        table.insert(notifList,nd)
        reposNotifs()
        local idx=#notifList
        local nx=SW-NW-NX
        local ny=NY0+(idx-1)*(NH+NGAP)
        nd.y=ny
        local function a(o) table.insert(nObjs,o) end
        a(Draw.Rect   (nx,ny,NW,NH,C.notifBg,20))
        a(Draw.Outline(nx,ny,NW,NH,col,1.2,21))
        a(Draw.Rect   (nx+5,ny+6,3,NH-12,col,21))
        a(Draw.Text   (nx+14,ny+NH/2-8,icon or "+",col,13,22))
        a(Draw.Text   (nx+30,ny+10,title,C.white,12,22))
        a(Draw.Text   (nx+30,ny+27,msg,C.muted,10,22))
        Draw.SetVisible(nObjs,true)
        task.delay(NDUR,function()
            local steps,sx=14,nx
            for i=1,steps do
                task.wait(0.022)
                local ox=sx+i*(NW+NX+30)/steps
                for _,o in ipairs(nObjs) do pcall(function()
                    if o.Position then o.Position=Vector2.new(ox,o.Position.Y) end
                end) end
            end
            Draw.Destroy(nObjs)
            for i2,n2 in ipairs(notifList) do if n2==nd then table.remove(notifList,i2) break end end
            reposNotifs()
        end)
    end

    -- ── PUBLIC API ──────────────────────────────────────────
    function UI.Init()
        task.spawn(function()
            makeDefaultTabs()
            buildWindow()
            Draw.SetVisible(baseObjs,true)
            uiReady   = true
            uiVisible = true
            if UI._onReady then UI._onReady() end
        end)
    end

    local _q={}
    UI._onReady=function() UI._onReady=nil for _,f in ipairs(_q) do pcall(f) end _q={} end
    local function defer(fn) if uiReady then pcall(fn) else table.insert(_q,fn) end end

    function UI.LoadGameModule(gm)
        defer(function()
            dynName = gm.Name    or dynName
            dynVer  = gm.Version or dynVer
            refreshTitle()
            addLog("Module : "..dynName.." "..dynVer)
            local newTabs={}
            if gm.Tabs and #gm.Tabs>0 then
                for _,t in ipairs(gm.Tabs) do table.insert(newTabs,t) end
            else
                table.insert(newTabs,{name="Main",buildFn=function(ctx)
                    local o,cx,cy=ctx.objs,ctx.cx,ctx.cy
                    table.insert(o,Draw.Text(cx,cy,   "STATUT", ctx.C.muted,9,4))
                    table.insert(o,Draw.Text(cx,cy+14,"Actif",  ctx.ACH(),12,4))
                    table.insert(o,Draw.Text(cx,cy+38, dynName, ctx.C.white,12,4))
                    table.insert(o,Draw.Text(cx,cy+56, dynVer,  ctx.ACH(),10,4))
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
        defer(function()
            notify("Bienvenue","EXE.HUB est actif",AC(),"+")
            addLog("Hub demarre")
        end)
    end
    function UI.ShowGameDetected(n,ver)
        dynName=n or "—" dynVer=ver or "—"
        defer(function()
            refreshTitle()
            notify("Jeu detecte",n,C.green,">")
            addLog("Jeu : "..n.." "..(ver or ""))
        end)
    end
    function UI.ShowGameLoaded(n,ver)
        dynName=n or dynName dynVer=ver or dynVer
        defer(function()
            refreshTitle()
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
            elseif t=="error"   then c=C.red    i="x" end
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
local Loader = {}
do
    function Loader.LoadGame(gameInfo, loadModuleFn, ui, utils)
        if not gameInfo or not gameInfo.module then utils.Error("gameInfo invalide") return end
        utils.Log("Chargement : "..gameInfo.module)
        ui.ShowGameDetected(gameInfo.name, gameInfo.version)
        local gm = loadModuleFn(gameInfo.module)
        if not gm then ui.ShowLoadError(gameInfo.name) return end
        gm.Name    = gm.Name    or gameInfo.name
        gm.Version = gm.Version or gameInfo.version
        if type(gm.Init)=="function" then
            local ok,err = pcall(function() gm.Init({UI=ui,Utils=utils}) end)
            if not ok then ui.ShowLoadError(gameInfo.name) utils.Error(tostring(err)) return end
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
    local url=BASE..path..CACHE_BUST
    local raw
    pcall(function() raw=game:HttpGet(url,true) end)
    if not raw or raw=="" then Utils.Error("HTTP fail: "..path) return nil end
    local fn,e=loadstring(raw)
    if not fn then Utils.Error("Compile fail: "..path.." | "..tostring(e)) return nil end
    local ok,result=pcall(fn)
    if not ok then Utils.Error("Exec fail: "..path.." | "..tostring(result)) return nil end
    if result~=nil then return result end
    local key=path:match("([^/]+)%.lua$")
    if key and _G.__EXE_HUB_MODULES[key] then
        local mod=_G.__EXE_HUB_MODULES[key]
        _G.__EXE_HUB_MODULES[key]=nil
        return mod
    end
    Utils.Error("NIL after exec: "..path)
    return nil
end

-- ============================================================
-- LAUNCH
-- ============================================================
UI.Init()
UI.ShowWelcome()

local placeId = game.PlaceId
local gameInfo = Registry.GetGame(placeId)
if gameInfo then
    Loader.LoadGame(gameInfo, loadModule, UI, Utils)
else
    UI.ShowNotSupported(placeId)
end
