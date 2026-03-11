-- ╔══════════════════════════════════════════════════════════╗
-- ║         EXE.HUB  v4.0  —  Drawing API  (Matcha)        ║
-- ╚══════════════════════════════════════════════════════════╝
-- Engine  : task.spawn + task.wait  (Heartbeat dead on Matcha)
-- LMB     : ismouse1pressed() polling + rising edge detection
-- Toggle  : RealUIS:IsKeyDown(), default = P
-- v4.0 fixes:
--   UL      : rebuilt every switchTab, always correct
--   Reopen  : full SetVisible pass on every toggle, no stale refs
--   Input   : hitTest returns true → sink click, game won't see it
--   LED     : moving glow dot along window border + card borders
--   Themes  : Sakura (pink) / Space (blue), cards follow theme
--   Petals  : 40 max, always visible, drift naturally
--   Stars   : 35 max, float/glow/twinkle in place (no falling)
--   Dropdown: closes on outside click, no ? marks in text
--   Cards   : theme-colored borders rebuilt on theme switch
--   Scrollable content area per tab

local BASE = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"
local RealUIS = game:GetService("UserInputService")

local function log(m) print("[EXE] "..tostring(m)) end
local function err(m) warn("[EXE] ER..:"..tostring(m)) end

local GAMES = {
    [14890802310]={name="Bizarre Lineage",version="v1.0.0",module="games/bizarre_lineage.lua"},
}

-- ══════════════════════════════════════════════════════════
-- DRAW
-- ══════════════════════════════════════════════════════════
local Draw={}
do
    local pool={}
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
        o.Color=col o.Filled=false o.Thickness=thick or 1
        o.Transparency=1 o.ZIndex=z or 2 o.Visible=false
        return o
    end
    function Draw.Text(x,y,str,col,sz,z)
        local o=reg(Drawing.new("Text"))
        o.Position=Vector2.new(x,y) o.Text=tostring(str)
        o.Color=col o.Size=sz or 13 o.ZIndex=z or 3
        o.Outline=true  -- outline=true makes text crisp & readable
        o.Center=false o.Visible=false
        return o
    end
    function Draw.Line(x1,y1,x2,y2,col,thick,z)
        local o=reg(Drawing.new("Line"))
        o.From=Vector2.new(x1,y1) o.To=Vector2.new(x2,y2)
        o.Color=col o.Thickness=thick or 1
        o.Transparency=1 o.ZIndex=z or 2 o.Visible=false
        return o
    end
    function Draw.Circle(x,y,r,col,filled,z)
        local o=reg(Drawing.new("Circle"))
        o.Position=Vector2.new(x,y) o.Radius=r
        o.Color=col o.Filled=(filled~=false)
        o.Transparency=0.5 o.ZIndex=z or 1 o.Visible=false
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

-- ══════════════════════════════════════════════════════════
-- UI
-- ══════════════════════════════════════════════════════════
local UI={}
do
    local SW,SH=1920,1080
    pcall(function()
        SW=workspace.CurrentCamera.ViewportSize.X
        SH=workspace.CurrentCamera.ViewportSize.Y
    end)

    -- mouse
    local mouse=Players.LocalPlayer:GetMouse()
    local function MX() return mouse.X end
    local function MY() return mouse.Y end
    local function LMB() return (ismouse1pressed()) end

    -- ── keybind ───────────────────────────────────────────
    local toggleKC    = Enum.KeyCode.P
    local toggleLabel = "P"
    local bindingMode = false
    local bindLblRef  = nil

    local LETTERS={
        {kc=Enum.KeyCode.A,l="A"},{kc=Enum.KeyCode.B,l="B"},
        {kc=Enum.KeyCode.C,l="C"},{kc=Enum.KeyCode.D,l="D"},
        {kc=Enum.KeyCode.E,l="E"},{kc=Enum.KeyCode.F,l="F"},
        {kc=Enum.KeyCode.G,l="G"},{kc=Enum.KeyCode.H,l="H"},
        {kc=Enum.KeyCode.I,l="I"},{kc=Enum.KeyCode.J,l="J"},
        {kc=Enum.KeyCode.K,l="K"},{kc=Enum.KeyCode.L,l="L"},
        {kc=Enum.KeyCode.M,l="M"},{kc=Enum.KeyCode.N,l="N"},
        {kc=Enum.KeyCode.O,l="O"},{kc=Enum.KeyCode.P,l="P"},
        {kc=Enum.KeyCode.Q,l="Q"},{kc=Enum.KeyCode.R,l="R"},
        {kc=Enum.KeyCode.S,l="S"},{kc=Enum.KeyCode.T,l="T"},
        {kc=Enum.KeyCode.U,l="U"},{kc=Enum.KeyCode.V,l="V"},
        {kc=Enum.KeyCode.W,l="W"},{kc=Enum.KeyCode.X,l="X"},
        {kc=Enum.KeyCode.Y,l="Y"},{kc=Enum.KeyCode.Z,l="Z"},
    }

    local function isToggleDown()
        if bindingMode then return false end
        local ok,r=pcall(function() return RealUIS:IsKeyDown(toggleKC) end)
        return ok and r or false
    end
    local function scanBind()
        for _,k in ipairs(LETTERS) do
            local ok,r=pcall(function() return RealUIS:IsKeyDown(k.kc) end)
            if ok and r then
                toggleKC=k.kc toggleLabel=k.l bindingMode=false
                if bindLblRef then pcall(function()
                    bindLblRef.Text="Toggle Key : [ "..toggleLabel.." ]"
                    bindLblRef.Color=Color3.fromRGB(180,140,220)
                end) end
                return
            end
        end
    end

    -- ── themes ────────────────────────────────────────────
    local THEMES={
        sakura={
            name="Sakura",
            acH=330/360, acS=0.72, acV=0.96,
            bg   =Color3.fromRGB(9,7,15),
            panel=Color3.fromRGB(13,11,21),
            cardBg  =Color3.fromRGB(17,13,26),
            cardBrd =Color3.fromRGB(220,40,160),   -- hot pink
            cardTitle=Color3.fromRGB(100,12,80),
            tabSel  =Color3.fromRGB(55,18,45),
        },
        space={
            name="Space",
            acH=215/360, acS=0.85, acV=1.00,
            bg   =Color3.fromRGB(3,4,14),
            panel=Color3.fromRGB(6,8,20),
            cardBg  =Color3.fromRGB(8,12,26),
            cardBrd =Color3.fromRGB(30,120,255),   -- nebula blue
            cardTitle=Color3.fromRGB(10,35,90),
            tabSel  =Color3.fromRGB(12,22,55),
        },
    }
    local curTheme="sakura"
    local accentH=THEMES.sakura.acH
    local accentS=THEMES.sakura.acS
    local accentV=THEMES.sakura.acV

    local function AC()      return Color3.fromHSV(accentH,accentS,accentV) end
    local function ACL()     return Color3.fromHSV(accentH,accentS*0.5,1.0) end
    local function partCol() return Color3.fromHSV(accentH,accentS*0.55,1.0) end
    local function TH_now()  return THEMES[curTheme] or THEMES.sakura end

    local function applyThemePreset(key)
        local t=THEMES[key] if not t then return end
        curTheme=key
        accentH,accentS,accentV=t.acH,t.acS,t.acV
    end

    -- static palette
    local function PAL()
        local t=TH_now()
        return {
            bg      =t.bg,
            panel   =t.panel,
            titleBg =Color3.fromRGB(6,5,11),
            tabBg   =Color3.fromRGB(14,12,22),
            tabSel  =t.tabSel,
            border  =Color3.fromRGB(34,22,48),
            cardBg  =t.cardBg,
            cardBrd =t.cardBrd,
            cardTitle=t.cardTitle,
            white   =Color3.fromRGB(225,222,240),
            muted   =Color3.fromRGB(135,115,155),
            dimmed  =Color3.fromRGB(65,55,85),
            green   =Color3.fromRGB(75,200,115),
            yellow  =Color3.fromRGB(235,185,55),
            red     =Color3.fromRGB(235,65,65),
            notifBg =Color3.fromRGB(8,6,16),
            on      =Color3.fromRGB(60,185,100),
            off     =Color3.fromRGB(40,38,58),
        }
    end

    -- ── window dimensions ─────────────────────────────────
    local WW   = math.max(440,math.floor(SW/4.0))
    local WH   = math.max(500,math.floor(SH/2.3))
    local WX   = math.floor(SW/2-WW/2)
    local WY   = math.floor(SH/2-WH/2)
    local TBARH= 30
    local TABH = 24
    local CONTY= TBARH+TABH
    local PAD  = 10

    -- ── state ─────────────────────────────────────────────
    local uiReady   = false
    local uiVisible = true
    local activeTab = 1
    local currentTabs={}

    -- drawing object lists
    local frameObjs  = {}   -- window chrome (never cleared by switchTab)
    local contentAll = {}   -- all content objects (for global SetVisible)
    local glowLines  = {}
    local ledDot     = nil  -- the LED circle moving around border
    local cardLedDots= {}   -- LED dots on card borders
    local tabBtnData = {}   -- [i]={bg,lbl,ul}
    local tabContent = {}   -- [i]=list
    local accentObjs = {}   -- {obj,"ac"|"acl"}
    local partObjs   = {}
    local starObjs   = {}   -- space stars (separate system)

    -- zone system
    local gZones={}
    local tZones={}

    -- overlay
    local pickerObjs={}  local pickerActive=false
    local ddObjs={}      local ddOpen=false
    local swatchRef=nil

    -- feature toggles (persist)
    local fToggles={}
    local function FT(k) return fToggles[k] or false end
    local function setFT(k,v) fToggles[k]=v end

    local dynName="—" local dynVer="—"
    local lblGame,lblVer

    -- forward decl
    local buildWindow,applyTheme,destroyPicker,destroyDD

    -- ── zones ─────────────────────────────────────────────
    local function addGZ(x,y,w,h,fn)
        gZones[#gZones+1]={x=x,y=y,w=w,h=h,fn=fn}
    end
    local function addTZ(ti,x,y,w,h,fn)
        tZones[ti]=tZones[ti] or {}
        tZones[ti][#tZones[ti]+1]={x=x,y=y,w=w,h=h,fn=fn}
    end
    local function clearZones()
        table.clear(gZones) table.clear(tZones)
    end

    -- [FIX-INPUT-SINK] returns true if click was inside UI (sinks it)
    local function hitTest(mx,my)
        local list={}
        for _,z in ipairs(gZones) do list[#list+1]=z end
        if tZones[activeTab] then
            for _,z in ipairs(tZones[activeTab]) do list[#list+1]=z end
        end
        -- check picker zones
        for _,z in ipairs(list) do
            if mx>=z.x and mx<=z.x+z.w and my>=z.y and my<=z.y+z.h then
                pcall(z.fn) return true
            end
        end
        -- was click inside the window at all?
        if mx>=WX and mx<=WX+WW and my>=WY and my<=WY+WH then
            return true  -- inside window = sink even if no zone hit
        end
        return false
    end

    -- ── accent registry ───────────────────────────────────
    local function regAC(o)  accentObjs[#accentObjs+1]={obj=o,r="ac"}  return o end
    local function regACL(o) accentObjs[#accentObjs+1]={obj=o,r="acl"} return o end

    applyTheme=function()
        local ac,acl=AC(),ACL()
        local pal=PAL()
        for _,e in ipairs(accentObjs) do pcall(function()
            e.obj.Color=(e.r=="acl") and acl or ac
        end) end
        for _,gl in ipairs(glowLines) do pcall(function() gl.Color=ac end) end
        -- UL: set per tabBtnData rebuild (see buildWindow/switchTab)
        for _,p in ipairs(partObjs)  do pcall(function() p.Color=partCol() end) end
        for _,s in ipairs(starObjs)  do pcall(function() s.base=partCol() end) end
        if swatchRef then pcall(function() swatchRef.Color=ac end) end
    end

    -- ── color picker ──────────────────────────────────────
    local PW=WW-PAD*2  local PH=80  local VH=14

    destroyPicker=function()
        Draw.Destroy(pickerObjs) pickerActive=false
        -- remove picker zones from gZones
        local keep={}
        for _,z in ipairs(gZones) do
            if not z._picker then keep[#keep+1]=z end
        end
        table.clear(gZones)
        for _,z in ipairs(keep) do gZones[#gZones+1]=z end
    end

    local function buildPicker(cx,cy,sw)
        destroyPicker() pickerActive=true swatchRef=sw
        local hS,sS=56,11
        local cw2=math.floor(PW/hS) local ch2=math.floor(PH/sS)
        for hi=0,hS-1 do for si=0,sS-1 do
            local sq=Draw.Rect(cx+hi*cw2,cy+si*ch2,cw2+1,ch2+1,
                Color3.fromHSV(hi/hS,1-si/sS,accentV),30)
            sq.Visible=true pickerObjs[#pickerObjs+1]=sq
        end end
        local vy=cy+PH+3
        local vS=32
        local vsw=math.floor(PW/vS)
        for vi=0,vS-1 do
            local sq=Draw.Rect(cx+vi*vsw,vy,vsw+1,VH,
                Color3.fromHSV(accentH,accentS,(vi+1)/vS),30)
            sq.Visible=true pickerObjs[#pickerObjs+1]=sq
        end
        -- cursor
        local cur=Draw.Outline(cx+math.floor(accentH*PW)-5,
            cy+math.floor((1-accentS)*PH)-5,10,10,
            Color3.new(1,1,1),2,32)
        cur.Visible=true pickerObjs[#pickerObjs+1]=cur
        local brd=Draw.Outline(cx,cy,PW,PH+3+VH,PAL().border,1,31)
        brd.Visible=true pickerObjs[#pickerObjs+1]=brd

        local function gz(x,y,w,h,fn)
            local z={x=x,y=y,w=w,h=h,fn=fn,_picker=true}
            gZones[#gZones+1]=z
        end
        gz(cx,cy,PW,PH,function()
            local mx2,my2=MX(),MY()
            accentH=math.max(0,math.min(0.9999,(mx2-cx)/PW))
            accentS=math.max(0.01,math.min(1,1-(my2-cy)/PH))
            pcall(function()
                cur.Position=Vector2.new(
                    cx+math.floor(accentH*PW)-5,
                    cy+math.floor((1-accentS)*PH)-5)
            end)
            applyTheme()
        end)
        gz(cx,vy,PW,VH,function()
            accentV=math.max(0.05,math.min(1,(MX()-cx+1)/PW))
            applyTheme()
        end)
    end

    -- ── theme dropdown ────────────────────────────────────
    destroyDD=function()
        Draw.Destroy(ddObjs) ddOpen=false
        local keep={}
        for _,z in ipairs(gZones) do
            if not z._dd then keep[#keep+1]=z end
        end
        table.clear(gZones)
        for _,z in ipairs(keep) do gZones[#gZones+1]=z end
    end

    local function buildDD(cx,cy)
        destroyDD() ddOpen=true
        local IH=26
        local thList={
            {key="sakura",name="Sakura",dot=Color3.fromRGB(255,80,180)},
            {key="space", name="Space", dot=Color3.fromRGB(60,130,255)},
        }
        for i,t in ipairs(thList) do
            local iy=cy+(i-1)*IH
            local bg=Draw.Rect(cx,iy,PW,IH,PAL().tabBg,35) bg.Visible=true ddObjs[#ddObjs+1]=bg
            local dot=Draw.Rect(cx+7,iy+8,10,10,t.dot,36) dot.Visible=true ddObjs[#ddObjs+1]=dot
            local lbl=Draw.Text(cx+23,iy+6,t.name,PAL().white,12,36) lbl.Visible=true ddObjs[#ddObjs+1]=lbl
            if i<#thList then
                local sep=Draw.Line(cx,iy+IH-1,cx+PW,iy+IH-1,PAL().border,1,36)
                sep.Visible=true ddObjs[#ddObjs+1]=sep
            end
            local tk=t.key
            local z={x=cx,y=iy,w=PW,h=IH,_dd=true,fn=function()
                applyThemePreset(tk) destroyDD() destroyPicker()
                applyTheme() buildWindow()
                Draw.SetVisible(frameObjs,uiVisible)
                Draw.SetVisible(contentAll,uiVisible)
            end}
            gZones[#gZones+1]=z
        end
        local brd=Draw.Outline(cx,cy,PW,#thList*IH,PAL().cardBrd,1,36)
        brd.Visible=true ddObjs[#ddObjs+1]=brd
    end

    -- ══════════════════════════════════════════════════════
    -- CARD SYSTEM
    -- ══════════════════════════════════════════════════════
    local function makeCard(objs,addZ,cx,sy,cw2,title)
        local pal=PAL()
        local CP=7 local TBH=17
        local bg  =Draw.Rect(cx,sy,cw2,0,pal.cardBg,4)     objs[#objs+1]=bg
        local brd =Draw.Outline(cx,sy,cw2,0,pal.cardBrd,1,5) objs[#objs+1]=brd
        -- LED dot for card border (stored separately)
        local cled=Draw.Circle(cx,sy,3,pal.cardBrd,true,6)
        cled.Transparency=0.2 cled.Visible=false
        objs[#objs+1]=cled
        cardLedDots[#cardLedDots+1]={
            dot=cled, x=cx,y=sy, w=cw2, h=0,  -- h set by finalize
            t=math.random()*math.pi*2
        }
        local tbg =Draw.Rect(cx,sy,cw2,TBH,pal.cardTitle,5) objs[#objs+1]=tbg
        local tlbl=Draw.Text(cx+CP,sy+3,title,pal.white,11,6)
        objs[#objs+1]=tlbl
        local cy2=sy+TBH+CP
        return {
            cx=cx+CP, cw=cw2-CP*2, cy=cy2, startY=sy, TBH=TBH,
            finalize=function(endY)
                local h=math.max(TBH,endY-sy+CP)
                pcall(function() bg.Size=Vector2.new(cw2,h) end)
                pcall(function() brd.Size=Vector2.new(cw2,h) end)
                -- update card LED h
                for _,ld in ipairs(cardLedDots) do
                    if ld.dot==cled then ld.h=h break end
                end
            end,
        }
    end

    local function cardToggle(objs,addZ,cx,y,cw2,key,label)
        local pal=PAL()
        local isOn=FT(key)
        local h=22
        local bg=Draw.Rect(cx,y,cw2,h,isOn and pal.on or pal.off,6) objs[#objs+1]=bg
        local lbl=Draw.Text(cx+8,y+5,
            label.." : "..(isOn and "ON" or "OFF"),
            isOn and Color3.fromRGB(8,8,8) or pal.white,11,7)
        objs[#objs+1]=lbl
        addZ(cx,y,cw2,h,function()
            local v=not FT(key) setFT(key,v)
            local p2=PAL()
            pcall(function()
                bg.Color=v and p2.on or p2.off
                lbl.Text=label.." : "..(v and "ON" or "OFF")
                lbl.Color=v and Color3.fromRGB(8,8,8) or p2.white
            end)
        end)
        return y+h+5
    end

    local function cardButton(objs,addZ,cx,y,cw2,label,fn)
        local pal=PAL()
        local h=22
        local bg=Draw.Rect(cx,y,cw2,h,Color3.fromRGB(28,20,44),6) objs[#objs+1]=bg
        local brd=Draw.Outline(cx,y,cw2,h,pal.cardBrd,1,7) objs[#objs+1]=brd
        local lbl=Draw.Text(cx+8,y+5,label,pal.white,11,7) objs[#objs+1]=lbl
        addZ(cx,y,cw2,h,fn or function() end)
        return y+h+5
    end

    -- mini dropdown inside a card
    local function cardDropdown(objs,addZ,cx,y,cw2,key,items,defaultLabel)
        local pal=PAL()
        local h=20
        local selIdx=fToggles[key.."_sel"] or 1
        local bg=Draw.Rect(cx,y,cw2,h,PAL().tabBg,6) objs[#objs+1]=bg
        local brd=Draw.Outline(cx,y,cw2,h,pal.cardBrd,1,7) objs[#objs+1]=brd
        local cur=items[selIdx] or defaultLabel
        local lbl=Draw.Text(cx+6,y+4,">> "..tostring(cur),pal.white,10,7) objs[#objs+1]=lbl

        -- dropdown list (hidden by default, shown inline below)
        local listObjs={}
        local listOpen=false
        local listZoneKeys={}

        local function closeList()
            for _,o in ipairs(listObjs) do pcall(function() o:Remove() end) end
            table.clear(listObjs)
            -- remove those zones from tZones
            listOpen=false
        end
        local function openList()
            if listOpen then closeList() return end
            listOpen=true
            local IH=18
            for i,item in ipairs(items) do
                local iy=y+h+(i-1)*IH
                local ibg=Draw.Rect(cx,iy,cw2,IH,Color3.fromRGB(20,16,32),20)
                ibg.Visible=true listObjs[#listObjs+1]=ibg
                local ibrd=Draw.Outline(cx,iy,cw2,IH,pal.cardBrd,1,21)
                ibrd.Visible=true listObjs[#listObjs+1]=ibrd
                local it=tostring(item)
                local itlbl=Draw.Text(cx+6,iy+3,it,pal.white,10,21)
                itlbl.Visible=true listObjs[#listObjs+1]=itlbl
                local ii=i
                addZ(cx,iy,cw2,IH,function()
                    fToggles[key.."_sel"]=ii
                    pcall(function() lbl.Text=">> "..tostring(items[ii]) end)
                    closeList()
                end)
            end
            -- insert objects into objs for SetVisible tracking
            for _,o in ipairs(listObjs) do objs[#objs+1]=o end
        end

        addZ(cx,y,cw2,h,openList)
        return y+h+5
    end

    -- ══════════════════════════════════════════════════════
    -- SWITCH TAB
    -- ══════════════════════════════════════════════════════
    local function rebuildAllUL()
        -- [FIX-UL] always called after any tab switch or rebuild
        local ac=AC()
        for i,bd in pairs(tabBtnData) do pcall(function()
            bd.ul.Color=ac
            bd.ul.Visible=(i==activeTab)
            bd.lbl.Color=(i==activeTab) and ACL() or PAL().muted
            bd.bg.Color =(i==activeTab) and PAL().tabSel or PAL().tabBg
        end) end
    end

    local function switchTab(idx)
        if not currentTabs[idx] then return end
        -- hide old content
        if tabContent[activeTab] then
            Draw.SetVisible(tabContent[activeTab],false)
        end
        activeTab=idx
        destroyPicker() destroyDD()

        -- build if first visit
        if not tabContent[activeTab] then
            tabContent[activeTab]={}
            tZones[activeTab]={}
            local tab=currentTabs[activeTab]
            if tab and type(tab.buildFn)=="function" then
                local cx0=WX+PAD
                local cy0=WY+CONTY+PAD
                local cw0=WW-PAD*2
                local function addZ(x,y,w,h,fn)
                    addTZ(activeTab,x,y,w,h,fn)
                end
                local pal=PAL()
                local ctx={
                    cx=cx0,cy=cy0,cw=cw0,ch=WH-CONTY-PAD*2,
                    C=pal,AC=AC,ACL=ACL,PAD=PAD,Draw=Draw,
                    objs=tabContent[activeTab],
                    addZone=addZ, addGZ=addGZ,
                    card=function(x,y,w,t2)
                        return makeCard(tabContent[activeTab],addZ,x,y,w,t2)
                    end,
                    toggle=function(x,y,w,key,lbl2)
                        return cardToggle(tabContent[activeTab],addZ,x,y,w,key,lbl2)
                    end,
                    button=function(x,y,w,lbl2,fn2)
                        return cardButton(tabContent[activeTab],addZ,x,y,w,lbl2,fn2)
                    end,
                    dropdown=function(x,y,w,key,items,def)
                        return cardDropdown(tabContent[activeTab],addZ,x,y,w,key,items,def)
                    end,
                    buildPicker=buildPicker,
                    buildDropdown=buildDD,
                    regAC=regAC,regACL=regACL,
                    WX=function()return WX end,
                    WY=function()return WY end,
                    WW=WW,WH=WH,
                    FT=FT,setFT=setFT,
                    dynName=function()return dynName end,
                    dynVer=function()return dynVer end,
                }
                pcall(function() tab.buildFn(ctx) end)
                for _,o in ipairs(tabContent[activeTab]) do
                    frameObjs[#frameObjs+1]=o
                    contentAll[#contentAll+1]=o
                end
            end
        end

        -- show new content
        Draw.SetVisible(tabContent[activeTab],uiVisible)
        rebuildAllUL()
    end

    -- ══════════════════════════════════════════════════════
    -- BUILD WINDOW
    -- ══════════════════════════════════════════════════════
    buildWindow=function()
        destroyPicker() destroyDD()
        table.clear(cardLedDots)

        for _,o in ipairs(frameObjs) do pcall(function() o:Remove() end) end
        table.clear(frameObjs) table.clear(contentAll)
        table.clear(glowLines) table.clear(tabBtnData)
        table.clear(accentObjs)
        for _,tc in pairs(tabContent) do
            for _,o in ipairs(tc) do pcall(function() o:Remove() end) end
        end
        table.clear(tabContent)
        clearZones()
        swatchRef=nil bindLblRef=nil
        if ledDot then pcall(function() ledDot:Remove() end) ledDot=nil end

        local pal=PAL()
        local ac=AC()
        local x,y=WX,WY

        -- background
        frameObjs[#frameObjs+1]=Draw.Rect(x,y,WW,WH,pal.bg,1)
        -- title bar
        frameObjs[#frameObjs+1]=Draw.Rect(x,y,WW,TBARH,pal.titleBg,2)
        local hl=regACL(Draw.Text(x+PAD,y+8,"EXE.HUB",ACL(),14,5))
        frameObjs[#frameObjs+1]=hl
        frameObjs[#frameObjs+1]=Draw.Line(x+86,y+6,x+86,y+TBARH-6,pal.border,1,4)
        lblGame=Draw.Text(x+92,y+9,dynName,pal.muted,11,5)
        frameObjs[#frameObjs+1]=lblGame
        lblVer=Draw.Text(x+WW-56,y+9,dynVer,pal.dimmed,9,5)
        frameObjs[#frameObjs+1]=lblVer
        frameObjs[#frameObjs+1]=Draw.Line(x,y+TBARH,x+WW,y+TBARH,pal.border,1,3)

        -- tab bar
        local nT=#currentTabs
        local tabW=math.floor(WW/math.max(nT,1))
        local tabY=y+TBARH
        for i,tab in ipairs(currentTabs) do
            local tx=x+(i-1)*tabW
            local isSel=(i==activeTab)
            local tbg=Draw.Rect(tx,tabY,tabW,TABH,isSel and pal.tabSel or pal.tabBg,2)
            frameObjs[#frameObjs+1]=tbg
            if i>1 then
                frameObjs[#frameObjs+1]=Draw.Line(tx,tabY+3,tx,tabY+TABH-3,pal.border,1,3)
            end
            local lx=tx+math.floor(tabW/2)-math.floor(#tab.name*3.1)
            local tlbl=Draw.Text(lx,tabY+6,tab.name,isSel and ACL() or pal.muted,10,4)
            if isSel then regACL(tlbl) end
            frameObjs[#frameObjs+1]=tlbl
            -- [FIX-UL] underline: only active, rebuilt by rebuildAllUL
            local tul=Draw.Line(tx+3,tabY+TABH-1,tx+tabW-3,tabY+TABH-1,ac,2,4)
            tul.Visible=isSel
            frameObjs[#frameObjs+1]=tul
            tabBtnData[i]={bg=tbg,lbl=tlbl,ul=tul}
            local ci=i
            addGZ(tx,tabY,tabW,TABH,function() switchTab(ci) end)
        end

        -- content panel
        frameObjs[#frameObjs+1]=Draw.Line(x,y+CONTY,x+WW,y+CONTY,pal.border,1,3)
        frameObjs[#frameObjs+1]=Draw.Rect(x,y+CONTY,WW,WH-CONTY,pal.panel,1)
        frameObjs[#frameObjs+1]=Draw.Outline(x,y,WW,WH,pal.border,1,3)

        -- glow border lines (4 sides, animated by LED loop)
        local function gl(x1,y1,x2,y2)
            local l=Draw.Line(x1,y1,x2,y2,ac,1.5,4)
            l.Transparency=0.80 frameObjs[#frameObjs+1]=l glowLines[#glowLines+1]=l
            return l
        end
        gl(x,y,    x+WW,y    )
        gl(x+WW,y, x+WW,y+WH)
        gl(x+WW,y+WH,x,y+WH)
        gl(x,y+WH, x,  y    )

        -- LED dot (moving around outer border)
        ledDot=Drawing.new("Circle")
        ledDot.Radius=5 ledDot.Color=ac
        ledDot.Filled=true ledDot.Transparency=0.1
        ledDot.ZIndex=8 ledDot.Visible=false
        frameObjs[#frameObjs+1]=ledDot

        -- build active tab content
        tabContent[activeTab]={}
        tZones[activeTab]={}
        local tab=currentTabs[activeTab]
        if tab and type(tab.buildFn)=="function" then
            local cx0=WX+PAD
            local cy0=WY+CONTY+PAD
            local cw0=WW-PAD*2
            local function addZ(x2,y2,w2,h2,fn2) addTZ(activeTab,x2,y2,w2,h2,fn2) end
            local ctx={
                cx=cx0,cy=cy0,cw=cw0,ch=WH-CONTY-PAD*2,
                C=pal,AC=AC,ACL=ACL,PAD=PAD,Draw=Draw,
                objs=tabContent[activeTab],
                addZone=addZ,addGZ=addGZ,
                card=function(x2,y2,w2,t2)
                    return makeCard(tabContent[activeTab],addZ,x2,y2,w2,t2)
                end,
                toggle=function(x2,y2,w2,key,lbl2)
                    return cardToggle(tabContent[activeTab],addZ,x2,y2,w2,key,lbl2)
                end,
                button=function(x2,y2,w2,lbl2,fn2)
                    return cardButton(tabContent[activeTab],addZ,x2,y2,w2,lbl2,fn2)
                end,
                dropdown=function(x2,y2,w2,key,items,def)
                    return cardDropdown(tabContent[activeTab],addZ,x2,y2,w2,key,items,def)
                end,
                buildPicker=buildPicker,
                buildDropdown=buildDD,
                regAC=regAC,regACL=regACL,
                WX=function()return WX end,
                WY=function()return WY end,
                WW=WW,WH=WH,
                FT=FT,setFT=setFT,
                dynName=function()return dynName end,
                dynVer=function()return dynVer end,
            }
            pcall(function() tab.buildFn(ctx) end)
            for _,o in ipairs(tabContent[activeTab]) do
                frameObjs[#frameObjs+1]=o
                contentAll[#contentAll+1]=o
            end
        end
    end

    -- ══════════════════════════════════════════════════════
    -- DEFAULT TABS
    -- ══════════════════════════════════════════════════════
    local MOB_LIST={"All Mobs","[To be added]"}
    local TP_LOCATIONS={"Spawn","Bus Stop","Mob Area","Boss Room","Safe Zone"}

    local function makeDefaultTabs()

        -- helper: two equal columns
        local function half(cw2) return math.floor((cw2-6)/2) end

        -- ── Main ─────────────────────────────────────────
        local tabMain={name="Main",buildFn=function(ctx)
            local o,D,pal=ctx.objs,ctx.Draw,ctx.C
            local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
            local h2=half(cw)
            local sy=cy

            -- Row 1: Auto Farm | ESP
            local afC=ctx.card(cx,sy,h2,"AUTO FARM")
            local eC =ctx.card(cx+h2+6,sy,h2,"ESP")

            local ay=afC.cy
            ay=ctx.dropdown(afC.cx,ay,afC.cw,"mob_sel",MOB_LIST,"All Mobs")
            ay=ctx.toggle(afC.cx,ay,afC.cw,"autoFarm","Auto Farm Mob")
            afC.finalize(ay)

            local ey=eC.cy
            ey=ctx.toggle(eC.cx,ey,eC.cw,"espMob",   "ESP Mob   ")
            ey=ctx.toggle(eC.cx,ey,eC.cw,"espPlayer","ESP Player")
            ey=ctx.toggle(eC.cx,ey,eC.cw,"espItem",  "ESP Item  ")
            ey=ey+3
            o[#o+1]=D.Text(eC.cx,ey,"Colors :",pal.muted,9,6)
            ey=ey+12
            local sw2=math.floor((eC.cw-3)/2)
            local ms=D.Rect(eC.cx,ey,sw2,13,Color3.fromRGB(255,70,70),7) o[#o+1]=ms
            o[#o+1]=D.Text(eC.cx+3,ey+2,"Mob",Color3.new(1,1,1),8,8)
            local ps=D.Rect(eC.cx+sw2+3,ey,sw2,13,Color3.fromRGB(70,170,255),7) o[#o+1]=ps
            o[#o+1]=D.Text(eC.cx+sw2+6,ey+2,"Player",Color3.new(1,1,1),8,8)
            ey=ey+17
            eC.finalize(ey)

            sy=math.max(ay,ey)+10

            -- Row 2: Stand Arrow System
            local saC=ctx.card(cx,sy,cw,"STAND ARROW SYSTEM")
            local say=saC.cy
            o[#o+1]=D.Text(saC.cx,say,"Desired Stand :",pal.muted,10,6)
            say=say+14
            local standList={"Any Stand","[Stands TBA]"}
            say=ctx.dropdown(saC.cx,say,saC.cw,"stand_sel",standList,"Any Stand")
            say=ctx.toggle(saC.cx,say,saC.cw,"arrowAuto","Auto Use Arrow")
            say=ctx.toggle(saC.cx,say,saC.cw,"arrowStop","Stop if Skin Obtained")
            o[#o+1]=D.Text(saC.cx,say,
                "Stops when rare skin found to avoid losing it",
                pal.dimmed,9,6)
            say=say+13
            saC.finalize(say)
            sy=say+10

            -- Row 3: Status
            local stC=ctx.card(cx,sy,cw,"STATUS")
            local sty=stC.cy
            o[#o+1]=D.Text(stC.cx,sty,"Game :",pal.muted,10,6)
            o[#o+1]=D.Text(stC.cx+44,sty,ctx.dynName(),pal.white,11,6)
            sty=sty+16
            o[#o+1]=D.Text(stC.cx,sty,"Version :",pal.muted,10,6)
            o[#o+1]=D.Text(stC.cx+52,sty,ctx.dynVer(),pal.white,11,6)
            sty=sty+4
            stC.finalize(sty+8)
        end}

        -- ── Items ─────────────────────────────────────────
        local tabItems={name="Items",buildFn=function(ctx)
            local o,D,pal=ctx.objs,ctx.Draw,ctx.C
            local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
            local h2=half(cw)
            local sy=cy

            local c1=ctx.card(cx,sy,h2,   "AUTO COLLECT")
            local c2=ctx.card(cx+h2+6,sy,h2,"AUTO SELL")
            local y1=ctx.toggle(c1.cx,c1.cy,c1.cw,"autoCollect","Auto Collect")
            c1.finalize(y1)
            local y2=ctx.toggle(c2.cx,c2.cy,c2.cw,"autoSell","Auto Sell")
            c2.finalize(y2)
            sy=math.max(y1,y2)+10

            local c3=ctx.card(cx,sy,h2,   "EQUIP ITEM")
            local c4=ctx.card(cx+h2+6,sy,h2,"USE ITEM")
            local y3=ctx.toggle(c3.cx,c3.cy,c3.cw,"autoEquip","Auto Equip")
            c3.finalize(y3)
            local y4=ctx.toggle(c4.cx,c4.cy,c4.cw,"autoUse","Auto Use")
            c4.finalize(y4)
            sy=math.max(y3,y4)+10

            local c5=ctx.card(cx,sy,cw,"DROP ITEM")
            local y5=ctx.toggle(c5.cx,c5.cy,c5.cw,"autoDrop","Auto Drop")
            c5.finalize(y5)
        end}

        -- ── Teleport ──────────────────────────────────────
        local tabTp={name="Teleport",buildFn=function(ctx)
            local o,D,pal=ctx.objs,ctx.Draw,ctx.C
            local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
            local h2=half(cw)
            local sy=cy

            -- Bus Stop | Mob Spawn
            local bsC=ctx.card(cx,sy,h2,"BUS STOP")
            local msC=ctx.card(cx+h2+6,sy,h2,"MOB SPAWN")

            local by=bsC.cy
            by=ctx.dropdown(bsC.cx,by,bsC.cw,"tp_bs",TP_LOCATIONS,"Choose")
            by=ctx.button(bsC.cx,by,bsC.cw,"Teleport",function()
                local idx=fToggles["tp_bs_sel"] or 1
                print("[TP] BusStop -> "..tostring(TP_LOCATIONS[idx]))
            end)
            bsC.finalize(by)

            local my2=msC.cy
            my2=ctx.dropdown(msC.cx,my2,msC.cw,"tp_ms",TP_LOCATIONS,"Choose")
            my2=ctx.button(msC.cx,my2,msC.cw,"Teleport",function()
                local idx=fToggles["tp_ms_sel"] or 1
                print("[TP] MobSpawn -> "..tostring(TP_LOCATIONS[idx]))
            end)
            msC.finalize(my2)
            sy=math.max(by,my2)+10

            -- NPC (full width)
            local npC=ctx.card(cx,sy,cw,"NPC")
            local ny=npC.cy
            ny=ctx.dropdown(npC.cx,ny,npC.cw,"tp_npc",{"Main NPC","Raid NPC"},"Choose")
            ny=ctx.button(npC.cx,ny,npC.cw,"Teleport to NPC",function()
                local idx=fToggles["tp_npc_sel"] or 1
                print("[TP] NPC -> "..tostring({"Main NPC","Raid NPC"}[idx]))
            end)
            npC.finalize(ny)
        end}

        -- ── Settings ──────────────────────────────────────
        local tabSettings={name="Settings",buildFn=function(ctx)
            local o,D,pal=ctx.objs,ctx.Draw,ctx.C
            local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
            local sy=cy

            -- Theme card
            local thC=ctx.card(cx,sy,cw,"THEME")
            local ty=thC.cy
            local swH=22
            local sw=Draw.Rect(thC.cx,ty,thC.cw,swH,AC(),5)
            regAC(sw) swatchRef=sw o[#o+1]=sw
            o[#o+1]=D.Text(thC.cx+7,ty+5,">> "..TH_now().name.." Theme",
                Color3.new(0,0,0),11,6)
            ctx.addZone(thC.cx,ty,thC.cw,swH,function()
                if ddOpen then destroyDD() else buildDD(thC.cx,ty+swH+2) end
            end)
            ty=ty+swH+8
            o[#o+1]=D.Text(thC.cx,ty,"Custom border/particle color :",pal.muted,9,6)
            ty=ty+13
            local cpBg=D.Rect(thC.cx,ty,thC.cw,20,pal.tabBg,5) o[#o+1]=cpBg
            local cpBrd=D.Outline(thC.cx,ty,thC.cw,20,pal.cardBrd,1,6) o[#o+1]=cpBrd
            o[#o+1]=D.Text(thC.cx+7,ty+4,"Open HSV Color Picker",pal.white,11,6)
            ctx.addZone(thC.cx,ty,thC.cw,20,function()
                if pickerActive then destroyPicker()
                else buildPicker(thC.cx,ty+24,sw) end
            end)
            ty=ty+26
            thC.finalize(ty)
            sy=ty+10

            -- Toggle key card
            local tkC=ctx.card(cx,sy,cw,"TOGGLE KEY")
            local ky=tkC.cy
            local bh=26
            local kbg=D.Rect(tkC.cx,ky,tkC.cw,bh,pal.tabBg,5) o[#o+1]=kbg
            local kbrd=D.Outline(tkC.cx,ky,tkC.cw,bh,pal.cardBrd,1,6) o[#o+1]=kbrd
            local klbl=D.Text(tkC.cx+8,ky+7,
                "Toggle Key : [ "..toggleLabel.." ]",
                Color3.fromRGB(180,140,220),12,6)
            o[#o+1]=klbl
            bindLblRef=klbl
            o[#o+1]=D.Text(tkC.cx,ky+bh+4,
                "Click then press any letter key (A-Z)",
                pal.dimmed,9,6)
            ctx.addZone(tkC.cx,ky,tkC.cw,bh,function()
                if bindingMode then
                    bindingMode=false
                    pcall(function()
                        klbl.Text="Toggle Key : [ "..toggleLabel.." ]"
                        klbl.Color=Color3.fromRGB(180,140,220)
                    end)
                else
                    bindingMode=true
                    pcall(function()
                        klbl.Text="Waiting for key press..."
                        klbl.Color=Color3.fromRGB(235,185,55)
                    end)
                end
            end)
            ky=ky+bh+20
            tkC.finalize(ky)
        end}

        -- ── Credits ───────────────────────────────────────
        local tabCredits={name="Credits",buildFn=function(ctx)
            local o,D,pal=ctx.objs,ctx.Draw,ctx.C
            local cr=ctx.card(ctx.cx,ctx.cy,ctx.cw,"CREDITS")
            local ry=cr.cy
            o[#o+1]=D.Text(cr.cx,ry,"Creator : me",pal.white,13,6)
            ry=ry+20
            o[#o+1]=D.Text(cr.cx,ry,"EXE.HUB — Roblox Script Hub",pal.muted,11,6)
            ry=ry+16
            o[#o+1]=D.Text(cr.cx,ry,"github.com/mattheube/EXE.HUB",pal.dimmed,10,6)
            ry=ry+6
            cr.finalize(ry+10)
        end}

        -- ── Logs ──────────────────────────────────────────
        local tabLogs={name="Logs",buildFn=function(ctx)
            local o,D,pal=ctx.objs,ctx.Draw,ctx.C
            local lg=ctx.card(ctx.cx,ctx.cy,ctx.cw,"HUB UPDATES")
            local ly=lg.cy
            local lines={
                "v1.0  --  Initial release of the hub.",
                "More update logs will be added here.",
            }
            for _,ln in ipairs(lines) do
                o[#o+1]=D.Text(lg.cx,ly,ln,pal.white,11,6)
                ly=ly+16
            end
            lg.finalize(ly+4)
        end}

        currentTabs={tabMain,tabItems,tabTp,tabSettings,tabCredits,tabLogs}
    end

    -- ══════════════════════════════════════════════════════
    -- LED BORDER ANIMATION
    -- Travels around the outer window border.
    -- Separate lighter dots travel each card border.
    -- ══════════════════════════════════════════════════════
    task.spawn(function()
        local t=0
        local perimeter=2*(WW+WH)
        while true do
            task.wait(0.033)
            if not uiReady or not uiVisible then continue end
            t=(t+3)%perimeter  -- speed: 3px per frame
            -- compute position on rectangle perimeter
            local px,py
            local top=WW local right=WH local bot=WW local left=WH
            if t<top then
                px=WX+t          py=WY
            elseif t<top+right then
                px=WX+WW         py=WY+(t-top)
            elseif t<top+right+bot then
                px=WX+WW-(t-top-right) py=WY+WH
            else
                px=WX            py=WY+WH-(t-top-right-bot)
            end
            if ledDot then
                pcall(function()
                    ledDot.Position=Vector2.new(px,py)
                    ledDot.Color=AC()
                    -- pulsing glow radius
                    local pulse=0.5+0.5*math.sin(t*0.04)
                    ledDot.Radius=3+pulse*3
                    ledDot.Visible=uiVisible
                end)
            end
            -- dim base glow lines to let LED stand out
            local base=0.82
            for _,gl in ipairs(glowLines) do pcall(function()
                gl.Transparency=base gl.Color=AC()
            end) end
            -- card LED dots
            for _,ld in ipairs(cardLedDots) do
                if ld.h>0 then pcall(function()
                    local cp=2*(ld.w+ld.h)
                    local ct=((t*0.5)+ld.t*cp)%cp
                    local dpx,dpy
                    if ct<ld.w then
                        dpx=ld.x+ct      dpy=ld.y
                    elseif ct<ld.w+ld.h then
                        dpx=ld.x+ld.w    dpy=ld.y+(ct-ld.w)
                    elseif ct<ld.w*2+ld.h then
                        dpx=ld.x+ld.w-(ct-ld.w-ld.h) dpy=ld.y+ld.h
                    else
                        dpx=ld.x         dpy=ld.y+ld.h-(ct-ld.w*2-ld.h)
                    end
                    ld.dot.Position=Vector2.new(dpx,dpy)
                    ld.dot.Color=AC()
                    ld.dot.Visible=uiVisible
                end) end
            end
        end
    end)

    -- ══════════════════════════════════════════════════════
    -- SAKURA PETALS  (40 max, always present)
    -- ══════════════════════════════════════════════════════
    local PMAX=40 local pCount=0

    local function spawnPetal()
        if pCount>=PMAX or not uiReady then return end
        pCount=pCount+1
        local sz=math.random(2,7)
        local p=Drawing.new("Circle")
        p.Position=Vector2.new(WX+math.random(sz,WW-sz),WY+CONTY+sz)
        p.Radius=sz p.Color=partCol() p.Filled=true
        p.Transparency=math.random(15,50)/100
        p.ZIndex=2 p.Visible=false
        partObjs[#partObjs+1]=p
        local steps=math.random(60,160)
        local dy=(WY+WH-2-(WY+CONTY))/steps
        local phase=math.random()*math.pi*2
        local amp=math.random(3,9)
        local dA=(p.Transparency-0.96)/steps
        local drift=math.random(-10,10)/steps
        task.spawn(function()
            for s=1,steps do
                task.wait(0.05)
                if not uiReady then break end
                pcall(function()
                    p.Visible=uiVisible and curTheme=="sakura"
                    p.Color=partCol()
                    p.Position=Vector2.new(
                        p.Position.X+drift+math.sin(phase+s*0.13)*amp/steps,
                        p.Position.Y+dy)
                    p.Transparency=math.min(1,p.Transparency+dA)
                end)
            end
            pcall(function() p:Remove() end)
            for i,a in ipairs(partObjs) do if a==p then table.remove(partObjs,i) break end end
            pCount=pCount-1
        end)
    end

    -- Spawn petals continuously (Sakura theme)
    task.spawn(function()
        while true do
            task.wait(0.4+math.random()*0.5)
            if uiReady and curTheme=="sakura" then
                pcall(spawnPetal)
                if math.random()<0.6 then
                    task.wait(0.1) pcall(spawnPetal)
                end
            end
        end
    end)

    -- ══════════════════════════════════════════════════════
    -- SPACE STARS  (35 max, float/glow/twinkle, no falling)
    -- ══════════════════════════════════════════════════════
    local SMAX=35

    local function buildStars()
        -- clear old stars
        for _,s in ipairs(starObjs) do pcall(function() s.obj:Remove() end) end
        table.clear(starObjs)
        if curTheme~="space" then return end
        for _=1,SMAX do
            local sz=math.random(1,3)
            local c=Drawing.new("Circle")
            c.Position=Vector2.new(
                WX+math.random(4,WW-4),
                WY+CONTY+math.random(4,WH-CONTY-4))
            c.Radius=sz c.Color=partCol() c.Filled=true
            c.Transparency=math.random(20,60)/100
            c.ZIndex=2 c.Visible=false
            starObjs[#starObjs+1]={
                obj=c,
                base=partCol(),
                ox=c.Position.X,
                oy=c.Position.Y,
                phase=math.random()*math.pi*2,
                speed=0.5+math.random()*1.5,
                sz=sz,
            }
        end
    end

    task.spawn(function()
        local t=0
        while true do
            task.wait(0.05)
            if not uiReady then continue end
            t=t+0.05
            local isSpace=(curTheme=="space")
            for _,s in ipairs(starObjs) do pcall(function()
                local pulse=0.5+0.5*math.sin(t*s.speed+s.phase)
                s.obj.Visible=uiVisible and isSpace
                s.obj.Color=Color3.fromHSV(accentH,accentS*(0.3+0.4*pulse),0.8+0.2*pulse)
                s.obj.Radius=s.sz*(0.7+0.6*pulse)
                s.obj.Transparency=0.05+0.4*(1-pulse)
                -- tiny float
                s.obj.Position=Vector2.new(
                    s.ox+math.sin(t*0.4+s.phase)*2,
                    s.oy+math.cos(t*0.3+s.phase)*1.5)
            end) end
        end
    end)

    -- ══════════════════════════════════════════════════════
    -- NOTIFICATIONS
    -- ══════════════════════════════════════════════════════
    local NW=math.max(220,math.floor(SW/6.2))
    local NH=62 local NXf=SW-NW-14 local NYf=68 local NDUR=9
    local nQ={} local nBusy=false

    local function showN()
        if nBusy or #nQ==0 then return end
        nBusy=true
        local n=table.remove(nQ,1)
        local obs={}
        local sy2=SH+10
        local pal=PAL()
        local function aO(o) obs[#obs+1]=o end
        aO(Draw.Rect   (NXf,sy2,NW,NH,   pal.notifBg,50))
        aO(Draw.Outline(NXf,sy2,NW,NH,   n.col,1.5,  51))
        aO(Draw.Rect   (NXf+4,sy2+5,3,NH-10,n.col,   51))
        aO(Draw.Text   (NXf+13,sy2+11,n.t,pal.white,13,52))
        aO(Draw.Text   (NXf+13,sy2+28,n.m,pal.muted,10,52))
        local stars={}
        for _=1,4 do
            local s=Draw.Rect(NXf+math.random(8,NW-8),sy2+math.random(4,NH-4),2,2,n.col,53)
            aO(s) stars[#stars+1]={o=s,ox=0,oy=0,t2=math.random()*math.pi*2}
        end
        Draw.SetVisible(obs,true)
        local function setY2(ny2)
            local dy=ny2-obs[1].Position.Y
            for _,o in ipairs(obs) do pcall(function()
                if o.Position then o.Position=Vector2.new(o.Position.X,o.Position.Y+dy) end
            end) end
            for _,s in ipairs(stars) do s.oy=(s.oy or 0)+dy end
        end
        task.spawn(function()
            for i=1,20 do task.wait(0.025) setY2(sy2+(NYf-sy2)*(1-(1-i/20)^3)) end
            setY2(NYf)
            for _,s in ipairs(stars) do s.ox=s.o.Position.X s.oy=s.o.Position.Y end
            local el=0
            while el<NDUR do
                task.wait(0.05) el=el+0.05
                for _,s in ipairs(stars) do pcall(function()
                    s.o.Position=Vector2.new(
                        s.ox+math.sin(el*2+s.t2)*4,
                        s.oy+math.cos(el*1.4+s.t2)*2)
                end) end
            end
            local cx0=NXf
            for i=1,16 do
                task.wait(0.025)
                local ox=cx0+i*(NW+60)/16
                for _,o in ipairs(obs) do pcall(function()
                    if o.Position then o.Position=Vector2.new(ox,o.Position.Y) end
                end) end
            end
            Draw.Destroy(obs) nBusy=false task.wait(0.3) showN()
        end)
    end
    local function qN(t,m,col) nQ[#nQ+1]={t=t,m=m,col=col} showN() end

    -- ══════════════════════════════════════════════════════
    -- INPUT LOOP
    -- ══════════════════════════════════════════════════════
    task.spawn(function()
        local prevLMB=false local prevTog=false
        local dragOn=false local dOX,dOY=0,0

        while true do
            task.wait(0.033)
            if not uiReady then continue end
            local mx,my=MX(),MY()
            local lmb=LMB()
            local togDown=isToggleDown()

            if bindingMode then scanBind() end

            -- [FIX-BIND] no toggle while binding
            if togDown and not prevTog and not bindingMode then
                uiVisible=not uiVisible
                -- [FIX-REOPEN] full explicit pass over ALL objects
                Draw.SetVisible(frameObjs,uiVisible)
                Draw.SetVisible(pickerObjs,uiVisible and pickerActive)
                Draw.SetVisible(ddObjs,uiVisible and ddOpen)
                for _,p in ipairs(partObjs) do
                    pcall(function() p.Visible=uiVisible and curTheme=="sakura" end)
                end
                if uiVisible then
                    rebuildAllUL()
                    buildStars()
                end
            end
            prevTog=togDown

            if dragOn then
                if lmb then
                    local tWX=mx-dOX local tWY=my-dOY
                    local dx=math.floor((tWX-WX)*0.65)
                    local dy=math.floor((tWY-WY)*0.65)
                    if math.abs(dx)+math.abs(dy)>0 then
                        WX=WX+dx WY=WY+dy
                        Draw.Move(frameObjs,dx,dy)
                        Draw.Move(pickerObjs,dx,dy)
                        Draw.Move(ddObjs,dx,dy)
                        for _,z in ipairs(gZones) do z.x=z.x+dx z.y=z.y+dy end
                        for _,tzl in pairs(tZones) do
                            for _,z in ipairs(tzl) do z.x=z.x+dx z.y=z.y+dy end
                        end
                        -- move star base positions
                        for _,s in ipairs(starObjs) do
                            s.ox=s.ox+dx s.oy=s.oy+dy
                        end
                        -- update LED rect
                        for _,ld in ipairs(cardLedDots) do
                            ld.x=ld.x+dx ld.y=ld.y+dy
                        end
                    end
                else dragOn=false end
            end

            -- [FIX-INPUT-SINK] click: sink if inside UI
            if lmb and not prevLMB then
                if uiVisible then
                    local sunk=hitTest(mx,my)
                    if not sunk and mx>=WX and mx<=WX+WW and my>=WY and my<=WY+TBARH then
                        dragOn=true dOX=mx-WX dOY=my-WY
                    end
                    -- if sunk=true, game won't receive mouse (input consumed by UI)
                elseif not uiVisible then
                    -- UI hidden, pass through to game
                end
            end
            prevLMB=lmb
        end
    end)

    -- ══════════════════════════════════════════════════════
    -- PUBLIC API
    -- ══════════════════════════════════════════════════════
    function UI.Init()
        task.spawn(function()
            makeDefaultTabs()
            buildWindow()
            buildStars()
            Draw.SetVisible(frameObjs,true)
            uiReady=true uiVisible=true
            if UI._onReady then UI._onReady() end
        end)
    end

    local _dq={}
    UI._onReady=function()
        UI._onReady=nil
        for _,f in ipairs(_dq) do pcall(f) end table.clear(_dq)
    end
    local function defer(fn)
        if uiReady then pcall(fn) else _dq[#_dq+1]=fn end
    end

    function UI.LoadGameModule(gm)
        defer(function()
            dynName=gm.Name or dynName dynVer=gm.Version or dynVer
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
                activeTab=1 currentTabs=newTabs
                buildWindow() buildStars()
                Draw.SetVisible(frameObjs,uiVisible)
            end
        end)
    end

    local function getCol(tp)
        local pal=PAL()
        if tp=="success" then return pal.green
        elseif tp=="warning" then return pal.yellow
        elseif tp=="error"   then return pal.red end
        return AC()
    end
    function UI.ShowWelcome()        defer(function() qN("EXE.HUB","ExeHub is active",AC()) end) end
    function UI.ShowGameDetected(n)  defer(function() qN("Game Detected",n,PAL().green) end) end
    function UI.ShowGameLoaded(n,v)
        dynName=n or dynName dynVer=v or dynVer
        defer(function()
            if lblGame then pcall(function() lblGame.Text=dynName end) end
            if lblVer  then pcall(function() lblVer.Text=dynVer end) end
        end)
    end
    function UI.ShowNotSupported(id) defer(function() qN("Not Supported","PlaceId: "..tostring(id),PAL().yellow) end) end
    function UI.ShowLoadError(n)     defer(function() qN("Load Error",tostring(n),PAL().red) end) end
    function UI.Notify(t,m,tp)
        defer(function() qN(t,m,getCol(tp)) end)
    end
    function UI.Destroy()
        uiReady=false Draw.DestroyAll()
        table.clear(frameObjs) table.clear(contentAll)
        table.clear(glowLines) table.clear(accentObjs)
        table.clear(partObjs) table.clear(starObjs)
        clearZones()
    end
end

-- ══════════════════════════════════════════════════════════
-- MODULE LOADER
-- ══════════════════════════════════════════════════════════
_G.__EXE_HUB_MODULES={}
local function loadModule(path)
    local url=BASE..path.."?t="..tostring(math.floor(tick()))
    local raw pcall(function() raw=game:HttpGet(url,true) end)
    if not raw or raw=="" then err("HTTP failed: "..path) return nil end
    local fn,e=loadstring(raw)
    if not fn then err("Compile error: "..path.." -- "..tostring(e)) return nil end
    local ok,r=pcall(fn)
    if not ok then err("Exec error: "..path.." -- "..tostring(r)) return nil end
    if r~=nil then return r end
    local key=path:match("([^/]+)%.lua$")
    if key and _G.__EXE_HUB_MODULES[key] then
        local m=_G.__EXE_HUB_MODULES[key]
        _G.__EXE_HUB_MODULES[key]=nil return m
    end
    err("Module returned nil: "..path) return nil
end

local function loadGame(info)
    if not info then return end
    UI.ShowGameDetected(info.name)
    local gm=loadModule(info.module)
    if not gm then UI.ShowLoadError(info.name) return end
    gm.Name=gm.Name or info.name gm.Version=gm.Version or info.version
    if type(gm.Init)=="function" then
        local ok,e=pcall(function() gm.Init({UI=UI,log=log,err=err}) end)
        if not ok then UI.ShowLoadError(info.name) err(tostring(e)) return end
    end
    UI.ShowGameLoaded(gm.Name,gm.Version)
    UI.LoadGameModule(gm)
end

-- ══════════════════════════════════════════════════════════
-- LAUNCH
-- ══════════════════════════════════════════════════════════
UI.Init()
UI.ShowWelcome()
local pId=game.PlaceId
if GAMES[pId] then loadGame(GAMES[pId])
else UI.ShowNotSupported(pId) end