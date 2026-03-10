-- EXE.HUB | system/ui.lua
-- Interface sakura neon sombre. Sans annotations de type (compat loadstring).
-- Ecrit pour fonctionner dans les executeurs Roblox (Matcha, Synapse, etc.)

local UI = {}

-- Services
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- LocalPlayer et PlayerGui
local LocalPlayer = Players.LocalPlayer
local PlayerGui

-- Attente robuste du PlayerGui (max 10s)
local t0 = tick()
repeat
    PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not PlayerGui then task.wait(0.1) end
until PlayerGui or (tick() - t0 > 10)

if not PlayerGui then
    warn("[EXE.HUB] PlayerGui introuvable. UI annulee.")
    return UI
end

-- ============================================================
-- COULEURS
-- ============================================================
local C = {
    Panel    = Color3.fromRGB(18, 18, 26),
    TitleBg  = Color3.fromRGB(14, 10, 20),
    Content  = Color3.fromRGB(12, 10, 20),
    Pink     = Color3.fromRGB(220, 80, 140),
    PinkHot  = Color3.fromRGB(255, 130, 180),
    White    = Color3.fromRGB(235, 235, 248),
    Muted    = Color3.fromRGB(150, 110, 155),
    Green    = Color3.fromRGB(90, 210, 130),
    Yellow   = Color3.fromRGB(250, 195, 75),
    Red      = Color3.fromRGB(250, 85, 85),
    NotifBg  = Color3.fromRGB(18, 12, 25),
    Divider  = Color3.fromRGB(45, 22, 42),
    Petal    = Color3.fromRGB(255, 175, 205),
    CloseBg  = Color3.fromRGB(170, 35, 75),
}

-- ============================================================
-- POLICES (compatibles tous clients Roblox recents)
-- ============================================================
local FONT_BOLD   = Enum.Font.GothamSemibold
local FONT_NORMAL = Enum.Font.Gotham

-- ============================================================
-- VARIABLES D'ETAT
-- ============================================================
local sg          = nil  -- ScreenGui racine
local mainWin     = nil  -- Frame fenetre principale
local lblStatus   = nil  -- Label statut
local lblGame     = nil  -- Label jeu detecte

local notifs      = {}   -- Queue des notifications
local petalCount  = 0

-- Dimensions et timing
local WIN_W    = 370
local WIN_H    = 255
local NOTIF_W  = 290
local NOTIF_H  = 62
local NOTIF_X  = 14
local NOTIF_Y0 = 76
local NOTIF_GAP= 9
local DUR_NOTIF= 4.5
local DUR_ANIM = 0.28
local PETAL_MAX= 7
local PETAL_FRQ= 7

-- ============================================================
-- HELPERS INTERNES
-- ============================================================

local function mkCorner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = parent
end

local function mkStroke(parent, color, thick)
    local s = Instance.new("UIStroke")
    s.Color     = color
    s.Thickness = thick or 1.5
    s.Parent    = parent
end

local function mkFrame(parent, size, pos, color, rad, zi)
    local f = Instance.new("Frame")
    f.Size             = size
    f.Position         = pos
    f.BackgroundColor3 = color
    f.BorderSizePixel  = 0
    f.ZIndex           = zi or 2
    f.Parent           = parent
    if rad and rad > 0 then mkCorner(f, rad) end
    return f
end

local function mkLabel(parent, text, size, pos, color, fs, font, zi, xa)
    local l = Instance.new("TextLabel")
    l.Text                   = text
    l.Size                   = size
    l.Position               = pos
    l.BackgroundTransparency = 1
    l.TextColor3             = color
    l.Font                   = font or FONT_BOLD
    l.TextSize               = fs or 13
    l.TextXAlignment         = xa or Enum.TextXAlignment.Left
    l.TextYAlignment         = Enum.TextYAlignment.Center
    l.ZIndex                 = zi or 3
    l.Parent                 = parent
    return l
end

-- ============================================================
-- CONSTRUCTION SCREENGUI
-- ============================================================

local function buildGui()
    local old = PlayerGui:FindFirstChild("EXE_HUB_GUI")
    if old then old:Destroy() end

    local g = Instance.new("ScreenGui")
    g.Name           = "EXE_HUB_GUI"
    g.ResetOnSpawn   = false
    g.IgnoreGuiInset = true
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    g.Parent         = PlayerGui
    return g
end

-- ============================================================
-- CONSTRUCTION FENETRE PRINCIPALE
-- ============================================================

local function buildMainWindow()
    -- Fenetre principale
    local win = mkFrame(sg,
        UDim2.new(0, WIN_W, 0, WIN_H),
        UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
        C.Panel, 12, 5)
    win.Name    = "EXE_MainWindow"
    win.Visible = false
    mkStroke(win, C.Pink, 1.5)
    mainWin = win

    -- Barre de titre
    local tb = mkFrame(win,
        UDim2.new(1, 0, 0, 40),
        UDim2.new(0, 0, 0, 0),
        C.TitleBg, 12, 6)

    -- Remplissage du bas de la titlebar (masque coins arrondis du bas)
    local tbFill = mkFrame(win,
        UDim2.new(1, 0, 0, 22),
        UDim2.new(0, 0, 0, 20),
        C.TitleBg, 0, 5)

    -- Titre
    mkLabel(tb, "✦  EXE.HUB",
        UDim2.new(1, -90, 1, 0),
        UDim2.new(0, 14, 0, 0),
        C.PinkHot, 15, FONT_BOLD, 7)

    -- Version
    local vl = mkLabel(tb, "v1.0.0",
        UDim2.new(0, 55, 1, 0),
        UDim2.new(1, -66, 0, 0),
        C.Muted, 10, FONT_NORMAL, 7,
        Enum.TextXAlignment.Right)

    -- Bouton fermer
    local cb = Instance.new("TextButton")
    cb.Size             = UDim2.new(0, 25, 0, 25)
    cb.Position         = UDim2.new(1, -31, 0, 8)
    cb.BackgroundColor3 = C.CloseBg
    cb.TextColor3       = C.White
    cb.Text             = "x"
    cb.Font             = FONT_BOLD
    cb.TextSize         = 13
    cb.BorderSizePixel  = 0
    cb.ZIndex           = 9
    cb.Parent           = tb
    mkCorner(cb, 5)

    cb.MouseButton1Click:Connect(function()
        local tw = TweenService:Create(win,
            TweenInfo.new(DUR_ANIM, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -WIN_W/2, 1.3, 0)})
        tw:Play()
        tw.Completed:Connect(function()
            win.Visible = false
            win.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
        end)
    end)

    -- Separateur
    mkFrame(win,
        UDim2.new(1, -24, 0, 1),
        UDim2.new(0, 12, 0, 44),
        C.Divider, 0, 6)

    -- Zone de contenu
    local content = mkFrame(win,
        UDim2.new(1, -24, 1, -64),
        UDim2.new(0, 12, 0, 52),
        C.Content, 8, 5)

    lblStatus = mkLabel(content, "Initialisation...",
        UDim2.new(1, -16, 0, 22),
        UDim2.new(0, 8, 0, 8),
        C.Muted, 12, FONT_NORMAL, 6)
    lblStatus.Name = "EXE_StatusLabel"

    lblGame = mkLabel(content, "",
        UDim2.new(1, -16, 0, 26),
        UDim2.new(0, 8, 0, 32),
        C.PinkHot, 14, FONT_BOLD, 6)
    lblGame.Name = "EXE_GameLabel"

    -- Ligne deco
    local deco = mkFrame(content,
        UDim2.new(0, 45, 0, 2),
        UDim2.new(0, 8, 1, -14),
        C.Pink, 2, 6)

    -- Footer
    mkLabel(win, "EXE.HUB  |  sakura neon",
        UDim2.new(1, -24, 0, 16),
        UDim2.new(0, 12, 1, -20),
        C.Muted, 10, FONT_NORMAL, 6,
        Enum.TextXAlignment.Center)
end

-- ============================================================
-- OUVERTURE FENETRE AVEC ANIMATION
-- ============================================================

local function openWindow()
    if not mainWin then return end
    mainWin.Position = UDim2.new(0.5, -WIN_W/2, -0.3, 0)
    mainWin.Visible  = true
    TweenService:Create(mainWin,
        TweenInfo.new(DUR_ANIM, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)}
    ):Play()
end

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

local function repositionNotifs()
    for i, nf in ipairs(notifs) do
        local y = NOTIF_Y0 + (i - 1) * (NOTIF_H + NOTIF_GAP)
        TweenService:Create(nf,
            TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, -(NOTIF_W + NOTIF_X), 0, y)}
        ):Play()
    end
end

local function notify(title, msg, accent, icon)
    if not sg then return end

    local nf = mkFrame(sg,
        UDim2.new(0, NOTIF_W, 0, NOTIF_H),
        UDim2.new(1, 40, 0, NOTIF_Y0),
        C.NotifBg, 8, 20)
    mkStroke(nf, accent, 1.2)

    -- Barre coloree laterale
    mkFrame(nf, UDim2.new(0, 3, 1, -12), UDim2.new(0, 6, 0, 6), accent, 2, 21)

    -- Icone
    mkLabel(nf, icon or "o",
        UDim2.new(0, 22, 1, 0),
        UDim2.new(0, 14, 0, 0),
        accent, 15, FONT_BOLD, 22,
        Enum.TextXAlignment.Center)

    -- Titre
    mkLabel(nf, title,
        UDim2.new(1, -46, 0, 22),
        UDim2.new(0, 42, 0, 5),
        C.White, 12, FONT_BOLD, 22)

    -- Message
    mkLabel(nf, msg,
        UDim2.new(1, -46, 0, 20),
        UDim2.new(0, 42, 0, 25),
        C.Muted, 11, FONT_NORMAL, 22)

    table.insert(notifs, nf)
    repositionNotifs()

    -- Entree depuis la droite
    TweenService:Create(nf,
        TweenInfo.new(DUR_ANIM, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -(NOTIF_W + NOTIF_X), 0, NOTIF_Y0)}
    ):Play()

    -- Sortie automatique
    task.delay(DUR_NOTIF, function()
        if not nf or not nf.Parent then return end
        local cy = nf.Position.Y.Offset
        local tw = TweenService:Create(nf,
            TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 40, 0, cy)})
        tw:Play()
        tw.Completed:Connect(function()
            local idx = table.find(notifs, nf)
            if idx then table.remove(notifs, idx) end
            if nf and nf.Parent then nf:Destroy() end
            repositionNotifs()
        end)
    end)
end

-- ============================================================
-- PETALES SAKURA
-- ============================================================

local function spawnPetal()
    if not sg or petalCount >= PETAL_MAX then return end
    petalCount = petalCount + 1

    local sz = math.random(4, 9)
    local px = math.random(2, 95) / 100

    local p = mkFrame(sg,
        UDim2.new(0, sz, 0, math.max(1, math.floor(sz * 0.6))),
        UDim2.new(px, 0, -0.03, 0),
        C.Petal, sz, 1)
    p.BackgroundTransparency = math.random(30, 60) / 100
    p.Rotation = math.random(-30, 30)

    local dur   = math.random(60, 110) / 10
    local drift = math.random(-10, 10) / 100

    local tw = TweenService:Create(p,
        TweenInfo.new(dur, Enum.EasingStyle.Linear),
        {
            Position              = UDim2.new(px + drift, 0, 1.06, 0),
            Rotation              = p.Rotation + math.random(-70, 70),
            BackgroundTransparency= 0.9,
        })
    tw:Play()
    tw.Completed:Connect(function()
        if p and p.Parent then p:Destroy() end
        petalCount = petalCount - 1
    end)
end

local function startPetals()
    task.spawn(function()
        while sg and sg.Parent do
            pcall(spawnPetal)
            task.wait(PETAL_FRQ + math.random(0, 3))
        end
    end)
end

-- ============================================================
-- API PUBLIQUE
-- ============================================================

function UI.Init()
    sg = buildGui()
    buildMainWindow()
    startPetals()
    print("[EXE.HUB] UI.Init() OK — ScreenGui cree dans PlayerGui")
end

function UI.ShowWelcome()
    notify("Bienvenue", "EXE.HUB est actif", C.Pink, "+")
    openWindow()
    if lblStatus then lblStatus.Text = "Hub actif." end
end

function UI.ShowGameDetected(gameName)
    notify("Jeu detecte", gameName, C.Green, ">")
    if lblStatus then lblStatus.Text = "Chargement..." end
    if lblGame   then lblGame.Text   = "> " .. gameName end
end

function UI.ShowGameLoaded(gameName)
    notify("Module charge", gameName .. " pret.", C.Green, "v")
    if lblStatus then lblStatus.Text = "Actif." end
end

function UI.ShowNotSupported(placeId)
    notify("Non supporte", "PlaceId : " .. tostring(placeId), C.Yellow, "!")
    if lblStatus then lblStatus.Text = "Jeu non pris en charge." end
end

function UI.ShowLoadError(moduleName)
    notify("Erreur", tostring(moduleName), C.Red, "x")
    if lblStatus then lblStatus.Text = "Erreur de chargement." end
end

function UI.Notify(title, message, notifType)
    local accent = C.Pink
    local icon   = "+"
    if notifType == "success" then accent = C.Green  icon = "v" end
    if notifType == "warning" then accent = C.Yellow icon = "!" end
    if notifType == "error"   then accent = C.Red    icon = "x" end
    notify(title, message, accent, icon)
end

function UI.SetMainWindowStatus(status, gameName)
    if lblStatus then lblStatus.Text = tostring(status) end
    if lblGame and gameName then lblGame.Text = "> " .. gameName end
end

return UI