-- ============================================================
--  EXE.HUB | system/ui.lua
--  Module d'interface utilisateur principal.
--  Style : sombre + sakura néon
--  Contient :
--    - fenêtre principale du hub
--    - notifications (bienvenue, jeu détecté, non supporté)
--    - pétales sakura discrets en arrière-plan
--    - bordures néon roses subtiles
-- ============================================================

local UI = {}

-- ============================================================
-- SERVICES ROBLOX
-- ============================================================

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")

local LocalPlayer    = Players.LocalPlayer
local PlayerGui      = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- PALETTE DE COULEURS — Thème Sakura Néon Sombre
-- ============================================================

local COLORS = {
    Background      = Color3.fromRGB(10,  10,  14),   -- Noir quasi-pur
    Panel           = Color3.fromRGB(18,  18,  26),   -- Gris très sombre
    PanelBorder     = Color3.fromRGB(220, 80,  140),  -- Rose néon principal
    PanelBorderGlow = Color3.fromRGB(255, 120, 180),  -- Rose néon lumineux
    TextPrimary     = Color3.fromRGB(240, 240, 248),  -- Blanc légèrement bleuté
    TextSecondary   = Color3.fromRGB(180, 140, 180),  -- Violet-rose doux
    TextAccent      = Color3.fromRGB(255, 130, 180),  -- Rose vif
    NotifBg         = Color3.fromRGB(22,  16,  28),   -- Fond notification sombre
    NotifBorder     = Color3.fromRGB(200, 70,  130),  -- Bordure notification
    NotifSuccess    = Color3.fromRGB(120, 240, 160),  -- Vert succès doux
    NotifWarning    = Color3.fromRGB(255, 200, 80),   -- Jaune avertissement
    NotifError      = Color3.fromRGB(255, 90,  90),   -- Rouge erreur
    Petal           = Color3.fromRGB(255, 180, 210),  -- Couleur pétale sakura
    Divider         = Color3.fromRGB(60,  30,  50),   -- Séparateur sombre
    ButtonBg        = Color3.fromRGB(35,  20,  45),   -- Fond bouton
    ButtonHover     = Color3.fromRGB(55,  30,  70),   -- Fond bouton hover
}

-- ============================================================
-- PARAMÈTRES GÉNÉRAUX
-- ============================================================

local SETTINGS = {
    HubVersion      = "1.0.0",
    HubTitle        = "EXE.HUB",
    MainWindowWidth = 380,
    MainWindowHeight= 260,
    NotifWidth      = 300,
    NotifHeight     = 64,
    NotifDuration   = 4.0,   -- secondes avant disparition
    PetalCount      = 8,     -- nb max de pétales simultanés
    PetalFrequency  = 6.0,   -- secondes entre apparitions de pétale
    AnimSpeed       = 0.35,  -- vitesse des tweens UI en secondes
}

-- ============================================================
-- CONTENEUR RACINE DE L'UI
-- ============================================================

local screenGui: ScreenGui = nil

local function createScreenGui(): ScreenGui
    -- Supprime un ancien hub s'il existe déjà
    local existing = PlayerGui:FindFirstChild("EXE_HUB_GUI")
    if existing then
        existing:Destroy()
    end

    local gui       = Instance.new("ScreenGui")
    gui.Name        = "EXE_HUB_GUI"
    gui.ResetOnSpawn= false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.Parent      = PlayerGui

    return gui
end

-- ============================================================
-- HELPER : Crée un Frame arrondi avec bordure néon
-- ============================================================

local function createRoundFrame(
    parent: Instance,
    size: UDim2,
    position: UDim2,
    bgColor: Color3,
    cornerRadius: number?,
    zIndex: number?
): Frame
    local frame         = Instance.new("Frame")
    frame.Size          = size
    frame.Position      = position
    frame.BackgroundColor3 = bgColor
    frame.BorderSizePixel  = 0
    frame.ZIndex        = zIndex or 1
    frame.Parent        = parent

    local corner        = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius or 8)
    corner.Parent       = frame

    return frame
end

-- ============================================================
-- HELPER : Crée un label de texte stylisé
-- ============================================================

local function createLabel(
    parent: Instance,
    text: string,
    size: UDim2,
    position: UDim2,
    color: Color3,
    fontSize: number?,
    fontWeight: Enum.FontWeight?,
    zIndex: number?
): TextLabel
    local label             = Instance.new("TextLabel")
    label.Text              = text
    label.Size              = size
    label.Position          = position
    label.BackgroundTransparency = 1
    label.TextColor3        = color
    label.Font              = Enum.Font.GothamBold
    label.TextSize          = fontSize or 13
    label.TextXAlignment    = Enum.TextXAlignment.Left
    label.TextYAlignment    = Enum.TextYAlignment.Center
    label.ZIndex            = zIndex or 2
    label.Parent            = parent
    return label
end

-- ============================================================
-- HELPER : Stroke (contour extérieur simulé)
-- Roblox UIStroke appliqué à un Frame/Label
-- ============================================================

local function applyStroke(instance: Instance, color: Color3, thickness: number?): UIStroke
    local stroke    = Instance.new("UIStroke")
    stroke.Color    = color
    stroke.Thickness= thickness or 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent   = instance
    return stroke
end

-- ============================================================
-- FENÊTRE PRINCIPALE DU HUB
-- ============================================================

local mainWindow: Frame = nil
local isMainWindowOpen: boolean = false

local function buildMainWindow()
    if mainWindow then return end

    -- Fond semi-transparent de toute la fenêtre (container centré)
    mainWindow = createRoundFrame(
        screenGui,
        UDim2.new(0, SETTINGS.MainWindowWidth, 0, SETTINGS.MainWindowHeight),
        UDim2.new(0.5, -SETTINGS.MainWindowWidth / 2, 0.5, -SETTINGS.MainWindowHeight / 2),
        COLORS.Panel,
        12,
        5
    )
    mainWindow.Visible = false

    -- Bordure néon extérieure via UIStroke
    applyStroke(mainWindow, COLORS.PanelBorder, 1.8)

    -- ── Barre de titre ────────────────────────────────────────
    local titleBar = createRoundFrame(
        mainWindow,
        UDim2.new(1, 0, 0, 38),
        UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(14, 10, 20),
        12
    )
    titleBar.ZIndex = 6

    -- Masque le bas des coins arrondis de la barre (effet plat en bas)
    local titleBarBottom = createRoundFrame(
        mainWindow,
        UDim2.new(1, 0, 0, 20),
        UDim2.new(0, 0, 0, 20),
        Color3.fromRGB(14, 10, 20),
        0
    )
    titleBarBottom.ZIndex = 5

    -- Icône / titre texte
    local titleLabel = createLabel(
        titleBar,
        "✦  " .. SETTINGS.HubTitle,
        UDim2.new(1, -80, 1, 0),
        UDim2.new(0, 16, 0, 0),
        COLORS.TextAccent,
        15,
        nil,
        7
    )

    -- Version en petit
    local versionLabel = createLabel(
        titleBar,
        "v" .. SETTINGS.HubVersion,
        UDim2.new(0, 60, 1, 0),
        UDim2.new(1, -68, 0, 0),
        COLORS.TextSecondary,
        11,
        nil,
        7
    )
    versionLabel.TextXAlignment = Enum.TextXAlignment.Right

    -- Bouton fermeture
    local closeBtn          = Instance.new("TextButton")
    closeBtn.Size           = UDim2.new(0, 28, 0, 28)
    closeBtn.Position       = UDim2.new(1, -34, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 80)
    closeBtn.TextColor3     = COLORS.TextPrimary
    closeBtn.Text           = "✕"
    closeBtn.Font           = Enum.Font.GothamBold
    closeBtn.TextSize       = 12
    closeBtn.BorderSizePixel= 0
    closeBtn.ZIndex         = 8
    closeBtn.Parent         = titleBar
    local closeBtnCorner    = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent   = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        local tweenOut = TweenService:Create(
            mainWindow,
            TweenInfo.new(SETTINGS.AnimSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -SETTINGS.MainWindowWidth / 2, 1.2, 0), BackgroundTransparency = 1}
        )
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            mainWindow.Visible = false
            isMainWindowOpen = false
            -- Reset position pour réouverture
            mainWindow.Position = UDim2.new(0.5, -SETTINGS.MainWindowWidth / 2, 0.5, -SETTINGS.MainWindowHeight / 2)
            mainWindow.BackgroundTransparency = 0
        end)
    end)

    -- ── Séparateur sous la barre de titre ─────────────────────
    local divider = Instance.new("Frame")
    divider.Size  = UDim2.new(1, -24, 0, 1)
    divider.Position = UDim2.new(0, 12, 0, 42)
    divider.BackgroundColor3 = COLORS.Divider
    divider.BorderSizePixel  = 0
    divider.ZIndex = 6
    divider.Parent = mainWindow

    -- ── Corps du contenu ──────────────────────────────────────
    local contentArea = createRoundFrame(
        mainWindow,
        UDim2.new(1, -24, 1, -60),
        UDim2.new(0, 12, 0, 52),
        Color3.fromRGB(14, 12, 22),
        8,
        6
    )

    -- Texte de statut (mis à jour dynamiquement)
    local statusLabel = createLabel(
        contentArea,
        "Initialisation...",
        UDim2.new(1, -16, 0, 24),
        UDim2.new(0, 8, 0, 8),
        COLORS.TextSecondary,
        12,
        nil,
        7
    )
    statusLabel.Name = "StatusLabel"

    -- Texte jeu détecté
    local gameLabel = createLabel(
        contentArea,
        "",
        UDim2.new(1, -16, 0, 28),
        UDim2.new(0, 8, 0, 34),
        COLORS.TextAccent,
        14,
        nil,
        7
    )
    gameLabel.Name = "GameLabel"

    -- Petite ligne décorative basse
    local decoLine = Instance.new("Frame")
    decoLine.Size  = UDim2.new(0, 60, 0, 2)
    decoLine.Position = UDim2.new(0, 8, 1, -16)
    decoLine.BackgroundColor3 = COLORS.PanelBorder
    decoLine.BorderSizePixel  = 0
    decoLine.ZIndex = 7
    local decoCorner = Instance.new("UICorner")
    decoCorner.CornerRadius = UDim.new(0, 2)
    decoCorner.Parent = decoLine
    decoLine.Parent = contentArea

    -- Label de version en bas
    local footerLabel = createLabel(
        mainWindow,
        "EXE.HUB  •  Crafted with ✦",
        UDim2.new(1, -16, 0, 18),
        UDim2.new(0, 12, 1, -22),
        COLORS.TextSecondary,
        10,
        nil,
        7
    )
    footerLabel.TextXAlignment = Enum.TextXAlignment.Center
    footerLabel.Size = UDim2.new(1, -24, 0, 18)
end

-- ============================================================
-- SYSTÈME DE NOTIFICATIONS EMPILÉES
-- ============================================================

local notifQueue: {Frame} = {}
local NOTIF_X_OFFSET = 16
local NOTIF_Y_START  = 80
local NOTIF_GAP      = 10

-- Recalcule la position de chaque notification dans la pile
local function repositionNotifs()
    for i, notif in ipairs(notifQueue) do
        local targetY = NOTIF_Y_START + (i - 1) * (SETTINGS.NotifHeight + NOTIF_GAP)
        TweenService:Create(
            notif,
            TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, -(SETTINGS.NotifWidth + NOTIF_X_OFFSET), 0, targetY)}
        ):Play()
    end
end

local function createNotification(
    title: string,
    message: string,
    accentColor: Color3,
    icon: string?
)
    local notifFrame = createRoundFrame(
        screenGui,
        UDim2.new(0, SETTINGS.NotifWidth, 0, SETTINGS.NotifHeight),
        UDim2.new(1, 40, 0, NOTIF_Y_START), -- Hors écran droite au départ
        COLORS.NotifBg,
        8,
        20
    )

    -- Barre latérale colorée (accent)
    local accentBar = createRoundFrame(
        notifFrame,
        UDim2.new(0, 3, 1, -12),
        UDim2.new(0, 6, 0, 6),
        accentColor,
        2,
        21
    )

    -- Icône
    local iconLabel = createLabel(
        notifFrame,
        icon or "◆",
        UDim2.new(0, 22, 1, 0),
        UDim2.new(0, 16, 0, 0),
        accentColor,
        16,
        nil,
        22
    )
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- Titre
    local titleLbl = createLabel(
        notifFrame,
        title,
        UDim2.new(1, -50, 0, 22),
        UDim2.new(0, 44, 0, 6),
        COLORS.TextPrimary,
        12,
        nil,
        22
    )

    -- Message
    local msgLbl = createLabel(
        notifFrame,
        message,
        UDim2.new(1, -50, 0, 20),
        UDim2.new(0, 44, 0, 26),
        COLORS.TextSecondary,
        11,
        nil,
        22
    )

    -- Bordure néon de la notif
    applyStroke(notifFrame, accentColor, 1.2)

    -- Ajoute à la queue
    table.insert(notifQueue, notifFrame)
    repositionNotifs()

    -- Animation d'entrée depuis la droite
    TweenService:Create(
        notifFrame,
        TweenInfo.new(SETTINGS.AnimSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -(SETTINGS.NotifWidth + NOTIF_X_OFFSET), 0, NOTIF_Y_START)}
    ):Play()

    -- Auto-disparition après NOTIF_DURATION secondes
    task.delay(SETTINGS.NotifDuration, function()
        -- Animation de sortie vers la droite
        local tweenOut = TweenService:Create(
            notifFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 40, 0, notifFrame.Position.Y.Offset), BackgroundTransparency = 1}
        )
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            -- Retire de la queue
            local idx = table.find(notifQueue, notifFrame)
            if idx then
                table.remove(notifQueue, idx)
            end
            notifFrame:Destroy()
            repositionNotifs()
        end)
    end)
end

-- ============================================================
-- SYSTÈME DE PÉTALES SAKURA
-- Pétales discrets et légers en arrière-plan de l'écran.
-- ============================================================

local petalCount: number = 0

local function spawnPetal()
    if petalCount >= SETTINGS.PetalCount then return end
    petalCount += 1

    local size    = math.random(4, 10)
    local startX  = math.random(0, 100) / 100
    local petal   = Instance.new("Frame")
    petal.Size    = UDim2.new(0, size, 0, size * 0.7)
    petal.Position= UDim2.new(startX, 0, -0.05, 0)
    petal.BackgroundColor3 = COLORS.Petal
    petal.BackgroundTransparency = math.random(30, 60) / 100
    petal.BorderSizePixel = 0
    petal.ZIndex  = 1
    petal.Rotation= math.random(-30, 30)
    petal.Parent  = screenGui

    local corner  = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = petal

    -- Animation de chute (durée aléatoire pour naturel)
    local fallDuration = math.random(60, 120) / 10  -- 6 à 12 secondes
    local driftX       = (math.random(-15, 15)) / 100

    local tweenFall = TweenService:Create(
        petal,
        TweenInfo.new(fallDuration, Enum.EasingStyle.Linear),
        {
            Position  = UDim2.new(startX + driftX, 0, 1.1, 0),
            Rotation  = petal.Rotation + math.random(-90, 90),
            BackgroundTransparency = 0.9
        }
    )
    tweenFall:Play()
    tweenFall.Completed:Connect(function()
        petal:Destroy()
        petalCount -= 1
    end)
end

local function startPetalSystem()
    task.spawn(function()
        while screenGui and screenGui.Parent do
            spawnPetal()
            task.wait(SETTINGS.PetalFrequency + math.random(-2, 3))
        end
    end)
end

-- ============================================================
-- API PUBLIQUE DU MODULE
-- ============================================================

-- Initialise l'UI (doit être appelé en premier)
function UI.Init()
    screenGui = createScreenGui()
    buildMainWindow()
    startPetalSystem()
end

-- Ouvre la fenêtre principale avec animation d'entrée
function UI.OpenMainWindow()
    if not mainWindow then return end
    isMainWindowOpen = true
    mainWindow.Position = UDim2.new(0.5, -SETTINGS.MainWindowWidth / 2, -0.3, 0)
    mainWindow.BackgroundTransparency = 0
    mainWindow.Visible = true

    TweenService:Create(
        mainWindow,
        TweenInfo.new(SETTINGS.AnimSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -SETTINGS.MainWindowWidth / 2, 0.5, -SETTINGS.MainWindowHeight / 2)}
    ):Play()
end

-- Met à jour les labels de statut dans la fenêtre principale
function UI.SetMainWindowStatus(status: string, gameName: string?)
    if not mainWindow then return end
    local contentArea = mainWindow:FindFirstChild("Frame", true)
    -- On cherche les labels par nom dans l'arborescence
    local function findLabel(name: string): TextLabel?
        for _, desc in ipairs(mainWindow:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Name == name then
                return desc
            end
        end
        return nil
    end
    local statusLbl = findLabel("StatusLabel")
    local gameLbl   = findLabel("GameLabel")
    if statusLbl then statusLbl.Text = status end
    if gameLbl and gameName then gameLbl.Text = "▸ " .. gameName end
end

-- Notification de bienvenue
function UI.ShowWelcome()
    createNotification(
        "Bienvenue",
        "EXE.HUB est actif ✦",
        COLORS.PanelBorder,
        "✦"
    )
    UI.OpenMainWindow()
    UI.SetMainWindowStatus("Hub initialisé avec succès.")
end

-- Notification de jeu détecté
function UI.ShowGameDetected(gameName: string)
    createNotification(
        "Jeu détecté",
        gameName,
        COLORS.NotifSuccess,
        "◈"
    )
    UI.SetMainWindowStatus("Chargement du module...", gameName)
end

-- Notification de chargement réussi
function UI.ShowGameLoaded(gameName: string)
    createNotification(
        "Module chargé",
        gameName .. " est prêt.",
        COLORS.NotifSuccess,
        "✔"
    )
    UI.SetMainWindowStatus("Actif.", gameName)
end

-- Notification jeu non supporté
function UI.ShowNotSupported(placeId: number)
    createNotification(
        "Non supporté",
        "PlaceId " .. tostring(placeId),
        COLORS.NotifWarning,
        "⚠"
    )
    UI.SetMainWindowStatus("Jeu non pris en charge.")
end

-- Notification d'erreur de chargement
function UI.ShowLoadError(moduleName: string)
    createNotification(
        "Erreur de chargement",
        moduleName,
        COLORS.NotifError,
        "✖"
    )
    UI.SetMainWindowStatus("Erreur lors du chargement.")
end

-- Notification personnalisée (pour les modules jeux)
function UI.Notify(title: string, message: string, notifType: string?)
    local color = COLORS.PanelBorder
    local icon  = "◆"
    if notifType == "success" then
        color = COLORS.NotifSuccess
        icon  = "✔"
    elseif notifType == "warning" then
        color = COLORS.NotifWarning
        icon  = "⚠"
    elseif notifType == "error" then
        color = COLORS.NotifError
        icon  = "✖"
    end
    createNotification(title, message, color, icon)
end

return UI