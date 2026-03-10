-- ============================================================
--  EXE.HUB | games/bizarre_lineage.lua
--  Module de jeu : Bizarre Lineage
--  Ce fichier est le point d'entrée du module pour ce jeu.
--  Il expose une fonction Init(deps) qui reçoit :
--    deps.UI    → module UI du hub (notifications, fenêtres)
--    deps.Utils → module utilitaires (logs, helpers)
--
--  Pour ajouter des fonctionnalités à ce jeu :
--    → Ajoute des fonctions dans ce fichier
--    → Ou crée des sous-modules et charge-les ici
-- ============================================================

local BizarreLineage = {}

-- ============================================================
-- MÉTADONNÉES DU MODULE
-- ============================================================

BizarreLineage.Name    = "Bizarre Lineage"
BizarreLineage.Version = "1.0.0"
BizarreLineage.Author  = "EXE.HUB"

-- ============================================================
-- RÉFÉRENCES AUX DÉPENDANCES (injectées à l'Init)
-- ============================================================

local UI: any    = nil
local Utils: any = nil

-- ============================================================
-- FONCTIONNALITÉS DU JEU
-- À compléter avec les vraies mécaniques plus tard.
-- ============================================================

-- Exemple de feature : à remplacer par une vraie logique
local function setupAutoFarm()
    -- TODO : implémenter l'auto-farm pour Bizarre Lineage
    Utils.Log("[Bizarre Lineage] AutoFarm initialisé (placeholder).")
end

local function setupESP()
    -- TODO : implémenter l'ESP (affichage des joueurs, objets)
    Utils.Log("[Bizarre Lineage] ESP initialisé (placeholder).")
end

local function setupQOL()
    -- TODO : qualité de vie (raccourcis, tweaks de confort)
    Utils.Log("[Bizarre Lineage] QoL initialisé (placeholder).")
end

-- ============================================================
-- POINT D'ENTRÉE : Init(deps)
-- Appelé automatiquement par le Loader après chargement.
-- deps : { UI, Utils }
-- ============================================================

function BizarreLineage.Init(deps: {UI: any, Utils: any})

    -- Récupère les dépendances injectées par le hub
    UI    = deps.UI
    Utils = deps.Utils

    -- Log de confirmation dans la console
    Utils.Log("═══════════════════════════════════")
    Utils.Log("  Bizarre Lineage — Module chargé  ")
    Utils.Log("  Version : " .. BizarreLineage.Version)
    Utils.Log("═══════════════════════════════════")

    -- Notification dans l'UI du hub
    UI.Notify(
        "Bizarre Lineage",
        "Module v" .. BizarreLineage.Version .. " chargé ✦",
        "success"
    )

    -- Initialisation des features (placeholders pour l'instant)
    setupAutoFarm()
    setupESP()
    setupQOL()

    Utils.Log("[Bizarre Lineage] Toutes les features sont initialisées.")
end

-- ============================================================
-- RETOURNE LE MODULE
-- ============================================================

return BizarreLineage