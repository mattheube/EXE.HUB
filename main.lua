-- ╔══════════════════════════════════════════════════════════════╗
-- ║   EXE.HUB  v8.0  —  main.lua  (Matcha / Drawing API only)  ║
-- ║   Shared framework only — NO game-specific content here     ║
-- ╚══════════════════════════════════════════════════════════════╝
-- Engine  : task.spawn + task.wait  (RunService dead on Matcha)
-- Input   : ismouse1pressed() for LMB | RealUIS:IsKeyDown() keys
-- Toggle  : default P (rebindable — letters/numbers/F-keys/etc.)
-- Creator : MATTHEUBE  |  github.com/mattheube/EXE.HUB

local BASE    = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"
local RealUIS = game:GetService("UserInputService")
local function log(m) print("[EXE] "..tostring(m)) end
local function err(m) warn("[EXE] ERR: "..tostring(m)) end

-- ── Game registry ─────────────────────────────────────────────
local GAMES = {
    [14890802310] = {
        name    = "Bizarre Lineage",
        version = "V1",
        module  = "games/bizarre_lineage.lua",
    },
}

-- ══════════════════════════════════════════════════════════════
-- DRAW MODULE
-- ══════════════════════════════════════════════════════════════
local Draw = {}
do
    local _pool = {}
    local function reg(o) _pool[#_pool+1]=o; return o end

    function Draw.Rect(x,y,w,h,col,z)
        local o=reg(Drawing.new("Square"))
        o.Position=Vector2.new(x,y); o.Size=Vector2.new(w,h)
        o.Color=col; o.Filled=true; o.Transparency=1; o.Thickness=1
        o.ZIndex=z or 1; o.Visible=false; return o
    end
    function Draw.Outline(x,y,w,h,col,thick,z)
        local o=reg(Drawing.new("Square"))
        o.Position=Vector2.new(x,y); o.Size=Vector2.new(w,h)
        o.Color=col; o.Filled=false; o.Thickness=thick or 1
        o.Transparency=1; o.ZIndex=z or 2; o.Visible=false; return o
    end
    function Draw.Text(x,y,str,col,sz,z)
        local o=reg(Drawing.new("Text"))
        o.Position=Vector2.new(x,y); o.Text=tostring(str)
        o.Color=col; o.Size=sz or 12; o.ZIndex=z or 3
        o.Outline=true; o.Center=false; o.Visible=false; return o
    end
    function Draw.Line(x1,y1,x2,y2,col,thick,z)
        local o=reg(Drawing.new("Line"))
        o.From=Vector2.new(x1,y1); o.To=Vector2.new(x2,y2)
        o.Color=col; o.Thickness=thick or 1
        o.Transparency=1; o.ZIndex=z or 2; o.Visible=false; return o
    end
    function Draw.Circle(x,y,r,col,filled,z)
        local o=reg(Drawing.new("Circle"))
        o.Position=Vector2.new(x,y); o.Radius=r
        o.Color=col; o.Filled=(filled~=false)
        o.Transparency=0.4; o.ZIndex=z or 1; o.Visible=false; return o
    end
    function Draw.SetVisible(list,v)
        for _,o in ipairs(list) do pcall(function() o.Visible=v end) end
    end
    function Draw.Destroy(list)
        for _,o in ipairs(list) do
            pcall(function() o:Remove() end)
            for i,p in ipairs(_pool) do
                if p==o then table.remove(_pool,i); break end
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
        for _,o in ipairs(_pool) do pcall(function() o:Remove() end) end
        table.clear(_pool)
    end
end

-- ══════════════════════════════════════════════════════════════
-- UI ENGINE  (shared framework)
-- ══════════════════════════════════════════════════════════════
local UI = {}
do
    -- ── Screen ──────────────────────────────────────────────
    local SW,SH = 1920,1080
    pcall(function()
        SW=workspace.CurrentCamera.ViewportSize.X
        SH=workspace.CurrentCamera.ViewportSize.Y
    end)
    local mouse = Players.LocalPlayer:GetMouse()
    local function MX() return mouse.X end
    local function MY() return mouse.Y end
    local function LMB() return (ismouse1pressed()) end

    -- ── Keybind — full keyboard detection ───────────────────
    local toggleKC    = Enum.KeyCode.P
    local toggleLabel = "P"
    local bindMode    = false
    local bindLblRef  = nil

    local ALL_KEYS = {
        {Enum.KeyCode.A,"A"},{Enum.KeyCode.B,"B"},{Enum.KeyCode.C,"C"},
        {Enum.KeyCode.D,"D"},{Enum.KeyCode.E,"E"},{Enum.KeyCode.F,"F"},
        {Enum.KeyCode.G,"G"},{Enum.KeyCode.H,"H"},{Enum.KeyCode.I,"I"},
        {Enum.KeyCode.J,"J"},{Enum.KeyCode.K,"K"},{Enum.KeyCode.L,"L"},
        {Enum.KeyCode.M,"M"},{Enum.KeyCode.N,"N"},{Enum.KeyCode.O,"O"},
        {Enum.KeyCode.P,"P"},{Enum.KeyCode.Q,"Q"},{Enum.KeyCode.R,"R"},
        {Enum.KeyCode.S,"S"},{Enum.KeyCode.T,"T"},{Enum.KeyCode.U,"U"},
        {Enum.KeyCode.V,"V"},{Enum.KeyCode.W,"W"},{Enum.KeyCode.X,"X"},
        {Enum.KeyCode.Y,"Y"},{Enum.KeyCode.Z,"Z"},
        {Enum.KeyCode.Zero,"0"},{Enum.KeyCode.One,"1"},{Enum.KeyCode.Two,"2"},
        {Enum.KeyCode.Three,"3"},{Enum.KeyCode.Four,"4"},{Enum.KeyCode.Five,"5"},
        {Enum.KeyCode.Six,"6"},{Enum.KeyCode.Seven,"7"},{Enum.KeyCode.Eight,"8"},
        {Enum.KeyCode.Nine,"9"},
        {Enum.KeyCode.F1,"F1"},{Enum.KeyCode.F2,"F2"},{Enum.KeyCode.F3,"F3"},
        {Enum.KeyCode.F4,"F4"},{Enum.KeyCode.F5,"F5"},{Enum.KeyCode.F6,"F6"},
        {Enum.KeyCode.F7,"F7"},{Enum.KeyCode.F8,"F8"},{Enum.KeyCode.F9,"F9"},
        {Enum.KeyCode.F10,"F10"},{Enum.KeyCode.F11,"F11"},{Enum.KeyCode.F12,"F12"},
        {Enum.KeyCode.Tab,"Tab"},{Enum.KeyCode.Insert,"Insert"},
        {Enum.KeyCode.Home,"Home"},{Enum.KeyCode.End,"End"},
        {Enum.KeyCode.PageUp,"PgUp"},{Enum.KeyCode.PageDown,"PgDn"},
        {Enum.KeyCode.LeftShift,"LShift"},{Enum.KeyCode.RightShift,"RShift"},
        {Enum.KeyCode.LeftControl,"LCtrl"},{Enum.KeyCode.RightControl,"RCtrl"},
        {Enum.KeyCode.LeftAlt,"LAlt"},{Enum.KeyCode.RightAlt,"RAlt"},
    }
    local function isToggleDown()
        if bindMode then return false end
        local ok,r=pcall(function() return RealUIS:IsKeyDown(toggleKC) end)
        return ok and r or false
    end
    local function scanBind()
        for _,kp in ipairs(ALL_KEYS) do
            local ok,r=pcall(function() return RealUIS:IsKeyDown(kp[1]) end)
            if ok and r then
                toggleKC=kp[1]; toggleLabel=kp[2]; bindMode=false
                if bindLblRef then pcall(function()
                    bindLblRef.Text ="Toggle Key : [ "..toggleLabel.." ]"
                    bindLblRef.Color=Color3.fromRGB(180,140,220)
                end) end
                return
            end
        end
    end

    -- ── Themes (no color picker) ─────────────────────────────
    local THEMES = {
        sakura = {
            name="Sakura", acH=330/360, acS=0.72, acV=0.96,
            bg        =Color3.fromRGB(9,7,15),
            panel     =Color3.fromRGB(13,11,21),
            cardBg    =Color3.fromRGB(16,12,24),
            cardBrd   =Color3.fromRGB(220,40,160),
            cardTitle =Color3.fromRGB(90,10,70),
            tabSel    =Color3.fromRGB(50,16,42),
        },
        space = {
            name="Space", acH=215/360, acS=0.85, acV=1.00,
            bg        =Color3.fromRGB(3,4,14),
            panel     =Color3.fromRGB(6,8,20),
            cardBg    =Color3.fromRGB(7,11,24),
            cardBrd   =Color3.fromRGB(30,120,255),
            cardTitle =Color3.fromRGB(8,30,85),
            tabSel    =Color3.fromRGB(10,20,52),
        },
    }
    local curTheme="sakura"
    local acH=THEMES.sakura.acH
    local acS=THEMES.sakura.acS
    local acV=THEMES.sakura.acV

    local function AC()  return Color3.fromHSV(acH,acS,acV) end
    local function ACL() return Color3.fromHSV(acH,acS*0.38,1.0) end
    local function TH()  return THEMES[curTheme] or THEMES.sakura end

    local function applyThemePreset(key)
        local t=THEMES[key]; if not t then return end
        curTheme=key; acH,acS,acV=t.acH,t.acS,t.acV
    end

    -- Palette — improved text colours for readability
    local function PAL()
        local t=TH()
        return {
            bg=t.bg, panel=t.panel,
            titleBg   =Color3.fromRGB(6,5,11),
            tabBg     =Color3.fromRGB(13,11,20),
            tabSel    =t.tabSel,
            border    =Color3.fromRGB(30,20,44),
            cardBg    =t.cardBg,
            cardBrd   =t.cardBrd,
            cardTitle =t.cardTitle,
            -- Text — higher contrast for legibility inside boxes
            white  =Color3.fromRGB(238,234,252),  -- main text
            label  =Color3.fromRGB(200,185,225),  -- secondary labels
            muted  =Color3.fromRGB(155,130,175),  -- hints/dim
            dimmed =Color3.fromRGB(72,58,90),
            green  =Color3.fromRGB(68,200,110),
            yellow =Color3.fromRGB(228,178,48),
            red    =Color3.fromRGB(228,58,58),
            notifBg=Color3.fromRGB(8,6,16),
            chkBg  =Color3.fromRGB(20,16,32),
            itemBg =Color3.fromRGB(18,14,28),
        }
    end

    -- ── Window geometry ──────────────────────────────────────
    local WW    = math.max(490,math.floor(SW/3.75))
    local WH    = math.max(560,math.floor(SH/2.0))
    local WX    = math.floor(SW/2-WW/2)
    local WY    = math.floor(SH/2-WH/2)
    local TBARH = 30
    local TABH  = 24
    local CONTY = TBARH+TABH
    local PAD   = 10

    -- ── Runtime state ────────────────────────────────────────
    local uiReady   = false
    local uiVisible = true
    local activeTab = 1
    local currentTabs = {}

    local frameObjs  = {}   -- all chrome + content
    local glowLines  = {}
    local ledDot     = nil
    local cardLeds   = {}   -- {dot,x,y,w,h,phase}
    local tabBtnData = {}
    local tabContent = {}   -- [i]=list (lazy, built once)
    local accentObjs = {}
    local partObjs   = {}   -- petals
    local starParts  = {}   -- space sparkles

    local gZones = {}       -- global zones (tab bar)
    local tZones = {}       -- [i]=per-tab

    local ddObjs = {}
    local ddOpen = false

    -- Feature toggle state — persists across tab switches
    local fT = {}
    local function FT(k)     return fT[k] or false end
    local function setFT(k,v) fT[k]=v end

    -- Shared colour presets for ESP swatches
    local COLOR_PRESETS = {
        Color3.fromRGB(255,80,80),  Color3.fromRGB(80,200,120),
        Color3.fromRGB(80,150,255), Color3.fromRGB(255,200,60),
        Color3.fromRGB(200,80,255), Color3.fromRGB(255,255,255),
        Color3.fromRGB(255,140,40), Color3.fromRGB(40,220,220),
    }

    local lblGame, lblVer
    local dynName="--"; local dynVer="--"

    -- forward declarations
    local buildWindow, applyTheme, destroyDD, rebuildAllUL, switchTab

    -- ── Zone helpers ─────────────────────────────────────────
    local function addGZ(x,y,w,h,fn)
        gZones[#gZones+1]={x=x,y=y,w=w,h=h,fn=fn}
    end
    local function addTZ(ti,x,y,w,h,fn)
        tZones[ti]=tZones[ti] or {}
        tZones[ti][#tZones[ti]+1]={x=x,y=y,w=w,h=h,fn=fn}
    end
    local function clearAllZones()
        table.clear(gZones); table.clear(tZones)
    end
    local function hitTest(mx,my)
        local list={}
        for _,z in ipairs(gZones) do list[#list+1]=z end
        if tZones[activeTab] then
            for _,z in ipairs(tZones[activeTab]) do list[#list+1]=z end
        end
        for _,z in ipairs(list) do
            if mx>=z.x and mx<=z.x+z.w and my>=z.y and my<=z.y+z.h then
                pcall(z.fn); return true
            end
        end
        return mx>=WX and mx<=WX+WW and my>=WY and my<=WY+WH
    end

    -- ── Accent registry ──────────────────────────────────────
    local function regAC(o)  accentObjs[#accentObjs+1]={o=o,t="ac"};  return o end
    local function regACL(o) accentObjs[#accentObjs+1]={o=o,t="acl"}; return o end

    applyTheme=function()
        local ac,acl=AC(),ACL()
        for _,e in ipairs(accentObjs) do
            pcall(function() e.o.Color=(e.t=="acl") and acl or ac end)
        end
        for _,gl in ipairs(glowLines) do pcall(function() gl.Color=ac end) end
    end

    -- ── Theme dropdown ───────────────────────────────────────
    destroyDD=function()
        Draw.Destroy(ddObjs); ddOpen=false
        local keep={}
        for _,z in ipairs(gZones) do if not z._dd then keep[#keep+1]=z end end
        table.clear(gZones)
        for _,z in ipairs(keep) do gZones[#gZones+1]=z end
    end
    local function openThemeDD(bx,by)
        destroyDD(); ddOpen=true
        local DW=WW-PAD*2; local IH=26
        local entries={
            {key="sakura",name="Sakura",dot=Color3.fromRGB(255,80,180)},
            {key="space", name="Space", dot=Color3.fromRGB(60,130,255)},
        }
        for i,e in ipairs(entries) do
            local iy=by+(i-1)*IH
            local bg=Draw.Rect(bx,iy,DW,IH,PAL().tabBg,35); bg.Visible=true; ddObjs[#ddObjs+1]=bg
            Draw.Rect(bx+7,iy+8,10,10,e.dot,36).Visible=true; ddObjs[#ddObjs+1]=ddObjs[#ddObjs]
            local lbl=Draw.Text(bx+22,iy+6,e.name,PAL().white,12,36); lbl.Visible=true; ddObjs[#ddObjs+1]=lbl
            if i<#entries then
                local sep=Draw.Line(bx,iy+IH-1,bx+DW,iy+IH-1,PAL().border,1,36)
                sep.Visible=true; ddObjs[#ddObjs+1]=sep
            end
            local ek=e.key
            gZones[#gZones+1]={x=bx,y=iy,w=DW,h=IH,_dd=true,fn=function()
                applyThemePreset(ek); destroyDD()
                applyTheme(); buildWindow()
                Draw.SetVisible(frameObjs,uiVisible)
            end}
        end
        local brd=Draw.Outline(bx,by,DW,#entries*IH,PAL().cardBrd,1,36)
        brd.Visible=true; ddObjs[#ddObjs+1]=brd
    end

    -- ══════════════════════════════════════════════════════════
    -- REUSABLE WIDGET LIBRARY  (exported via ctx)
    -- ══════════════════════════════════════════════════════════

    -- ── CARD — 4-sided complete border, title always enclosed ─
    local function Card(objs,zFn,bx,by,bw,title)
        local pal=PAL(); local CP=7; local TBH=18
        local bg=Draw.Rect(bx,by,bw,0,pal.cardBg,4); objs[#objs+1]=bg
        -- 4 separate border lines updated in finalize
        local lT=Draw.Line(bx,by,bx+bw,by,pal.cardBrd,1,6);       objs[#objs+1]=lT
        local lB=Draw.Line(bx,by,bx+bw,by,pal.cardBrd,1,6);       objs[#objs+1]=lB
        local lL=Draw.Line(bx,by,bx,by,pal.cardBrd,1,6);           objs[#objs+1]=lL
        local lR=Draw.Line(bx+bw,by,bx+bw,by,pal.cardBrd,1,6);    objs[#objs+1]=lR
        -- animated LED dot on border
        local cled=Draw.Circle(bx,by,3,pal.cardBrd,true,7)
        cled.Transparency=0.1; cled.Visible=false; objs[#objs+1]=cled
        cardLeds[#cardLeds+1]={dot=cled,x=bx,y=by,w=bw,h=0,phase=math.random()*6.28}
        -- title bar fill
        local tbg=Draw.Rect(bx,by,bw,TBH,pal.cardTitle,5); objs[#objs+1]=tbg
        -- title text — bright white for readability
        objs[#objs+1]=Draw.Text(bx+CP,by+4,title,Color3.fromRGB(248,240,255),11,6)
        local cledRef=cled
        return {
            cx=bx+CP, cw=bw-CP*2, cy=by+TBH+CP, bx=bx, bw=bw, by=by,
            finalize=function(endY)
                local h=math.max(TBH+CP*2,endY-by+CP)
                pcall(function()
                    bg.Size=Vector2.new(bw,h)
                    lT.From=Vector2.new(bx,by);    lT.To=Vector2.new(bx+bw,by)
                    lB.From=Vector2.new(bx,by+h);  lB.To=Vector2.new(bx+bw,by+h)
                    lL.From=Vector2.new(bx,by);    lL.To=Vector2.new(bx,by+h)
                    lR.From=Vector2.new(bx+bw,by); lR.To=Vector2.new(bx+bw,by+h)
                end)
                for _,ld in ipairs(cardLeds) do
                    if ld.dot==cledRef then ld.h=h; break end
                end
                return by+h
            end,
        }
    end

    -- ── SECTION DIVIDER ──────────────────────────────────────
    local function Section(objs,cx,y,cw,label)
        local pal=PAL()
        objs[#objs+1]=Draw.Text(cx,y,"[ "..label.." ]",pal.label,10,6)
        objs[#objs+1]=Draw.Line(cx,y+14,cx+cw,y+14,pal.border,1,5)
        return y+20
    end

    -- ── LABEL ────────────────────────────────────────────────
    local function Label(objs,cx,y,text,col)
        objs[#objs+1]=Draw.Text(cx,y,text,col or PAL().muted,9,6)
        return y+13
    end

    -- ── CHECKBOX (empty=off, filled+tick=on) ─────────────────
    -- Improved: larger hit area, bright white label for readability
    local function Checkbox(objs,zFn,cx,y,key,label)
        local pal=PAL(); local SZ=13; local on=FT(key)
        objs[#objs+1]=Draw.Rect(cx,y,SZ,SZ,pal.chkBg,7)
        objs[#objs+1]=Draw.Outline(cx,y,SZ,SZ,pal.cardBrd,1,8)
        local fill=Draw.Rect(cx+1,y+1,SZ-2,SZ-2,AC(),7)
        fill.Visible=on; objs[#objs+1]=fill
        local t1=Draw.Line(cx+2,y+6, cx+5,y+10,Color3.fromRGB(255,255,255),2,9)
        local t2=Draw.Line(cx+5,y+10,cx+11,y+3,Color3.fromRGB(255,255,255),2,9)
        t1.Visible=on; t2.Visible=on; objs[#objs+1]=t1; objs[#objs+1]=t2
        -- Label: white/light for readability inside dark cards
        objs[#objs+1]=Draw.Text(cx+SZ+5,y+1,label,Color3.fromRGB(228,222,245),11,7)
        zFn(cx,y,SZ+6+math.max(80,#label*6+10),SZ+2,function()
            local v=not FT(key); setFT(key,v)
            pcall(function()
                fill.Visible=v; fill.Color=AC()
                t1.Visible=v;   t2.Visible=v
            end)
        end)
        return y+SZ+7
    end

    -- ── DROPDOWN (inline expanding list) ─────────────────────
    local function Dropdown(objs,zFn,cx,y,cw,key,items,placeholder)
        local pal=PAL(); local H=21
        local sidx=fT[key.."_sel"] or 0
        local cur=(sidx>0 and items[sidx]) or placeholder or "Select..."
        objs[#objs+1]=Draw.Rect(cx,y,cw,H,pal.itemBg,6)
        objs[#objs+1]=Draw.Outline(cx,y,cw,H,pal.cardBrd,1,7)
        local lbl=Draw.Text(cx+7,y+5,"  "..cur,Color3.fromRGB(228,222,245),10,7); objs[#objs+1]=lbl
        objs[#objs+1]=Draw.Text(cx+cw-14,y+5,"v",pal.muted,9,7)
        local listOpen=false; local listObjs={}
        local function closeList()
            for _,o in ipairs(listObjs) do pcall(function() o:Remove() end) end
            table.clear(listObjs); listOpen=false
            if tZones[activeTab] then
                local keep={}
                for _,z in ipairs(tZones[activeTab]) do if not z._dl then keep[#keep+1]=z end end
                table.clear(tZones[activeTab])
                for _,z in ipairs(keep) do tZones[activeTab][#tZones[activeTab]+1]=z end
            end
        end
        local function openList()
            if listOpen then closeList(); return end; listOpen=true
            local IH=17
            for i,item in ipairs(items) do
                local iy=y+H+(i-1)*IH
                local ibg=Draw.Rect(cx,iy,cw,IH,Color3.fromRGB(14,10,22),20); ibg.Visible=true; listObjs[#listObjs+1]=ibg
                local ibrd=Draw.Outline(cx,iy,cw,IH,pal.cardBrd,1,21); ibrd.Visible=true; listObjs[#listObjs+1]=ibrd
                local it=Draw.Text(cx+7,iy+4,tostring(item),Color3.fromRGB(228,222,245),10,21); it.Visible=true; listObjs[#listObjs+1]=it
                local ii=i
                if tZones[activeTab] then
                    tZones[activeTab][#tZones[activeTab]+1]={
                        x=cx,y=iy,w=cw,h=IH,_dl=true,fn=function()
                            fT[key.."_sel"]=ii
                            pcall(function() lbl.Text="  "..tostring(items[ii]) end)
                            closeList()
                        end}
                end
            end
            for _,o in ipairs(listObjs) do objs[#objs+1]=o end
        end
        zFn(cx,y,cw,H,openList)
        return y+H+5
    end

    -- ── BUTTON ───────────────────────────────────────────────
    local function Button(objs,zFn,cx,y,cw,label,fn)
        local pal=PAL(); local H=23
        objs[#objs+1]=Draw.Rect(cx,y,cw,H,Color3.fromRGB(20,14,34),6)
        objs[#objs+1]=Draw.Outline(cx,y,cw,H,pal.cardBrd,1,7)
        objs[#objs+1]=Draw.Text(cx+9,y+6,label,Color3.fromRGB(228,222,245),11,7)
        zFn(cx,y,cw,H,fn or function() end)
        return y+H+5
    end

    -- ── SLIDER ───────────────────────────────────────────────
    local function Slider(objs,zFn,cx,y,cw,key,label,minV,maxV,defV)
        local pal=PAL(); local TKH=8
        local val=fT[key.."_val"] or defV or minV
        local frac=(val-minV)/math.max(1,maxV-minV)
        local lbl=Draw.Text(cx,y,label.." : "..tostring(math.floor(val)),Color3.fromRGB(228,222,245),10,6)
        objs[#objs+1]=lbl; y=y+14
        objs[#objs+1]=Draw.Rect(cx,y+2,cw,TKH,pal.chkBg,6)
        objs[#objs+1]=Draw.Outline(cx,y+2,cw,TKH,pal.cardBrd,1,7)
        local fw=math.max(TKH,math.floor(frac*cw))
        local fill=Draw.Rect(cx,y+2,fw,TKH,AC(),7); objs[#objs+1]=fill; regAC(fill)
        local hnd=Draw.Rect(cx+math.floor(frac*cw)-4,y,8,TKH+4,PAL().muted,8); objs[#objs+1]=hnd
        zFn(cx,y,cw,TKH+6,function()
            local nf=math.max(0,math.min(1,(MX()-cx)/cw))
            local nv=math.floor(minV+(maxV-minV)*nf)
            fT[key.."_val"]=nv
            pcall(function()
                lbl.Text=label.." : "..tostring(nv)
                fill.Size=Vector2.new(math.max(TKH,math.floor(nf*cw)),TKH)
                hnd.Position=Vector2.new(cx+math.floor(nf*cw)-4,y)
            end)
        end)
        return y+TKH+12
    end

    -- ── COLOR SWATCH ─────────────────────────────────────────
    local function ColorSwatch(objs,zFn,cx,y,label,colorRef)
        local pal=PAL(); local SW2,SH2=20,13
        local swatch=Draw.Rect(cx,y,SW2,SH2,colorRef[1],7); objs[#objs+1]=swatch
        objs[#objs+1]=Draw.Outline(cx,y,SW2,SH2,pal.cardBrd,1,8)
        objs[#objs+1]=Draw.Text(cx+SW2+5,y+2,label,pal.muted,9,7)
        local ci=1
        zFn(cx,y,SW2+5+math.max(60,#label*7),SH2,function()
            ci=ci%#COLOR_PRESETS+1
            colorRef[1]=COLOR_PRESETS[ci]
            pcall(function() swatch.Color=COLOR_PRESETS[ci] end)
        end)
        return y+SH2+5
    end

    -- ── CONTEXT FACTORY (given to each buildFn) ──────────────
    local function makeCtx(tabIdx)
        local objs=tabContent[tabIdx]
        local function zFn(x,y2,w,h,fn) addTZ(tabIdx,x,y2,w,h,fn) end
        return {
            cx=WX+PAD, cy=WY+CONTY+PAD, cw=WW-PAD*2,
            objs=objs, D=Draw, C=PAL(), PAD=PAD,
            WW=WW, WH=WH, CONTY=CONTY,
            Card        =function(bx,by,bw,t)          return Card(objs,zFn,bx,by,bw,t) end,
            Section     =function(bx,by,bw,t)          return Section(objs,bx,by,bw,t) end,
            Label       =function(bx,by,t,col)         return Label(objs,bx,by,t,col) end,
            Checkbox    =function(bx,by,k,l)           return Checkbox(objs,zFn,bx,by,k,l) end,
            Dropdown    =function(bx,by,bw,k,items,ph) return Dropdown(objs,zFn,bx,by,bw,k,items,ph) end,
            Button      =function(bx,by,bw,l,f)        return Button(objs,zFn,bx,by,bw,l,f) end,
            Slider      =function(bx,by,bw,k,l,mn,mx2,d) return Slider(objs,zFn,bx,by,bw,k,l,mn,mx2,d) end,
            ColorSwatch =function(bx,by,l,ref)         return ColorSwatch(objs,zFn,bx,by,l,ref) end,
            Zone=zFn, GZone=addGZ, RegAC=regAC, RegACL=regACL,
            FT=FT, setFT=setFT,
            WX=function()return WX end, WY=function()return WY end,
            AC=AC, ACL=ACL, PAL=PAL, TH=TH,
            dynName=function()return dynName end,
            dynVer =function()return dynVer  end,
            openThemeDD=openThemeDD,
            ddOpen =function()return ddOpen end,
            destroyDD=destroyDD,
            COLOR_PRESETS=COLOR_PRESETS,
        }
    end

    -- ── Rebuild underlines ───────────────────────────────────
    rebuildAllUL=function()
        local ac=AC()
        for i,bd in pairs(tabBtnData) do pcall(function()
            local sel=(i==activeTab)
            bd.ul.Color=ac; bd.ul.Visible=sel
            bd.lbl.Color=sel and ACL() or PAL().muted
            bd.bg.Color=sel and PAL().tabSel or PAL().tabBg
        end) end
    end

    -- ── Switch tab (lazy build) ──────────────────────────────
    switchTab=function(idx)
        if not currentTabs[idx] then return end
        if tabContent[activeTab] then Draw.SetVisible(tabContent[activeTab],false) end
        activeTab=idx; destroyDD()
        if not tabContent[activeTab] then
            tabContent[activeTab]={} ; tZones[activeTab]={}
            local tab=currentTabs[activeTab]
            if tab and type(tab.buildFn)=="function" then
                local ctx=makeCtx(activeTab)
                pcall(function() tab.buildFn(ctx) end)
                for _,o in ipairs(tabContent[activeTab]) do frameObjs[#frameObjs+1]=o end
            end
        end
        Draw.SetVisible(tabContent[activeTab],uiVisible)
        rebuildAllUL()
    end

    -- ── Build window chrome ──────────────────────────────────
    buildWindow=function()
        destroyDD(); table.clear(cardLeds)
        for _,o in ipairs(frameObjs) do pcall(function() o:Remove() end) end
        table.clear(frameObjs); table.clear(glowLines)
        table.clear(tabBtnData); table.clear(accentObjs)
        for _,tc in pairs(tabContent) do
            for _,o in ipairs(tc) do pcall(function() o:Remove() end) end
        end
        table.clear(tabContent); clearAllZones(); bindLblRef=nil
        if ledDot then pcall(function() ledDot:Remove() end); ledDot=nil end

        local pal=PAL(); local ac=AC()
        local x,y=WX,WY

        -- window bg + title bar
        frameObjs[#frameObjs+1]=Draw.Rect(x,y,WW,WH,pal.bg,1)
        frameObjs[#frameObjs+1]=Draw.Rect(x,y,WW,TBARH,pal.titleBg,2)
        frameObjs[#frameObjs+1]=regACL(Draw.Text(x+PAD,y+8,"EXE.HUB",ACL(),14,5))
        frameObjs[#frameObjs+1]=Draw.Line(x+90,y+5,x+90,y+TBARH-5,pal.border,1,4)
        lblGame=Draw.Text(x+96,y+8,dynName,pal.muted,10,5); frameObjs[#frameObjs+1]=lblGame
        lblVer =Draw.Text(x+WW-62,y+9,dynVer,pal.dimmed,9,5); frameObjs[#frameObjs+1]=lblVer
        frameObjs[#frameObjs+1]=Draw.Line(x,y+TBARH,x+WW,y+TBARH,pal.border,1,3)

        -- tab bar
        local nT=#currentTabs
        local tabW=math.floor(WW/math.max(nT,1))
        local tabY=y+TBARH
        for i,tab in ipairs(currentTabs) do
            local tx=x+(i-1)*tabW; local sel=(i==activeTab)
            local tbg=Draw.Rect(tx,tabY,tabW,TABH,sel and pal.tabSel or pal.tabBg,2)
            frameObjs[#frameObjs+1]=tbg
            if i>1 then
                frameObjs[#frameObjs+1]=Draw.Line(tx,tabY+3,tx,tabY+TABH-3,pal.border,1,3)
            end
            local lx=tx+math.floor(tabW/2)-math.floor(#tab.name*2.9)
            local tlbl=Draw.Text(lx,tabY+6,tab.name,sel and ACL() or pal.muted,10,4)
            if sel then regACL(tlbl) end
            frameObjs[#frameObjs+1]=tlbl
            local tul=Draw.Line(tx+3,tabY+TABH-1,tx+tabW-3,tabY+TABH-1,ac,2,4)
            tul.Visible=sel; frameObjs[#frameObjs+1]=tul
            tabBtnData[i]={bg=tbg,lbl=tlbl,ul=tul}
            local ci=i; addGZ(tx,tabY,tabW,TABH,function() switchTab(ci) end)
        end

        -- content area
        frameObjs[#frameObjs+1]=Draw.Line(x,y+CONTY,x+WW,y+CONTY,pal.border,1,3)
        frameObjs[#frameObjs+1]=Draw.Rect(x,y+CONTY,WW,WH-CONTY,pal.panel,1)
        frameObjs[#frameObjs+1]=Draw.Outline(x,y,WW,WH,pal.border,1,3)

        -- glow border
        local function glow(x1,y1,x2,y2)
            local l=Draw.Line(x1,y1,x2,y2,ac,1.5,4); l.Transparency=0.84
            frameObjs[#frameObjs+1]=l; glowLines[#glowLines+1]=l
        end
        glow(x,y,x+WW,y); glow(x+WW,y,x+WW,y+WH)
        glow(x+WW,y+WH,x,y+WH); glow(x,y+WH,x,y)

        -- window LED dot
        ledDot=Drawing.new("Circle")
        ledDot.Radius=5; ledDot.Color=ac; ledDot.Filled=true
        ledDot.Transparency=0.1; ledDot.ZIndex=8; ledDot.Visible=false
        frameObjs[#frameObjs+1]=ledDot

        -- build active tab content
        tabContent[activeTab]={} ; tZones[activeTab]={}
        local tab=currentTabs[activeTab]
        if tab and type(tab.buildFn)=="function" then
            local ctx=makeCtx(activeTab)
            pcall(function() tab.buildFn(ctx) end)
            for _,o in ipairs(tabContent[activeTab]) do frameObjs[#frameObjs+1]=o end
        end
    end

    -- ══════════════════════════════════════════════════════════
    -- SHARED TABS  (Settings / Credits / Logs)
    -- ══════════════════════════════════════════════════════════

    local function buildSettings(ctx)
        local o,D,pal=ctx.objs,ctx.D,ctx.C
        local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
        local sy=cy

        -- Theme
        local thC=ctx.Card(cx,sy,cw,"THEME")
        local ty=thC.cy
        local swH=23
        local sw=Draw.Rect(thC.cx,ty,thC.cw,swH,AC(),5); regAC(sw); o[#o+1]=sw
        o[#o+1]=D.Text(thC.cx+7,ty+6,"  Theme : "..ctx.TH().name,Color3.fromRGB(8,8,8),11,6)
        ctx.Zone(thC.cx,ty,thC.cw,swH,function()
            if ctx.ddOpen() then ctx.destroyDD()
            else ctx.openThemeDD(thC.cx,ty+swH+2) end
        end)
        ty=ty+swH+6; thC.finalize(ty); sy=ty+10

        -- Toggle Key
        local tkC=ctx.Card(cx,sy,cw,"TOGGLE KEY")
        local ky=tkC.cy
        local bh=27
        o[#o+1]=D.Rect(tkC.cx,ky,tkC.cw,bh,pal.itemBg,5)
        o[#o+1]=D.Outline(tkC.cx,ky,tkC.cw,bh,pal.cardBrd,1,6)
        local klbl=D.Text(tkC.cx+9,ky+8,"Toggle Key : [ "..toggleLabel.." ]",
            Color3.fromRGB(185,148,228),12,6)
        o[#o+1]=klbl; bindLblRef=klbl
        ky=ky+bh+5
        o[#o+1]=D.Text(tkC.cx,ky,"Click the box, then press any key to rebind.",pal.muted,9,6)
        ky=ky+13
        ctx.Zone(tkC.cx,ky-bh-18,tkC.cw,bh,function()
            if bindMode then
                bindMode=false
                pcall(function()
                    klbl.Text ="Toggle Key : [ "..toggleLabel.." ]"
                    klbl.Color=Color3.fromRGB(185,148,228)
                end)
            else
                bindMode=true
                pcall(function()
                    klbl.Text ="Waiting for key..."
                    klbl.Color=Color3.fromRGB(235,185,55)
                end)
            end
        end)
        tkC.finalize(ky); sy=ky+10

        -- Hub Status (V1)
        local hsC=ctx.Card(cx,sy,cw,"HUB STATUS")
        local hsy=hsC.cy
        o[#o+1]=D.Text(hsC.cx,hsy,"Version :",pal.muted,10,6)
        o[#o+1]=D.Text(hsC.cx+56,hsy,"V1",Color3.fromRGB(210,188,255),11,6)
        hsy=hsy+16
        o[#o+1]=D.Text(hsC.cx,hsy,"V1  —  Initial release of the hub.",pal.label,9,6)
        hsy=hsy+14
        o[#o+1]=D.Text(hsC.cx,hsy,"Game :",pal.muted,10,6)
        o[#o+1]=D.Text(hsC.cx+42,hsy,ctx.dynName(),Color3.fromRGB(228,222,245),11,6)
        hsC.finalize(hsy+8)
    end

    local function buildCredits(ctx)
        local o,D,pal=ctx.objs,ctx.D,ctx.C
        local cr=ctx.Card(ctx.cx,ctx.cy,ctx.cw,"CREDITS")
        local ry=cr.cy
        o[#o+1]=D.Text(cr.cx,ry,"Creator : MATTHEUBE",Color3.fromRGB(248,240,255),13,6); ry=ry+20
        o[#o+1]=D.Text(cr.cx,ry,"EXE.HUB — Roblox Script Hub",pal.muted,11,6); ry=ry+16
        o[#o+1]=D.Text(cr.cx,ry,"github.com/mattheube/EXE.HUB",pal.dimmed,10,6); ry=ry+6
        cr.finalize(ry+10)
    end

    local function buildLogs(ctx)
        local o,D,pal=ctx.objs,ctx.D,ctx.C
        local lg=ctx.Card(ctx.cx,ctx.cy,ctx.cw,"HUB UPDATES")
        local ly=lg.cy
        local lines={
            "V1 — Initial release of the hub.",
            "Future updates will be listed here.",
        }
        for _,ln in ipairs(lines) do
            o[#o+1]=D.Text(lg.cx,ly,ln,Color3.fromRGB(228,222,245),11,6); ly=ly+16
        end
        lg.finalize(ly+4)
    end

    -- ══════════════════════════════════════════════════════════
    -- LED ANIMATION LOOP
    -- ══════════════════════════════════════════════════════════
    task.spawn(function()
        local t=0; local perim=2*(WW+WH)
        while true do
            task.wait(0.033)
            if not uiReady or not uiVisible then continue end
            t=(t+3)%perim
            local px,py
            if t<WW then px=WX+t; py=WY
            elseif t<WW+WH then px=WX+WW; py=WY+(t-WW)
            elseif t<WW*2+WH then px=WX+WW-(t-WW-WH); py=WY+WH
            else px=WX; py=WY+WH-(t-WW*2-WH) end
            if ledDot then pcall(function()
                ledDot.Position=Vector2.new(px,py); ledDot.Color=AC()
                ledDot.Radius=3+2.5*(0.5+0.5*math.sin(t*0.04))
                ledDot.Visible=uiVisible
            end) end
            for _,gl in ipairs(glowLines) do
                pcall(function() gl.Transparency=0.85; gl.Color=AC() end)
            end
            for _,ld in ipairs(cardLeds) do
                if ld.h>0 then pcall(function()
                    local cp=2*(ld.w+ld.h)
                    local ct=((t*0.55)+ld.phase*cp)%cp
                    local dpx,dpy
                    if ct<ld.w then dpx=ld.x+ct; dpy=ld.y
                    elseif ct<ld.w+ld.h then dpx=ld.x+ld.w; dpy=ld.y+(ct-ld.w)
                    elseif ct<ld.w*2+ld.h then dpx=ld.x+ld.w-(ct-ld.w-ld.h); dpy=ld.y+ld.h
                    else dpx=ld.x; dpy=ld.y+ld.h-(ct-ld.w*2-ld.h) end
                    ld.dot.Position=Vector2.new(dpx,dpy)
                    ld.dot.Color=AC(); ld.dot.Visible=uiVisible
                end) end
            end
        end
    end)

    -- ══════════════════════════════════════════════════════════
    -- SAKURA PETALS
    -- ══════════════════════════════════════════════════════════
    local PMAX=52; local pCount=0
    local function spawnPetal()
        if pCount>=PMAX or not uiReady then return end; pCount=pCount+1
        local sz=math.random(2,6)
        local p=Drawing.new("Circle")
        p.Position=Vector2.new(WX+math.random(sz,WW-sz),WY+CONTY+sz)
        p.Radius=sz; p.Color=Color3.fromHSV(acH,acS*0.55,1.0)
        p.Filled=true; p.Transparency=math.random(10,42)/100; p.ZIndex=2; p.Visible=false
        partObjs[#partObjs+1]=p
        local steps=math.random(60,155); local dy=(WY+WH-2-(WY+CONTY))/steps
        local ph=math.random()*6.28; local amp=math.random(3,10)
        local dA=(p.Transparency-0.97)/steps; local drift=math.random(-10,10)/steps
        task.spawn(function()
            for s=1,steps do task.wait(0.05); if not uiReady then break end
                pcall(function()
                    p.Visible=uiVisible and (curTheme=="sakura")
                    p.Color=Color3.fromHSV(acH,acS*0.55,1.0)
                    p.Position=Vector2.new(
                        p.Position.X+drift+math.sin(ph+s*0.13)*amp/steps,
                        p.Position.Y+dy)
                    p.Transparency=math.min(1,p.Transparency+dA)
                end)
            end
            pcall(function() p:Remove() end)
            for i,a in ipairs(partObjs) do if a==p then table.remove(partObjs,i); break end end
            pCount=pCount-1
        end)
    end
    task.spawn(function()
        while true do
            task.wait(0.22+math.random()*0.32)
            if uiReady and curTheme=="sakura" then
                pcall(spawnPetal)
                if math.random()<0.72 then task.wait(0.07); pcall(spawnPetal) end
                if math.random()<0.45 then task.wait(0.07); pcall(spawnPetal) end
                if math.random()<0.22 then task.wait(0.07); pcall(spawnPetal) end
            end
        end
    end)

    -- ══════════════════════════════════════════════════════════
    -- SPACE STARS  — 4-arm sparkle, rich grid distribution
    -- ══════════════════════════════════════════════════════════
    local STAR_ARMS={
        {-1,0,   1,0  },
        { 0,-1,  0,1  },
        {-0.65,-0.65, 0.65, 0.65},
        { 0.65,-0.65,-0.65, 0.65},
    }
    local function buildStars()
        for _,s in ipairs(starParts) do
            for _,l in ipairs(s.lines) do pcall(function() l:Remove() end) end
        end
        table.clear(starParts)
        if curTheme~="space" then return end
        -- Grid-based distribution with noise: 9 cols × 10 rows = 90 base stars
        local cols=9; local rows=10
        local cW=WW/cols; local cH=(WH-CONTY)/rows
        for row=0,rows-1 do
            for col=0,cols-1 do
                local bx=WX + col*cW + math.random(3,math.max(4,cW-4))
                local by=WY+CONTY + row*cH + math.random(3,math.max(4,cH-4))
                local sz=math.random(2,5)
                local lines={}
                for _,arm in ipairs(STAR_ARMS) do
                    local l=Drawing.new("Line")
                    l.From=Vector2.new(bx+arm[1]*sz,by+arm[2]*sz)
                    l.To  =Vector2.new(bx+arm[3]*sz,by+arm[4]*sz)
                    l.Color=Color3.fromHSV(acH,acS*0.35,0.92)
                    l.Thickness=1.1; l.Transparency=0.25; l.ZIndex=2; l.Visible=false
                    lines[#lines+1]=l
                end
                starParts[#starParts+1]={
                    lines=lines, ox=bx, oy=by, sz=sz,
                    phase=math.random()*6.28, speed=0.28+math.random()*1.3,
                }
            end
        end
        -- 14 large accent stars scattered at random
        for _=1,14 do
            local bx=WX+math.random(8,WW-8)
            local by=WY+CONTY+math.random(8,WH-CONTY-8)
            local sz=math.random(5,10)
            local lines={}
            for _,arm in ipairs(STAR_ARMS) do
                local l=Drawing.new("Line")
                l.From=Vector2.new(bx+arm[1]*sz,by+arm[2]*sz)
                l.To  =Vector2.new(bx+arm[3]*sz,by+arm[4]*sz)
                l.Color=Color3.fromHSV(acH,acS*0.25,1.0)
                l.Thickness=1.4; l.Transparency=0.15; l.ZIndex=2; l.Visible=false
                lines[#lines+1]=l
            end
            starParts[#starParts+1]={
                lines=lines, ox=bx, oy=by, sz=sz,
                phase=math.random()*6.28, speed=0.12+math.random()*0.55,
            }
        end
    end
    task.spawn(function()
        local t=0
        while true do task.wait(0.05); t=t+0.05
            local isSp=(curTheme=="space")
            for _,s in ipairs(starParts) do pcall(function()
                local pulse=0.5+0.5*math.sin(t*s.speed+s.phase)
                local col=Color3.fromHSV(acH,acS*(0.18+0.52*pulse),0.68+0.32*pulse)
                local sc=s.sz*(0.38+0.92*pulse)
                local tr=0.03+0.6*(1-pulse)
                local ox=s.ox+math.sin(t*0.28+s.phase)*1.6
                local oy=s.oy+math.cos(t*0.22+s.phase)*1.2
                for i,l in ipairs(s.lines) do
                    l.Visible=uiVisible and isSp; l.Color=col; l.Transparency=tr
                    local arm=STAR_ARMS[i]
                    l.From=Vector2.new(ox+arm[1]*sc,oy+arm[2]*sc)
                    l.To  =Vector2.new(ox+arm[3]*sc,oy+arm[4]*sc)
                end
            end) end
        end
    end)

    -- ══════════════════════════════════════════════════════════
    -- NOTIFICATIONS
    -- ══════════════════════════════════════════════════════════
    local NW=math.max(220,math.floor(SW/6.2)); local NH=62
    local NXf=SW-NW-14; local NYf=68; local NDUR=9
    local nQ={}; local nBusy=false
    local function showNextNotif()
        if nBusy or #nQ==0 then return end; nBusy=true
        local n=table.remove(nQ,1); local obs={}; local sy2=SH+10; local pal=PAL()
        local function aO(o2) obs[#obs+1]=o2 end
        aO(Draw.Rect(NXf,sy2,NW,NH,pal.notifBg,50))
        aO(Draw.Outline(NXf,sy2,NW,NH,n.col,1.5,51))
        aO(Draw.Rect(NXf+4,sy2+5,3,NH-10,n.col,51))
        aO(Draw.Text(NXf+13,sy2+11,n.title,Color3.fromRGB(238,234,252),13,52))
        aO(Draw.Text(NXf+13,sy2+28,n.msg,pal.muted,10,52))
        local sp={}
        for _=1,4 do
            local s2=Draw.Rect(NXf+math.random(8,NW-8),sy2+math.random(4,NH-4),2,2,n.col,53)
            aO(s2); sp[#sp+1]={o=s2,ox=0,oy=0,ph=math.random()*6.28}
        end
        Draw.SetVisible(obs,true)
        local function setNY(ny)
            local dy=ny-obs[1].Position.Y
            for _,ob in ipairs(obs) do pcall(function()
                if ob.Position then ob.Position=Vector2.new(ob.Position.X,ob.Position.Y+dy) end
            end) end
            for _,s2 in ipairs(sp) do s2.oy=(s2.oy or 0)+dy end
        end
        task.spawn(function()
            for i=1,20 do task.wait(0.025); setNY(sy2+(NYf-sy2)*(1-(1-i/20)^3)) end
            setNY(NYf)
            for _,s2 in ipairs(sp) do s2.ox=s2.o.Position.X; s2.oy=s2.o.Position.Y end
            local el=0
            while el<NDUR do task.wait(0.05); el=el+0.05
                for _,s2 in ipairs(sp) do pcall(function()
                    s2.o.Position=Vector2.new(
                        s2.ox+math.sin(el*2+s2.ph)*4,
                        s2.oy+math.cos(el*1.4+s2.ph)*2)
                end) end
            end
            for i=1,16 do task.wait(0.025)
                local ox2=NXf+i*(NW+60)/16
                for _,ob in ipairs(obs) do pcall(function()
                    if ob.Position then ob.Position=Vector2.new(ox2,ob.Position.Y) end
                end) end
            end
            Draw.Destroy(obs); nBusy=false; task.wait(0.3); showNextNotif()
        end)
    end
    local function notify(title,msg,col)
        nQ[#nQ+1]={title=title,msg=msg,col=col}; showNextNotif()
    end

    -- ══════════════════════════════════════════════════════════
    -- INPUT LOOP (drag + toggle + click routing)
    -- ══════════════════════════════════════════════════════════
    task.spawn(function()
        local prevLMB=false; local prevTog=false
        local dragOn=false; local dRelX,dRelY=0,0
        while true do
            task.wait(0.033); if not uiReady then continue end
            local mx,my=MX(),MY(); local lmb=LMB(); local togNow=isToggleDown()

            if bindMode then scanBind() end

            -- Toggle visibility — full explicit SetVisible pass (reopen fix)
            if togNow and not prevTog and not bindMode then
                uiVisible=not uiVisible
                Draw.SetVisible(frameObjs,uiVisible)
                Draw.SetVisible(ddObjs,uiVisible and ddOpen)
                for _,p in ipairs(partObjs) do
                    pcall(function() p.Visible=uiVisible and (curTheme=="sakura") end)
                end
                for _,s in ipairs(starParts) do
                    for _,l in ipairs(s.lines) do
                        pcall(function() l.Visible=uiVisible and (curTheme=="space") end)
                    end
                end
                if uiVisible then rebuildAllUL() end
            end
            prevTog=togNow

            -- Drag via title bar
            if dragOn then
                if lmb then
                    local dx=math.floor((mx-dRelX-WX)*0.72)
                    local dy=math.floor((my-dRelY-WY)*0.72)
                    if math.abs(dx)+math.abs(dy)>0 then
                        WX=WX+dx; WY=WY+dy
                        Draw.Move(frameObjs,dx,dy); Draw.Move(ddObjs,dx,dy)
                        for _,z in ipairs(gZones) do z.x=z.x+dx; z.y=z.y+dy end
                        for _,tzl in pairs(tZones) do
                            for _,z in ipairs(tzl) do z.x=z.x+dx; z.y=z.y+dy end
                        end
                        for _,s in ipairs(starParts) do s.ox=s.ox+dx; s.oy=s.oy+dy end
                        for _,ld in ipairs(cardLeds) do ld.x=ld.x+dx; ld.y=ld.y+dy end
                    end
                else dragOn=false end
            end

            if lmb and not prevLMB then
                if uiVisible then
                    if mx>=WX and mx<=WX+WW and my>=WY and my<=WY+TBARH then
                        dragOn=true; dRelX=mx-WX; dRelY=my-WY
                    else
                        hitTest(mx,my)
                    end
                end
            end
            prevLMB=lmb
        end
    end)

    -- ══════════════════════════════════════════════════════════
    -- PUBLIC API
    -- ══════════════════════════════════════════════════════════
    function UI.Init()
        task.spawn(function()
            currentTabs={
                {name="Settings", buildFn=buildSettings},
                {name="Credits",  buildFn=buildCredits},
                {name="Logs",     buildFn=buildLogs},
            }
            buildWindow(); buildStars()
            Draw.SetVisible(frameObjs,true)
            uiReady=true; uiVisible=true
            if UI._onReady then UI._onReady() end
        end)
    end

    local _dQ={}
    UI._onReady=function()
        UI._onReady=nil
        for _,f in ipairs(_dQ) do pcall(f) end
        table.clear(_dQ)
    end
    local function defer(fn)
        if uiReady then pcall(fn) else _dQ[#_dQ+1]=fn end
    end

    -- Called by game module to inject tabs
    function UI.LoadGameModule(gm)
        defer(function()
            dynName=gm.Name or dynName; dynVer=gm.Version or dynVer
            if lblGame then pcall(function() lblGame.Text=dynName end) end
            if lblVer  then pcall(function() lblVer.Text=dynVer   end) end
            if gm.Tabs and #gm.Tabs>0 then
                local newTabs={}
                for _,t in ipairs(gm.Tabs) do newTabs[#newTabs+1]=t end
                for _,t in ipairs(currentTabs) do
                    if t.name=="Settings" or t.name=="Credits" or t.name=="Logs" then
                        newTabs[#newTabs+1]=t
                    end
                end
                activeTab=1; currentTabs=newTabs
                buildWindow(); buildStars()
                Draw.SetVisible(frameObjs,uiVisible)
            end
        end)
    end

    local function nCol(tp)
        local p=PAL()
        if tp=="success" then return p.green
        elseif tp=="warning" then return p.yellow
        elseif tp=="error"   then return p.red
        end; return AC()
    end
    function UI.ShowWelcome()
        defer(function() notify("EXE.HUB","Hub active  —  V1",AC()) end) end
    function UI.ShowGameDetected(n)
        defer(function() notify("Game Detected",n,PAL().green) end) end
    function UI.ShowGameLoaded(n,v)
        dynName=n or dynName; dynVer=v or dynVer
        defer(function()
            if lblGame then pcall(function() lblGame.Text=dynName end) end
            if lblVer  then pcall(function() lblVer.Text=dynVer   end) end
        end)
    end
    function UI.ShowNotSupported(id)
        defer(function() notify("Not Supported","PlaceId: "..tostring(id),PAL().yellow) end) end
    function UI.ShowLoadError(n)
        defer(function() notify("Load Error",tostring(n),PAL().red) end) end
    function UI.Notify(t2,m,tp)
        defer(function() notify(t2,m,nCol(tp)) end) end
    function UI.Destroy()
        uiReady=false; Draw.DestroyAll()
        table.clear(frameObjs); table.clear(glowLines); table.clear(accentObjs)
        table.clear(partObjs); table.clear(starParts); clearAllZones()
    end
end

-- ══════════════════════════════════════════════════════════════
-- MODULE LOADER
-- ══════════════════════════════════════════════════════════════
_G.__EXE_HUB_MODULES={}
local function loadModule(path)
    local url=BASE..path.."?t="..tostring(math.floor(tick()))
    local raw; pcall(function() raw=game:HttpGet(url,true) end)
    if not raw or raw=="" then err("HTTP: "..path); return nil end
    local fn,e=loadstring(raw)
    if not fn then err("Compile: "..path.." "..tostring(e)); return nil end
    local ok,r=pcall(fn)
    if not ok then err("Exec: "..path.." "..tostring(r)); return nil end
    if r~=nil then return r end
    local key=path:match("([^/]+)%.lua$")
    if key and _G.__EXE_HUB_MODULES[key] then
        local m=_G.__EXE_HUB_MODULES[key]; _G.__EXE_HUB_MODULES[key]=nil; return m
    end
    err("NIL module: "..path); return nil
end
local function loadGame(info)
    if not info then return end
    UI.ShowGameDetected(info.name)
    local gm=loadModule(info.module)
    if not gm then UI.ShowLoadError(info.name); return end
    gm.Name=gm.Name or info.name; gm.Version=gm.Version or info.version
    if type(gm.Init)=="function" then
        local ok,e=pcall(function() gm.Init({UI=UI,log=log,err=err}) end)
        if not ok then UI.ShowLoadError(info.name); err(tostring(e)); return end
    end
    UI.ShowGameLoaded(gm.Name,gm.Version)
    UI.LoadGameModule(gm)
end

-- ══════════════════════════════════════════════════════════════
-- LAUNCH
-- ══════════════════════════════════════════════════════════════
UI.Init(); UI.ShowWelcome()
local pId=game.PlaceId
if GAMES[pId] then loadGame(GAMES[pId]) else UI.ShowNotSupported(pId) end