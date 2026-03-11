-- ╔══════════════════════════════════════════════════════════╗
-- ║         EXE.HUB  v3.2  —  Drawing API  (Matcha)        ║
-- ╚══════════════════════════════════════════════════════════╝
-- Engine : task.spawn + task.wait  (Heartbeat dead on Matcha)
-- LMB    : ismouse1pressed() polling + rising edge
-- Toggle : game:GetService("UserInputService"):IsKeyDown()
-- Default toggle key : P
-- Language : English

local BASE = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"

local RealUIS = game:GetService("UserInputService")

-- ── Utils ─────────────────────────────────────────────────
local function log(m)  print("[EXE.HUB] "..tostring(m)) end
local function err(m)  warn("[EXE.HUB] ERR: "..tostring(m)) end

-- ── Registry ──────────────────────────────────────────────
local GAMES = {
    [14890802310] = {name="Bizarre Lineage",version="v1.0.0",module="games/bizarre_lineage.lua"},
}

-- ══════════════════════════════════════════════════════════
-- DRAW MODULE
-- ══════════════════════════════════════════════════════════
local Draw = {}
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
        o.Color=col o.Filled=false o.Thickness=thick or 1.5
        o.Transparency=1 o.ZIndex=z or 2 o.Visible=false
        return o
    end
    function Draw.Text(x,y,str,col,sz,z)
        local o=reg(Drawing.new("Text"))
        o.Position=Vector2.new(x,y) o.Text=tostring(str)
        o.Color=col o.Size=sz or 12 o.ZIndex=z or 3
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
            for i,p in ipairs(pool) do if p==o then table.remove(pool,i) break end end
        end
        table.clear(list)
    end
    function Draw.Move(list,dx,dy)
        for _,o in ipairs(list) do pcall(function()
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

-- ══════════════════════════════════════════════════════════
-- UI
-- ══════════════════════════════════════════════════════════
local UI = {}
do
    -- screen
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

    -- ── Keybind ───────────────────────────────────────────
    local toggleKC    = Enum.KeyCode.P   -- default P
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
        if bindingMode then return false end  -- NEVER trigger while binding
        local ok,r=pcall(function() return RealUIS:IsKeyDown(toggleKC) end)
        return ok and r or false
    end

    local function scanBind()
        for _,k in ipairs(LETTERS) do
            local ok,r=pcall(function() return RealUIS:IsKeyDown(k.kc) end)
            if ok and r then
                toggleKC=k.kc toggleLabel=k.l bindingMode=false
                if bindLblRef then
                    pcall(function()
                        bindLblRef.Text="Current Key :  [ "..toggleLabel.." ]"
                        bindLblRef.Color=Color3.fromRGB(180,140,220)
                    end)
                end
                return
            end
        end
    end

    -- ── Themes ────────────────────────────────────────────
    local THEMES={
        sakura={name="Sakura",acH=330/360,acS=0.70,acV=0.95,
            bg=Color3.fromRGB(10,8,16),panel=Color3.fromRGB(14,12,22)},
        space ={name="Space", acH=220/360,acS=0.80,acV=1.00,
            bg=Color3.fromRGB(4,5,14), panel=Color3.fromRGB(7,9,20)},
    }
    local curTheme="sakura"
    local accentH=THEMES.sakura.acH
    local accentS=THEMES.sakura.acS
    local accentV=THEMES.sakura.acV

    local function AC()  return Color3.fromHSV(accentH,accentS,accentV) end
    local function ACL() return Color3.fromHSV(accentH,accentS*0.55,1.0) end  -- light accent
    local function partCol() return Color3.fromHSV(accentH,accentS*0.5,1.0) end

    local function applyThemePreset(key)
        local t=THEMES[key] if not t then return end
        curTheme=key
        accentH,accentS,accentV=t.acH,t.acS,t.acV
    end

    -- ── Color palette (computed from theme) ──────────────
    local function P()
        local t=THEMES[curTheme] or THEMES.sakura
        return {
            bg      =t.bg,
            panel   =t.panel,
            titleBg =Color3.fromRGB(7,6,12),
            tabBg   =Color3.fromRGB(16,14,24),
            tabSel  =Color3.fromRGB(26,20,38),
            border  =Color3.fromRGB(36,24,50),
            -- card colors (reference image: dark bg, pink/purple border)
            cardBg  =Color3.fromRGB(18,16,28),
            cardBrd =Color3.fromRGB(180,50,180),  -- hot pink/purple like ref
            cardTitleBg=Color3.fromRGB(100,20,100),
            white   =Color3.fromRGB(220,218,235),
            muted   =Color3.fromRGB(140,120,160),
            dimmed  =Color3.fromRGB(70,60,90),
            green   =Color3.fromRGB(80,200,120),
            yellow  =Color3.fromRGB(235,180,60),
            red     =Color3.fromRGB(235,70,70),
            cyan    =Color3.fromRGB(60,200,220),
            notifBg =Color3.fromRGB(10,8,18),
            on      =Color3.fromRGB(80,200,120),
            off     =Color3.fromRGB(50,45,65),
        }
    end

    -- ── Dimensions ────────────────────────────────────────
    -- Wider window to support 2-column card layout
    local WW   = math.max(420, math.floor(SW/4.2))
    local WH   = math.max(480, math.floor(SH/2.4))
    local WX   = math.floor(SW/2-WW/2)
    local WY   = math.floor(SH/2-WH/2)
    local TH   = 32   -- title bar height
    local TABH = 26   -- tab bar height
    local CONTY= TH+TABH
    local PAD  = 10

    -- ── State ─────────────────────────────────────────────
    local uiReady   = false
    local uiVisible = true
    local activeTab = 1
    local currentTabs={}

    local frameObjs={}   -- all chrome + content objects
    local glowLines={}
    local tabBtnData={}  -- [i]={bg,lbl,ul}
    local tabContent={}  -- [i]=list of Drawing objects
    local accentObjs={}  -- {obj,"ac"|"acl"}
    local partObjs={}

    -- [FIX-OVERLAP] per-tab zones + global zones
    local gZones={}
    local tZones={}

    -- overlay objects
    local pickerObjs={}  local pickerActive=false
    local ddObjs={}      local ddOpen=false
    local swatchRef=nil

    -- feature toggles (persist across tab switches)
    local fToggles={}
    local function FT(k) return fToggles[k] or false end
    local function setFT(k,v) fToggles[k]=v end

    local dynName="—" local dynVer="—"
    local lblGame,lblVer

    -- forward decl
    local buildWindow,applyTheme,destroyPicker,destroyDD

    -- ── Zone helpers ──────────────────────────────────────
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
    local function hitTest(mx,my)
        local list={}
        for _,z in ipairs(gZones) do list[#list+1]=z end
        if tZones[activeTab] then
            for _,z in ipairs(tZones[activeTab]) do list[#list+1]=z end
        end
        for _,z in ipairs(list) do
            if mx>=z.x and mx<=z.x+z.w and my>=z.y and my<=z.y+z.h then
                pcall(z.fn) return
            end
        end
    end

    -- ── Accent tracking ───────────────────────────────────
    local function regAC(o)  accentObjs[#accentObjs+1]={obj=o,r="ac"}  return o end
    local function regACL(o) accentObjs[#accentObjs+1]={obj=o,r="acl"} return o end

    applyTheme=function()
        local ac,acl=AC(),ACL()
        for _,e in ipairs(accentObjs) do pcall(function()
            e.obj.Color=(e.r=="acl") and acl or ac
        end) end
        for _,gl in ipairs(glowLines) do pcall(function() gl.Color=ac end) end
        -- [FIX-UL] Option A: only active tab gets underline
        for i,bd in pairs(tabBtnData) do pcall(function()
            bd.ul.Color=ac
            bd.ul.Visible=(i==activeTab)
        end) end
        for _,p in ipairs(partObjs) do pcall(function() p.Color=partCol() end) end
        if swatchRef then pcall(function() swatchRef.Color=ac end) end
    end

    -- ── Color picker ──────────────────────────────────────
    local PW=WW-PAD*2 local PH=72 local VH=12

    destroyPicker=function()
        Draw.Destroy(pickerObjs) pickerActive=false
    end

    local function buildPicker(cx,cy,sw)
        destroyPicker() pickerActive=true swatchRef=sw
        local hS,sS=48,9
        local cw2=math.floor(PW/hS) local ch2=math.floor(PH/sS)
        for hi=0,hS-1 do for si=0,sS-1 do
            local sq=Draw.Rect(cx+hi*cw2,cy+si*ch2,cw2+1,ch2+1,
                Color3.fromHSV(hi/hS,1-si/sS,accentV),30)
            sq.Visible=true pickerObjs[#pickerObjs+1]=sq
        end end
        local vy=cy+PH+3
        for vi=0,23 do
            local sq=Draw.Rect(cx+vi*math.floor(PW/24),vy,math.floor(PW/24)+1,VH,
                Color3.fromHSV(accentH,accentS,(vi+1)/24),30)
            sq.Visible=true pickerObjs[#pickerObjs+1]=sq
        end
        local cur=Draw.Outline(
            cx+math.floor(accentH*PW)-4,cy+math.floor((1-accentS)*PH)-4,
            8,8,Color3.new(1,1,1),1.5,32)
        cur.Visible=true pickerObjs[#pickerObjs+1]=cur
        Draw.SetVisible({Draw.Outline(cx,cy,PW,PH+3+VH,P().border,1.5,31)},true)
        addGZ(cx,cy,PW,PH,function()
            local mx2,my2=MX(),MY()
            accentH=math.max(0,math.min(0.9999,(mx2-cx)/PW))
            accentS=math.max(0.01,math.min(1,1-(my2-cy)/PH))
            pcall(function()
                cur.Position=Vector2.new(
                    cx+math.floor(accentH*PW)-4,
                    cy+math.floor((1-accentS)*PH)-4)
            end)
            applyTheme()
        end)
        addGZ(cx,vy,PW,VH,function()
            accentV=math.max(0.05,math.min(1,(MX()-cx+1)/PW))
            applyTheme()
        end)
    end

    -- ── Theme dropdown ────────────────────────────────────
    destroyDD=function() Draw.Destroy(ddObjs) ddOpen=false end

    local function buildDD(cx,cy)
        destroyDD() ddOpen=true
        local IH=24
        local thList={{key="sakura",name="  Sakura  🌸"},{key="space",name="  Space   ✦"}}
        for i,t in ipairs(thList) do
            local iy=cy+(i-1)*IH
            local col=Color3.fromHSV(THEMES[t.key].acH,THEMES[t.key].acS,THEMES[t.key].acV)
            local bg=Draw.Rect(cx,iy,PW,IH,P().tabBg,35) bg.Visible=true ddObjs[#ddObjs+1]=bg
            local dot=Draw.Rect(cx+8,iy+7,10,10,col,36) dot.Visible=true ddObjs[#ddObjs+1]=dot
            local lbl=Draw.Text(cx+24,iy+6,t.name,P().white,11,36) lbl.Visible=true ddObjs[#ddObjs+1]=lbl
            local sep=Draw.Line(cx,iy+IH-1,cx+PW,iy+IH-1,P().border,1,36) sep.Visible=true ddObjs[#ddObjs+1]=sep
            local tk=t.key
            addGZ(cx,iy,PW,IH,function()
                applyThemePreset(tk) destroyDD() destroyPicker()
                applyTheme() buildWindow()
                Draw.SetVisible(frameObjs,uiVisible)
            end)
        end
        local brd=Draw.Outline(cx,cy,PW,#thList*IH,P().border,1.5,36) brd.Visible=true ddObjs[#ddObjs+1]=brd
    end

    -- ════════════════════════════════════════════════════
    -- CARD SYSTEM  (reference image style)
    -- Each card: pink/purple outline, dark title bar, content inside
    -- ════════════════════════════════════════════════════
    -- makeCard returns a builder table with helpers
    local function makeCard(objs,addZ, cx,sy,cw,title)
        local col=P()
        local CP=7  -- card inner padding
        local TBH=16 -- card title bar height

        local bg  = Draw.Rect(cx,sy,cw,0,col.cardBg,4)       objs[#objs+1]=bg
        local brd = Draw.Outline(cx,sy,cw,0,col.cardBrd,1,5) objs[#objs+1]=brd
        local tbg = Draw.Rect(cx,sy,cw,TBH,col.cardTitleBg,5) objs[#objs+1]=tbg
        local tlbl= Draw.Text(cx+CP,sy+3,title,Color3.fromRGB(230,200,240),9,6) objs[#objs+1]=tlbl

        local contentX=cx+CP
        local contentW=cw-CP*2
        local contentY=sy+TBH+CP

        return {
            cx=contentX, cw=contentW, cy=contentY,
            startY=sy,
            finalize=function(endY)
                local h=endY-sy+CP
                pcall(function() bg.Size=Vector2.new(cw,h) end)
                pcall(function() brd.Size=Vector2.new(cw,h) end)
            end,
        }
    end

    -- Small label-value row inside a card
    local function cardLabel(objs,cx,y,label,value,col)
        local c=col or P()
        objs[#objs+1]=Draw.Text(cx,y,label,c.muted,9,6)
        if value then
            objs[#objs+1]=Draw.Text(cx,y+12,tostring(value),c.white,10,6)
            return y+26
        end
        return y+14
    end

    -- Toggle button (full width, ON/OFF)
    local function cardToggle(objs,addZ,cx,y,cw,key,label)
        local col=P()
        local isOn=FT(key)
        local h=20
        local bg=Draw.Rect(cx,y,cw,h,isOn and col.on or col.off,6)
        objs[#objs+1]=bg
        local lbl=Draw.Text(cx+8,y+5,label.." : "..(isOn and "ON" or "OFF"),
            isOn and Color3.fromRGB(10,10,10) or col.white,10,7)
        objs[#objs+1]=lbl
        addZ(cx,y,cw,h,function()
            local v=not FT(key) setFT(key,v)
            local c2=P()
            pcall(function()
                bg.Color=v and c2.on or c2.off
                lbl.Text=label.." : "..(v and "ON" or "OFF")
                lbl.Color=v and Color3.fromRGB(10,10,10) or c2.white
            end)
        end)
        return y+h+4
    end

    -- Action button (full width, accent colored)
    local function cardButton(objs,addZ,cx,y,cw,label,fn)
        local col=P()
        local h=20
        local bg=Draw.Rect(cx,y,cw,h,Color3.fromRGB(60,20,80),6)
        objs[#objs+1]=bg
        local brd=Draw.Outline(cx,y,cw,h,col.cardBrd,1,7)
        objs[#objs+1]=brd
        local lbl=Draw.Text(cx+8,y+5,label,col.white,10,7)
        objs[#objs+1]=lbl
        addZ(cx,y,cw,h,fn or function() end)
        return y+h+4
    end

    -- ════════════════════════════════════════════════════
    -- SWITCH TAB
    -- ════════════════════════════════════════════════════
    local function switchTab(idx)
        if not currentTabs[idx] then return end

        -- [FIX-REOPEN] hide old content completely
        if tabContent[activeTab] then
            Draw.SetVisible(tabContent[activeTab],false)
        end

        -- deactivate old tab button + hide its underline [FIX-UL]
        local old=tabBtnData[activeTab]
        if old then
            old.bg.Color=P().tabBg
            old.lbl.Color=P().muted
            old.ul.Visible=false  -- hide underline on inactive
        end

        destroyPicker() destroyDD()
        activeTab=idx

        -- build content on first visit
        if not tabContent[activeTab] then
            tabContent[activeTab]={}
            tZones[activeTab]={}
            local tab=currentTabs[activeTab]
            if tab and type(tab.buildFn)=="function" then
                local cx0=WX+PAD
                local cy0=WY+CONTY+PAD
                local cw0=WW-PAD*2
                local ctx={
                    cx=cx0,cy=cy0,cw=cw0,ch=WH-CONTY-PAD*2,
                    C=P(),AC=AC,ACL=ACL,PAD=PAD,Draw=Draw,
                    objs=tabContent[activeTab],
                    addZone=function(x,y,w,h,fn) addTZ(activeTab,x,y,w,h,fn) end,
                    addGZ=addGZ,
                    card=function(x,y,w,t2)
                        return makeCard(tabContent[activeTab],
                            function(x2,y2,w2,h2,fn2) addTZ(activeTab,x2,y2,w2,h2,fn2) end,
                            x,y,w,t2)
                    end,
                    toggle=function(x,y,w,key,lbl)
                        return cardToggle(tabContent[activeTab],
                            function(x2,y2,w2,h2,fn2) addTZ(activeTab,x2,y2,w2,h2,fn2) end,
                            x,y,w,key,lbl)
                    end,
                    button=function(x,y,w,lbl,fn2)
                        return cardButton(tabContent[activeTab],
                            function(x2,y2,w2,h2,fn3) addTZ(activeTab,x2,y2,w2,h2,fn3) end,
                            x,y,w,lbl,fn2)
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
                end
            end
        end

        -- show new content [FIX-REOPEN]
        Draw.SetVisible(tabContent[activeTab],uiVisible)

        -- activate new tab button + show underline [FIX-UL]
        local nw=tabBtnData[activeTab]
        if nw then
            nw.bg.Color=P().tabSel
            nw.lbl.Color=ACL()
            nw.ul.Color=AC()
            nw.ul.Visible=true  -- ONLY the active tab
        end
    end

    -- ════════════════════════════════════════════════════
    -- BUILD WINDOW
    -- ════════════════════════════════════════════════════
    buildWindow=function()
        destroyPicker() destroyDD()

        for _,o in ipairs(frameObjs) do pcall(function() o:Remove() end) end
        table.clear(frameObjs)
        table.clear(glowLines)
        table.clear(tabBtnData)
        table.clear(accentObjs)
        for _,tc in pairs(tabContent) do
            for _,o in ipairs(tc) do pcall(function() o:Remove() end) end
        end
        table.clear(tabContent)
        clearZones()
        swatchRef=nil bindLblRef=nil

        local col=P()
        local x,y=WX,WY
        local ac=AC()

        -- window background
        frameObjs[#frameObjs+1]=Draw.Rect(x,y,WW,WH,col.bg,1)

        -- title bar
        frameObjs[#frameObjs+1]=Draw.Rect(x,y,WW,TH,col.titleBg,2)
        local ht=regACL(Draw.Text(x+PAD,y+9,"EXE.HUB",ACL(),13,5))
        frameObjs[#frameObjs+1]=ht
        frameObjs[#frameObjs+1]=Draw.Line(x+84,y+7,x+84,y+TH-7,col.border,1,4)
        lblGame=Draw.Text(x+90,y+10,dynName,col.muted,10,5)
        frameObjs[#frameObjs+1]=lblGame
        lblVer=Draw.Text(x+WW-54,y+10,dynVer,col.dimmed,9,5)
        frameObjs[#frameObjs+1]=lblVer
        frameObjs[#frameObjs+1]=Draw.Line(x,y+TH,x+WW,y+TH,col.border,1,3)

        -- tab bar
        local nT=#currentTabs
        local tabW=math.floor(WW/math.max(nT,1))
        local tabY=y+TH
        for i,tab in ipairs(currentTabs) do
            local tx=x+(i-1)*tabW
            local isSel=(i==activeTab)
            local tbg=Draw.Rect(tx,tabY,tabW,TABH,isSel and col.tabSel or col.tabBg,2)
            frameObjs[#frameObjs+1]=tbg
            if i>1 then
                frameObjs[#frameObjs+1]=Draw.Line(tx,tabY+4,tx,tabY+TABH-4,col.border,1,3)
            end
            -- center tab label
            local lx=tx+math.floor(tabW/2)-math.floor(#tab.name*3.0)
            local tlbl=Draw.Text(lx,tabY+8,tab.name,isSel and ACL() or col.muted,10,4)
            if isSel then regACL(tlbl) end
            frameObjs[#frameObjs+1]=tlbl

            -- [FIX-UL] Option A: underline ONLY on selected tab
            local tul=Draw.Line(tx+3,tabY+TABH-2,tx+tabW-3,tabY+TABH-2,ac,2,4)
            tul.Visible=isSel  -- set at creation, never modified by applyTheme except color
            frameObjs[#frameObjs+1]=tul
            tabBtnData[i]={bg=tbg,lbl=tlbl,ul=tul}

            local ci=i
            addGZ(tx,tabY,tabW,TABH,function() switchTab(ci) end)
        end

        -- content area
        frameObjs[#frameObjs+1]=Draw.Line(x,y+CONTY,x+WW,y+CONTY,col.border,1,3)
        frameObjs[#frameObjs+1]=Draw.Rect(x,y+CONTY,WW,WH-CONTY,col.panel,1)
        frameObjs[#frameObjs+1]=Draw.Outline(x,y,WW,WH,col.border,1,3)

        -- glow lines
        local function gl(x1,y1,x2,y2)
            local l=Draw.Line(x1,y1,x2,y2,ac,1.5,4)
            l.Transparency=0.7
            frameObjs[#frameObjs+1]=l
            glowLines[#glowLines+1]=l
        end
        gl(x,y,   x+WW,y   ) gl(x+WW,y,   x+WW,y+WH)
        gl(x+WW,y+WH,x,y+WH) gl(x,y+WH,   x,   y   )

        -- build active tab content
        tabContent[activeTab]={}
        tZones[activeTab]={}
        local tab=currentTabs[activeTab]
        if tab and type(tab.buildFn)=="function" then
            local cx0=WX+PAD
            local cy0=WY+CONTY+PAD
            local cw0=WW-PAD*2
            local ctx={
                cx=cx0,cy=cy0,cw=cw0,ch=WH-CONTY-PAD*2,
                C=col,AC=AC,ACL=ACL,PAD=PAD,Draw=Draw,
                objs=tabContent[activeTab],
                addZone=function(x2,y2,w2,h2,fn2) addTZ(activeTab,x2,y2,w2,h2,fn2) end,
                addGZ=addGZ,
                card=function(x2,y2,w2,t2)
                    return makeCard(tabContent[activeTab],
                        function(xa,ya,wa,ha,fna) addTZ(activeTab,xa,ya,wa,ha,fna) end,
                        x2,y2,w2,t2)
                end,
                toggle=function(x2,y2,w2,key,lbl2)
                    return cardToggle(tabContent[activeTab],
                        function(xa,ya,wa,ha,fna) addTZ(activeTab,xa,ya,wa,ha,fna) end,
                        x2,y2,w2,key,lbl2)
                end,
                button=function(x2,y2,w2,lbl2,fn2)
                    return cardButton(tabContent[activeTab],
                        function(xa,ya,wa,ha,fna) addTZ(activeTab,xa,ya,wa,ha,fna) end,
                        x2,y2,w2,lbl2,fn2)
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
            end
        end
    end

    -- ════════════════════════════════════════════════════
    -- DEFAULT TABS
    -- ════════════════════════════════════════════════════
    local function makeDefaultTabs()

        -- helper: two-column row of cards
        -- returns left card, right card, given a y position
        local function twoCol(ctx,sy,leftTitle,rightTitle)
            local half=math.floor((ctx.cw-6)/2)
            local lc=ctx.card(ctx.cx,sy,half,leftTitle)
            local rc=ctx.card(ctx.cx+half+6,sy,half,rightTitle)
            return lc,rc
        end

        -- ── Tab 1: Main ───────────────────────────────
        local tabMain={name="Main",buildFn=function(ctx)
            local o,D,col=ctx.objs,ctx.Draw,ctx.C
            local sy=ctx.cy
            local half=math.floor((ctx.cw-6)/2)

            -- Row 1: Auto Farm | ESP
            local afCard=ctx.card(ctx.cx,sy,half,"AUTO FARM")
            local espCard=ctx.card(ctx.cx+half+6,sy,half,"ESP")

            -- Auto Farm content
            local ay=afCard.cy
            o[#o+1]=D.Text(afCard.cx,ay,"Mob Target :",col.muted,9,6)
            ay=ay+12
            -- mob selector placeholder (will be updated when mobs provided)
            local mobBg=D.Rect(afCard.cx,ay,afCard.cw,18,col.tabBg,6)
            o[#o+1]=mobBg
            o[#o+1]=D.Outline(afCard.cx,ay,afCard.cw,18,P().cardBrd,1,7)
            o[#o+1]=D.Text(afCard.cx+4,ay+4,"▼  All Mobs",col.white,9,7)
            ay=ay+22
            ay=ctx.toggle(afCard.cx,ay,afCard.cw,"autoFarm","Auto Farm")
            afCard.finalize(ay)

            -- ESP content
            local ey=espCard.cy
            ey=ctx.toggle(espCard.cx,ey,espCard.cw,"espMob",   "ESP Mob   ")
            ey=ctx.toggle(espCard.cx,ey,espCard.cw,"espPlayer","ESP Player")
            ey=ctx.toggle(espCard.cx,ey,espCard.cw,"espItem",  "ESP Item  ")
            ey=ey+4
            o[#o+1]=D.Text(espCard.cx,ey,"ESP Colors :",col.muted,9,6)
            ey=ey+12
            -- color swatch buttons
            local sw2=math.floor((espCard.cw-4)/2)
            local mobSwt=D.Rect(espCard.cx,ey,sw2,14,Color3.fromRGB(255,80,80),7)
            o[#o+1]=mobSwt
            o[#o+1]=D.Text(espCard.cx+2,ey+3,"Mob",Color3.new(1,1,1),8,8)
            local plSwt=D.Rect(espCard.cx+sw2+4,ey,sw2,14,Color3.fromRGB(80,180,255),7)
            o[#o+1]=plSwt
            o[#o+1]=D.Text(espCard.cx+sw2+6,ey+3,"Player",Color3.new(1,1,1),8,8)
            ey=ey+18
            espCard.finalize(ey)

            local bottomY=math.max(
                afCard.startY+(afCard.cy-afCard.startY+(ay-afCard.cy)),
                espCard.startY+(espCard.cy-espCard.startY+(ey-espCard.cy))
            )
            -- use max finalized bottom
            sy=math.max(ay,ey)+14

            -- Row 2: Status info (single full-width card)
            local stCard=ctx.card(ctx.cx,sy,ctx.cw,"STATUS")
            local sty=stCard.cy
            o[#o+1]=D.Text(stCard.cx,sty,"Game :",col.muted,9,6)
            o[#o+1]=D.Text(stCard.cx+40,sty,ctx.dynName(),col.white,10,6)
            sty=sty+14
            o[#o+1]=D.Text(stCard.cx,sty,"Version :",col.muted,9,6)
            o[#o+1]=D.Text(stCard.cx+50,sty,ctx.dynVer(),col.white,10,6)
            sty=sty+4
            stCard.finalize(sty+8)
        end}

        -- ── Tab 2: Items ──────────────────────────────
        local tabItems={name="Items",buildFn=function(ctx)
            local o,D,col=ctx.objs,ctx.Draw,ctx.C
            local sy=ctx.cy
            local half=math.floor((ctx.cw-6)/2)

            -- Row 1: Auto Collect | Auto Sell
            local col1=ctx.card(ctx.cx,sy,half,"AUTO COLLECT")
            local col2=ctx.card(ctx.cx+half+6,sy,half,"AUTO SELL")
            local y1=ctx.toggle(col1.cx,col1.cy,col1.cw,"autoCollect","Auto Collect")
            col1.finalize(y1)
            local y2=ctx.toggle(col2.cx,col2.cy,col2.cw,"autoSell","Auto Sell")
            col2.finalize(y2)
            sy=math.max(y1,y2)+10

            -- Row 2: Equip | Use
            local col3=ctx.card(ctx.cx,sy,half,"EQUIP ITEM")
            local col4=ctx.card(ctx.cx+half+6,sy,half,"USE ITEM")
            local y3=ctx.toggle(col3.cx,col3.cy,col3.cw,"autoEquip","Auto Equip")
            col3.finalize(y3)
            local y4=ctx.toggle(col4.cx,col4.cy,col4.cw,"autoUse","Auto Use")
            col4.finalize(y4)
            sy=math.max(y3,y4)+10

            -- Row 3: Drop (full width)
            local col5=ctx.card(ctx.cx,sy,ctx.cw,"DROP ITEM")
            local y5=ctx.toggle(col5.cx,col5.cy,col5.cw,"autoDrop","Auto Drop")
            col5.finalize(y5)
        end}

        -- ── Tab 3: Teleport ───────────────────────────
        local tabTp={name="Teleport",buildFn=function(ctx)
            local o,D,col=ctx.objs,ctx.Draw,ctx.C
            local sy=ctx.cy
            local half=math.floor((ctx.cw-6)/2)

            local function tpButton(card,y,label,dest)
                return ctx.button(card.cx,y,card.cw,label,function()
                    print("[TP] "..dest)
                end)
            end

            -- Row 1: Bus Stop | Mob Spawn
            local bs=ctx.card(ctx.cx,sy,half,"BUS STOP")
            local ms=ctx.card(ctx.cx+half+6,sy,half,"MOB SPAWN")
            local yb=tpButton(bs,bs.cy,"Teleport",  "BusStop")
            bs.finalize(yb)
            local ym=tpButton(ms,ms.cy,"Teleport","MobSpawn")
            ms.finalize(ym)
            sy=math.max(yb,ym)+10

            -- Row 2: NPC (full width, with Raid NPC subsection)
            local np=ctx.card(ctx.cx,sy,ctx.cw,"NPC")
            local ny=np.cy
            ny=tpButton(np,ny,"NPC — Main","NPC")
            o[#o+1]=D.Text(np.cx,ny,"  ╰ Raid NPC",col.muted,9,6)
            ny=ny+12
            ny=tpButton(np,ny,"Raid NPC","RaidNPC")
            np.finalize(ny)
        end}

        -- ── Tab 4: Settings ───────────────────────────
        local tabSettings={name="Settings",buildFn=function(ctx)
            local o,D,col=ctx.objs,ctx.Draw,ctx.C
            local sy=ctx.cy

            -- Card: Theme
            local thCard=ctx.card(ctx.cx,sy,ctx.cw,"THEME")
            local ty=thCard.cy

            -- swatch / dropdown trigger
            local swH=20
            local sw=D.Rect(thCard.cx,ty,thCard.cw,swH,AC(),5)
            regAC(sw) swatchRef=sw o[#o+1]=sw
            o[#o+1]=D.Text(thCard.cx+6,ty+5,"▼  "..THEMES[curTheme].name.." Theme",
                Color3.new(0,0,0),10,6)
            ctx.addZone(thCard.cx,ty,thCard.cw,swH,function()
                if ddOpen then destroyDD() else buildDD(thCard.cx,ty+swH+2) end
            end)
            ty=ty+swH+8

            o[#o+1]=D.Text(thCard.cx,ty,"Custom border/particle color :",col.muted,9,6)
            ty=ty+12
            local cpBg=D.Rect(thCard.cx,ty,thCard.cw,18,col.tabBg,5)
            o[#o+1]=cpBg
            o[#o+1]=D.Outline(thCard.cx,ty,thCard.cw,18,P().cardBrd,1,6)
            o[#o+1]=D.Text(thCard.cx+6,ty+4,"Open HSV Color Picker",col.white,10,6)
            ctx.addZone(thCard.cx,ty,thCard.cw,18,function()
                if pickerActive then destroyPicker()
                else buildPicker(thCard.cx,ty+22,sw) end
            end)
            ty=ty+24
            thCard.finalize(ty)
            sy=ty+10

            -- Card: Toggle Key
            local tkCard=ctx.card(ctx.cx,sy,ctx.cw,"TOGGLE KEY")
            local ky=tkCard.cy

            local bh=26
            local kbg=D.Rect(tkCard.cx,ky,tkCard.cw,bh,col.tabBg,5)
            o[#o+1]=kbg
            o[#o+1]=D.Outline(tkCard.cx,ky,tkCard.cw,bh,P().cardBrd,1,6)
            local klbl=D.Text(tkCard.cx+8,ky+7,
                "Current Key :  [ "..toggleLabel.." ]",
                Color3.fromRGB(180,140,220),12,6)
            o[#o+1]=klbl
            bindLblRef=klbl
            o[#o+1]=D.Text(tkCard.cx,ky+bh+4,
                "Click then press a key (A–Z) to rebind",col.dimmed,9,6)
            ctx.addZone(tkCard.cx,ky,tkCard.cw,bh,function()
                if bindingMode then
                    bindingMode=false
                    pcall(function()
                        klbl.Text="Current Key :  [ "..toggleLabel.." ]"
                        klbl.Color=Color3.fromRGB(180,140,220)
                    end)
                else
                    bindingMode=true
                    pcall(function()
                        klbl.Text="Waiting for key press…"
                        klbl.Color=Color3.fromRGB(235,185,60)
                    end)
                end
            end)
            ky=ky+bh+20
            tkCard.finalize(ky)
        end}

        -- ── Tab 5: Credits ────────────────────────────
        local tabCredits={name="Credits",buildFn=function(ctx)
            local o,D,col=ctx.objs,ctx.Draw,ctx.C
            local cr=ctx.card(ctx.cx,ctx.cy,ctx.cw,"CREDITS")
            local ry=cr.cy
            o[#o+1]=D.Text(cr.cx,ry,"Creator : me",col.white,12,6)
            ry=ry+18
            o[#o+1]=D.Text(cr.cx,ry,"EXE.HUB — Roblox Script Hub",col.muted,10,6)
            ry=ry+14
            o[#o+1]=D.Text(cr.cx,ry,"github.com/mattheube/EXE.HUB",col.dimmed,9,6)
            ry=ry+5
            cr.finalize(ry+10)
        end}

        -- ── Tab 6: Logs ───────────────────────────────
        local tabLogs={name="Logs",buildFn=function(ctx)
            local o,D,col=ctx.objs,ctx.Draw,ctx.C
            local lg=ctx.card(ctx.cx,ctx.cy,ctx.cw,"HUB UPDATES")
            local ly=lg.cy
            local lines={
                "v1.0  —  Initial release of the hub.",
                "More updates will be added here.",
            }
            for _,l in ipairs(lines) do
                o[#o+1]=D.Text(lg.cx,ly,l,col.white,10,6)
                ly=ly+14
            end
            lg.finalize(ly+4)
        end}

        currentTabs={tabMain,tabItems,tabTp,tabSettings,tabCredits,tabLogs}
    end

    -- ════════════════════════════════════════════════════
    -- GLOW LOOP
    -- ════════════════════════════════════════════════════
    task.spawn(function()
        local t=0
        while true do
            task.wait(0.05)
            if not uiReady or not uiVisible then continue end
            t=t+0.09
            local p=0.5+0.5*math.sin(t)
            local ac2=AC()
            for _,gl in ipairs(glowLines) do pcall(function()
                gl.Thickness=1+p*2.5
                gl.Transparency=0.20+0.74*(1-p)
                gl.Color=ac2
            end) end
        end
    end)

    -- ════════════════════════════════════════════════════
    -- PARTICLES  (Sakura petals / Space stars)
    -- ════════════════════════════════════════════════════
    local PMAX=20 local pCount=0

    local function spawnParticle()
        if pCount>=PMAX or not uiReady then return end
        pCount=pCount+1
        local isSakura=(curTheme=="sakura")
        local sz=isSakura and math.random(2,6) or math.random(1,2)
        local p=Drawing.new("Circle")
        p.Position=Vector2.new(WX+math.random(sz,WW-sz),WY+CONTY+sz)
        p.Radius=sz p.Color=partCol() p.Filled=true
        p.Transparency=math.random(20,55)/100 p.ZIndex=2 p.Visible=false
        partObjs[#partObjs+1]=p

        local steps=isSakura and math.random(70,180) or math.random(30,90)
        local dy=(WY+WH-4-(WY+CONTY))/steps
        local dx=(isSakura and math.random(-12,12) or math.random(-2,2))/steps
        local dA=(p.Transparency-0.96)/steps
        local phase=math.random()*math.pi*2
        local amp=isSakura and math.random(2,7)/steps or 0.3/steps

        task.spawn(function()
            for s=1,steps do
                task.wait(0.05)
                if not uiReady then break end
                pcall(function()
                    p.Visible=uiVisible p.Color=partCol()
                    p.Position=Vector2.new(
                        p.Position.X+dx+math.sin(phase+s*0.13)*amp,
                        p.Position.Y+dy)
                    p.Transparency=math.min(1,p.Transparency+dA)
                end)
            end
            pcall(function() p:Remove() end)
            for i,a in ipairs(partObjs) do if a==p then table.remove(partObjs,i) break end end
            pCount=pCount-1
        end)
    end

    task.spawn(function()
        while true do
            local w=curTheme=="sakura" and 1.0+math.random()*1.4 or 0.3+math.random()*0.6
            task.wait(w)
            if uiReady then pcall(spawnParticle) end
        end
    end)

    -- ════════════════════════════════════════════════════
    -- NOTIFICATIONS
    -- ════════════════════════════════════════════════════
    local NW=math.max(220,math.floor(SW/6.2))
    local NH=62 local NXf=SW-NW-14 local NYf=68 local NDUR=9
    local nQ={} local nBusy=false

    local function showN()
        if nBusy or #nQ==0 then return end
        nBusy=true
        local n=table.remove(nQ,1)
        local obs={}
        local sy2=SH+10
        local function aO(o) obs[#obs+1]=o end
        aO(Draw.Rect   (NXf,sy2,NW,NH,   P().notifBg,50))
        aO(Draw.Outline(NXf,sy2,NW,NH,   n.col,1.5,  51))
        aO(Draw.Rect   (NXf+4,sy2+5,3,NH-10,n.col,   51))
        aO(Draw.Text   (NXf+13,sy2+11,n.t, P().white,13,52))
        aO(Draw.Text   (NXf+13,sy2+28,n.m, P().muted,10,52))
        local stars={}
        for _=1,4 do
            local s=Draw.Rect(NXf+math.random(8,NW-8),sy2+math.random(4,NH-4),2,2,n.col,53)
            aO(s) stars[#stars+1]={o=s,ox=0,oy=0,t=math.random()*math.pi*2}
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
            for i=1,20 do
                task.wait(0.025)
                setY2(sy2+(NYf-sy2)*(1-(1-i/20)^3))
            end
            setY2(NYf)
            for _,s in ipairs(stars) do s.ox=s.o.Position.X s.oy=s.o.Position.Y end
            local el=0
            while el<NDUR do
                task.wait(0.05) el=el+0.05
                for _,s in ipairs(stars) do pcall(function()
                    s.o.Position=Vector2.new(s.ox+math.sin(el*2+s.t)*4,s.oy+math.cos(el*1.4+s.t)*2)
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
            Draw.Destroy(obs) nBusy=false
            task.wait(0.3) showN()
        end)
    end

    local function qN(t,m,col)
        nQ[#nQ+1]={t=t,m=m,col=col} showN()
    end

    -- ════════════════════════════════════════════════════
    -- INPUT LOOP
    -- ════════════════════════════════════════════════════
    task.spawn(function()
        local prevLMB=false local prevTog=false
        local dragOn=false local dOX,dOY=0,0

        while true do
            task.wait(0.033)
            if not uiReady then continue end

            local mx,my=MX(),MY()
            local lmb=LMB()
            local togDown=isToggleDown()

            -- [FIX-BIND] scan for new key while in bind mode
            if bindingMode then scanBind() end

            -- [FIX-BIND] toggle: never fires while binding
            if togDown and not prevTog and not bindingMode then
                uiVisible=not uiVisible
                Draw.SetVisible(frameObjs,uiVisible)
                Draw.SetVisible(pickerObjs,uiVisible and pickerActive)
                Draw.SetVisible(ddObjs,uiVisible and ddOpen)
                for _,p in ipairs(partObjs) do pcall(function() p.Visible=uiVisible end) end
                -- [FIX-UL] restore underline of active tab on reopen
                if uiVisible then
                    local bd=tabBtnData[activeTab]
                    if bd then bd.ul.Visible=true end
                end
            end
            prevTog=togDown

            -- drag
            if dragOn then
                if lmb then
                    local tWX=mx-dOX local tWY=my-dOY
                    local dx=math.floor((tWX-WX)*0.6)
                    local dy=math.floor((tWY-WY)*0.6)
                    if math.abs(dx)+math.abs(dy)>0 then
                        WX=WX+dx WY=WY+dy
                        Draw.Move(frameObjs,dx,dy)
                        Draw.Move(pickerObjs,dx,dy)
                        Draw.Move(ddObjs,dx,dy)
                        for _,z in ipairs(gZones) do z.x=z.x+dx z.y=z.y+dy end
                        for _,tzl in pairs(tZones) do
                            for _,z in ipairs(tzl) do z.x=z.x+dx z.y=z.y+dy end
                        end
                    end
                else dragOn=false end
            end

            -- click
            if lmb and not prevLMB and uiVisible then
                if mx>=WX and mx<=WX+WW and my>=WY and my<=WY+TH then
                    dragOn=true dOX=mx-WX dOY=my-WY
                else
                    hitTest(mx,my)
                end
            end
            prevLMB=lmb
        end
    end)

    -- ════════════════════════════════════════════════════
    -- PUBLIC API
    -- ════════════════════════════════════════════════════
    function UI.Init()
        task.spawn(function()
            makeDefaultTabs()
            buildWindow()
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
            dynName=gm.Name or dynName
            dynVer =gm.Version or dynVer
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
                buildWindow() Draw.SetVisible(frameObjs,uiVisible)
            end
        end)
    end

    function UI.ShowWelcome()   defer(function() qN("EXE.HUB","ExeHub is active",AC()) end) end
    function UI.ShowGameDetected(n) defer(function() qN("Game Detected",n,P().green) end) end
    function UI.ShowGameLoaded(n,v)
        dynName=n or dynName dynVer=v or dynVer
        defer(function()
            if lblGame then pcall(function() lblGame.Text=dynName end) end
            if lblVer  then pcall(function() lblVer.Text=dynVer   end) end
        end)
    end
    function UI.ShowNotSupported(id) defer(function() qN("Not Supported","PlaceId: "..tostring(id),P().yellow) end) end
    function UI.ShowLoadError(n)     defer(function() qN("Error",tostring(n),P().red) end) end
    function UI.Notify(t,m,tp)
        defer(function()
            local col=AC()
            if tp=="success" then col=P().green
            elseif tp=="warning" then col=P().yellow
            elseif tp=="error" then col=P().red end
            qN(t,m,col)
        end)
    end
    function UI.Destroy()
        uiReady=false Draw.DestroyAll()
        table.clear(frameObjs) table.clear(glowLines) table.clear(accentObjs)
        table.clear(partObjs) clearZones()
    end
end

-- ══════════════════════════════════════════════════════════
-- LOADER
-- ══════════════════════════════════════════════════════════
_G.__EXE_HUB_MODULES={}
local function loadModule(path)
    local url=BASE..path.."?t="..tostring(math.floor(tick()))
    local raw pcall(function() raw=game:HttpGet(url,true) end)
    if not raw or raw=="" then err("HTTP: "..path) return nil end
    local fn,e=loadstring(raw)
    if not fn then err("Compile: "..path.." "..tostring(e)) return nil end
    local ok,r=pcall(fn)
    if not ok then err("Exec: "..path.." "..tostring(r)) return nil end
    if r~=nil then return r end
    local key=path:match("([^/]+)%.lua$")
    if key and _G.__EXE_HUB_MODULES[key] then
        local m=_G.__EXE_HUB_MODULES[key]
        _G.__EXE_HUB_MODULES[key]=nil return m
    end
    err("NIL: "..path) return nil
end

local function loadGame(info)
    if not info then return end
    UI.ShowGameDetected(info.name)
    local gm=loadModule(info.module)
    if not gm then UI.ShowLoadError(info.name) return end
    gm.Name=gm.Name or info.name
    gm.Version=gm.Version or info.version
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
local placeId=game.PlaceId
local gameInfo=GAMES[placeId]
if gameInfo then loadGame(gameInfo)
else UI.ShowNotSupported(placeId) end