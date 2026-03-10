-- ============================================================
--  EXE.HUB | system/ui.lua
--  Module d'interface utilisateur principal.
--  Style : sombre + sakura néon
-- ============================================================

local UI = {}

-- ============================================================
-- SERVICES ROBLOX
-- ============================================================

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Récupération sûre du LocalPlayer et PlayerGui
-- On n'utilise pas WaitForChild() qui peut bloquer dans certains exécuteurs
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    or LocalPlayer:WaitForChild("PlayerGui", 10)

if not PlayerGui then
    warn("[EXE.HUB] PlayerGui introuvable — UI annulée.")
    return UI
end

-- ============================================================
-- POLICE DE CARACTÈRES — Compatibilité maximale
-- Enum.Font.GothamBold est obsolète dans les clients récents.
-- On utilise l'API FontFace moderne avec fallback sûr.
-- ============================================================

local function safeFont(primary: Enum.Font): Enum.Font
    -- Test silencieux : si la valeur n'est pas reconnue, on retourne
    -- une police universellement supportée
    local ok = pcall(function()
        local _ = Enum.Font[primary.Name]
    end)
    if ok then return primary end
    return Enum.Font.GothamSemibold
end

-- Police principale : on utilise GothamSemibold qui est toujours supporté
local FONT_BOLD   = Enum.Font.GothamSemibold
local FONT_NORMAL = Enum.Font.Gotham

-- ============================================================
-- PALETTE DE COULEURS — Thème Sakura Néon Sombre
-- ============================================================

local C = {
    Panel        = Color3.fromRGB(18,  18,  26),
    TitleBar     = Color3.fromRGB(14,  10,  20),
    Content      = Color3.fromRGB(14,  12,  22),
    PinkNeon     = Color3.fromRGB(220, 80,  140),
    PinkBright   = Color3.fromRGB(255, 130, 180),
    White        = Color3.fromRGB(240, 240, 248),
    Muted        = Color3.fromRGB(160, 120, 160),
    Green        = Color3.fromRGB(100, 220, 140),
    Yellow       = Color3.fromRGB(255, 200, 80),
    Red          = Color3.fromRGB(255, 90,  90),
    NotifBg      = Color3.fromRGB(20,  14,  26),
    Divider      = Color3.fromRGB(50,  25,  45),
    Petal        = Color3.fromRGB(255, 180, 210),
    CloseBtn     = Color3.fromRGB(180, 40,  80),
}

-- ============================================================
-- HELPERS DE CONSTRUCTION UI
-- ============================================================

local function corner(parent: Instance, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number)
    local s = Instance.new("UIStroke")
    s.Color     = color
    s.Thickness = thickness
    -- On n'utilise pas ApplyStrokeMode qui a changé de nom
    -- Le comportement par défaut (Border) est ce qu'on veut
    s.Parent    = parent
end

local function frame(
    parent   : Instance,
    size     : UDim2,
    pos      : UDim2,
    color    : Color3,
    rad      : number?,
    zi       : number?
): Frame
    local f = Instance.new("Frame")
    f.Size                 = size
    f.Position             = pos
    f.BackgroundColor3     = color
    f.BorderSizePixel      = 0
    f.ZIndex               = zi or 2
    f.Parent               = parent
    if rad and rad > 0 then corner(f, rad) end
    return f
end

local function label(
    parent : Instance,
    text   : string,
    size   : UDim2,
    pos    : UDim2,
    color  : Color3,
    fs     : number,
    font   : Enum.Font?,
    zi     : number?,
    align  : Enum.TextXAlignment?
): TextLabel
    local l = Instance.new("TextLabel")
    l.Text                    = text
    l.Size                    = size
    l.Position                = pos
    l.BackgroundTransparency  = 1
    l.TextColor3              = color
    l.Font                    = font or FONT_BOLD
    l.TextSize                = fs
    l.TextXAlignment          = align or Enum.TextXAlignment.Left
    l.TextYAlignment          = Enum.TextYAlignment.Center
    l.ZIndex                  = zi or 3
    l.Parent                  = parent
    return l
end

-- ============================================================
-- VARIABLES D'ÉTAT INTERNES
-- ============================================================

local screenGui  : ScreenGui = nil
local mainWindow : Frame     = nil
local statusLabel: TextLabel = nil
local gameLabel  : TextLabel = nil

local notifQueue  = {}
local petalCount  = 0

local NOTIF_W     = 300
local NOTIF_H     = 64
local NOTIF_X     = 16
local NOTIF_Y0    = 80
local NOTIF_GAP   = 10
local NOTIF_DUR   = 4.5
local WIN_W       = 380
local WIN_H       = 265
local ANIM_SPEED  = 0.3
local PETAL_MAX   = 8
local PETAL_FREQ  = 7.0

-- ============================================================
-- CONSTRUCTION DU SCREENGUI
-- ============================================================

local function buildScreenGui()
    -- Nettoyage d'une instance précédente
    local old = PlayerGui:FindFirstChild("EXE_HUB_GUI")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name            = "EXE_HUB_GUI"
    sg.ResetOnSpawn    = false
    sg.IgnoreGuiInset  = true
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    sg.Parent          = PlayerGui
    return sg
end

-- ============================================================
-- CONSTRUCTION DE LA FENÊTRE PRINCIPALE
-- ============================================================

local function buildMainWindow()
    -- Conteneur principal
    local win = frame(
        screenGui,
        UDim2.new(0, WIN_W, 0, WIN_H),
        UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
        C.Panel, 12, 5
    )
    win.Visible = false
    win.Name    = "MainWindow"
    stroke(win, C.PinkNeon, 1.5)
    mainWindow = win

    -- ── Barre de titre ────────────────────────────────────────
    local tb = frame(win, UDim2.new(1,0,0,40), UDim2.new(0,0,0,0), C.TitleBar, 12, 6)

    -- Cache les coins arrondis du bas de la titlebar
    local tbFill = frame(win, UDim2.new(1,0,0,20), UDim2.new(0,0,0,22), C.TitleBar, 0, 5)

    -- Titre
    label(tb, "✦  EXE.HUB",
        UDim2.new(1,-90,1,0), UDim2.new(0,14,0,0),
        C.PinkBright, 15, FONT_BOLD, 7)

    -- Version
    local vl = label(tb, "v1.0.0",
        UDim2.new(0,55,1,0), UDim2.new(1,-65,0,0),
        C.Muted, 11, FONT_NORMAL, 7, Enum.TextXAlignment.Right)

    -- Bouton fermer
    local cb = Instance.new("TextButton")
    cb.Size              = UDim2.new(0,26,0,26)
    cb.Position          = UDim2.new(1,-32,0,7)
    cb.BackgroundColor3  = C.CloseBtn
    cb.TextColor3        = C.White
    cb.Text              = "✕"
    cb.Font              = FONT_BOLD
    cb.TextSize          = 12
    cb.BorderSizePixel   = 0
    cb.ZIndex            = 9
    cb.Parent            = tb
    corner(cb, 5)

    cb.MouseButton1Click:Connect(function()
        local t = TweenService:Create(win,
            TweenInfo.new(ANIM_SPEED, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -WIN_W/2, 1.3, 0)})
        t:Play()
        t.Completed:Connect(function()
            win.Visible = false
            win.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
        end)
    end)

    -- ── Séparateur ────────────────────────────────────────────
    local div = frame(win, UDim2.new(1,-24,0,1), UDim2.new(0,12,0,44), C.Divider, 0, 6)

    -- ── Zone de contenu ───────────────────────────────────────
    local content = frame(win, UDim2.new(1,-24,1,-64), UDim2.new(0,12,0,54), C.Content, 8, 5)

    statusLabel = label(content, "Initialisation...",
        UDim2.new(1,-16,0,22), UDim2.new(0,8,0,8),
        C.Muted, 12, FONT_NORMAL, 6)
    statusLabel.Name = "StatusLabel"

    gameLabel = label(content, "",
        UDim2.new(1,-16,0,26), UDim2.new(0,8,0,32),
        C.PinkBright, 14, FONT_BOLD, 6)
    gameLabel.Name = "GameLabel"

    -- Ligne décorative
    local deco = frame(content, UDim2.new(0,50,0,2), UDim2.new(0,8,1,-14), C.PinkNeon, 2, 6)

    -- ── Footer ────────────────────────────────────────────────
    local footer = label(win, "EXE.HUB  •  Crafted with ✦",
        UDim2.new(1,-24,0,16), UDim2.new(0,12,1,-20),
        C.Muted, 10, FONT_NORMAL, 6, Enum.TextXAlignment.Center)
end

-- ============================================================
-- ANIMATION D'OUVERTURE DE LA FENÊTRE
-- ============================================================

local function openMainWindow()
    if not mainWindow then return end
    mainWindow.Position    = UDim2.new(0.5, -WIN_W/2, -0.25, 0)
    mainWindow.Visible     = true
    TweenService:Create(mainWindow,
        TweenInfo.new(ANIM_SPEED, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)}
    ):Play()
end

-- ============================================================
-- SYSTÈME DE NOTIFICATIONS
-- ============================================================

local function repositionNotifs()
    for i, nf in ipairs(notifQueue) do
        local y = NOTIF_Y0 + (i-1) * (NOTIF_H + NOTIF_GAP)
        TweenService:Create(nf,
            TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, -(NOTIF_W + NOTIF_X), 0, y)}
        ):Play()
    end
end

local function notify(title: string, msg: string, accent: Color3, icon: string)
    if not screenGui then return end

    local nf = frame(screenGui,
        UDim2.new(0, NOTIF_W, 0, NOTIF_H),
        UDim2.new(1, 40, 0, NOTIF_Y0),  -- départ hors écran à droite
        C.NotifBg, 8, 20)
    stroke(nf, accent, 1.2)

    -- Barre d'accent latérale
    frame(nf, UDim2.new(0,3,1,-12), UDim2.new(0,6,0,6), accent, 2, 21)

    -- Icône
    local il = label(nf, icon,
        UDim2.new(0,22,1,0), UDim2.new(0,16,0,0),
        accent, 16, FONT_BOLD, 22, Enum.TextXAlignment.Center)

    -- Titre et message
    label(nf, title,
        UDim2.new(1,-50,0,22), UDim2.new(0,44,0,6),
        C.White, 12, FONT_BOLD, 22)
    label(nf, msg,
        UDim2.new(1,-50,0,20), UDim2.new(0,44,0,26),
        C.Muted, 11, FONT_NORMAL, 22)

    -- Ajoute à la queue et repositionne
    table.insert(notifQueue, nf)
    repositionNotifs()

    -- Animation d'entrée depuis la droite
    TweenService:Create(nf,
        TweenInfo.new(ANIM_SPEED, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -(NOTIF_W + NOTIF_X), 0, NOTIF_Y0)}
    ):Play()

    -- Sortie automatique après NOTIF_DUR secondes
    task.delay(NOTIF_DUR, function()
        if not nf or not nf.Parent then return end
        local currentY = nf.Position.Y.Offset
        local tout = TweenService:Create(nf,
            TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 40, 0, currentY)})
        tout:Play()
        tout.Completed:Connect(function()
            local idx = table.find(notifQueue, nf)
            if idx then table.remove(notifQueue, idx) end
            if nf and nf.Parent then nf:Destroy() end
            repositionNotifs()
        end)
    end)
end

-- ============================================================
-- SYSTÈME DE PÉTALES SAKURA
-- ============================================================

local function spawnPetal()
    if not screenGui or petalCount >= PETAL_MAX then return end
    petalCount += 1

    local sz = math.random(4, 9)
    local px = math.random(0, 95) / 100

    local p = frame(screenGui,
        UDim2.new(0, sz, 0, math.floor(sz * 0.65)),
        UDim2.new(px, 0, -0.04, 0),
        C.Petal, sz, 1)
    p.BackgroundTransparency = math.random(35, 65) / 100
    p.Rotation = math.random(-35, 35)

    local dur   = math.random(55, 110) / 10
    local drift = math.random(-12, 12) / 100

    local t = TweenService:Create(p,
        TweenInfo.new(dur, Enum.EasingStyle.Linear),
        {
            Position              = UDim2.new(px + drift, 0, 1.08, 0),
            Rotation              = p.Rotation + math.random(-80, 80),
            BackgroundTransparency= 0.92
        })
    t:Play()
    t.Completed:Connect(function()
        if p and p.Parent then p:Destroy() end
        petalCount -= 1
    end)
end

local function startPetals()
    task.spawn(function()
        while screenGui and screenGui.Parent do
            pcall(spawnPetal)
            task.wait(PETAL_FREQ + math.random(0, 4) - 2)
        end
    end)
end

-- ============================================================
-- API PUBLIQUE
-- ============================================================

function UI.Init()
    screenGui = buildScreenGui()
    buildMainWindow()
    startPetals()
    print("[EXE.HUB] UI initialisée avec succès.")
end

function UI.ShowWelcome()
    notify("Bienvenue", "EXE.HUB est actif ✦", C.PinkNeon, "✦")
    openMainWindow()
    if statusLabel then statusLabel.Text = "Hub initialisé avec succès." end
end

function UI.ShowGameDetected(gameName: string)
    notify("Jeu détecté", gameName, C.Green, "◈")
    if statusLabel then statusLabel.Text = "Chargement du module..." end
    if gameLabel   then gameLabel.Text   = "▸ " .. gameName end
end

function UI.ShowGameLoaded(gameName: string)
    notify("Module chargé", gameName .. " est prêt.", C.Green, "✔")
    if statusLabel then statusLabel.Text = "Actif." end
end

function UI.ShowNotSupported(placeId: number)
    notify("Non supporté", "PlaceId : " .. tostring(placeId), C.Yellow, "⚠")
    if statusLabel then statusLabel.Text = "Jeu non pris en charge." end
end

function UI.ShowLoadError(moduleName: string)
    notify("Erreur", moduleName, C.Red, "✖")
    if statusLabel then statusLabel.Text = "Erreur de chargement." end
end

function UI.Notify(title: string, message: string, notifType: string?)
    local accent = C.PinkNeon
    local icon   = "◆"
    if notifType == "success" then accent = C.Green  ; icon = "✔" end
    if notifType == "warning" then accent = C.Yellow ; icon = "⚠" end
    if notifType == "error"   then accent = C.Red    ; icon = "✖" end
    notify(title, message, accent, icon)
end

function UI.SetMainWindowStatus(status: string, gameName: string?)
    if statusLabel then statusLabel.Text = status end
    if gameLabel and gameName then gameLabel.Text = "▸ " .. gameName end
end

return UI