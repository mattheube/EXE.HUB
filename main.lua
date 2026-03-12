-- ╔═══════════════════════════════════════════════════════════════╗
-- ║           EXE.HUB  v7.0  —  Drawing API  (Matcha)           ║
-- ╚═══════════════════════════════════════════════════════════════╝
-- Engine : task.spawn + task.wait  (RunService.Heartbeat = dead on Matcha)
-- Input  : ismouse1pressed() for LMB  |  RealUIS:IsKeyDown() for keys
-- Toggle : default = P  (rebindable: letters, numbers, F-keys, specials)
-- Creator: MaTub  |  github.com/mattheube/EXE.HUB

local BASE = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"
local RealUIS = game:GetService("UserInputService")
local function log(m) print("[EXE] "..tostring(m)) end
local function err(m) warn("[EXE] ERR: "..tostring(m)) end

local GAMES = {
    [14890802310] = {name="Bizarre Lineage", version="V1", module="games/bizarre_lineage.lua"},
}

-- ═══════════════════════════════════════════════════════════
-- GAME DATA  (modular — add values here to expand lists)
-- ═══════════════════════════════════════════════════════════
local DATA = {}

DATA.STANDS = {
    "Any Stand",
    "Star Platinum","The World","Crazy Diamond",
    "Gold Experience","King Crimson","Sticky Fingers",
    "Purple Haze","White Snake","C-Moon",
    "Made in Heaven","Soft and Wet",
    "Tusk Act 4","D4C Love Train","Bohemian Rhapsody",
}
DATA.STAT_RANKS  = {"D","C","B","A","S"}
DATA.PERSONALITIES = {"[Personalities TBA]"}
DATA.MOBS        = {"All Mobs","[Mob names TBA]"}

DATA.BUS_STOPS = {}
for i = 1,19 do DATA.BUS_STOPS[i] = "Bus Stop "..i end

DATA.MOB_SPAWNS = {"All Mob Spawns","[Mob spawns TBA]"}

-- NPC categories (verified names)
DATA.NPC_MAIN_QUEST = {
    "Jotaro Kujo","Mr. Rengatei","Lowly Thief","Rohan Kishibe",
    "Akihiko","Aya Tsuji","Okuyasu Nijimura","Detective",
}
DATA.NPC_SIDE_QUEST = {
    "Shozuki","Tonio Trussardi","Rose","Dedequan",
    "Ancient Ghost","Gardner Gwen","Geordie Greep","Kaiser",
    "Shadowy Figure","Jean Pierre Polnareff",
    "Speedwagon Scientist","Rudol von Stroheim",
}
DATA.NPC_RAID    = {"Yoshikage Kira","Chumbo","Muhammad Avdol"}
DATA.NPC_UTILITY = {"Gym Owner","Rhett","Reina","Gupta","Saitama","Masuyo"}
DATA.NPC_FIGHT   = {"Karate Sensei"}

-- Item names (verified)
DATA.CORE_ITEMS = {
    "Stand Arrow","Stone Mask","Lucky Arrow",
    "Common Chest","Rare Chest","Legendary Chest",
    "DIO's Diary","Red Stone of Aja",
}
DATA.ESSENCE_ITEMS = {
    "Stat Point Essence","Stand Skin Essence","Stand Stat Essence",
    "Stand Personality Essence","Stand Conjuration Essence","Custom Clothing Essence",
}
DATA.CHEST_ITEMS = {"Common Chest","Rare Chest","Legendary Chest"}

-- Ground-collectable items (extend this list as confirmed)
DATA.COLLECTIBLE_ITEMS = {
    "Stand Arrow","Lucky Arrow","Stone Mask",
    "Red Stone of Aja","DIO's Diary",
}

-- Items with per-item ESP color
DATA.ESP_ITEMS = {
    "Stand Arrow","Lucky Arrow",
    "Common Chest","Rare Chest","Legendary Chest",
    "Stat Point Essence","Stand Skin Essence",
}

-- ═══════════════════════════════════════════════════════════
-- DRAW MODULE
-- ═══════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════
-- UI ENGINE
-- ═══════════════════════════════════════════════════════════
local UI = {}
do
    local SW,SH = 1920,1080
    pcall(function()
        SW=workspace.CurrentCamera.ViewportSize.X
        SH=workspace.CurrentCamera.ViewportSize.Y
    end)

    local mouse = Players.LocalPlayer:GetMouse()
    local function MX() return mouse.X end
    local function MY() return mouse.Y end
    local function LMB() return (ismouse1pressed()) end

    -- ───────────────────────────────────────────────────────
    -- KEYBIND  — full keyboard: letters, numbers, F-keys, specials
    -- ───────────────────────────────────────────────────────
    local toggleKC    = Enum.KeyCode.P
    local toggleLabel = "P"
    local bindMode    = false
    local bindLabelRef = nil

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
    }

    local function isToggleDown()
        if bindMode then return false end
        local ok,r = pcall(function() return RealUIS:IsKeyDown(toggleKC) end)
        return ok and r or false
    end
    local function scanBind()
        for _,kp in ipairs(ALL_KEYS) do
            local ok,r = pcall(function() return RealUIS:IsKeyDown(kp[1]) end)
            if ok and r then
                toggleKC=kp[1]; toggleLabel=kp[2]; bindMode=false
                if bindLabelRef then pcall(function()
                    bindLabelRef.Text  = "Toggle Key : [ "..toggleLabel.." ]"
                    bindLabelRef.Color = Color3.fromRGB(180,140,220)
                end) end
                return
            end
        end
    end

    -- ───────────────────────────────────────────────────────
    -- THEMES  (no manual color picker — themes only)
    -- ───────────────────────────────────────────────────────
    local THEMES = {
        sakura = {
            name="Sakura",
            acH=330/360, acS=0.72, acV=0.96,
            bg=Color3.fromRGB(9,7,15),     panel=Color3.fromRGB(13,11,21),
            cardBg=Color3.fromRGB(16,12,24), cardBrd=Color3.fromRGB(220,40,160),
            cardTitle=Color3.fromRGB(90,10,70), tabSel=Color3.fromRGB(50,16,42),
        },
        space = {
            name="Space",
            acH=215/360, acS=0.85, acV=1.00,
            bg=Color3.fromRGB(3,4,14),     panel=Color3.fromRGB(6,8,20),
            cardBg=Color3.fromRGB(7,11,24), cardBrd=Color3.fromRGB(30,120,255),
            cardTitle=Color3.fromRGB(8,30,85), tabSel=Color3.fromRGB(10,20,52),
        },
    }
    local curTheme = "sakura"
    local acH = THEMES.sakura.acH
    local acS = THEMES.sakura.acS
    local acV = THEMES.sakura.acV

    local function AC()  return Color3.fromHSV(acH,acS,acV) end
    local function ACL() return Color3.fromHSV(acH,acS*0.4,1.0) end
    local function TH()  return THEMES[curTheme] or THEMES.sakura end

    local function applyThemePreset(key)
        local t=THEMES[key]; if not t then return end
        curTheme=key; acH,acS,acV=t.acH,t.acS,t.acV
    end

    local function PAL()
        local t=TH()
        return {
            bg=t.bg, panel=t.panel,
            titleBg=Color3.fromRGB(6,5,11),
            tabBg=Color3.fromRGB(13,11,20),
            tabSel=t.tabSel,
            border=Color3.fromRGB(30,20,44),
            cardBg=t.cardBg, cardBrd=t.cardBrd, cardTitle=t.cardTitle,
            white=Color3.fromRGB(225,222,240),
            muted=Color3.fromRGB(128,108,148),
            dimmed=Color3.fromRGB(58,48,76),
            green=Color3.fromRGB(68,192,108),
            yellow=Color3.fromRGB(228,178,48),
            red=Color3.fromRGB(228,58,58),
            notifBg=Color3.fromRGB(8,6,16),
            chkBg=Color3.fromRGB(20,16,32),
            itemBg=Color3.fromRGB(18,14,28),
        }
    end

    -- ───────────────────────────────────────────────────────
    -- WINDOW GEOMETRY
    -- ───────────────────────────────────────────────────────
    local WW    = math.max(480,math.floor(SW/3.8))
    local WH    = math.max(540,math.floor(SH/2.1))
    local WX    = math.floor(SW/2-WW/2)
    local WY    = math.floor(SH/2-WH/2)
    local TBARH = 30
    local TABH  = 24
    local CONTY = TBARH+TABH
    local PAD   = 10

    -- ───────────────────────────────────────────────────────
    -- STATE
    -- ───────────────────────────────────────────────────────
    local uiReady   = false
    local uiVisible = true
    local activeTab = 1
    local currentTabs = {}

    local frameObjs  = {}   -- all chrome + tab content (SetVisible / Move)
    local glowLines  = {}
    local ledDot     = nil
    local cardLeds   = {}   -- {dot,x,y,w,h,phase}
    local tabBtnData = {}   -- [i]={bg,lbl,ul}
    local tabContent = {}   -- [i]=list (lazy-built once, never cleared)
    local accentObjs = {}
    local partObjs   = {}
    local starParts  = {}

    local gZones  = {}      -- global zones (tab bar, title)
    local tZones  = {}      -- [i] = per-tab zone list

    local ddObjs = {}
    local ddOpen = false

    local fT = {}
    local function FT(k)   return fT[k] or false end
    local function setFT(k,v) fT[k]=v end

    -- ESP color state
    local ESPItemColors = {}
    for _,item in ipairs(DATA.ESP_ITEMS) do
        ESPItemColors[item] = {Color3.fromRGB(255,200,60)}
    end
    local ESPMobColorRef    = {Color3.fromRGB(255,80,80)}
    local ESPPlayerColorRef = {Color3.fromRGB(80,180,255)}

    local COLOR_PRESETS = {
        Color3.fromRGB(255,80,80),  Color3.fromRGB(80,200,120),
        Color3.fromRGB(80,150,255), Color3.fromRGB(255,200,60),
        Color3.fromRGB(200,80,255), Color3.fromRGB(255,255,255),
        Color3.fromRGB(255,140,40), Color3.fromRGB(40,220,220),
    }

    local lblGame, lblVer
    local dynName = "--"
    local dynVer  = "--"

    -- forward declarations
    local buildWindow, applyTheme, destroyDD, rebuildAllUL, switchTab

    -- ───────────────────────────────────────────────────────
    -- ZONE SYSTEM
    -- ───────────────────────────────────────────────────────
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

    -- ───────────────────────────────────────────────────────
    -- ACCENT REGISTRY
    -- ───────────────────────────────────────────────────────
    local function regAC(o)  accentObjs[#accentObjs+1]={o=o,t="ac"};  return o end
    local function regACL(o) accentObjs[#accentObjs+1]={o=o,t="acl"}; return o end

    applyTheme=function()
        local ac,acl=AC(),ACL()
        for _,e in ipairs(accentObjs) do
            pcall(function() e.o.Color=(e.t=="acl") and acl or ac end)
        end
        for _,gl in ipairs(glowLines) do
            pcall(function() gl.Color=ac end)
        end
    end

    -- ───────────────────────────────────────────────────────
    -- THEME DROPDOWN
    -- ───────────────────────────────────────────────────────
    destroyDD=function()
        Draw.Destroy(ddObjs); ddOpen=false
        local keep={}
        for _,z in ipairs(gZones) do if not z._dd then keep[#keep+1]=z end end
        table.clear(gZones)
        for _,z in ipairs(keep) do gZones[#gZones+1]=z end
    end

    local function openThemeDD(bx,by)
        destroyDD(); ddOpen=true
        local DW=WW-PAD*2
        local IH=26
        local entries={
            {key="sakura",name="Sakura",dot=Color3.fromRGB(255,80,180)},
            {key="space", name="Space", dot=Color3.fromRGB(60,130,255)},
        }
        for i,e in ipairs(entries) do
            local iy=by+(i-1)*IH
            local bg=Draw.Rect(bx,iy,DW,IH,PAL().tabBg,35); bg.Visible=true; ddObjs[#ddObjs+1]=bg
            local dot=Draw.Rect(bx+7,iy+8,10,10,e.dot,36); dot.Visible=true; ddObjs[#ddObjs+1]=dot
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

    -- ═══════════════════════════════════════════════════════
    -- WIDGET LIBRARY
    -- All helpers: (objs, zFn, ...) -> nextY
    -- ═══════════════════════════════════════════════════════

    -- ── CARD (complete 4-sided border including title) ────
    local function Card(objs,zFn,bx,by,bw,title)
        local pal=PAL()
        local CP=7; local TBH=17
        local bg=Draw.Rect(bx,by,bw,0,pal.cardBg,4); objs[#objs+1]=bg
        -- 4 border lines (updated in finalize)
        local lT=Draw.Line(bx,by,bx+bw,by,pal.cardBrd,1,6); objs[#objs+1]=lT
        local lB=Draw.Line(bx,by,bx+bw,by,pal.cardBrd,1,6); objs[#objs+1]=lB
        local lL=Draw.Line(bx,by,bx,by,pal.cardBrd,1,6);    objs[#objs+1]=lL
        local lR=Draw.Line(bx+bw,by,bx+bw,by,pal.cardBrd,1,6); objs[#objs+1]=lR
        -- LED dot
        local cled=Draw.Circle(bx,by,3,pal.cardBrd,true,7)
        cled.Transparency=0.1; cled.Visible=false; objs[#objs+1]=cled
        cardLeds[#cardLeds+1]={dot=cled,x=bx,y=by,w=bw,h=0,phase=math.random()*6.28}
        -- Title bar
        local tbg=Draw.Rect(bx,by,bw,TBH,pal.cardTitle,5); objs[#objs+1]=tbg
        local tlbl=Draw.Text(bx+CP,by+3,title,pal.white,11,6); objs[#objs+1]=tlbl
        local cledRef=cled
        return {
            cx=bx+CP, cw=bw-CP*2, cy=by+TBH+CP, bx=bx, bw=bw, by=by,
            finalize=function(endY)
                local h=math.max(TBH+CP*2, endY-by+CP)
                pcall(function()
                    bg.Size=Vector2.new(bw,h)
                    lT.From=Vector2.new(bx,by);     lT.To=Vector2.new(bx+bw,by)
                    lB.From=Vector2.new(bx,by+h);   lB.To=Vector2.new(bx+bw,by+h)
                    lL.From=Vector2.new(bx,by);     lL.To=Vector2.new(bx,by+h)
                    lR.From=Vector2.new(bx+bw,by);  lR.To=Vector2.new(bx+bw,by+h)
                end)
                for _,ld in ipairs(cardLeds) do
                    if ld.dot==cledRef then ld.h=h; break end
                end
                return by+h
            end,
        }
    end

    -- ── SECTION DIVIDER ──────────────────────────────────
    local function Section(objs,cx,y,cw,label)
        local pal=PAL()
        objs[#objs+1]=Draw.Text(cx,y,"[ "..label.." ]",pal.muted,10,6)
        objs[#objs+1]=Draw.Line(cx,y+14,cx+cw,y+14,pal.border,1,5)
        return y+20
    end

    -- ── MUTED LABEL ──────────────────────────────────────
    local function Label(objs,cx,y,text)
        objs[#objs+1]=Draw.Text(cx,y,text,PAL().muted,9,6)
        return y+13
    end

    -- ── CHECKBOX ─────────────────────────────────────────
    local function Checkbox(objs,zFn,cx,y,key,label)
        local pal=PAL(); local SZ=13; local on=FT(key)
        local bg  =Draw.Rect(cx,y,SZ,SZ,pal.chkBg,7);     objs[#objs+1]=bg
        local brd =Draw.Outline(cx,y,SZ,SZ,pal.cardBrd,1,8); objs[#objs+1]=brd
        local fill=Draw.Rect(cx+1,y+1,SZ-2,SZ-2,AC(),7)
        fill.Visible=on; objs[#objs+1]=fill
        local t1=Draw.Line(cx+2,y+6, cx+5,y+10,pal.white,2,9)
        local t2=Draw.Line(cx+5,y+10,cx+11,y+3,pal.white,2,9)
        t1.Visible=on; t2.Visible=on; objs[#objs+1]=t1; objs[#objs+1]=t2
        local lbl=Draw.Text(cx+SZ+5,y+1,label,pal.white,11,7); objs[#objs+1]=lbl
        local hitW=SZ+6+math.max(80,#label*6+10)
        zFn(cx,y,hitW,SZ,function()
            local v=not FT(key); setFT(key,v); local ac2=AC()
            pcall(function()
                fill.Visible=v; fill.Color=ac2
                t1.Visible=v;   t2.Visible=v
            end)
        end)
        return y+SZ+6
    end

    -- ── DROPDOWN (inline expanding list) ─────────────────
    local function Dropdown(objs,zFn,cx,y,cw,key,items,placeholder)
        local pal=PAL(); local H=20
        local sidx=fT[key.."_sel"] or 0
        local cur=(sidx>0 and items[sidx]) or placeholder or "Select..."
        local bg =Draw.Rect(cx,y,cw,H,pal.itemBg,6);      objs[#objs+1]=bg
        local brd=Draw.Outline(cx,y,cw,H,pal.cardBrd,1,7); objs[#objs+1]=brd
        local lbl=Draw.Text(cx+6,y+4,"  "..cur,pal.white,10,7); objs[#objs+1]=lbl
        objs[#objs+1]=Draw.Text(cx+cw-14,y+4,"v",pal.muted,9,7)
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
            if listOpen then closeList(); return end
            listOpen=true
            local IH=16
            for i,item in ipairs(items) do
                local iy=y+H+(i-1)*IH
                local ibg=Draw.Rect(cx,iy,cw,IH,Color3.fromRGB(14,10,22),20); ibg.Visible=true; listObjs[#listObjs+1]=ibg
                local ibrd=Draw.Outline(cx,iy,cw,IH,pal.cardBrd,1,21); ibrd.Visible=true; listObjs[#listObjs+1]=ibrd
                local it=Draw.Text(cx+6,iy+3,tostring(item),pal.white,10,21); it.Visible=true; listObjs[#listObjs+1]=it
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

    -- ── BUTTON ───────────────────────────────────────────
    local function Button(objs,zFn,cx,y,cw,label,fn)
        local pal=PAL(); local H=22
        local bg =Draw.Rect(cx,y,cw,H,Color3.fromRGB(20,14,34),6); objs[#objs+1]=bg
        local brd=Draw.Outline(cx,y,cw,H,pal.cardBrd,1,7);         objs[#objs+1]=brd
        objs[#objs+1]=Draw.Text(cx+8,y+5,label,pal.white,11,7)
        zFn(cx,y,cw,H,fn or function() end)
        return y+H+5
    end

    -- ── SLIDER ───────────────────────────────────────────
    local function Slider(objs,zFn,cx,y,cw,key,label,minV,maxV,defV)
        local pal=PAL(); local TKH=8
        local val=fT[key.."_val"] or defV or minV
        local frac=(val-minV)/math.max(1,maxV-minV)
        local lbl=Draw.Text(cx,y,label.." : "..tostring(math.floor(val)),pal.white,10,6); objs[#objs+1]=lbl
        y=y+13
        objs[#objs+1]=Draw.Rect(cx,y+2,cw,TKH,pal.chkBg,6)
        objs[#objs+1]=Draw.Outline(cx,y+2,cw,TKH,pal.cardBrd,1,7)
        local fw=math.max(TKH,math.floor(frac*cw))
        local fill=Draw.Rect(cx,y+2,fw,TKH,AC(),7); objs[#objs+1]=fill; regAC(fill)
        local hnd=Draw.Rect(cx+math.floor(frac*cw)-4,y,8,TKH+4,pal.white,8); objs[#objs+1]=hnd
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
        return y+TKH+11
    end

    -- ── COLOR SWATCH (click-to-cycle presets) ────────────
    local function ColorSwatch(objs,zFn,cx,y,label,colorRef)
        local pal=PAL(); local SW2,SH2=20,12
        local swatch=Draw.Rect(cx,y,SW2,SH2,colorRef[1],7); objs[#objs+1]=swatch
        objs[#objs+1]=Draw.Outline(cx,y,SW2,SH2,pal.cardBrd,1,8)
        objs[#objs+1]=Draw.Text(cx+SW2+5,y+1,label,pal.muted,9,7)
        local ci=1
        zFn(cx,y,SW2+5+math.max(60,#label*7),SH2,function()
            ci=ci%#COLOR_PRESETS+1
            colorRef[1]=COLOR_PRESETS[ci]
            pcall(function() swatch.Color=COLOR_PRESETS[ci] end)
        end)
        return y+SH2+5
    end

    -- ═══════════════════════════════════════════════════════
    -- CONTEXT FACTORY
    -- ═══════════════════════════════════════════════════════
    local function makeCtx(tabIdx)
        local objs=tabContent[tabIdx]
        local function zFn(x,y,w,h,fn) addTZ(tabIdx,x,y,w,h,fn) end
        local cx0=WX+PAD; local cy0=WY+CONTY+PAD; local cw0=WW-PAD*2
        return {
            cx=cx0, cy=cy0, cw=cw0, objs=objs, D=Draw, C=PAL(), PAD=PAD,
            Card     =function(bx,by,bw,t)           return Card(objs,zFn,bx,by,bw,t) end,
            Section  =function(bx,by,bw,t)           return Section(objs,bx,by,bw,t) end,
            Label    =function(bx,by,t)              return Label(objs,bx,by,t) end,
            Checkbox =function(bx,by,k,l)            return Checkbox(objs,zFn,bx,by,k,l) end,
            Dropdown =function(bx,by,bw,k,items,ph) return Dropdown(objs,zFn,bx,by,bw,k,items,ph) end,
            Button   =function(bx,by,bw,l,f)         return Button(objs,zFn,bx,by,bw,l,f) end,
            Slider   =function(bx,by,bw,k,l,mn,mx2,d) return Slider(objs,zFn,bx,by,bw,k,l,mn,mx2,d) end,
            ColorSwatch=function(bx,by,l,ref)        return ColorSwatch(objs,zFn,bx,by,l,ref) end,
            Zone=zFn, GZone=addGZ, RegAC=regAC, RegACL=regACL,
            FT=FT, setFT=setFT,
            WX=function()return WX end, WY=function()return WY end,
            WW=WW, WH=WH, CONTY=CONTY,
            dynName=function()return dynName end,
            dynVer=function()return dynVer end,
            DATA=DATA, AC=AC, ACL=ACL, PAL=PAL, TH=TH,
            openThemeDD=openThemeDD,
            ddOpen=function()return ddOpen end,
            destroyDD=destroyDD,
        }
    end

    -- ═══════════════════════════════════════════════════════
    -- REBUILD TAB UNDERLINES
    -- ═══════════════════════════════════════════════════════
    rebuildAllUL=function()
        local ac=AC()
        for i,bd in pairs(tabBtnData) do pcall(function()
            local sel=(i==activeTab)
            bd.ul.Color=ac; bd.ul.Visible=sel
            bd.lbl.Color=sel and ACL() or PAL().muted
            bd.bg.Color=sel and PAL().tabSel or PAL().tabBg
        end) end
    end

    -- ═══════════════════════════════════════════════════════
    -- SWITCH TAB
    -- ═══════════════════════════════════════════════════════
    switchTab=function(idx)
        if not currentTabs[idx] then return end
        if tabContent[activeTab] then
            Draw.SetVisible(tabContent[activeTab],false)
        end
        activeTab=idx; destroyDD()
        if not tabContent[activeTab] then
            tabContent[activeTab]={}; tZones[activeTab]={}
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

    -- ═══════════════════════════════════════════════════════
    -- BUILD WINDOW CHROME
    -- ═══════════════════════════════════════════════════════
    buildWindow=function()
        destroyDD()
        table.clear(cardLeds)
        for _,o in ipairs(frameObjs) do pcall(function() o:Remove() end) end
        table.clear(frameObjs)
        table.clear(glowLines); table.clear(tabBtnData); table.clear(accentObjs)
        for _,tc in pairs(tabContent) do
            for _,o in ipairs(tc) do pcall(function() o:Remove() end) end
        end
        table.clear(tabContent); clearAllZones()
        bindLabelRef=nil
        if ledDot then pcall(function() ledDot:Remove() end); ledDot=nil end

        local pal=PAL(); local ac=AC()
        local x,y=WX,WY

        -- window bg
        frameObjs[#frameObjs+1]=Draw.Rect(x,y,WW,WH,pal.bg,1)
        -- title bar
        frameObjs[#frameObjs+1]=Draw.Rect(x,y,WW,TBARH,pal.titleBg,2)
        local hl=regACL(Draw.Text(x+PAD,y+8,"EXE.HUB",ACL(),14,5)); frameObjs[#frameObjs+1]=hl
        frameObjs[#frameObjs+1]=Draw.Line(x+90,y+5,x+90,y+TBARH-5,pal.border,1,4)
        lblGame=Draw.Text(x+96,y+8,dynName,pal.muted,10,5); frameObjs[#frameObjs+1]=lblGame
        lblVer =Draw.Text(x+WW-60,y+9,dynVer,pal.dimmed,9,5); frameObjs[#frameObjs+1]=lblVer
        frameObjs[#frameObjs+1]=Draw.Line(x,y+TBARH,x+WW,y+TBARH,pal.border,1,3)

        -- tab bar
        local nT=#currentTabs; local tabW=math.floor(WW/math.max(nT,1)); local tabY=y+TBARH
        for i,tab in ipairs(currentTabs) do
            local tx=x+(i-1)*tabW; local sel=(i==activeTab)
            local tbg=Draw.Rect(tx,tabY,tabW,TABH,sel and pal.tabSel or pal.tabBg,2); frameObjs[#frameObjs+1]=tbg
            if i>1 then frameObjs[#frameObjs+1]=Draw.Line(tx,tabY+3,tx,tabY+TABH-3,pal.border,1,3) end
            local lx=tx+math.floor(tabW/2)-math.floor(#tab.name*2.9)
            local tlbl=Draw.Text(lx,tabY+6,tab.name,sel and ACL() or pal.muted,10,4)
            if sel then regACL(tlbl) end; frameObjs[#frameObjs+1]=tlbl
            local tul=Draw.Line(tx+3,tabY+TABH-1,tx+tabW-3,tabY+TABH-1,ac,2,4)
            tul.Visible=sel; frameObjs[#frameObjs+1]=tul
            tabBtnData[i]={bg=tbg,lbl=tlbl,ul=tul}
            local ci=i; addGZ(tx,tabY,tabW,TABH,function() switchTab(ci) end)
        end

        -- content area
        frameObjs[#frameObjs+1]=Draw.Line(x,y+CONTY,x+WW,y+CONTY,pal.border,1,3)
        frameObjs[#frameObjs+1]=Draw.Rect(x,y+CONTY,WW,WH-CONTY,pal.panel,1)
        frameObjs[#frameObjs+1]=Draw.Outline(x,y,WW,WH,pal.border,1,3)

        -- glow lines
        local function glow(x1,y1,x2,y2)
            local l=Draw.Line(x1,y1,x2,y2,ac,1.5,4); l.Transparency=0.84
            frameObjs[#frameObjs+1]=l; glowLines[#glowLines+1]=l
        end
        glow(x,y,x+WW,y); glow(x+WW,y,x+WW,y+WH); glow(x+WW,y+WH,x,y+WH); glow(x,y+WH,x,y)

        -- window LED dot
        ledDot=Drawing.new("Circle")
        ledDot.Radius=5; ledDot.Color=ac; ledDot.Filled=true
        ledDot.Transparency=0.1; ledDot.ZIndex=8; ledDot.Visible=false
        frameObjs[#frameObjs+1]=ledDot

        -- build active tab
        tabContent[activeTab]={}; tZones[activeTab]={}
        local tab=currentTabs[activeTab]
        if tab and type(tab.buildFn)=="function" then
            local ctx=makeCtx(activeTab)
            pcall(function() tab.buildFn(ctx) end)
            for _,o in ipairs(tabContent[activeTab]) do frameObjs[#frameObjs+1]=o end
        end
    end

    -- ═══════════════════════════════════════════════════════
    -- TAB: MAIN
    -- ═══════════════════════════════════════════════════════
    local function buildMain(ctx)
        local o,D,pal=ctx.objs,ctx.D,ctx.C
        local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
        local h2=math.floor((cw-6)/2)
        local sy=cy

        -- ┌─ AUTO FARM MOB ──────────────────────────────────┐
        local af=ctx.Card(cx,sy,h2,"AUTO FARM MOB")
        local ay=af.cy
        ay=ctx.Label(af.cx,ay,"Mob Selection :")
        ay=ctx.Dropdown(af.cx,ay,af.cw,"mob_sel",DATA.MOBS,"All Mobs")
        ay=ay+3
        ay=ctx.Checkbox(af.cx,ay,"farmActivateStand","Auto Activate Stand")
        ay=ctx.Checkbox(af.cx,ay,"farmKillStand","Auto Kill Stand")
        ay=ay+3
        ay=ctx.Label(af.cx,ay,"Position Method :")
        ay=ctx.Dropdown(af.cx,ay,af.cw,"farm_method",{"Above","Below"},"Above")
        ay=ctx.Slider(af.cx,ay,af.cw,"farmOffY","Offset Y",-50,50,0)
        sy=af.finalize(ay)+8

        -- ┌─ AUTO MEDITATE ──────────────────────────────────┐
        local md=ctx.Card(cx+h2+6,af.by,h2,"AUTO MEDITATE")
        local my=md.cy
        my=ctx.Label(md.cx,my,"Meditate automatically")
        my=ctx.Checkbox(md.cx,my,"autoMeditate","Auto Meditate")
        local mEnd=md.finalize(my)+8
        sy=math.max(sy,mEnd)

        -- ┌─ ESP ────────────────────────────────────────────┐
        local ec=ctx.Card(cx,sy,cw,"ESP")
        local ey=ec.cy
        local c3=math.floor((ec.cw-8)/3)

        -- Mob ESP column
        o[#o+1]=D.Text(ec.cx,ey,"MOB ESP",pal.muted,9,6)
        local ey_mob=ey+12
        ey_mob=ctx.Checkbox(ec.cx,ey_mob,"espMobOn","Enable")
        ey_mob=ctx.ColorSwatch(ec.cx,ey_mob,"Mob Color",ESPMobColorRef)

        -- Player ESP column
        local pcx=ec.cx+c3+4
        o[#o+1]=D.Text(pcx,ey,"PLAYER ESP",pal.muted,9,6)
        local ey_pl=ey+12
        ey_pl=Checkbox(o,ctx.Zone,pcx,ey_pl,"espPlayerOn","Enable")
        ey_pl=ColorSwatch(o,ctx.Zone,pcx,ey_pl,"Player Color",ESPPlayerColorRef)

        -- Item ESP column
        local icx=ec.cx+c3*2+8
        o[#o+1]=D.Text(icx,ey,"ITEM ESP",pal.muted,9,6)
        local ey_it=ey+12
        ey_it=Checkbox(o,ctx.Zone,icx,ey_it,"espItemOn","Enable")
        for _,item in ipairs(DATA.ESP_ITEMS) do
            local ref=ESPItemColors[item]
            local short=item:match("^(.-)%s") or item:sub(1,10)
            ey_it=ColorSwatch(o,ctx.Zone,icx,ey_it,short,ref)
        end

        local ey_all=math.max(ey_mob,ey_pl,ey_it)
        ec.finalize(ey_all); sy=ey_all+10

        -- ┌─ STATUS ─────────────────────────────────────────┐
        local stc=ctx.Card(cx,sy,cw,"STATUS")
        local sty=stc.cy
        o[#o+1]=D.Text(stc.cx,sty,"Game :",pal.muted,10,6)
        o[#o+1]=D.Text(stc.cx+46,sty,ctx.dynName(),pal.white,11,6); sty=sty+16
        o[#o+1]=D.Text(stc.cx,sty,"Version :",pal.muted,10,6)
        o[#o+1]=D.Text(stc.cx+54,sty,ctx.dynVer(),pal.white,11,6)
        stc.finalize(sty+8)
    end

    -- ═══════════════════════════════════════════════════════
    -- TAB: ITEMS
    -- ═══════════════════════════════════════════════════════
    local function buildItems(ctx)
        local o,D,pal=ctx.objs,ctx.D,ctx.C
        local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
        local sy=cy

        -- ┌─ ITEM SELECTION ─────────────────────────────────┐
        local allItems={}
        for _,v in ipairs(DATA.CORE_ITEMS)    do allItems[#allItems+1]=v end
        for _,v in ipairs(DATA.ESSENCE_ITEMS) do allItems[#allItems+1]=v end

        local isc=ctx.Card(cx,sy,cw,"ITEM SELECTION")
        local iy=isc.cy
        iy=ctx.Label(isc.cx,iy,"Select item to manage :")
        iy=ctx.Dropdown(isc.cx,iy,isc.cw,"item_sel",allItems,"All Items")
        sy=isc.finalize(iy)+8

        -- ┌─ AUTO COLLECT ITEM ──────────────────────────────┐
        local acc=ctx.Card(cx,sy,cw,"AUTO COLLECT ITEM")
        local ay=acc.cy
        ay=ctx.Label(acc.cx,ay,"Teleports to world items and auto-collects them.")
        ay=ctx.Label(acc.cx,ay,"Only ground-spawn items:")
        ay=ay+2
        for _,item in ipairs(DATA.COLLECTIBLE_ITEMS) do
            local k="collect_"..item:lower():gsub("[^%a%d]","_")
            ay=ctx.Checkbox(acc.cx,ay,k,item)
        end
        sy=acc.finalize(ay)+8

        -- ┌─ AUTO USE (one big box, three sections) ─────────┐
        local auc=ctx.Card(cx,sy,cw,"AUTO USE")
        local uy=auc.cy

        -- §§ AUTO ARROW
        uy=ctx.Section(auc.cx,uy,auc.cw,"Auto Arrow")
        uy=ctx.Label(auc.cx,uy,"Arrow type :")
        uy=ctx.Dropdown(auc.cx,uy,auc.cw,"arrow_type",{"Stand Arrow","Lucky Arrow"},"Stand Arrow")
        uy=ctx.Label(auc.cx,uy,"Target Stand :")
        uy=ctx.Dropdown(auc.cx,uy,auc.cw,"arrow_stand",DATA.STANDS,"Any Stand")
        uy=ctx.Checkbox(auc.cx,uy,"arrowAutoSpin","Auto Spin (repeat until target)")
        uy=ctx.Checkbox(auc.cx,uy,"arrowStopSkin","Stop if Stand Skin obtained")
        uy=uy+3
        -- Stat filter
        uy=ctx.Label(auc.cx,uy,"Stop when Stand stats >=")
        local sw3=math.floor((auc.cw-8)/3)
        o[#o+1]=D.Text(auc.cx,uy,"STR",pal.dimmed,8,6)
        o[#o+1]=D.Text(auc.cx+sw3+4,uy,"SPD",pal.dimmed,8,6)
        o[#o+1]=D.Text(auc.cx+sw3*2+8,uy,"SPEC",pal.dimmed,8,6)
        uy=uy+11
        local row_start=uy
        uy=ctx.Dropdown(auc.cx,        uy,    sw3,"req_str", DATA.STAT_RANKS,"D")
        Dropdown(o,ctx.Zone,auc.cx+sw3+4,   row_start,sw3,"req_spd", DATA.STAT_RANKS,"D")
        Dropdown(o,ctx.Zone,auc.cx+sw3*2+8, row_start,sw3,"req_spec",DATA.STAT_RANKS,"D")
        uy=uy+4
        -- Personality filter
        uy=ctx.Label(auc.cx,uy,"Search Personality :")
        uy=ctx.Dropdown(auc.cx,uy,auc.cw,"req_pers",DATA.PERSONALITIES,"Any")
        uy=uy+8

        -- §§ AUTO CHEST
        uy=ctx.Section(auc.cx,uy,auc.cw,"Auto Chest")
        for _,chest in ipairs(DATA.CHEST_ITEMS) do
            local k="autoChest_"..chest:lower():gsub("[^%a%d]","_")
            uy=ctx.Checkbox(auc.cx,uy,k,chest)
        end
        uy=uy+8

        -- §§ AUTO USE ESSENCE
        uy=ctx.Section(auc.cx,uy,auc.cw,"Auto Use Essence")
        for _,ess in ipairs(DATA.ESSENCE_ITEMS) do
            local k="autoEss_"..ess:lower():gsub("[^%a%d]","_")
            uy=ctx.Checkbox(auc.cx,uy,k,ess)
        end
        uy=uy+6

        auc.finalize(uy)
    end

    -- ═══════════════════════════════════════════════════════
    -- TAB: TELEPORT
    -- ═══════════════════════════════════════════════════════
    local function buildTeleport(ctx)
        local o,D,pal=ctx.objs,ctx.D,ctx.C
        local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
        local sy=cy

        -- ┌─ BUS STOPS ──────────────────────────────────────┐
        local bsC=ctx.Card(cx,sy,cw,"BUS STOPS")
        local by=bsC.cy
        by=ctx.Label(bsC.cx,by,"Select bus stop (1-19) :")
        by=ctx.Dropdown(bsC.cx,by,bsC.cw,"tp_bus",DATA.BUS_STOPS,"Bus Stop 1")
        by=ctx.Button(bsC.cx,by,bsC.cw,"Teleport to Bus Stop",function()
            local idx=fT["tp_bus_sel"] or 1
            log("TP -> "..tostring(DATA.BUS_STOPS[idx]))
        end)
        sy=bsC.finalize(by)+8

        -- ┌─ MOB SPAWN ──────────────────────────────────────┐
        local msC=ctx.Card(cx,sy,cw,"MOB SPAWN")
        local my=msC.cy
        my=ctx.Label(msC.cx,my,"Select mob spawn area :")
        my=ctx.Dropdown(msC.cx,my,msC.cw,"tp_mob",DATA.MOB_SPAWNS,"Select mob")
        my=ctx.Button(msC.cx,my,msC.cw,"Teleport to Mob Spawn",function()
            local idx=fT["tp_mob_sel"] or 1
            log("TP -> "..tostring(DATA.MOB_SPAWNS[idx]))
        end)
        sy=msC.finalize(my)+8

        -- ┌─ NPC TELEPORT ───────────────────────────────────┐
        local npC=ctx.Card(cx,sy,cw,"NPC TELEPORT")
        local ny=npC.cy

        -- Helper to create one NPC category
        local function npcSection(key,items,sectionLabel)
            ny=ctx.Section(npC.cx,ny,npC.cw,sectionLabel)
            ny=ctx.Dropdown(npC.cx,ny,npC.cw,"tp_"..key,items,"Select NPC")
            ny=ctx.Button(npC.cx,ny,npC.cw,"Teleport",function()
                local idx=fT["tp_"..key.."_sel"] or 1
                log("TP NPC -> "..tostring(items[idx]))
            end)
            ny=ny+5
        end

        npcSection("mq",   DATA.NPC_MAIN_QUEST, "Main Quest NPCs")
        npcSection("sq",   DATA.NPC_SIDE_QUEST, "Side Quest NPCs")
        npcSection("raid", DATA.NPC_RAID,        "Raid NPCs")
        npcSection("util", DATA.NPC_UTILITY,     "Utility NPCs")
        npcSection("fight",DATA.NPC_FIGHT,       "Fighting Style NPCs")

        npC.finalize(ny)
    end

    -- ═══════════════════════════════════════════════════════
    -- TAB: SETTINGS
    -- ═══════════════════════════════════════════════════════
    local function buildSettings(ctx)
        local o,D,pal=ctx.objs,ctx.D,ctx.C
        local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
        local sy=cy

        -- ┌─ THEME ──────────────────────────────────────────┐
        local thC=ctx.Card(cx,sy,cw,"THEME")
        local ty=thC.cy
        local swH=22
        local sw=Draw.Rect(thC.cx,ty,thC.cw,swH,AC(),5); regAC(sw); o[#o+1]=sw
        o[#o+1]=D.Text(thC.cx+7,ty+5,"  Theme : "..ctx.TH().name,Color3.fromRGB(8,8,8),11,6)
        ctx.Zone(thC.cx,ty,thC.cw,swH,function()
            if ctx.ddOpen() then ctx.destroyDD() else ctx.openThemeDD(thC.cx,ty+swH+2) end
        end)
        ty=ty+swH+6; thC.finalize(ty); sy=ty+10

        -- ┌─ TOGGLE KEY ─────────────────────────────────────┐
        local tkC=ctx.Card(cx,sy,cw,"TOGGLE KEY")
        local ky=tkC.cy
        local bh=26
        o[#o+1]=D.Rect(tkC.cx,ky,tkC.cw,bh,pal.itemBg,5)
        o[#o+1]=D.Outline(tkC.cx,ky,tkC.cw,bh,pal.cardBrd,1,6)
        local klbl=D.Text(tkC.cx+8,ky+7,"Toggle Key : [ "..toggleLabel.." ]",
            Color3.fromRGB(180,140,220),12,6); o[#o+1]=klbl; bindLabelRef=klbl
        ky=ky+bh+4
        o[#o+1]=D.Text(tkC.cx,ky,"Click box then press any key to rebind",pal.dimmed,8,6)
        ky=ky+13
        ctx.Zone(tkC.cx,ky-bh-17,tkC.cw,bh,function()
            if bindMode then
                bindMode=false
                pcall(function()
                    klbl.Text="Toggle Key : [ "..toggleLabel.." ]"
                    klbl.Color=Color3.fromRGB(180,140,220)
                end)
            else
                bindMode=true
                pcall(function()
                    klbl.Text="Waiting for key..."
                    klbl.Color=Color3.fromRGB(235,185,55)
                end)
            end
        end)
        tkC.finalize(ky)
    end

    -- ═══════════════════════════════════════════════════════
    -- TAB: CREDITS
    -- ═══════════════════════════════════════════════════════
    local function buildCredits(ctx)
        local o,D,pal=ctx.objs,ctx.D,ctx.C
        local cr=ctx.Card(ctx.cx,ctx.cy,ctx.cw,"CREDITS")
        local ry=cr.cy
        o[#o+1]=D.Text(cr.cx,ry,"Creator : MaTub",pal.white,13,6);               ry=ry+20
        o[#o+1]=D.Text(cr.cx,ry,"EXE.HUB - Roblox Script Hub",pal.muted,11,6);   ry=ry+16
        o[#o+1]=D.Text(cr.cx,ry,"github.com/mattheube/EXE.HUB",pal.dimmed,10,6); ry=ry+6
        cr.finalize(ry+10)
    end

    -- ═══════════════════════════════════════════════════════
    -- TAB: LOGS
    -- ═══════════════════════════════════════════════════════
    local function buildLogs(ctx)
        local o,D,pal=ctx.objs,ctx.D,ctx.C
        local lg=ctx.Card(ctx.cx,ctx.cy,ctx.cw,"HUB UPDATES")
        local ly=lg.cy
        local lines={
            "V1 - Initial release of the hub.",
            "All future updates will be listed here.",
        }
        for _,ln in ipairs(lines) do
            o[#o+1]=D.Text(lg.cx,ly,ln,pal.white,11,6); ly=ly+16
        end
        lg.finalize(ly+4)
    end

    -- ═══════════════════════════════════════════════════════
    -- TAB REGISTRY
    -- ═══════════════════════════════════════════════════════
    local function makeDefaultTabs()
        currentTabs={
            {name="Main",     buildFn=buildMain},
            {name="Items",    buildFn=buildItems},
            {name="Teleport", buildFn=buildTeleport},
            {name="Settings", buildFn=buildSettings},
            {name="Credits",  buildFn=buildCredits},
            {name="Logs",     buildFn=buildLogs},
        }
    end

    -- ═══════════════════════════════════════════════════════
    -- LED BORDER LOOP
    -- ═══════════════════════════════════════════════════════
    task.spawn(function()
        local t=0; local perim=2*(WW+WH)
        while true do
            task.wait(0.033); if not uiReady or not uiVisible then continue end
            t=(t+3)%perim
            local px,py
            if t<WW then
                px=WX+t;            py=WY
            elseif t<WW+WH then
                px=WX+WW;           py=WY+(t-WW)
            elseif t<WW*2+WH then
                px=WX+WW-(t-WW-WH); py=WY+WH
            else
                px=WX;              py=WY+WH-(t-WW*2-WH)
            end
            if ledDot then pcall(function()
                ledDot.Position=Vector2.new(px,py); ledDot.Color=AC()
                local p2=0.5+0.5*math.sin(t*0.04)
                ledDot.Radius=3+p2*3; ledDot.Visible=uiVisible
            end) end
            for _,gl in ipairs(glowLines) do pcall(function() gl.Transparency=0.85; gl.Color=AC() end) end
            for _,ld in ipairs(cardLeds) do
                if ld.h>0 then pcall(function()
                    local cp=2*(ld.w+ld.h)
                    local ct=((t*0.55)+ld.phase*cp)%cp
                    local dpx,dpy
                    if ct<ld.w then         dpx=ld.x+ct;              dpy=ld.y
                    elseif ct<ld.w+ld.h then dpx=ld.x+ld.w;          dpy=ld.y+(ct-ld.w)
                    elseif ct<ld.w*2+ld.h then dpx=ld.x+ld.w-(ct-ld.w-ld.h); dpy=ld.y+ld.h
                    else         dpx=ld.x;  dpy=ld.y+ld.h-(ct-ld.w*2-ld.h) end
                    ld.dot.Position=Vector2.new(dpx,dpy); ld.dot.Color=AC(); ld.dot.Visible=uiVisible
                end) end
            end
        end
    end)

    -- ═══════════════════════════════════════════════════════
    -- SAKURA PETALS
    -- ═══════════════════════════════════════════════════════
    local PMAX=42; local pCount=0
    local function spawnPetal()
        if pCount>=PMAX or not uiReady then return end; pCount=pCount+1
        local sz=math.random(2,7)
        local p=Drawing.new("Circle")
        p.Position=Vector2.new(WX+math.random(sz,WW-sz),WY+CONTY+sz)
        p.Radius=sz; p.Color=Color3.fromHSV(acH,acS*0.55,1.0); p.Filled=true
        p.Transparency=math.random(14,48)/100; p.ZIndex=2; p.Visible=false
        partObjs[#partObjs+1]=p
        local steps=math.random(55,140); local dy=(WY+WH-2-(WY+CONTY))/steps
        local ph=math.random()*6.28; local amp=math.random(3,10)
        local dA=(p.Transparency-0.97)/steps; local drift=math.random(-8,8)/steps
        task.spawn(function()
            for s=1,steps do task.wait(0.05); if not uiReady then break end
                pcall(function()
                    p.Visible=uiVisible and (curTheme=="sakura")
                    p.Color=Color3.fromHSV(acH,acS*0.55,1.0)
                    p.Position=Vector2.new(p.Position.X+drift+math.sin(ph+s*0.13)*amp/steps,p.Position.Y+dy)
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
            task.wait(0.35+math.random()*0.4)
            if uiReady and curTheme=="sakura" then
                pcall(spawnPetal)
                if math.random()<0.65 then task.wait(0.1); pcall(spawnPetal) end
                if math.random()<0.3  then task.wait(0.1); pcall(spawnPetal) end
            end
        end
    end)

    -- ═══════════════════════════════════════════════════════
    -- SPACE STARS  (4-arm sparkle shape, not dots)
    -- ═══════════════════════════════════════════════════════
    local SMAX=38
    local STAR_ARMS={
        {-1,0,   1,0  },           -- horizontal
        { 0,-1,  0,1  },           -- vertical
        {-0.65,-0.65, 0.65, 0.65}, -- diagonal /
        { 0.65,-0.65,-0.65, 0.65}, -- diagonal \
    }
    local function buildStars()
        for _,s in ipairs(starParts) do
            for _,l in ipairs(s.lines) do pcall(function() l:Remove() end) end
        end
        table.clear(starParts)
        if curTheme~="space" then return end
        for _=1,SMAX do
            local sx=WX+math.random(6,WW-6)
            local sy=WY+CONTY+math.random(6,WH-CONTY-6)
            local sz=math.random(3,7)
            local lines={}
            for _,arm in ipairs(STAR_ARMS) do
                local l=Drawing.new("Line")
                l.From=Vector2.new(sx+arm[1]*sz,sy+arm[2]*sz)
                l.To  =Vector2.new(sx+arm[3]*sz,sy+arm[4]*sz)
                l.Color=Color3.fromHSV(acH,acS*0.5,0.9); l.Thickness=1.2
                l.Transparency=0.35; l.ZIndex=2; l.Visible=false
                lines[#lines+1]=l
            end
            starParts[#starParts+1]={
                lines=lines, ox=sx, oy=sy, sz=sz,
                phase=math.random()*6.28, speed=0.4+math.random()*1.2,
            }
        end
    end
    task.spawn(function()
        local t=0
        while true do task.wait(0.05); t=t+0.05
            local isSp=(curTheme=="space")
            for _,s in ipairs(starParts) do pcall(function()
                local pulse=0.5+0.5*math.sin(t*s.speed+s.phase)
                local col=Color3.fromHSV(acH,acS*(0.25+0.45*pulse),0.75+0.25*pulse)
                local sc=s.sz*(0.5+0.8*pulse)
                local tr=0.05+0.5*(1-pulse)
                local ox=s.ox+math.sin(t*0.35+s.phase)*2.5
                local oy=s.oy+math.cos(t*0.28+s.phase)*1.8
                for i,l in ipairs(s.lines) do
                    l.Visible=uiVisible and isSp; l.Color=col; l.Transparency=tr
                    local arm=STAR_ARMS[i]
                    l.From=Vector2.new(ox+arm[1]*sc,oy+arm[2]*sc)
                    l.To  =Vector2.new(ox+arm[3]*sc,oy+arm[4]*sc)
                end
            end) end
        end
    end)

    -- ═══════════════════════════════════════════════════════
    -- NOTIFICATIONS
    -- ═══════════════════════════════════════════════════════
    local NW=math.max(220,math.floor(SW/6.2)); local NH=62
    local NXf=SW-NW-14; local NYf=68; local NDUR=9
    local nQ={}; local nBusy=false
    local function showNextNotif()
        if nBusy or #nQ==0 then return end; nBusy=true
        local n=table.remove(nQ,1); local obs={}; local sy=SH+10; local pal=PAL()
        local function aO(o2) obs[#obs+1]=o2 end
        aO(Draw.Rect(NXf,sy,NW,NH,pal.notifBg,50))
        aO(Draw.Outline(NXf,sy,NW,NH,n.col,1.5,51))
        aO(Draw.Rect(NXf+4,sy+5,3,NH-10,n.col,51))
        aO(Draw.Text(NXf+13,sy+11,n.title,pal.white,13,52))
        aO(Draw.Text(NXf+13,sy+28,n.msg,pal.muted,10,52))
        local sp={}
        for _=1,4 do
            local s2=Draw.Rect(NXf+math.random(8,NW-8),sy+math.random(4,NH-4),2,2,n.col,53)
            aO(s2); sp[#sp+1]={o=s2,ox=0,oy=0,t2=math.random()*6.28}
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
            for i=1,20 do task.wait(0.025); setNY(sy+(NYf-sy)*(1-(1-i/20)^3)) end; setNY(NYf)
            for _,s2 in ipairs(sp) do s2.ox=s2.o.Position.X; s2.oy=s2.o.Position.Y end
            local el=0
            while el<NDUR do task.wait(0.05); el=el+0.05
                for _,s2 in ipairs(sp) do pcall(function()
                    s2.o.Position=Vector2.new(s2.ox+math.sin(el*2+s2.t2)*4,s2.oy+math.cos(el*1.4+s2.t2)*2)
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
    local function notify(title,msg,col) nQ[#nQ+1]={title=title,msg=msg,col=col}; showNextNotif() end

    -- ═══════════════════════════════════════════════════════
    -- INPUT LOOP
    -- ═══════════════════════════════════════════════════════
    task.spawn(function()
        local prevLMB=false; local prevTog=false
        local dragOn=false; local dRelX,dRelY=0,0
        while true do
            task.wait(0.033); if not uiReady then continue end
            local mx,my=MX(),MY(); local lmb=LMB(); local togNow=isToggleDown()

            if bindMode then scanBind() end

            -- Toggle visibility
            if togNow and not prevTog and not bindMode then
                uiVisible=not uiVisible
                -- Full pass (fixes reopen overlap/duplication bug)
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

            -- Drag (title bar)
            if dragOn then
                if lmb then
                    local dx=math.floor((mx-dRelX-WX)*0.7)
                    local dy=math.floor((my-dRelY-WY)*0.7)
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

    -- ═══════════════════════════════════════════════════════
    -- PUBLIC API
    -- ═══════════════════════════════════════════════════════
    function UI.Init()
        task.spawn(function()
            makeDefaultTabs(); buildWindow(); buildStars()
            Draw.SetVisible(frameObjs,true); uiReady=true; uiVisible=true
            if UI._onReady then UI._onReady() end
        end)
    end
    local _dQ={}
    UI._onReady=function() UI._onReady=nil; for _,f in ipairs(_dQ) do pcall(f) end; table.clear(_dQ) end
    local function defer(fn) if uiReady then pcall(fn) else _dQ[#_dQ+1]=fn end end

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
                buildWindow(); buildStars(); Draw.SetVisible(frameObjs,uiVisible)
            end
        end)
    end
    local function nCol(tp) local p=PAL()
        if tp=="success" then return p.green elseif tp=="warning" then return p.yellow
        elseif tp=="error" then return p.red end; return AC() end
    function UI.ShowWelcome()       defer(function() notify("EXE.HUB","Hub active - V1",AC()) end) end
    function UI.ShowGameDetected(n) defer(function() notify("Game Detected",n,PAL().green) end) end
    function UI.ShowGameLoaded(n,v)
        dynName=n or dynName; dynVer=v or dynVer
        defer(function()
            if lblGame then pcall(function() lblGame.Text=dynName end) end
            if lblVer  then pcall(function() lblVer.Text=dynVer   end) end
        end)
    end
    function UI.ShowNotSupported(id) defer(function() notify("Not Supported","PlaceId: "..tostring(id),PAL().yellow) end) end
    function UI.ShowLoadError(n)     defer(function() notify("Load Error",tostring(n),PAL().red) end) end
    function UI.Notify(t2,m,tp)      defer(function() notify(t2,m,nCol(tp)) end) end
    function UI.Destroy()
        uiReady=false; Draw.DestroyAll()
        table.clear(frameObjs); table.clear(glowLines); table.clear(accentObjs)
        table.clear(partObjs); table.clear(starParts); clearAllZones()
    end
end

-- ═══════════════════════════════════════════════════════════
-- MODULE LOADER
-- ═══════════════════════════════════════════════════════════
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
    err("NIL: "..path); return nil
end
local function loadGame(info)
    if not info then return end; UI.ShowGameDetected(info.name)
    local gm=loadModule(info.module)
    if not gm then UI.ShowLoadError(info.name); return end
    gm.Name=gm.Name or info.name; gm.Version=gm.Version or info.version
    if type(gm.Init)=="function" then
        local ok,e=pcall(function() gm.Init({UI=UI,log=log,err=err}) end)
        if not ok then UI.ShowLoadError(info.name); err(tostring(e)); return end
    end
    UI.ShowGameLoaded(gm.Name,gm.Version); UI.LoadGameModule(gm)
end

-- ═══════════════════════════════════════════════════════════
-- LAUNCH
-- ═══════════════════════════════════════════════════════════
UI.Init(); UI.ShowWelcome()
local pId=game.PlaceId
if GAMES[pId] then loadGame(GAMES[pId]) else UI.ShowNotSupported(pId) end