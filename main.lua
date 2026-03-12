-- ╔══════════════════════════════════════════════════════════╗
-- ║         EXE.HUB  v6.0  —  Drawing API  (Matcha)        ║
-- ╚══════════════════════════════════════════════════════════╝
-- Engine : task.spawn + task.wait  (Heartbeat dead on Matcha)
-- LMB    : ismouse1pressed() polling + rising edge
-- Toggle : RealUIS:IsKeyDown(), default = P
-- v6.0: no color picker, full keybind support, checkbox system,
--       star sparkles, dragging fixed, MaTub credit, modular tabs

local BASE = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"
local RealUIS = game:GetService("UserInputService")
local function log(m) print("[EXE] "..tostring(m)) end
local function err(m) warn("[EXE] ERR: "..tostring(m)) end

local GAMES = {
    [14890802310]={name="Bizarre Lineage",version="v1.0.0",module="games/bizarre_lineage.lua"},
}

-- ═══════════════════════════════════════════════
-- DRAW MODULE
-- ═══════════════════════════════════════════════
local Draw={}
do
    local pool={}
    local function reg(o) pool[#pool+1]=o return o end

    function Draw.Rect(x,y,w,h,col,z)
        local o=reg(Drawing.new("Square"))
        o.Position=Vector2.new(x,y) o.Size=Vector2.new(w,h)
        o.Color=col o.Filled=true o.Transparency=1 o.Thickness=1
        o.ZIndex=z or 1 o.Visible=false return o
    end
    function Draw.Outline(x,y,w,h,col,thick,z)
        local o=reg(Drawing.new("Square"))
        o.Position=Vector2.new(x,y) o.Size=Vector2.new(w,h)
        o.Color=col o.Filled=false o.Thickness=thick or 1
        o.Transparency=1 o.ZIndex=z or 2 o.Visible=false return o
    end
    function Draw.Text(x,y,str,col,sz,z)
        local o=reg(Drawing.new("Text"))
        o.Position=Vector2.new(x,y) o.Text=tostring(str)
        o.Color=col o.Size=sz or 12 o.ZIndex=z or 3
        o.Outline=true o.Center=false o.Visible=false return o
    end
    function Draw.Line(x1,y1,x2,y2,col,thick,z)
        local o=reg(Drawing.new("Line"))
        o.From=Vector2.new(x1,y1) o.To=Vector2.new(x2,y2)
        o.Color=col o.Thickness=thick or 1
        o.Transparency=1 o.ZIndex=z or 2 o.Visible=false return o
    end
    function Draw.Circle(x,y,r,col,filled,z)
        local o=reg(Drawing.new("Circle"))
        o.Position=Vector2.new(x,y) o.Radius=r
        o.Color=col o.Filled=(filled~=false)
        o.Transparency=0.4 o.ZIndex=z or 1 o.Visible=false return o
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
            if o.Position then o.Position=Vector2.new(o.Position.X+dx,o.Position.Y+dy) end
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

-- ═══════════════════════════════════════════════
-- UI CORE
-- ═══════════════════════════════════════════════
local UI={}
do
    local SW,SH=1920,1080
    pcall(function()
        SW=workspace.CurrentCamera.ViewportSize.X
        SH=workspace.CurrentCamera.ViewportSize.Y
    end)

    local mouse=Players.LocalPlayer:GetMouse()
    local function MX() return mouse.X end
    local function MY() return mouse.Y end
    local function LMB() return (ismouse1pressed()) end

    -- ─────────────────────────────────────────────
    -- KEYBIND  (full keyboard: letters, numbers, F-keys, specials)
    -- ─────────────────────────────────────────────
    local toggleKC    = Enum.KeyCode.P
    local toggleLabel = "P"
    local bindingMode = false
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
        {Enum.KeyCode.Tab,"Tab"},{Enum.KeyCode.Insert,"Ins"},
        {Enum.KeyCode.Home,"Home"},{Enum.KeyCode.End,"End"},
        {Enum.KeyCode.PageUp,"PgUp"},{Enum.KeyCode.PageDown,"PgDn"},
    }

    local function isToggleDown()
        if bindingMode then return false end
        local ok,r=pcall(function() return RealUIS:IsKeyDown(toggleKC) end)
        return ok and r or false
    end
    local function scanBind()
        for _,k in ipairs(ALL_KEYS) do
            local ok,r=pcall(function() return RealUIS:IsKeyDown(k[1]) end)
            if ok and r then
                toggleKC=k[1] toggleLabel=k[2] bindingMode=false
                if bindLblRef then pcall(function()
                    bindLblRef.Text="Toggle Key : [ "..toggleLabel.." ]"
                    bindLblRef.Color=Color3.fromRGB(180,140,220)
                end) end
                return
            end
        end
    end

    -- ─────────────────────────────────────────────
    -- THEMES  (no color picker, themes only)
    -- ─────────────────────────────────────────────
    local THEMES={
        sakura={
            name="Sakura",
            acH=330/360, acS=0.72, acV=0.96,
            bg=Color3.fromRGB(9,7,15),
            panel=Color3.fromRGB(13,11,21),
            cardBg=Color3.fromRGB(16,12,24),
            cardBrd=Color3.fromRGB(220,40,160),
            cardTitle=Color3.fromRGB(90,10,70),
            tabSel=Color3.fromRGB(50,16,42),
        },
        space={
            name="Space",
            acH=215/360, acS=0.85, acV=1.00,
            bg=Color3.fromRGB(3,4,14),
            panel=Color3.fromRGB(6,8,20),
            cardBg=Color3.fromRGB(7,11,24),
            cardBrd=Color3.fromRGB(30,120,255),
            cardTitle=Color3.fromRGB(8,30,85),
            tabSel=Color3.fromRGB(10,20,52),
        },
    }
    local curTheme="sakura"
    local accentH=THEMES.sakura.acH
    local accentS=THEMES.sakura.acS
    local accentV=THEMES.sakura.acV

    local function AC()      return Color3.fromHSV(accentH,accentS,accentV) end
    local function ACL()     return Color3.fromHSV(accentH,accentS*0.45,1.0) end
    local function partCol() return Color3.fromHSV(accentH,accentS*0.55,1.0) end
    local function TH()      return THEMES[curTheme] or THEMES.sakura end

    local function applyThemePreset(key)
        local t=THEMES[key] if not t then return end
        curTheme=key accentH,accentS,accentV=t.acH,t.acS,t.acV
    end

    local function PAL()
        local t=TH()
        return {
            bg=t.bg, panel=t.panel,
            titleBg =Color3.fromRGB(6,5,11),
            tabBg   =Color3.fromRGB(13,11,20),
            tabSel  =t.tabSel,
            border  =Color3.fromRGB(32,20,46),
            cardBg  =t.cardBg,
            cardBrd =t.cardBrd,
            cardTitle=t.cardTitle,
            white   =Color3.fromRGB(225,222,240),
            muted   =Color3.fromRGB(130,110,150),
            dimmed  =Color3.fromRGB(60,50,78),
            green   =Color3.fromRGB(70,195,110),
            yellow  =Color3.fromRGB(230,180,50),
            red     =Color3.fromRGB(230,60,60),
            notifBg =Color3.fromRGB(8,6,16),
            on      =Color3.fromRGB(55,175,95),
            off     =Color3.fromRGB(38,35,55),
            chkBg   =Color3.fromRGB(22,18,34),
        }
    end

    -- ─────────────────────────────────────────────
    -- WINDOW DIMENSIONS
    -- ─────────────────────────────────────────────
    local WW    = math.max(460,math.floor(SW/3.9))
    local WH    = math.max(520,math.floor(SH/2.2))
    local WX    = math.floor(SW/2-WW/2)
    local WY    = math.floor(SH/2-WH/2)
    local TBARH = 30
    local TABH  = 24
    local CONTY = TBARH+TABH
    local PAD   = 10

    -- ─────────────────────────────────────────────
    -- STATE
    -- ─────────────────────────────────────────────
    local uiReady=false local uiVisible=true
    local activeTab=1   local currentTabs={}

    local frameObjs  = {}   -- everything (chrome + content)
    local glowLines  = {}
    local ledDot     = nil
    local cardLedDots= {}
    local tabBtnData = {}   -- [i]={bg,lbl,ul}
    local tabContent = {}   -- [i]=list (lazy built once)
    local accentObjs = {}
    local partObjs   = {}
    local starObjs   = {}

    local gZones={}         -- global (tab bar)
    local tZones={}         -- per-tab content zones

    local ddObjs={}  local ddOpen=false

    local fToggles={}
    local function FT(k)   return fToggles[k] or false end
    local function setFT(k,v) fToggles[k]=v end

    local dynName="--" local dynVer="--"
    local lblGame,lblVer

    local buildWindow,applyTheme,destroyDD,rebuildAllUL

    -- ─────────────────────────────────────────────
    -- ZONE SYSTEM
    -- ─────────────────────────────────────────────
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
    -- Returns true = click captured by UI (game should not see it)
    local function hitTest(mx,my)
        local list={}
        for _,z in ipairs(gZones) do list[#list+1]=z end
        if tZones[activeTab] then
            for _,z in ipairs(tZones[activeTab]) do list[#list+1]=z end
        end
        for _,z in ipairs(list) do
            if mx>=z.x and mx<=z.x+z.w and my>=z.y and my<=z.y+z.h then
                pcall(z.fn) return true
            end
        end
        return mx>=WX and mx<=WX+WW and my>=WY and my<=WY+WH
    end

    -- ─────────────────────────────────────────────
    -- ACCENT REGISTRY
    -- ─────────────────────────────────────────────
    local function regAC(o)  accentObjs[#accentObjs+1]={obj=o,r="ac"}  return o end
    local function regACL(o) accentObjs[#accentObjs+1]={obj=o,r="acl"} return o end

    applyTheme=function()
        local ac,acl=AC(),ACL()
        for _,e in ipairs(accentObjs) do pcall(function()
            e.obj.Color=(e.r=="acl") and acl or ac
        end) end
        for _,gl in ipairs(glowLines) do pcall(function() gl.Color=ac end) end
        for _,p in ipairs(partObjs)   do pcall(function() p.Color=partCol() end) end
    end

    -- ─────────────────────────────────────────────
    -- THEME DROPDOWN
    -- ─────────────────────────────────────────────
    destroyDD=function()
        Draw.Destroy(ddObjs) ddOpen=false
        local keep={}
        for _,z in ipairs(gZones) do if not z._dd then keep[#keep+1]=z end end
        table.clear(gZones)
        for _,z in ipairs(keep) do gZones[#gZones+1]=z end
    end

    local function buildDD(cx,cy)
        destroyDD() ddOpen=true
        local IH=26 local DW=WW-PAD*2
        local list={{key="sakura",name="Sakura",dot=Color3.fromRGB(255,80,180)},
                    {key="space", name="Space", dot=Color3.fromRGB(60,130,255)}}
        for i,t in ipairs(list) do
            local iy=cy+(i-1)*IH
            local bg=Draw.Rect(cx,iy,DW,IH,PAL().tabBg,35)
            bg.Visible=true ddObjs[#ddObjs+1]=bg
            local dot=Draw.Rect(cx+7,iy+8,10,10,t.dot,36)
            dot.Visible=true ddObjs[#ddObjs+1]=dot
            local lbl=Draw.Text(cx+23,iy+6,t.name,PAL().white,12,36)
            lbl.Visible=true ddObjs[#ddObjs+1]=lbl
            if i<#list then
                local sep=Draw.Line(cx,iy+IH-1,cx+DW,iy+IH-1,PAL().border,1,36)
                sep.Visible=true ddObjs[#ddObjs+1]=sep
            end
            local tk=t.key
            gZones[#gZones+1]={x=cx,y=iy,w=DW,h=IH,_dd=true,fn=function()
                applyThemePreset(tk) destroyDD()
                applyTheme() buildWindow()
                Draw.SetVisible(frameObjs,uiVisible)
            end}
        end
        local brd=Draw.Outline(cx,cy,DW,#list*IH,PAL().cardBrd,1,36)
        brd.Visible=true ddObjs[#ddObjs+1]=brd
    end

    -- ═════════════════════════════════════════════
    -- WIDGET BUILDERS
    -- All helpers take (objs, addZ, ...) and return nextY
    -- ═════════════════════════════════════════════

    -- ── CARD ─────────────────────────────────────
    -- All 4 borders present including top (title area)
    local function makeCard(objs,addZ,cx,sy,cw2,title)
        local pal=PAL()
        local CP=7 local TBH=17
        -- draw order: bg first, then border on top so it shows fully
        local bg  = Draw.Rect(cx,sy,cw2,0,pal.cardBg,4)      objs[#objs+1]=bg
        -- border drawn as 4 separate lines so title top is always visible
        local bL  = Draw.Line(cx,      sy,   cx,      sy,   pal.cardBrd,1,5) objs[#objs+1]=bL
        local bR  = Draw.Line(cx+cw2,  sy,   cx+cw2,  sy,   pal.cardBrd,1,5) objs[#objs+1]=bR
        local bTop= Draw.Line(cx,      sy,   cx+cw2,  sy,   pal.cardBrd,1,5) objs[#objs+1]=bTop
        local bBot= Draw.Line(cx,      sy,   cx+cw2,  sy,   pal.cardBrd,1,5) objs[#objs+1]=bBot
        -- LED dot for card border animation
        local cled=Draw.Circle(cx,sy,3,pal.cardBrd,true,6)
        cled.Transparency=0.15 cled.Visible=false objs[#objs+1]=cled
        cardLedDots[#cardLedDots+1]={dot=cled,x=cx,y=sy,w=cw2,h=0,t=math.random()*6.28}
        -- title bar
        local tbg =Draw.Rect(cx,sy,cw2,TBH,pal.cardTitle,5) objs[#objs+1]=tbg
        local tlbl=Draw.Text(cx+CP,sy+3,title,pal.white,11,6) objs[#objs+1]=tlbl
        local cy2=sy+TBH+CP
        local cledRef=cled
        return {
            cx=cx+CP, cw=cw2-CP*2, cy=cy2, startY=sy,
            finalize=function(endY)
                local h=math.max(TBH+CP*2,endY-sy+CP)
                pcall(function() bg.Size=Vector2.new(cw2,h) end)
                -- update border lines
                pcall(function()
                    bL.From=Vector2.new(cx,sy)   bL.To=Vector2.new(cx,sy+h)
                    bR.From=Vector2.new(cx+cw2,sy) bR.To=Vector2.new(cx+cw2,sy+h)
                    bTop.From=Vector2.new(cx,sy)   bTop.To=Vector2.new(cx+cw2,sy)
                    bBot.From=Vector2.new(cx,sy+h) bBot.To=Vector2.new(cx+cw2,sy+h)
                end)
                for _,ld in ipairs(cardLedDots) do
                    if ld.dot==cledRef then ld.h=h break end
                end
            end,
        }
    end

    -- ── CHECKBOX ─────────────────────────────────
    -- Empty square=off, filled accent + tick=on
    local function makeCheckbox(objs,addZ,cx,y,key,label)
        local pal=PAL()
        local SZ=14
        local isOn=FT(key)
        local bg  =Draw.Rect(cx,y,SZ,SZ,pal.chkBg,7)       objs[#objs+1]=bg
        local brd =Draw.Outline(cx,y,SZ,SZ,pal.cardBrd,1,8) objs[#objs+1]=brd
        local fill=Draw.Rect(cx+1,y+1,SZ-2,SZ-2,AC(),7)
        fill.Visible=isOn objs[#objs+1]=fill
        local ck1=Draw.Line(cx+2,y+7,cx+5,y+11,pal.white,2,9)
        local ck2=Draw.Line(cx+5,y+11,cx+12,y+3,pal.white,2,9)
        ck1.Visible=isOn ck2.Visible=isOn
        objs[#objs+1]=ck1 objs[#objs+1]=ck2
        local lbl=Draw.Text(cx+SZ+6,y+1,label,pal.white,11,7) objs[#objs+1]=lbl
        -- hit area: label width too (generous)
        addZ(cx,y,math.max(SZ+6+#label*7,SZ+80),SZ,function()
            local v=not FT(key) setFT(key,v)
            pcall(function()
                fill.Visible=v fill.Color=AC()
                ck1.Visible=v  ck2.Visible=v
            end)
        end)
        return y+SZ+7
    end

    -- ── DROPDOWN ─────────────────────────────────
    -- Inline expanding list below the button
    local function makeDropdown(objs,addZ,cx,y,cw2,key,items,placeholder)
        local pal=PAL()
        local h=20
        local selIdx=fToggles[key.."_sel"] or 0
        local cur=(selIdx>0 and items[selIdx]) or placeholder or "Select..."
        local bg  =Draw.Rect(cx,y,cw2,h,pal.tabBg,6)        objs[#objs+1]=bg
        local brd =Draw.Outline(cx,y,cw2,h,pal.cardBrd,1,7) objs[#objs+1]=brd
        local lbl =Draw.Text(cx+6,y+4,"  "..tostring(cur),pal.white,10,7) objs[#objs+1]=lbl
        -- arrow indicator
        local arr =Draw.Text(cx+cw2-14,y+4,"v",pal.muted,9,7) objs[#objs+1]=arr
        local listOpen=false
        local listObjs={}
        local function closeList()
            for _,o in ipairs(listObjs) do pcall(function() o:Remove() end) end
            table.clear(listObjs) listOpen=false
            -- remove list zones from this tab
            local keep={}
            if tZones[activeTab] then
                for _,z in ipairs(tZones[activeTab]) do
                    if not z._ddlist then keep[#keep+1]=z end
                end
                table.clear(tZones[activeTab])
                for _,z in ipairs(keep) do tZones[activeTab][#tZones[activeTab]+1]=z end
            end
        end
        local function openList()
            if listOpen then closeList() return end
            listOpen=true
            local IH=17
            for i,item in ipairs(items) do
                local iy=y+h+(i-1)*IH
                local ibg=Draw.Rect(cx,iy,cw2,IH,Color3.fromRGB(16,12,26),20)
                ibg.Visible=true listObjs[#listObjs+1]=ibg
                local ibrd=Draw.Outline(cx,iy,cw2,IH,pal.cardBrd,1,21)
                ibrd.Visible=true listObjs[#listObjs+1]=ibrd
                local it=Draw.Text(cx+6,iy+3,tostring(item),pal.white,10,21)
                it.Visible=true listObjs[#listObjs+1]=it
                local ii=i
                addZ(cx,iy,cw2,IH,function()
                    fToggles[key.."_sel"]=ii
                    pcall(function() lbl.Text="  "..tostring(items[ii]) end)
                    closeList()
                end)
                tZones[activeTab][#tZones[activeTab]]._ddlist=true
                -- mark for cleanup ^
            end
            for _,o in ipairs(listObjs) do objs[#objs+1]=o end
        end
        addZ(cx,y,cw2,h,openList)
        return y+h+5
    end

    -- ── BUTTON ───────────────────────────────────
    local function makeButton(objs,addZ,cx,y,cw2,label,fn)
        local pal=PAL()
        local h=22
        local bg  =Draw.Rect(cx,y,cw2,h,Color3.fromRGB(22,16,36),6)  objs[#objs+1]=bg
        local brd =Draw.Outline(cx,y,cw2,h,pal.cardBrd,1,7)           objs[#objs+1]=brd
        local lbl =Draw.Text(cx+8,y+5,label,pal.white,11,7)            objs[#objs+1]=lbl
        addZ(cx,y,cw2,h,fn or function() end)
        return y+h+5
    end

    -- ── SLIDER ───────────────────────────────────
    local function makeSlider(objs,addZ,cx,y,cw2,key,label,minV,maxV,defV)
        local pal=PAL()
        local val=fToggles[key.."_val"] or defV or minV
        local TH2=8 -- track height
        local lbl=Draw.Text(cx,y,label.." : "..tostring(math.floor(val)),pal.white,10,6)
        objs[#objs+1]=lbl
        y=y+14
        Draw.Rect(cx,y+2,cw2,TH2,pal.chkBg,6)       -- track bg (created but not stored)
        Draw.Outline(cx,y+2,cw2,TH2,pal.cardBrd,1,7) -- track border
        local frac=(val-minV)/math.max(1,maxV-minV)
        local fillW=math.max(TH2,math.floor(frac*cw2))
        local fill=Draw.Rect(cx,y+2,fillW,TH2,AC(),7)  objs[#objs+1]=fill
        regAC(fill)
        local hnd=Draw.Rect(cx+math.floor(frac*cw2)-4,y,8,TH2+4,pal.white,8)
        objs[#objs+1]=hnd
        addZ(cx,y,cw2,TH2+6,function()
            local nf=math.max(0,math.min(1,(MX()-cx)/cw2))
            local nv=math.floor(minV+(maxV-minV)*nf)
            fToggles[key.."_val"]=nv
            pcall(function()
                lbl.Text=label.." : "..tostring(nv)
                fill.Size=Vector2.new(math.max(TH2,math.floor(nf*cw2)),TH2)
                hnd.Position=Vector2.new(cx+math.floor(nf*cw2)-4,y)
            end)
        end)
        return y+TH2+12
    end

    -- ── SECTION LABEL ────────────────────────────
    local function makeSection(objs,cx,y,label,pal)
        local p=pal or PAL()
        objs[#objs+1]=Draw.Text(cx,y,"[ "..label.." ]",p.muted,10,6)
        objs[#objs+1]=Draw.Line(cx,y+13,cx+WW-PAD*2-14,y+13,p.border,1,6)
        return y+18
    end

    -- ═════════════════════════════════════════════
    -- MAKE CTX OBJECT  (shared builder context)
    -- ═════════════════════════════════════════════
    local function makeCtx(tabIdx,cx0,cy0,cw0)
        local function az(x,y,w,h,fn) addTZ(tabIdx,x,y,w,h,fn) end
        return {
            cx=cx0, cy=cy0, cw=cw0, ch=WH-CONTY-PAD*2,
            C=PAL(), AC=AC, ACL=ACL, PAD=PAD, Draw=Draw,
            objs=tabContent[tabIdx],
            addZone=az, addGZ=addGZ,
            card=function(x,y,w,t2)
                return makeCard(tabContent[tabIdx],az,x,y,w,t2) end,
            checkbox=function(x,y,key,lbl)
                return makeCheckbox(tabContent[tabIdx],az,x,y,key,lbl) end,
            dropdown=function(x,y,w,key,items,ph)
                return makeDropdown(tabContent[tabIdx],az,x,y,w,key,items,ph) end,
            button=function(x,y,w,lbl,fn2)
                return makeButton(tabContent[tabIdx],az,x,y,w,lbl,fn2) end,
            slider=function(x,y,w,key,lbl,mn,mx2,def)
                return makeSlider(tabContent[tabIdx],az,x,y,w,key,lbl,mn,mx2,def) end,
            section=function(x,y,lbl)
                return makeSection(tabContent[tabIdx],x,y,lbl,PAL()) end,
            buildDropdown=buildDD,
            regAC=regAC, regACL=regACL,
            WX=function()return WX end,
            WY=function()return WY end,
            WW=WW, WH=WH,
            FT=FT, setFT=setFT,
            dynName=function()return dynName end,
            dynVer=function()return dynVer end,
        }
    end

    -- ═════════════════════════════════════════════
    -- SWITCH TAB
    -- ═════════════════════════════════════════════
    rebuildAllUL=function()
        local ac=AC()
        for i,bd in pairs(tabBtnData) do pcall(function()
            local isSel=(i==activeTab)
            bd.ul.Color=ac
            bd.ul.Visible=isSel
            bd.lbl.Color=isSel and ACL() or PAL().muted
            bd.bg.Color =isSel and PAL().tabSel or PAL().tabBg
        end) end
    end

    local function switchTab(idx)
        if not currentTabs[idx] then return end
        if tabContent[activeTab] then
            Draw.SetVisible(tabContent[activeTab],false)
        end
        activeTab=idx
        destroyDD()

        if not tabContent[activeTab] then
            tabContent[activeTab]={}
            tZones[activeTab]={}
            local tab=currentTabs[activeTab]
            if tab and type(tab.buildFn)=="function" then
                local ctx=makeCtx(activeTab,WX+PAD,WY+CONTY+PAD,WW-PAD*2)
                pcall(function() tab.buildFn(ctx) end)
                for _,o in ipairs(tabContent[activeTab]) do
                    frameObjs[#frameObjs+1]=o
                end
            end
        end
        Draw.SetVisible(tabContent[activeTab],uiVisible)
        rebuildAllUL()
    end

    -- ═════════════════════════════════════════════
    -- BUILD WINDOW CHROME
    -- ═════════════════════════════════════════════
    buildWindow=function()
        destroyDD()
        table.clear(cardLedDots)
        for _,o in ipairs(frameObjs) do pcall(function() o:Remove() end) end
        table.clear(frameObjs)
        table.clear(glowLines) table.clear(tabBtnData) table.clear(accentObjs)
        for _,tc in pairs(tabContent) do
            for _,o in ipairs(tc) do pcall(function() o:Remove() end) end
        end
        table.clear(tabContent)
        clearZones()
        bindLblRef=nil
        if ledDot then pcall(function() ledDot:Remove() end) ledDot=nil end

        local pal=PAL()
        local ac=AC()
        local x,y=WX,WY

        -- window bg + title
        frameObjs[#frameObjs+1]=Draw.Rect(x,y,WW,WH,pal.bg,1)
        frameObjs[#frameObjs+1]=Draw.Rect(x,y,WW,TBARH,pal.titleBg,2)
        local hl=regACL(Draw.Text(x+PAD,y+8,"EXE.HUB",ACL(),14,5))
        frameObjs[#frameObjs+1]=hl
        frameObjs[#frameObjs+1]=Draw.Line(x+88,y+5,x+88,y+TBARH-5,pal.border,1,4)
        lblGame=Draw.Text(x+94,y+8,dynName,pal.muted,10,5) frameObjs[#frameObjs+1]=lblGame
        lblVer =Draw.Text(x+WW-58,y+9,dynVer,pal.dimmed,9,5) frameObjs[#frameObjs+1]=lblVer
        frameObjs[#frameObjs+1]=Draw.Line(x,y+TBARH,x+WW,y+TBARH,pal.border,1,3)

        -- tabs
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
            local lx=tx+math.floor(tabW/2)-math.floor(#tab.name*3.0)
            local tlbl=Draw.Text(lx,tabY+6,tab.name,isSel and ACL() or pal.muted,10,4)
            if isSel then regACL(tlbl) end
            frameObjs[#frameObjs+1]=tlbl
            -- underline: only active tab
            local tul=Draw.Line(tx+3,tabY+TABH-1,tx+tabW-3,tabY+TABH-1,ac,2,4)
            tul.Visible=isSel
            frameObjs[#frameObjs+1]=tul
            tabBtnData[i]={bg=tbg,lbl=tlbl,ul=tul}
            local ci=i
            addGZ(tx,tabY,tabW,TABH,function() switchTab(ci) end)
        end

        -- content area
        frameObjs[#frameObjs+1]=Draw.Line(x,y+CONTY,x+WW,y+CONTY,pal.border,1,3)
        frameObjs[#frameObjs+1]=Draw.Rect(x,y+CONTY,WW,WH-CONTY,pal.panel,1)
        frameObjs[#frameObjs+1]=Draw.Outline(x,y,WW,WH,pal.border,1,3)

        -- glow border lines
        local function gl(x1,y1,x2,y2)
            local l=Draw.Line(x1,y1,x2,y2,ac,1.5,4)
            l.Transparency=0.84
            frameObjs[#frameObjs+1]=l glowLines[#glowLines+1]=l
        end
        gl(x,y,    x+WW,y   )
        gl(x+WW,y, x+WW,y+WH)
        gl(x+WW,y+WH,x, y+WH)
        gl(x,y+WH, x,   y   )

        -- LED dot
        ledDot=Drawing.new("Circle")
        ledDot.Radius=5 ledDot.Color=ac ledDot.Filled=true
        ledDot.Transparency=0.1 ledDot.ZIndex=8 ledDot.Visible=false
        frameObjs[#frameObjs+1]=ledDot

        -- build active tab content
        tabContent[activeTab]={}
        tZones[activeTab]={}
        local tab=currentTabs[activeTab]
        if tab and type(tab.buildFn)=="function" then
            local ctx=makeCtx(activeTab,WX+PAD,WY+CONTY+PAD,WW-PAD*2)
            pcall(function() tab.buildFn(ctx) end)
            for _,o in ipairs(tabContent[activeTab]) do
                frameObjs[#frameObjs+1]=o
            end
        end
    end

    -- ═════════════════════════════════════════════
    -- GAME DATA TABLES
    -- ═════════════════════════════════════════════
    local MOBS={"All Mobs","[Mob names TBA]"}
    local STANDS={
        "Any Stand","Star Platinum","The World","Crazy Diamond",
        "Gold Experience","King Crimson","Sticky Fingers","Purple Haze",
        "White Snake","C-Moon","Made in Heaven","Soft and Wet",
        "Tusk Act 4","D4C Love Train","Bohemian Rhapsody",
    }
    local PERSONALITIES={"Brave","[Personalities TBA]"}
    local STAT_RANKS={"D","C","B","A","S"}

    local BUS_STOPS={}
    for i=1,19 do BUS_STOPS[i]="Bus Stop "..i end

    local TP_MOBS={"All Mobs Spawn","[Mob spawns TBA]"}

    local NPC_OW  ={"Overworld NPC 1","Overworld NPC 2","[OW NPCs TBA]"}
    local NPC_MQ  ={"Main Quest NPC 1","Main Quest NPC 2","[MQ NPCs TBA]"}
    local NPC_SQ  ={"Side Quest NPC 1","Side Quest NPC 2","[SQ NPCs TBA]"}
    local NPC_UTIL={"Utility NPC 1","Trainer NPC","[Utility NPCs TBA]"}

    local BL_ITEMS={
        "Bizarre Lineage Core Item","Bizarre Lineage Essence",
        "Stand Arrow","Lucky Arrow","[Items TBA]",
    }

    -- ═════════════════════════════════════════════
    -- ESP COLOR STATE
    -- ═════════════════════════════════════════════
    local ESPColors={
        Mob    =Color3.fromRGB(255,80,80),
        Player =Color3.fromRGB(80,180,255),
        Arrow  =Color3.fromRGB(255,215,60),
        Essence=Color3.fromRGB(160,80,255),
    }
    local ESPPresets={
        Color3.fromRGB(255,80,80),  Color3.fromRGB(80,200,120),
        Color3.fromRGB(80,150,255), Color3.fromRGB(255,200,60),
        Color3.fromRGB(200,80,255), Color3.fromRGB(255,255,255),
        Color3.fromRGB(255,130,40),
    }
    -- Small color cycle swatch
    local function makeColorRow(objs,addZ,cx,y,label,colorKey)
        local pal=PAL()
        local col=ESPColors[colorKey] or Color3.fromRGB(255,255,255)
        local SW2=20 local SH2=12
        local swatch=Draw.Rect(cx,y,SW2,SH2,col,7)       objs[#objs+1]=swatch
        Draw.Outline(cx,y,SW2,SH2,pal.cardBrd,1,8)
        local lbl=Draw.Text(cx+SW2+5,y+1,label,pal.muted,9,7) objs[#objs+1]=lbl
        local ci=1
        addZ(cx,y,SW2+5+#label*7,SH2,function()
            ci=ci%#ESPPresets+1
            ESPColors[colorKey]=ESPPresets[ci]
            pcall(function() swatch.Color=ESPPresets[ci] end)
        end)
        return y+SH2+5
    end

    -- ═════════════════════════════════════════════
    -- DEFAULT TABS
    -- ═════════════════════════════════════════════
    local function H(cw2) return math.floor((cw2-6)/2) end

    local function makeDefaultTabs()

        -- ══ MAIN ═══════════════════════════════════
        local tabMain={name="Main",buildFn=function(ctx)
            local o,D,pal=ctx.objs,ctx.Draw,ctx.C
            local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
            local h2=H(cw)
            local sy=cy

            -- ── Auto Farm Mob ──────────────────────
            local af=ctx.card(cx,sy,h2,"AUTO FARM MOB")
            local ay=af.cy
            o[#o+1]=D.Text(af.cx,ay,"Mob Selection :",pal.muted,9,6) ay=ay+12
            ay=ctx.dropdown(af.cx,ay,af.cw,"mob_sel",MOBS,"All Mobs")
            ay=ay+3
            ay=ctx.checkbox(af.cx,ay,"autoActivateStand","Auto Activate Stand")
            ay=ctx.checkbox(af.cx,ay,"autoKillStand",    "Auto Kill Stand")
            ay=ay+3
            o[#o+1]=D.Text(af.cx,ay,"Method :",pal.muted,9,6) ay=ay+12
            ay=ctx.dropdown(af.cx,ay,af.cw,"farm_method",{"Above","Below"},"Above")
            ay=ctx.slider(af.cx,ay,af.cw,"farmOffY","Offset Y",-50,50,0)
            af.finalize(ay)

            -- ── Auto Meditate ──────────────────────
            local md=ctx.card(cx+h2+6,sy,h2,"AUTO MEDITATE")
            local my2=md.cy
            o[#o+1]=D.Text(md.cx,my2,"Meditate automatically",pal.muted,9,6) my2=my2+14
            my2=ctx.checkbox(md.cx,my2,"autoMeditate","Auto Meditate")
            md.finalize(my2)

            sy=math.max(ay,my2)+10

            -- ── ESP ────────────────────────────────
            local ec=ctx.card(cx,sy,cw,"ESP")
            local ey=ec.cy
            local col3=math.floor((ec.cw-8)/3)

            -- Mob ESP
            o[#o+1]=D.Text(ec.cx,ey,"MOB",pal.muted,9,6)  ey=ey+12
            ey=ctx.checkbox(ec.cx,ey,"espMobOn","Enable")
            ey=makeColorRow(o,function(x2,y2,w2,h2b,fn2) addTZ(activeTab,x2,y2,w2,h2b,fn2) end,
                ec.cx,ey,"Color","Mob")
            local ey_mob=ey

            -- Player ESP (offset column)
            local px=ec.cx+col3+4 local py=ec.cy
            o[#o+1]=D.Text(px,py,"PLAYER",pal.muted,9,6) py=py+12
            py=makeCheckbox(o,function(x2,y2,w2,h2b,fn2) addTZ(activeTab,x2,y2,w2,h2b,fn2) end,
                px,py,"espPlayerOn","Enable")
            py=makeColorRow(o,function(x2,y2,w2,h2b,fn2) addTZ(activeTab,x2,y2,w2,h2b,fn2) end,
                px,py,"Color","Player")
            local ey_player=py

            -- Item ESP (third column)
            local ix=ec.cx+col3*2+8 local iy=ec.cy
            o[#o+1]=D.Text(ix,iy,"ITEM",pal.muted,9,6) iy=iy+12
            iy=makeCheckbox(o,function(x2,y2,w2,h2b,fn2) addTZ(activeTab,x2,y2,w2,h2b,fn2) end,
                ix,iy,"espItemOn","Enable")
            iy=makeColorRow(o,function(x2,y2,w2,h2b,fn2) addTZ(activeTab,x2,y2,w2,h2b,fn2) end,
                ix,iy,"Arrow","Arrow")
            iy=makeColorRow(o,function(x2,y2,w2,h2b,fn2) addTZ(activeTab,x2,y2,w2,h2b,fn2) end,
                ix,iy,"Essence","Essence")

            ey=math.max(ey_mob,ey_player,iy)
            ec.finalize(ey)
            sy=ey+10

            -- ── Status ─────────────────────────────
            local stc=ctx.card(cx,sy,cw,"STATUS")
            local sty=stc.cy
            o[#o+1]=D.Text(stc.cx,sty,"Game :",pal.muted,10,6)
            o[#o+1]=D.Text(stc.cx+44,sty,ctx.dynName(),pal.white,11,6) sty=sty+16
            o[#o+1]=D.Text(stc.cx,sty,"Version :",pal.muted,10,6)
            o[#o+1]=D.Text(stc.cx+52,sty,ctx.dynVer(),pal.white,11,6)  sty=sty+4
            stc.finalize(sty+8)
        end}

        -- ══ ITEMS ══════════════════════════════════
        local tabItems={name="Items",buildFn=function(ctx)
            local o,D,pal=ctx.objs,ctx.Draw,ctx.C
            local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
            local h2=H(cw)
            local sy=cy

            -- Item selection dropdown
            local isc=ctx.card(cx,sy,cw,"ITEM SELECTION")
            local iy=isc.cy
            o[#o+1]=D.Text(isc.cx,iy,"Select items to manage :",pal.muted,9,6) iy=iy+12
            iy=ctx.dropdown(isc.cx,iy,isc.cw,"item_sel",BL_ITEMS,"All Items")
            isc.finalize(iy)
            sy=iy+10

            -- Auto Collect
            local acc=ctx.card(cx,sy,cw,"AUTO COLLECT ITEM")
            local ay=acc.cy
            o[#o+1]=D.Text(acc.cx,ay,
                "Teleports to item on ground and collects it",pal.muted,9,6) ay=ay+14
            ay=ctx.checkbox(acc.cx,ay,"autoCollect","Auto Collect")
            acc.finalize(ay)
            sy=ay+10

            -- Auto Use (large card with sections)
            local auc=ctx.card(cx,sy,cw,"AUTO USE")
            local uy=auc.cy

            -- Section: Auto Arrow
            uy=ctx.section(auc.cx,uy,"Auto Arrow")
            uy=ctx.dropdown(auc.cx,uy,auc.cw,"arrow_type",{"Stand Arrow","Lucky Arrow"},"Stand Arrow")
            uy=ctx.checkbox(auc.cx,uy,"autoSpin","Auto Spin (repeat until target)")
            o[#o+1]=D.Text(auc.cx,uy,"Target Stand :",pal.muted,9,6) uy=uy+12
            uy=ctx.dropdown(auc.cx,uy,auc.cw,"arrow_stand",STANDS,"Any Stand")
            uy=ctx.checkbox(auc.cx,uy,"stopOnSkin","Stop if Stand Skin obtained")
            -- Stat filter
            o[#o+1]=D.Text(auc.cx,uy,"Stop when Stand stats >=",pal.muted,9,6) uy=uy+12
            local sw4=math.floor((auc.cw-9)/3)
            o[#o+1]=D.Text(auc.cx,uy,"STR",pal.dimmed,8,6)
            o[#o+1]=D.Text(auc.cx+sw4+3,uy,"SPD",pal.dimmed,8,6)
            o[#o+1]=D.Text(auc.cx+sw4*2+6,uy,"SPEC",pal.dimmed,8,6)
            uy=uy+11
            uy=ctx.dropdown(auc.cx,uy,sw4,"req_str", STAT_RANKS,"D")
            -- next two dropdowns positioned inline - simplified to stacked for stability
            uy=ctx.dropdown(auc.cx,uy,sw4,"req_spd", STAT_RANKS,"D")
            uy=ctx.dropdown(auc.cx,uy,sw4,"req_spec",STAT_RANKS,"D")
            -- Personality
            o[#o+1]=D.Text(auc.cx,uy,"Search Personality :",pal.muted,9,6) uy=uy+12
            uy=ctx.dropdown(auc.cx,uy,auc.cw,"req_pers",PERSONALITIES,"Any")
            uy=uy+4

            -- Section: Auto Chest
            uy=ctx.section(auc.cx,uy,"Auto Chest")
            uy=ctx.checkbox(auc.cx,uy,"autoChestCommon","Common Chest")
            uy=ctx.checkbox(auc.cx,uy,"autoChestRare",  "Rare Chest")
            uy=ctx.checkbox(auc.cx,uy,"autoChestLegend","Legendary Chest")
            uy=uy+4

            -- Section: Auto Use Essence
            uy=ctx.section(auc.cx,uy,"Auto Use Essence")
            uy=ctx.checkbox(auc.cx,uy,"autoEssence","Auto Use Essence")
            uy=uy+4

            auc.finalize(uy)
            sy=uy+10

            -- Other actions row
            local otc=ctx.card(cx,sy,cw,"OTHER ACTIONS")
            local oy=otc.cy
            -- 2-column layout
            oy=ctx.dropdown(otc.cx,oy,h2,"autoSell_item",BL_ITEMS,"Select item")
            local sellY=ctx.button(otc.cx,oy,h2,"Auto Sell",function() log("AutoSell") end)
            oy=ctx.dropdown(otc.cx+h2+6,otc.cy,h2,"autoDrop_item",BL_ITEMS,"Select item")
            local dropY=ctx.button(otc.cx+h2+6,oy,h2,"Auto Drop",function() log("AutoDrop") end)
            oy=math.max(sellY,dropY)
            otc.finalize(oy)
        end}

        -- ══ TELEPORT ═══════════════════════════════
        local tabTp={name="Teleport",buildFn=function(ctx)
            local o,D,pal=ctx.objs,ctx.Draw,ctx.C
            local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
            local sy=cy

            -- Bus Stops
            local bsC=ctx.card(cx,sy,cw,"BUS STOPS")
            local by=bsC.cy
            o[#o+1]=D.Text(bsC.cx,by,"Select stop (1-19) :",pal.muted,9,6) by=by+12
            by=ctx.dropdown(bsC.cx,by,bsC.cw,"tp_bus",BUS_STOPS,"Bus Stop 1")
            by=ctx.button(bsC.cx,by,bsC.cw,"Teleport to Bus Stop",function()
                local idx=fToggles["tp_bus_sel"] or 1
                log("TP BusStop -> "..tostring(BUS_STOPS[idx]))
            end)
            bsC.finalize(by)
            sy=by+10

            -- Mob Spawn
            local msC=ctx.card(cx,sy,cw,"MOB SPAWN")
            local my2=msC.cy
            o[#o+1]=D.Text(msC.cx,my2,"Select mob spawn :",pal.muted,9,6) my2=my2+12
            my2=ctx.dropdown(msC.cx,my2,msC.cw,"tp_mob",TP_MOBS,"Select mob")
            my2=ctx.button(msC.cx,my2,msC.cw,"Teleport to Mob Spawn",function()
                local idx=fToggles["tp_mob_sel"] or 1
                log("TP MobSpawn -> "..tostring(TP_MOBS[idx]))
            end)
            msC.finalize(my2)
            sy=my2+10

            -- NPC Teleport (4 category dropdowns)
            local npC=ctx.card(cx,sy,cw,"NPC TELEPORT")
            local ny=npC.cy

            o[#o+1]=D.Text(npC.cx,ny,"Overworld NPCs :",pal.muted,9,6) ny=ny+12
            ny=ctx.dropdown(npC.cx,ny,npC.cw,"tp_npc_ow",NPC_OW,"Select NPC")
            ny=ctx.button(npC.cx,ny,npC.cw,"Teleport",function()
                local idx=fToggles["tp_npc_ow_sel"] or 1
                log("TP NPC OW -> "..tostring(NPC_OW[idx]))
            end)
            ny=ny+4

            o[#o+1]=D.Text(npC.cx,ny,"Main Quest NPCs :",pal.muted,9,6) ny=ny+12
            ny=ctx.dropdown(npC.cx,ny,npC.cw,"tp_npc_mq",NPC_MQ,"Select NPC")
            ny=ctx.button(npC.cx,ny,npC.cw,"Teleport",function()
                local idx=fToggles["tp_npc_mq_sel"] or 1
                log("TP NPC MQ -> "..tostring(NPC_MQ[idx]))
            end)
            ny=ny+4

            o[#o+1]=D.Text(npC.cx,ny,"Side Quest NPCs :",pal.muted,9,6) ny=ny+12
            ny=ctx.dropdown(npC.cx,ny,npC.cw,"tp_npc_sq",NPC_SQ,"Select NPC")
            ny=ctx.button(npC.cx,ny,npC.cw,"Teleport",function()
                log("TP NPC SQ")
            end)
            ny=ny+4

            o[#o+1]=D.Text(npC.cx,ny,"Utility NPCs :",pal.muted,9,6) ny=ny+12
            ny=ctx.dropdown(npC.cx,ny,npC.cw,"tp_npc_ut",NPC_UTIL,"Select NPC")
            ny=ctx.button(npC.cx,ny,npC.cw,"Teleport",function()
                log("TP NPC UT")
            end)
            npC.finalize(ny)
        end}

        -- ══ SETTINGS ═══════════════════════════════
        local tabSettings={name="Settings",buildFn=function(ctx)
            local o,D,pal=ctx.objs,ctx.Draw,ctx.C
            local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
            local sy=cy

            -- Theme card (dropdown only, no color picker)
            local thC=ctx.card(cx,sy,cw,"THEME")
            local ty=thC.cy
            local swH=22
            local sw=Draw.Rect(thC.cx,ty,thC.cw,swH,AC(),5)
            regAC(sw) o[#o+1]=sw
            o[#o+1]=D.Text(thC.cx+7,ty+5,"  Theme : "..TH().name,
                Color3.fromRGB(8,8,8),11,6)
            ctx.addZone(thC.cx,ty,thC.cw,swH,function()
                if ddOpen then destroyDD() else buildDD(thC.cx,ty+swH+2) end
            end)
            ty=ty+swH+6
            thC.finalize(ty)
            sy=ty+10

            -- Toggle key card
            local tkC=ctx.card(cx,sy,cw,"TOGGLE KEY")
            local ky=tkC.cy
            local bh=26
            local kbg=D.Rect(tkC.cx,ky,tkC.cw,bh,pal.tabBg,5)          o[#o+1]=kbg
            local kbrd=D.Outline(tkC.cx,ky,tkC.cw,bh,pal.cardBrd,1,6)  o[#o+1]=kbrd
            local klbl=D.Text(tkC.cx+8,ky+7,
                "Toggle Key : [ "..toggleLabel.." ]",
                Color3.fromRGB(180,140,220),12,6)                        o[#o+1]=klbl
            bindLblRef=klbl
            o[#o+1]=D.Text(tkC.cx,ky+bh+4,
                "Click then press any key (letters, numbers, F-keys...)",
                pal.dimmed,8,6)
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
                        klbl.Text="Waiting for key..."
                        klbl.Color=Color3.fromRGB(235,185,55)
                    end)
                end
            end)
            ky=ky+bh+22
            tkC.finalize(ky)
        end}

        -- ══ CREDITS ════════════════════════════════
        local tabCredits={name="Credits",buildFn=function(ctx)
            local o,D,pal=ctx.objs,ctx.Draw,ctx.C
            local cr=ctx.card(ctx.cx,ctx.cy,ctx.cw,"CREDITS")
            local ry=cr.cy
            o[#o+1]=D.Text(cr.cx,ry,"Creator : MaTub",pal.white,13,6)       ry=ry+20
            o[#o+1]=D.Text(cr.cx,ry,"EXE.HUB - Roblox Script Hub",pal.muted,11,6) ry=ry+16
            o[#o+1]=D.Text(cr.cx,ry,"github.com/mattheube/EXE.HUB",pal.dimmed,10,6) ry=ry+6
            cr.finalize(ry+10)
        end}

        -- ══ LOGS ═══════════════════════════════════
        local tabLogs={name="Logs",buildFn=function(ctx)
            local o,D,pal=ctx.objs,ctx.Draw,ctx.C
            local lg=ctx.card(ctx.cx,ctx.cy,ctx.cw,"HUB UPDATES")
            local ly=lg.cy
            local lines={
                "Version 1 - Initial release of the hub.",
                "More update logs will be added here.",
            }
            for _,ln in ipairs(lines) do
                o[#o+1]=D.Text(lg.cx,ly,ln,pal.white,11,6) ly=ly+16
            end
            lg.finalize(ly+4)
        end}

        currentTabs={tabMain,tabItems,tabTp,tabSettings,tabCredits,tabLogs}
    end

    -- ═════════════════════════════════════════════
    -- LED BORDER LOOP
    -- ═════════════════════════════════════════════
    task.spawn(function()
        local t=0
        local perim=2*(WW+WH)
        while true do
            task.wait(0.033)
            if not uiReady or not uiVisible then continue end
            t=(t+3)%perim
            local px,py
            if t<WW then
                px=WX+t py=WY
            elseif t<WW+WH then
                px=WX+WW py=WY+(t-WW)
            elseif t<WW*2+WH then
                px=WX+WW-(t-WW-WH) py=WY+WH
            else
                px=WX py=WY+WH-(t-WW*2-WH)
            end
            if ledDot then pcall(function()
                ledDot.Position=Vector2.new(px,py)
                ledDot.Color=AC()
                local p2=0.5+0.5*math.sin(t*0.04)
                ledDot.Radius=3+p2*3
                ledDot.Visible=uiVisible
            end) end
            for _,gl in ipairs(glowLines) do pcall(function()
                gl.Transparency=0.85 gl.Color=AC()
            end) end
            for _,ld in ipairs(cardLedDots) do
                if ld.h>0 then pcall(function()
                    local cp=2*(ld.w+ld.h)
                    local ct=((t*0.6)+ld.t*cp)%cp
                    local dpx,dpy
                    if ct<ld.w then
                        dpx=ld.x+ct dpy=ld.y
                    elseif ct<ld.w+ld.h then
                        dpx=ld.x+ld.w dpy=ld.y+(ct-ld.w)
                    elseif ct<ld.w*2+ld.h then
                        dpx=ld.x+ld.w-(ct-ld.w-ld.h) dpy=ld.y+ld.h
                    else
                        dpx=ld.x dpy=ld.y+ld.h-(ct-ld.w*2-ld.h)
                    end
                    ld.dot.Position=Vector2.new(dpx,dpy)
                    ld.dot.Color=AC()
                    ld.dot.Visible=uiVisible
                end) end
            end
        end
    end)

    -- ═════════════════════════════════════════════
    -- SAKURA PETALS
    -- ═════════════════════════════════════════════
    local PMAX=42 local pCount=0
    local function spawnPetal()
        if pCount>=PMAX or not uiReady then return end
        pCount=pCount+1
        local sz=math.random(2,7)
        local p=Drawing.new("Circle")
        p.Position=Vector2.new(WX+math.random(sz,WW-sz),WY+CONTY+sz)
        p.Radius=sz p.Color=partCol() p.Filled=true
        p.Transparency=math.random(14,48)/100 p.ZIndex=2 p.Visible=false
        partObjs[#partObjs+1]=p
        local steps=math.random(55,150)
        local dy=(WY+WH-2-(WY+CONTY))/steps
        local phase=math.random()*6.28 local amp=math.random(3,10)
        local dA=(p.Transparency-0.97)/steps
        local drift=math.random(-8,8)/steps
        task.spawn(function()
            for s=1,steps do
                task.wait(0.05) if not uiReady then break end
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
    task.spawn(function()
        while true do
            task.wait(0.35+math.random()*0.4)
            if uiReady and curTheme=="sakura" then
                pcall(spawnPetal)
                if math.random()<0.65 then task.wait(0.1) pcall(spawnPetal) end
                if math.random()<0.3  then task.wait(0.1) pcall(spawnPetal) end
            end
        end
    end)

    -- ═════════════════════════════════════════════
    -- SPACE STARS  (sparkle / star shape using 4 lines)
    -- ═════════════════════════════════════════════
    local SMAX=38
    local function buildStars()
        for _,s in ipairs(starObjs) do
            for _,p in ipairs(s.parts) do pcall(function() p:Remove() end) end
        end
        table.clear(starObjs)
        if curTheme~="space" then return end
        for _=1,SMAX do
            local sx=WX+math.random(6,WW-6)
            local sy=WY+CONTY+math.random(6,WH-CONTY-6)
            local sz=math.random(3,7)
            local parts={}
            -- 4-arm sparkle: horizontal, vertical, two diagonals
            local ARMS={{-1,0,1,0},{0,-1,0,1},{-.65,-.65,.65,.65},{.65,-.65,-.65,.65}}
            for _,d in ipairs(ARMS) do
                local l=Drawing.new("Line")
                l.From=Vector2.new(sx+d[1]*sz,sy+d[2]*sz)
                l.To  =Vector2.new(sx+d[3]*sz,sy+d[4]*sz)
                l.Color=partCol() l.Thickness=1.2
                l.Transparency=0.4 l.ZIndex=2 l.Visible=false
                parts[#parts+1]=l
            end
            starObjs[#starObjs+1]={
                parts=parts, ox=sx, oy=sy, sz=sz,
                phase=math.random()*6.28,
                speed=0.4+math.random()*1.2,
                arms=ARMS,
            }
        end
    end
    task.spawn(function()
        local t=0
        while true do
            task.wait(0.05) t=t+0.05
            local isSpace=(curTheme=="space")
            for _,s in ipairs(starObjs) do pcall(function()
                local pulse=0.5+0.5*math.sin(t*s.speed+s.phase)
                local col=Color3.fromHSV(accentH,accentS*(0.25+0.45*pulse),0.75+0.25*pulse)
                local sc=s.sz*(0.5+0.8*pulse)
                local tr=0.05+0.5*(1-pulse)
                local ox=s.ox+math.sin(t*0.35+s.phase)*2.5
                local oy=s.oy+math.cos(t*0.28+s.phase)*1.8
                for i,p in ipairs(s.parts) do
                    p.Visible=uiVisible and isSpace
                    p.Color=col p.Transparency=tr
                    local d=s.arms[i]
                    p.From=Vector2.new(ox+d[1]*sc,oy+d[2]*sc)
                    p.To  =Vector2.new(ox+d[3]*sc,oy+d[4]*sc)
                end
            end) end
        end
    end)

    -- ═════════════════════════════════════════════
    -- NOTIFICATIONS
    -- ═════════════════════════════════════════════
    local NW=math.max(220,math.floor(SW/6.2))
    local NH=62 local NXf=SW-NW-14 local NYf=68 local NDUR=9
    local nQ={} local nBusy=false
    local function showN()
        if nBusy or #nQ==0 then return end
        nBusy=true local n=table.remove(nQ,1)
        local obs={} local sy=SH+10 local pal=PAL()
        local function aO(o2) obs[#obs+1]=o2 end
        aO(Draw.Rect(NXf,sy,NW,NH,pal.notifBg,50))
        aO(Draw.Outline(NXf,sy,NW,NH,n.col,1.5,51))
        aO(Draw.Rect(NXf+4,sy+5,3,NH-10,n.col,51))
        aO(Draw.Text(NXf+13,sy+11,n.t,pal.white,13,52))
        aO(Draw.Text(NXf+13,sy+28,n.m,pal.muted,10,52))
        local stars={}
        for _=1,4 do
            local s=Draw.Rect(NXf+math.random(8,NW-8),sy+math.random(4,NH-4),2,2,n.col,53)
            aO(s) stars[#stars+1]={o=s,ox=0,oy=0,t2=math.random()*6.28}
        end
        Draw.SetVisible(obs,true)
        local function setY(ny)
            local dy=ny-obs[1].Position.Y
            for _,o2 in ipairs(obs) do pcall(function()
                if o2.Position then o2.Position=Vector2.new(o2.Position.X,o2.Position.Y+dy) end
            end) end
            for _,s in ipairs(stars) do s.oy=(s.oy or 0)+dy end
        end
        task.spawn(function()
            for i=1,20 do task.wait(0.025) setY(sy+(NYf-sy)*(1-(1-i/20)^3)) end
            setY(NYf)
            for _,s in ipairs(stars) do s.ox=s.o.Position.X s.oy=s.o.Position.Y end
            local el=0
            while el<NDUR do task.wait(0.05) el=el+0.05
                for _,s in ipairs(stars) do pcall(function()
                    s.o.Position=Vector2.new(
                        s.ox+math.sin(el*2+s.t2)*4,s.oy+math.cos(el*1.4+s.t2)*2)
                end) end
            end
            for i=1,16 do
                task.wait(0.025)
                local ox=NXf+i*(NW+60)/16
                for _,o2 in ipairs(obs) do pcall(function()
                    if o2.Position then o2.Position=Vector2.new(ox,o2.Position.Y) end
                end) end
            end
            Draw.Destroy(obs) nBusy=false task.wait(0.3) showN()
        end)
    end
    local function qN(t,m,col) nQ[#nQ+1]={t=t,m=m,col=col} showN() end

    -- ═════════════════════════════════════════════
    -- INPUT LOOP
    -- ═════════════════════════════════════════════
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

            if togDown and not prevTog and not bindingMode then
                uiVisible=not uiVisible
                -- Full pass over ALL frame objects (fixes reopen bug)
                Draw.SetVisible(frameObjs,uiVisible)
                Draw.SetVisible(ddObjs,uiVisible and ddOpen)
                for _,p in ipairs(partObjs) do
                    pcall(function() p.Visible=uiVisible and curTheme=="sakura" end)
                end
                for _,s in ipairs(starObjs) do
                    for _,p in ipairs(s.parts) do
                        pcall(function() p.Visible=uiVisible and curTheme=="space" end)
                    end
                end
                if uiVisible then rebuildAllUL() end
            end
            prevTog=togDown

            -- Dragging (title bar)
            if dragOn then
                if lmb then
                    local dx=math.floor((mx-dOX-WX)*0.65)
                    local dy=math.floor((my-dOY-WY)*0.65)
                    if math.abs(dx)+math.abs(dy)>0 then
                        WX=WX+dx WY=WY+dy
                        Draw.Move(frameObjs,dx,dy)
                        Draw.Move(ddObjs,dx,dy)
                        for _,z in ipairs(gZones) do z.x=z.x+dx z.y=z.y+dy end
                        for _,tzl in pairs(tZones) do
                            for _,z in ipairs(tzl) do z.x=z.x+dx z.y=z.y+dy end
                        end
                        for _,s in ipairs(starObjs) do s.ox=s.ox+dx s.oy=s.oy+dy end
                        for _,ld in ipairs(cardLedDots) do ld.x=ld.x+dx ld.y=ld.y+dy end
                    end
                else dragOn=false end
            end

            if lmb and not prevLMB then
                if uiVisible then
                    -- Title bar drag region
                    if mx>=WX and mx<=WX+WW and my>=WY and my<=WY+TBARH then
                        dragOn=true dOX=mx-WX dOY=my-WY
                    else
                        hitTest(mx,my)  -- zones + input sink
                    end
                end
            end
            prevLMB=lmb
        end
    end)

    -- ═════════════════════════════════════════════
    -- PUBLIC API
    -- ═════════════════════════════════════════════
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
        local p=PAL()
        if tp=="success" then return p.green
        elseif tp=="warning" then return p.yellow
        elseif tp=="error" then return p.red end
        return AC()
    end
    function UI.ShowWelcome()       defer(function() qN("EXE.HUB","ExeHub is active",AC()) end) end
    function UI.ShowGameDetected(n) defer(function() qN("Game Detected",n,PAL().green) end) end
    function UI.ShowGameLoaded(n,v)
        dynName=n or dynName dynVer=v or dynVer
        defer(function()
            if lblGame then pcall(function() lblGame.Text=dynName end) end
            if lblVer  then pcall(function() lblVer.Text=dynVer end) end
        end)
    end
    function UI.ShowNotSupported(id) defer(function() qN("Not Supported","PlaceId: "..tostring(id),PAL().yellow) end) end
    function UI.ShowLoadError(n)     defer(function() qN("Load Error",tostring(n),PAL().red) end) end
    function UI.Notify(t2,m,tp)      defer(function() qN(t2,m,getCol(tp)) end) end
    function UI.Destroy()
        uiReady=false Draw.DestroyAll()
        table.clear(frameObjs) table.clear(glowLines) table.clear(accentObjs)
        table.clear(partObjs) table.clear(starObjs) clearZones()
    end
end

-- ═══════════════════════════════════════════════
-- MODULE LOADER
-- ═══════════════════════════════════════════════
_G.__EXE_HUB_MODULES={}
local function loadModule(path)
    local url=BASE..path.."?t="..tostring(math.floor(tick()))
    local raw pcall(function() raw=game:HttpGet(url,true) end)
    if not raw or raw=="" then err("HTTP: "..path) return nil end
    local fn,e=loadstring(raw)
    if not fn then err("Compile: "..path.." -- "..tostring(e)) return nil end
    local ok,r=pcall(fn)
    if not ok then err("Exec: "..path.." -- "..tostring(r)) return nil end
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
    gm.Name=gm.Name or info.name gm.Version=gm.Version or info.version
    if type(gm.Init)=="function" then
        local ok2,e2=pcall(function() gm.Init({UI=UI,log=log,err=err}) end)
        if not ok2 then UI.ShowLoadError(info.name) err(tostring(e2)) return end
    end
    UI.ShowGameLoaded(gm.Name,gm.Version)
    UI.LoadGameModule(gm)
end

-- ═══════════════════════════════════════════════
-- LAUNCH
-- ═══════════════════════════════════════════════
UI.Init()
UI.ShowWelcome()
local pId=game.PlaceId
if GAMES[pId] then loadGame(GAMES[pId]) else UI.ShowNotSupported(pId) end