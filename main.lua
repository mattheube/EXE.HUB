-- EXE.HUB | main.lua (version autonome)
-- Tous les modules systeme sont integres directement dans ce fichier.
-- Seuls les modules jeux restent sur GitHub.
-- Raison : contourne tous les problemes de cache et de polices sur Matcha.

local BASE = "https://raw.githubusercontent.com/mattheube/EXE.HUB/main/"
local CACHE_BUST = "?t=" .. tostring(math.floor(tick()))

print("[EXE.HUB] === DEMARRAGE ===")

-- ============================================================
-- UTILS (inline)
-- ============================================================
local Utils = {}
do
    local P = "[EXE.HUB]"
    function Utils.Log(m)   print(P .. " " .. tostring(m)) end
    function Utils.Warn(m)  warn(P .. " WARN: " .. tostring(m)) end
    function Utils.Error(m) warn(P .. " ERR: " .. tostring(m)) end
    function Utils.SafeCall(fn, lbl)
        local ok, e = pcall(fn)
        if not ok then warn(P .. " [" .. tostring(lbl) .. "] " .. tostring(e)) end
    end
end
print("[EXE.HUB] utils OK")

-- ============================================================
-- REGISTRY (inline)
-- ============================================================
local Registry = {}
do
    local games = {
        [14890802310] = {
            name   = "Bizarre Lineage",
            module = "games/bizarre_lineage.lua"
        },
    }
    function Registry.GetGame(id) return games[id] or nil end
    function Registry.IsSupported(id) return games[id] ~= nil end
end
print("[EXE.HUB] registry OK")

-- ============================================================
-- UI (inline) — Style sakura neon sombre
-- ============================================================
local UI = {}
do
    local Players      = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local LP           = Players.LocalPlayer
    local PG

    local t0 = tick()
    repeat
        PG = LP:FindFirstChildOfClass("PlayerGui")
        if not PG then task.wait(0.05) end
    until PG or (tick() - t0 > 10)

    if not PG then
        warn("[EXE.HUB] PlayerGui introuvable - UI annulee")
    else

    -- Polices : detection dynamique sans jamais crasher
    local function sf(list)
        for _, n in ipairs(list) do
            local ok, v = pcall(function() return Enum.Font[n] end)
            if ok and v then return v end
        end
        return Enum.Font.Arial
    end
    local FB = sf({"GothamBold","GothamSemibold","Gotham","SourceSansBold","Arial"})
    local FN = sf({"Gotham","GothamSemibold","SourceSans","Arial"})

    -- Couleurs
    local C = {
        Panel   = Color3.fromRGB(18,18,26),
        TitleBg = Color3.fromRGB(14,10,20),
        Content = Color3.fromRGB(12,10,20),
        Pink    = Color3.fromRGB(220,80,140),
        PinkHot = Color3.fromRGB(255,130,180),
        White   = Color3.fromRGB(235,235,248),
        Muted   = Color3.fromRGB(150,110,155),
        Green   = Color3.fromRGB(90,210,130),
        Yellow  = Color3.fromRGB(250,195,75),
        Red     = Color3.fromRGB(250,85,85),
        NotifBg = Color3.fromRGB(18,12,25),
        Divider = Color3.fromRGB(45,22,42),
        Petal   = Color3.fromRGB(255,175,205),
        CloseBg = Color3.fromRGB(170,35,75),
    }

    -- Dimensions
    local WW,WH = 370,255
    local NW,NH = 290,62
    local NX,NY0,NGAP = 14,76,9
    local NDUR,ASPD = 4.5, 0.28
    local PMAX,PFRQ = 7, 7

    -- Variables d'etat
    local sg, mainWin, lblStatus, lblGame
    local notifs = {}
    local petalCount = 0

    -- Helpers
    local function mkC(p,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=p end
    local function mkS(p,col,t) local s=Instance.new("UIStroke") s.Color=col s.Thickness=t or 1.5 s.Parent=p end
    local function mkF(p,sz,pos,col,r,z)
        local f=Instance.new("Frame") f.Size=sz f.Position=pos f.BackgroundColor3=col
        f.BorderSizePixel=0 f.ZIndex=z or 2 f.Parent=p
        if r and r>0 then mkC(f,r) end return f
    end
    local function mkL(p,txt,sz,pos,col,fs,fnt,z,xa)
        local l=Instance.new("TextLabel") l.Text=txt l.Size=sz l.Position=pos
        l.BackgroundTransparency=1 l.TextColor3=col l.Font=fnt or FB
        l.TextSize=fs or 13 l.TextXAlignment=xa or Enum.TextXAlignment.Left
        l.TextYAlignment=Enum.TextYAlignment.Center l.ZIndex=z or 3 l.Parent=p return l
    end

    -- ScreenGui
    local function buildGui()
        local old=PG:FindFirstChild("EXE_HUB_GUI") if old then old:Destroy() end
        local g=Instance.new("ScreenGui") g.Name="EXE_HUB_GUI" g.ResetOnSpawn=false
        g.IgnoreGuiInset=true g.ZIndexBehavior=Enum.ZIndexBehavior.Sibling g.Parent=PG return g
    end

    -- Fenetre principale
    local function buildWin()
        local win=mkF(sg,UDim2.new(0,WW,0,WH),UDim2.new(0.5,-WW/2,0.5,-WH/2),C.Panel,12,5)
        win.Name="EXE_MainWindow" win.Visible=false mkS(win,C.Pink,1.5) mainWin=win
        local tb=mkF(win,UDim2.new(1,0,0,40),UDim2.new(0,0,0,0),C.TitleBg,12,6)
        mkF(win,UDim2.new(1,0,0,22),UDim2.new(0,0,0,20),C.TitleBg,0,5)
        mkL(tb,"EXE.HUB",UDim2.new(1,-90,1,0),UDim2.new(0,14,0,0),C.PinkHot,15,FB,7)
        mkL(tb,"v1.0.0",UDim2.new(0,55,1,0),UDim2.new(1,-66,0,0),C.Muted,10,FN,7,Enum.TextXAlignment.Right)
        local cb=Instance.new("TextButton") cb.Size=UDim2.new(0,25,0,25) cb.Position=UDim2.new(1,-31,0,8)
        cb.BackgroundColor3=C.CloseBg cb.TextColor3=C.White cb.Text="x" cb.Font=FB cb.TextSize=13
        cb.BorderSizePixel=0 cb.ZIndex=9 cb.Parent=tb mkC(cb,5)
        cb.MouseButton1Click:Connect(function()
            local tw=TweenService:Create(win,TweenInfo.new(ASPD,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=UDim2.new(0.5,-WW/2,1.3,0)})
            tw:Play() tw.Completed:Connect(function() win.Visible=false win.Position=UDim2.new(0.5,-WW/2,0.5,-WH/2) end)
        end)
        mkF(win,UDim2.new(1,-24,0,1),UDim2.new(0,12,0,44),C.Divider,0,6)
        local ct=mkF(win,UDim2.new(1,-24,1,-64),UDim2.new(0,12,0,52),C.Content,8,5)
        lblStatus=mkL(ct,"Initialisation...",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,8),C.Muted,12,FN,6)
        lblGame=mkL(ct,"",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,32),C.PinkHot,14,FB,6)
        mkF(ct,UDim2.new(0,45,0,2),UDim2.new(0,8,1,-14),C.Pink,2,6)
        mkL(win,"EXE.HUB  |  sakura neon",UDim2.new(1,-24,0,16),UDim2.new(0,12,1,-20),C.Muted,10,FN,6,Enum.TextXAlignment.Center)
    end

    local function openWin()
        if not mainWin then return end
        mainWin.Position=UDim2.new(0.5,-WW/2,-0.3,0) mainWin.Visible=true
        TweenService:Create(mainWin,TweenInfo.new(ASPD,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,-WW/2,0.5,-WH/2)}):Play()
    end

    -- Notifications
    local function reposNotifs()
        for i,nf in ipairs(notifs) do
            local y=NY0+(i-1)*(NH+NGAP)
            TweenService:Create(nf,TweenInfo.new(0.2,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.new(1,-(NW+NX),0,y)}):Play()
        end
    end

    local function notify(title, msg, accent, icon)
        if not sg then return end
        local nf=mkF(sg,UDim2.new(0,NW,0,NH),UDim2.new(1,40,0,NY0),C.NotifBg,8,20)
        mkS(nf,accent,1.2)
        mkF(nf,UDim2.new(0,3,1,-12),UDim2.new(0,6,0,6),accent,2,21)
        mkL(nf,icon or "+",UDim2.new(0,22,1,0),UDim2.new(0,14,0,0),accent,15,FB,22,Enum.TextXAlignment.Center)
        mkL(nf,title,UDim2.new(1,-46,0,22),UDim2.new(0,42,0,5),C.White,12,FB,22)
        mkL(nf,msg,UDim2.new(1,-46,0,20),UDim2.new(0,42,0,25),C.Muted,11,FN,22)
        table.insert(notifs,nf)
        reposNotifs()
        TweenService:Create(nf,TweenInfo.new(ASPD,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.new(1,-(NW+NX),0,NY0)}):Play()
        task.delay(NDUR,function()
            if not nf or not nf.Parent then return end
            local cy=nf.Position.Y.Offset
            local tw=TweenService:Create(nf,TweenInfo.new(0.25,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=UDim2.new(1,40,0,cy)})
            tw:Play()
            tw.Completed:Connect(function()
                local idx=table.find(notifs,nf) if idx then table.remove(notifs,idx) end
                if nf and nf.Parent then nf:Destroy() end
                reposNotifs()
            end)
        end)
    end

    -- Petales
    local function spawnPetal()
        if not sg or petalCount>=PMAX then return end
        petalCount=petalCount+1
        local sz=math.random(4,9) local px=math.random(2,95)/100
        local p=mkF(sg,UDim2.new(0,sz,0,math.max(1,math.floor(sz*0.6))),UDim2.new(px,0,-0.03,0),C.Petal,sz,1)
        p.BackgroundTransparency=math.random(30,60)/100 p.Rotation=math.random(-30,30)
        local dur=math.random(60,110)/10 local drift=math.random(-10,10)/100
        local tw=TweenService:Create(p,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Position=UDim2.new(px+drift,0,1.06,0),Rotation=p.Rotation+math.random(-70,70),BackgroundTransparency=0.9})
        tw:Play()
        tw.Completed:Connect(function() if p and p.Parent then p:Destroy() end petalCount=petalCount-1 end)
    end

    -- API publique
    function UI.Init()
        sg=buildGui() buildWin()
        task.spawn(function() while sg and sg.Parent do pcall(spawnPetal) task.wait(PFRQ+math.random(0,3)) end end)
        print("[EXE.HUB] UI.Init() OK")
    end
    function UI.ShowWelcome()
        notify("Bienvenue","EXE.HUB est actif",C.Pink,"+") openWin()
        if lblStatus then lblStatus.Text="Hub actif." end
    end
    function UI.ShowGameDetected(n)
        notify("Jeu detecte",n,C.Green,">")
        if lblStatus then lblStatus.Text="Chargement..." end
        if lblGame then lblGame.Text="> "..n end
    end
    function UI.ShowGameLoaded(n)
        notify("Module charge",n.." pret.",C.Green,"v")
        if lblStatus then lblStatus.Text="Actif." end
    end
    function UI.ShowNotSupported(id)
        notify("Non supporte","PlaceId: "..tostring(id),C.Yellow,"!")
        if lblStatus then lblStatus.Text="Jeu non supporte." end
    end
    function UI.ShowLoadError(n)
        notify("Erreur",tostring(n),C.Red,"x")
        if lblStatus then lblStatus.Text="Erreur." end
    end
    function UI.Notify(title,msg,t)
        local a,i=C.Pink,"+"
        if t=="success" then a=C.Green i="v" elseif t=="warning" then a=C.Yellow i="!" elseif t=="error" then a=C.Red i="x" end
        notify(title,msg,a,i)
    end
    function UI.SetMainWindowStatus(s,g)
        if lblStatus then lblStatus.Text=tostring(s) end
        if lblGame and g then lblGame.Text="> "..g end
    end

    end -- fin du if PG
end
print("[EXE.HUB] ui OK")

-- ============================================================
-- LOADER (inline)
-- ============================================================
local Loader = {}
do
    function Loader.LoadGame(gameInfo, loadModule, ui, utils)
        if not gameInfo or not gameInfo.module then utils.Error("gameInfo invalide") return end
        utils.Log("Chargement : " .. gameInfo.module)
        local gm = loadModule(gameInfo.module)
        if not gm then ui.ShowLoadError(gameInfo.name) return end
        if type(gm.Init) ~= "function" then ui.ShowLoadError(gameInfo.name.." (Init manquant)") return end
        local ok, err = pcall(function() gm.Init({UI=ui, Utils=utils}) end)
        if ok then ui.ShowGameLoaded(gameInfo.name) else ui.ShowLoadError(gameInfo.name) utils.Error(tostring(err)) end
    end
end
print("[EXE.HUB] loader OK")

-- ============================================================
-- CHARGEUR DE MODULES DISTANTS (pour les jeux)
-- ============================================================
_G.__EXE_HUB_MODULES = {}

local function loadModule(path)
    local url = BASE .. path .. CACHE_BUST
    print("[EXE.HUB] >> " .. url)
    local raw
    pcall(function() raw = game:HttpGet(url, true) end)
    if not raw or raw == "" then warn("[EXE.HUB] ECHEC HTTP : "..path) return nil end
    local fn, e = loadstring(raw)
    if not fn then warn("[EXE.HUB] ECHEC COMPILE : "..path.." | "..tostring(e)) return nil end
    local ok, result = pcall(fn)
    if not ok then warn("[EXE.HUB] ECHEC EXEC : "..path.." | "..tostring(result)) return nil end
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
print("[EXE.HUB] PlaceId = " .. tostring(placeId))

local gameInfo = Registry.GetGame(placeId)
if gameInfo then
    print("[EXE.HUB] Jeu reconnu : " .. gameInfo.name)
    UI.ShowGameDetected(gameInfo.name)
    Loader.LoadGame(gameInfo, loadModule, UI, Utils)
else
    print("[EXE.HUB] Jeu non supporte : " .. tostring(placeId))
    UI.ShowNotSupported(placeId)
end

print("[EXE.HUB] === PRET ===")
