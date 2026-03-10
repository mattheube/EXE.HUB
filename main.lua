-- EXE.HUB | main.lua (Matcha / Drawing API)
-- Instance.new indisponible sur Matcha → UI 100% Drawing

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
        if not ok then warn(P .. " [" .. tostring(lbl) .. "] " .. tostring(e)) end
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
            name   = "Bizarre Lineage",
            module = "games/bizarre_lineage.lua"
        },
    }
    function Registry.GetGame(id)     return games[id] or nil end
    function Registry.IsSupported(id) return games[id] ~= nil end
end
print("[EXE.HUB] registry OK")

-- ============================================================
-- UI — Drawing API (Matcha)
-- Style sakura neon sombre
-- ============================================================
local UI = {}
do
    -- Resolution de l'ecran
    local SW, SH = 1920, 1080
    pcall(function()
        local cam = workspace.CurrentCamera
        SW = cam.ViewportSize.X
        SH = cam.ViewportSize.Y
    end)

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

    -- Dimensions fenetre principale
    local WW, WH = 370, 255
    local WX = math.floor(SW/2 - WW/2)
    local WY = math.floor(SH/2 - WH/2)

    -- Dimensions notifs
    local NW, NH  = 290, 62
    local NX, NY0 = 14, 76
    local NGAP    = 9
    local NDUR    = 4.5

    -- Petales
    local PMAX, PFRQ = 6, 8
    local petalCount = 0

    -- Registre de tous les objets Drawing (pour cleanup)
    local allDrawings = {}
    local notifs      = {}
    local winObjs     = {}
    local winVisible  = false
    local lblStatus   = nil
    local lblGame     = nil
    local uiReady     = false

    -- --------------------------------------------------------
    -- Helpers Drawing
    -- --------------------------------------------------------
    local function D(cls)
        local obj = Drawing.new(cls)
        table.insert(allDrawings, obj)
        return obj
    end

    local function mkSquare(x, y, w, h, color, transp, zindex)
        local s = D("Square")
        s.Position     = Vector2.new(x, y)
        s.Size         = Vector2.new(w, h)
        s.Color        = color
        s.Filled       = true
        s.Transparency = transp or 1
        s.ZIndex       = zindex or 1
        s.Visible      = false
        return s
    end

    local function mkOutline(x, y, w, h, color, thickness, zindex)
        local s = D("Square")
        s.Position     = Vector2.new(x, y)
        s.Size         = Vector2.new(w, h)
        s.Color        = color
        s.Filled       = false
        s.Thickness    = thickness or 1.5
        s.Transparency = 1
        s.ZIndex       = zindex or 2
        s.Visible      = false
        return s
    end

    local function mkText(x, y, txt, color, size, zindex, center)
        local t = D("Text")
        t.Position = Vector2.new(x, y)
        t.Text     = txt
        t.Color    = color
        t.Size     = size or 13
        t.ZIndex   = zindex or 3
        t.Outline  = false
        t.Center   = center or false
        t.Visible  = false
        return t
    end

    local function setGroupVisible(group, vis)
        for _, obj in ipairs(group) do
            pcall(function() obj.Visible = vis end)
        end
    end

    local function destroyGroup(group)
        for _, obj in ipairs(group) do
            pcall(function() obj:Remove() end)
        end
        table.clear(group)
    end

    -- --------------------------------------------------------
    -- Detection clic via UserInputService polling
    -- --------------------------------------------------------
    local clickZones = {}

    local function registerHit(x, y, w, h, fn)
        table.insert(clickZones, {x=x, y=y, w=w, h=h, fn=fn})
    end

    task.spawn(function()
        local UIS    = UserInputService
        local wasDown = false
        while true do
            task.wait(0.05)
            if not uiReady then continue end
            local down = false
            pcall(function()
                down = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            end)
            if down and not wasDown then
                local mx, my
                pcall(function()
                    local pos = UIS:GetMouseLocation()
                    mx, my = pos.X, pos.Y
                end)
                if mx and my then
                    for _, z in ipairs(clickZones) do
                        if mx >= z.x and mx <= z.x+z.w and
                           my >= z.y and my <= z.y+z.h then
                            pcall(z.fn)
                        end
                    end
                end
            end
            wasDown = down
        end
    end)

    -- --------------------------------------------------------
    -- Fenetre principale
    -- --------------------------------------------------------
    local function buildWin()
        local x, y = WX, WY

        -- Fond
        table.insert(winObjs, mkSquare(x, y, WW, WH, C.Panel, 1, 1))
        -- Contour
        table.insert(winObjs, mkOutline(x, y, WW, WH, C.Pink, 1.5, 2))
        -- Barre de titre
        table.insert(winObjs, mkSquare(x, y, WW, 40, C.TitleBg, 1, 2))
        -- Titre
        table.insert(winObjs, mkText(x+14, y+13, "EXE.HUB", C.PinkHot, 15, 4))
        -- Version
        table.insert(winObjs, mkText(x+WW-68, y+15, "v1.0.0", C.Muted, 10, 4))
        -- Bouton fermer (fond + label)
        local cbX, cbY, cbW, cbH = x+WW-32, y+8, 24, 24
        table.insert(winObjs, mkSquare(cbX, cbY, cbW, cbH, C.CloseBg, 1, 3))
        table.insert(winObjs, mkText(cbX+7, cbY+6, "x", C.White, 12, 4))
        registerHit(cbX, cbY, cbW, cbH, function()
            setGroupVisible(winObjs, false)
            winVisible = false
        end)
        -- Separateur
        local sep = D("Line")
        sep.From        = Vector2.new(x+12, y+44)
        sep.To          = Vector2.new(x+WW-12, y+44)
        sep.Color       = C.Divider
        sep.Thickness   = 1
        sep.Transparency = 1
        sep.ZIndex      = 2
        sep.Visible     = false
        table.insert(winObjs, sep)
        -- Zone contenu
        table.insert(winObjs, mkSquare(x+12, y+52, WW-24, WH-64, C.Content, 1, 1))
        -- Labels
        lblStatus = mkText(x+20, y+65, "Initialisation...", C.Muted, 12, 3)
        table.insert(winObjs, lblStatus)
        lblGame = mkText(x+20, y+86, "", C.PinkHot, 13, 3)
        table.insert(winObjs, lblGame)
        -- Barre deco rose
        table.insert(winObjs, mkSquare(x+20, y+WH-18, 45, 2, C.Pink, 1, 2))
        -- Footer
        table.insert(winObjs, mkText(x+WW/2, y+WH-12, "EXE.HUB  |  sakura neon", C.Muted, 10, 2, true))
    end

    local function openWin()
        setGroupVisible(winObjs, true)
        winVisible = true
    end

    -- --------------------------------------------------------
    -- Notifications
    -- --------------------------------------------------------
    local function reposNotifs()
        -- Les notifs sont independantes (position fixe lors de la creation)
        -- On les repositionne proprement selon leur index
        for i, nd in ipairs(notifs) do
            local targetY = NY0 + (i-1)*(NH+NGAP)
            local targetX = SW - NW - NX
            local dy = targetY - nd.y
            if dy ~= 0 then
                for _, obj in ipairs(nd.objs) do
                    pcall(function()
                        if obj.Position then
                            obj.Position = Vector2.new(obj.Position.X, obj.Position.Y + dy)
                        end
                    end)
                end
                nd.y = targetY
            end
        end
    end

    local function notify(title, msg, accent, icon)
        local nfObjs = {}
        local nfData = {objs=nfObjs, y=NY0}
        table.insert(notifs, nfData)
        -- Repositionne les notifs existantes
        reposNotifs()
        -- Position de cette notif (derniere de la liste)
        local idx = #notifs
        local x   = SW - NW - NX
        local y   = NY0 + (idx-1)*(NH+NGAP)
        nfData.y  = y

        local function add(obj) table.insert(nfObjs, obj) end

        add(mkSquare(x, y, NW, NH, C.NotifBg, 1, 10))
        add(mkOutline(x, y, NW, NH, accent, 1.2, 11))
        add(mkSquare(x+6, y+6, 3, NH-12, accent, 1, 11))
        add(mkText(x+14, y+NH/2-8, icon or "+", accent, 15, 12))
        add(mkText(x+34, y+10, title, C.White, 12, 12))
        add(mkText(x+34, y+28, msg, C.Muted, 11, 12))

        setGroupVisible(nfObjs, true)

        task.delay(NDUR, function()
            -- Slide hors ecran vers la droite
            local steps = 10
            for i = 1, steps do
                task.wait(0.025)
                local ox = x + i*(NW+NX)/steps
                for _, obj in ipairs(nfObjs) do
                    pcall(function()
                        if obj.Position then
                            obj.Position = Vector2.new(ox, obj.Position.Y)
                        end
                    end)
                end
            end
            -- Supprime les objets Drawing
            for _, obj in ipairs(nfObjs) do
                pcall(function() obj:Remove() end)
                -- Retire aussi de allDrawings
                for i2, a in ipairs(allDrawings) do
                    if a == obj then table.remove(allDrawings, i2) break end
                end
            end
            -- Retire nfData de notifs
            for i2, nd in ipairs(notifs) do
                if nd == nfData then table.remove(notifs, i2) break end
            end
            reposNotifs()
        end)
    end

    -- --------------------------------------------------------
    -- Petales
    -- --------------------------------------------------------
    local function spawnPetal()
        if petalCount >= PMAX then return end
        petalCount = petalCount + 1
        local sz = math.random(3,7)
        local px = math.random(10, SW-10)
        local p  = Drawing.new("Circle")
        p.Position     = Vector2.new(px, -sz)
        p.Radius       = sz
        p.Color        = C.Petal
        p.Filled       = true
        p.Transparency = math.random(40,70)/100
        p.ZIndex       = 0
        p.Visible      = true
        table.insert(allDrawings, p)

        local dur   = math.random(70,130)/10
        local drift = math.random(-25,25)
        local steps = math.max(1, math.floor(dur / 0.05))
        local dy    = (SH + sz*2) / steps
        local dx    = drift / steps
        local dAlpha = (p.Transparency - 0.95) / steps

        task.spawn(function()
            for _ = 1, steps do
                task.wait(0.05)
                local ok = pcall(function()
                    p.Position = Vector2.new(p.Position.X + dx, p.Position.Y + dy)
                    p.Transparency = math.min(1, p.Transparency + dAlpha)
                end)
                if not ok then break end
            end
            pcall(function() p:Remove() end)
            petalCount = petalCount - 1
        end)
    end

    -- --------------------------------------------------------
    -- API publique
    -- --------------------------------------------------------
    function UI.Init()
        task.spawn(function()
            buildWin()
            uiReady = true
            print("[EXE.HUB] UI.Init() OK")
            if UI._onReady then UI._onReady() end
            task.spawn(function()
                while uiReady do
                    pcall(spawnPetal)
                    task.wait(PFRQ + math.random(0,3))
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

    function UI.ShowWelcome()
        defer(function()
            notify("Bienvenue", "EXE.HUB est actif", C.Pink, "+")
            openWin()
            if lblStatus then pcall(function() lblStatus.Text = "Hub actif." end) end
        end)
    end
    function UI.ShowGameDetected(n)
        defer(function()
            notify("Jeu detecte", n, C.Green, ">")
            if lblStatus then pcall(function() lblStatus.Text = "Chargement..." end) end
            if lblGame   then pcall(function() lblGame.Text   = "> "..n end) end
        end)
    end
    function UI.ShowGameLoaded(n)
        defer(function()
            notify("Module charge", n.." pret.", C.Green, "v")
            if lblStatus then pcall(function() lblStatus.Text = "Actif." end) end
        end)
    end
    function UI.ShowNotSupported(id)
        defer(function()
            notify("Non supporte", "PlaceId: "..tostring(id), C.Yellow, "!")
            if lblStatus then pcall(function() lblStatus.Text = "Jeu non supporte." end) end
        end)
    end
    function UI.ShowLoadError(n)
        defer(function()
            notify("Erreur", tostring(n), C.Red, "x")
            if lblStatus then pcall(function() lblStatus.Text = "Erreur." end) end
        end)
    end
    function UI.Notify(title, msg, t)
        defer(function()
            local a, i = C.Pink, "+"
            if     t == "success" then a = C.Green  i = "v"
            elseif t == "warning" then a = C.Yellow i = "!"
            elseif t == "error"   then a = C.Red    i = "x" end
            notify(title, msg, a, i)
        end)
    end
    function UI.SetMainWindowStatus(s, g)
        defer(function()
            if lblStatus then pcall(function() lblStatus.Text = tostring(s) end) end
            if lblGame and g then pcall(function() lblGame.Text = "> "..g end) end
        end)
    end
    function UI.Destroy()
        uiReady = false
        table.clear(clickZones)
        for _, obj in ipairs(allDrawings) do pcall(function() obj:Remove() end) end
        table.clear(allDrawings)
        table.clear(winObjs)
        table.clear(notifs)
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
        utils.Log("Chargement : " .. gameInfo.module)
        local gm = loadModule(gameInfo.module)
        if not gm then ui.ShowLoadError(gameInfo.name) return end
        if type(gm.Init) ~= "function" then
            ui.ShowLoadError(gameInfo.name.." (Init manquant)") return
        end
        local ok, err = pcall(function() gm.Init({UI=ui, Utils=utils}) end)
        if ok then
            ui.ShowGameLoaded(gameInfo.name)
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
    local url = BASE .. path .. CACHE_BUST
    print("[EXE.HUB] >> " .. url)
    local raw
    pcall(function() raw = game:HttpGet(url, true) end)
    if not raw or raw == "" then
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
