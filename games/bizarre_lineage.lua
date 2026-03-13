-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  EXE.HUB  —  games/bizarre_lineage.lua                         ║
-- ║  All Bizarre Lineage game content : Main / Items / Teleport     ║
-- ╚══════════════════════════════════════════════════════════════════╝

local BL = {}
_G.__EXE_HUB_MODULES = _G.__EXE_HUB_MODULES or {}
_G.__EXE_HUB_MODULES["bizarre_lineage"] = BL

BL.Name    = "Bizarre Lineage"
BL.Version = "V1"

-- ══════════════════════════════════════════════════════════════════
-- GAME DATA
-- ══════════════════════════════════════════════════════════════════
local D = {}

D.MOBS = {"All Mobs"}

D.MOB_SPAWNS = {"[Mob spawn locations TBA]"}

D.STANDS = {
    "Any Stand",
    "Star Platinum","The World","Crazy Diamond",
    "Gold Experience","King Crimson","Sticky Fingers",
    "Purple Haze","White Snake","C-Moon",
    "Made in Heaven","Soft and Wet",
    "Tusk Act 4","D4C Love Train","Bohemian Rhapsody",
}

D.STAT_RANKS    = {"D","C","B","A","S"}
D.PERSONALITIES = {"[Personalities TBA]"}

D.BUS_STOPS = {}
for i=1,19 do D.BUS_STOPS[i]="Bus Stop "..i end

D.NPC_MAIN_QUEST = {
    "Jotaro Kujo","Mr. Rengatei","Lowly Thief","Rohan Kishibe",
    "Akihiko","Aya Tsuji","Okuyasu Nijimura","Detective",
}
D.NPC_SIDE_QUEST = {
    "Shozuki","Tonio Trussardi","Rose","Dedequan",
    "Ancient Ghost","Gardner Gwen","Geordie Greep","Kaiser",
    "Shadowy Figure","Jean Pierre Polnareff",
    "Speedwagon Scientist","Rudol von Stroheim",
}
D.NPC_RAID    = {"Yoshikage Kira","Chumbo","Muhammad Avdol"}
D.NPC_UTILITY = {"Gym Owner","Rhett","Reina","Gupta","Saitama","Masuyo"}
D.NPC_FIGHT   = {"Karate Sensei"}

D.CORE_ITEMS = {
    "Stand Arrow","Stone Mask","Lucky Arrow",
    "Common Chest","Rare Chest","Legendary Chest",
    "DIO's Diary","Red Stone of Aja",
}
D.ESSENCE_ITEMS = {
    "Stat Point Essence","Stand Skin Essence","Stand Stat Essence",
    "Stand Personality Essence","Stand Conjuration Essence","Custom Clothing Essence",
}
D.CHEST_ITEMS = {"Common Chest","Rare Chest","Legendary Chest"}

-- Only items that actually spawn on the ground / in the world
D.COLLECTIBLE_ITEMS = {
    "Stand Arrow","Lucky Arrow","Stone Mask",
    "Red Stone of Aja","DIO's Diary",
}

-- Items with individual ESP colour selectors
D.ESP_ITEMS = {
    "Stand Arrow","Lucky Arrow",
    "Common Chest","Rare Chest","Legendary Chest",
    "Stat Point Essence","Stand Skin Essence",
}

D.TP_COORDS = {}  -- [name]=Vector3 — fill in once coords are known

-- ══════════════════════════════════════════════════════════════════
-- ESP COLOUR STATE
-- ══════════════════════════════════════════════════════════════════
local ESPMobColorRef    = {Color3.fromRGB(255,80,80)}
local ESPPlayerColorRef = {Color3.fromRGB(80,180,255)}
local ESPItemColors     = {}
for _,item in ipairs(D.ESP_ITEMS) do
    ESPItemColors[item] = {Color3.fromRGB(255,200,60)}
end

-- ══════════════════════════════════════════════════════════════════
-- FEATURE STATE
-- ══════════════════════════════════════════════════════════════════
local fT = {}
local function FT(k)      return fT[k] or false end
local function setFT(k,v) fT[k]=v end

-- ══════════════════════════════════════════════════════════════════
-- TELEPORT HELPER
-- ══════════════════════════════════════════════════════════════════
local function teleportTo(name)
    local pos = D.TP_COORDS[name]
    if pos then
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(pos)
        end
    else
        print("[EXE] TP '"..tostring(name).."' coords TBA")
    end
end

-- ══════════════════════════════════════════════════════════════════
-- AUTO FARM LOOP
-- ══════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.1)
        if not FT("farmActive") then continue end
        local char = Players.LocalPlayer.Character; if not char then continue end
        local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then continue end

        local targetName = nil
        local sidx = fT["mob_sel_sel"] or 0
        if sidx > 1 and D.MOBS[sidx] then targetName = D.MOBS[sidx] end

        local best, bestDist = nil, math.huge
        for _, npc in ipairs(workspace:GetChildren()) do
            if npc:IsA("Model") and npc ~= Players.LocalPlayer.Character then
                local h = npc:FindFirstChild("Humanoid")
                local r = npc:FindFirstChild("HumanoidRootPart")
                if h and r and h.Health > 0 then
                    if not targetName or npc.Name == targetName then
                        local d = (hrp.Position - r.Position).Magnitude
                        if d < bestDist then bestDist=d; best=r end
                    end
                end
            end
        end

        if best then
            local method  = (fT["farm_method_sel"] or 0) == 2 and "Below" or "Above"
            local offsetY = fT["farmOffY_val"] or 0
            local ty = best.Position.Y + (method=="Above" and (3+offsetY) or (-3-offsetY))
            hrp.CFrame = CFrame.new(best.Position.X, ty, best.Position.Z)
            task.wait(0.05)
            if FT("farmActivateStand") then
                pcall(function()
                    -- Stand activation hook — game-specific trigger goes here
                end)
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- AUTO MEDITATE LOOP
-- ══════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.5)
        if not FT("autoMeditate") then continue end
        pcall(function()
            -- Meditate trigger — game-specific hook goes here
        end)
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- AUTO COLLECT LOOP
-- ══════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.2)
        local anyOn = false
        for _, item in ipairs(D.COLLECTIBLE_ITEMS) do
            if FT("collect_"..item:lower():gsub("[^%a%d]","_")) then anyOn=true; break end
        end
        if not anyOn then continue end

        local char = Players.LocalPlayer.Character; if not char then continue end
        local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then continue end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("Part") then
                for _, item in ipairs(D.COLLECTIBLE_ITEMS) do
                    local k = "collect_"..item:lower():gsub("[^%a%d]","_")
                    if FT(k) and obj.Name:find(item,1,true) then
                        local pos = (obj:IsA("Part") and obj.Position)
                            or (obj:FindFirstChild("HumanoidRootPart") and obj.HumanoidRootPart.Position)
                            or (obj.PrimaryPart and obj.PrimaryPart.Position)
                        if pos then
                            hrp.CFrame = CFrame.new(pos+Vector3.new(0,3,0))
                            task.wait(0.15)
                        end
                        break
                    end
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- ESP RENDER LOOP
-- ══════════════════════════════════════════════════════════════════
local espDrawings = {}
local function clearESP()
    for _, d in ipairs(espDrawings) do pcall(function() d:Remove() end) end
    table.clear(espDrawings)
end
task.spawn(function()
    while true do
        task.wait(0.05)
        clearESP()
        local cam = workspace.CurrentCamera; if not cam then continue end
        local lp  = Players.LocalPlayer

        if FT("espMobOn") then
            for _, npc in ipairs(workspace:GetChildren()) do
                if npc:IsA("Model") and npc ~= lp.Character then
                    local h = npc:FindFirstChild("Humanoid")
                    local r = npc:FindFirstChild("HumanoidRootPart")
                    if h and r and h.Health > 0 then
                        local pt,vis = cam:WorldToViewportPoint(r.Position)
                        if vis then
                            local lbl = Drawing.new("Text")
                            lbl.Text=npc.Name; lbl.Size=12; lbl.Outline=true
                            lbl.Color=ESPMobColorRef[1]; lbl.Center=true
                            lbl.Position=Vector2.new(pt.X, pt.Y-10)
                            lbl.ZIndex=50; lbl.Visible=true
                            espDrawings[#espDrawings+1]=lbl
                        end
                    end
                end
            end
        end

        if FT("espPlayerOn") then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character then
                    local r = plr.Character:FindFirstChild("HumanoidRootPart")
                    if r then
                        local pt,vis = cam:WorldToViewportPoint(r.Position)
                        if vis then
                            local lbl = Drawing.new("Text")
                            lbl.Text=plr.Name; lbl.Size=12; lbl.Outline=true
                            lbl.Color=ESPPlayerColorRef[1]; lbl.Center=true
                            lbl.Position=Vector2.new(pt.X, pt.Y-10)
                            lbl.ZIndex=50; lbl.Visible=true
                            espDrawings[#espDrawings+1]=lbl
                        end
                    end
                end
            end
        end

        if FT("espItemOn") then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                    local ok2, pt2 = pcall(function()
                        return cam:WorldToViewportPoint(obj.Position)
                    end)
                    if ok2 and pt2.Z > 0 then
                        for _, item in ipairs(D.ESP_ITEMS) do
                            if obj.Name:find(item,1,true) then
                                local col = (ESPItemColors[item] and ESPItemColors[item][1])
                                    or Color3.fromRGB(255,200,60)
                                local lbl = Drawing.new("Text")
                                lbl.Text=item; lbl.Size=10; lbl.Outline=true
                                lbl.Color=col; lbl.Center=true
                                lbl.Position=Vector2.new(pt2.X, pt2.Y-8)
                                lbl.ZIndex=50; lbl.Visible=true
                                espDrawings[#espDrawings+1]=lbl
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- TAB: MAIN
-- ══════════════════════════════════════════════════════════════════
local function buildMain(ctx)
    local o, D2, pal = ctx.objs, ctx.D, ctx.C
    local cx, cy, cw = ctx.cx, ctx.cy, ctx.cw
    local h2 = math.floor((cw-6)/2)
    local sy = cy

    -- ┌─ AUTO FARM MOB (left column) ───────────────────────────┐
    local af = ctx.Card(cx, sy, h2, "AUTO FARM MOB")
    local ay = af.cy

    ay = ctx.Label(af.cx, ay, "Mob Selection :")
    ay = ctx.Dropdown(af.cx, ay, af.cw, "mob_sel", D.MOBS, "All Mobs")
    ay = ay + 3
    ay = ctx.Checkbox(af.cx, ay, "farmActive",       "Enable Farm")
    ay = ctx.Checkbox(af.cx, ay, "farmActivateStand","Auto Activate Stand")
    ay = ctx.Checkbox(af.cx, ay, "farmKillStand",    "Auto Kill Stand")
    ay = ay + 3
    ay = ctx.Label(af.cx, ay, "Position Method :")
    ay = ctx.Dropdown(af.cx, ay, af.cw, "farm_method", {"Above","Below"}, "Above")
    ay = ctx.Slider(af.cx, ay, af.cw, "farmOffY", "Offset Y", -50, 50, 0)
    local afEnd = af.finalize(ay)

    -- ┌─ AUTO MEDITATE (right column) ──────────────────────────┐
    local md = ctx.Card(cx+h2+6, af.by, h2, "AUTO MEDITATE")
    local my = md.cy
    my = ctx.Label(md.cx, my, "Meditate automatically.")
    my = ctx.Checkbox(md.cx, my, "autoMeditate", "Auto Meditate")
    local mdEnd = md.finalize(my)

    sy = math.max(afEnd, mdEnd) + 8

    -- ┌─ STATUS ────────────────────────────────────────────────┐
    -- Status is placed first; ESP goes directly below it
    local stc = ctx.Card(cx, sy, cw, "STATUS")
    local sty = stc.cy
    o[#o+1] = D2.Text(stc.cx,    sty, "Game :",    pal.muted, 10, 6)
    o[#o+1] = D2.Text(stc.cx+44, sty, ctx.dynName(), Color3.fromRGB(236,230,252), 11, 6)
    sty = sty + 16
    o[#o+1] = D2.Text(stc.cx,    sty, "Version :", pal.muted, 10, 6)
    o[#o+1] = D2.Text(stc.cx+52, sty, ctx.dynVer(),  Color3.fromRGB(236,230,252), 11, 6)
    sy = stc.finalize(sty+8) + 8

    -- ┌─ ESP (under Status, as specified) ──────────────────────┐
    local ec = ctx.Card(cx, sy, cw, "ESP")
    local ey = ec.cy
    local c3 = math.floor((ec.cw - 8) / 3)

    -- Helper: inline checkbox at an arbitrary x position
    local function inlineCheckbox(bx, by2, key, label)
        local SZ = 13; local on = FT(key)
        o[#o+1] = D2.Rect(bx, by2, SZ, SZ, pal.chkBg, 7)
        o[#o+1] = D2.Outline(bx, by2, SZ, SZ, pal.cardBrd, 1, 8)
        local fill = D2.Rect(bx+1, by2+1, SZ-2, SZ-2, ctx.AC(), 7); fill.Visible=on; o[#o+1]=fill
        local t1 = D2.Line(bx+2,by2+6, bx+5,by2+10, Color3.fromRGB(255,255,255), 2, 9)
        local t2 = D2.Line(bx+5,by2+10, bx+11,by2+3, Color3.fromRGB(255,255,255), 2, 9)
        t1.Visible=on; t2.Visible=on; o[#o+1]=t1; o[#o+1]=t2
        o[#o+1] = D2.Text(bx+SZ+5, by2+1, label, Color3.fromRGB(236,230,252), 11, 7)
        ctx.Zone(bx, by2, SZ+6+math.max(60,#label*6), SZ+2, function()
            local v = not FT(key); setFT(key,v)
            pcall(function() fill.Visible=v; fill.Color=ctx.AC(); t1.Visible=v; t2.Visible=v end)
        end)
        return by2 + SZ + 7
    end

    -- Helper: inline color swatch at an arbitrary x position
    local function inlineSwatch(bx, by2, label, colorRef)
        local SW2, SH2 = 20, 13
        local swatch = D2.Rect(bx, by2, SW2, SH2, colorRef[1], 7); o[#o+1]=swatch
        o[#o+1] = D2.Outline(bx, by2, SW2, SH2, pal.cardBrd, 1, 8)
        o[#o+1] = D2.Text(bx+SW2+5, by2+2, label, Color3.fromRGB(162,142,188), 9, 7)
        local ci = 1; local CP = ctx.COLOR_PRESETS
        ctx.Zone(bx, by2, SW2+5+math.max(60,#label*7), SH2, function()
            ci = ci%#CP+1; colorRef[1]=CP[ci]
            pcall(function() swatch.Color=CP[ci] end)
        end)
        return by2 + SH2 + 5
    end

    -- ── Mob ESP column ──────────────────────────────────────
    o[#o+1] = D2.Text(ec.cx, ey, "MOB ESP", pal.muted, 9, 6)
    local em = ey + 12
    em = inlineCheckbox(ec.cx, em, "espMobOn", "Enable")
    em = inlineSwatch(ec.cx, em, "Mob Color", ESPMobColorRef)

    -- ── Player ESP column ───────────────────────────────────
    local pcx = ec.cx + c3 + 4
    o[#o+1] = D2.Text(pcx, ey, "PLAYER ESP", pal.muted, 9, 6)
    local ep = ey + 12
    ep = inlineCheckbox(pcx, ep, "espPlayerOn", "Enable")
    ep = inlineSwatch(pcx, ep, "Player Color", ESPPlayerColorRef)

    -- ── Item ESP column ─────────────────────────────────────
    local icx = ec.cx + c3*2 + 8
    o[#o+1] = D2.Text(icx, ey, "ITEM ESP", pal.muted, 9, 6)
    local ei = ey + 12
    ei = inlineCheckbox(icx, ei, "espItemOn", "Enable")
    -- Per-item colour swatches
    for _, item in ipairs(D.ESP_ITEMS) do
        local ref   = ESPItemColors[item]
        local short = item:match("^(.-)%s") or item:sub(1,9)
        local SW2, SH2 = 16, 11
        local swatch = D2.Rect(icx, ei, SW2, SH2, ref[1], 7); o[#o+1]=swatch
        o[#o+1] = D2.Outline(icx, ei, SW2, SH2, pal.cardBrd, 1, 8)
        o[#o+1] = D2.Text(icx+SW2+4, ei+1, short, Color3.fromRGB(162,142,188), 8, 7)
        local ci=1; local r2=ref; local CP=ctx.COLOR_PRESETS
        ctx.Zone(icx, ei, SW2+4+60, SH2, function()
            ci=ci%#CP+1; r2[1]=CP[ci]
            pcall(function() swatch.Color=CP[ci] end)
        end)
        ei = ei + SH2 + 4
    end

    ec.finalize(math.max(em, ep, ei))
end

-- ══════════════════════════════════════════════════════════════════
-- TAB: ITEMS
-- ══════════════════════════════════════════════════════════════════
local function buildItems(ctx)
    local cx, cy, cw = ctx.cx, ctx.cy, ctx.cw
    local sy = cy

    -- Build full item list (Core + Essence)
    local allItems = {}
    for _,v in ipairs(D.CORE_ITEMS)    do allItems[#allItems+1]=v end
    for _,v in ipairs(D.ESSENCE_ITEMS) do allItems[#allItems+1]=v end

    -- ┌─ ITEM SELECTION ────────────────────────────────────────┐
    local isc = ctx.Card(cx, sy, cw, "ITEM SELECTION")
    local iy = isc.cy
    iy = ctx.Label(isc.cx, iy, "Select item to manage :")
    iy = ctx.Dropdown(isc.cx, iy, isc.cw, "item_sel", allItems, "All Items")
    sy = isc.finalize(iy) + 8

    -- ┌─ AUTO COLLECT ITEM ─────────────────────────────────────┐
    local acc = ctx.Card(cx, sy, cw, "AUTO COLLECT ITEM")
    local ay = acc.cy
    ay = ctx.Label(acc.cx, ay, "Teleports to world items and collects them.")
    ay = ctx.Label(acc.cx, ay, "Ground-spawn collectibles only.")
    ay = ay + 3
    for _, item in ipairs(D.COLLECTIBLE_ITEMS) do
        local k = "collect_"..item:lower():gsub("[^%a%d]","_")
        ay = ctx.Checkbox(acc.cx, ay, k, item)
    end
    sy = acc.finalize(ay) + 8

    -- ┌─ AUTO USE ──────────────────────────────────────────────┐
    local auc = ctx.Card(cx, sy, cw, "AUTO USE")
    local uy = auc.cy

    -- §§ AUTO ARROW
    uy = ctx.Section(auc.cx, uy, auc.cw, "Auto Arrow")
    uy = ctx.Label(auc.cx, uy, "Arrow type :")
    uy = ctx.Dropdown(auc.cx, uy, auc.cw, "arrow_type",
        {"Stand Arrow","Lucky Arrow"}, "Stand Arrow")
    uy = ctx.Label(auc.cx, uy, "Target Stand :")
    uy = ctx.Dropdown(auc.cx, uy, auc.cw, "arrow_stand", D.STANDS, "Any Stand")
    uy = ctx.Checkbox(auc.cx, uy, "arrowAutoSpin", "Auto Spin  (repeat until target)")
    uy = ctx.Checkbox(auc.cx, uy, "arrowStopSkin", "Stop when Stand Skin obtained")
    uy = uy + 4

    uy = ctx.Label(auc.cx, uy, "Stop when Stand stats >=")
    local sw3 = math.floor((auc.cw-8)/3)
    local o = ctx.objs; local D2 = ctx.D; local pal = ctx.C
    o[#o+1] = D2.Text(auc.cx,         uy, "STR",  pal.muted, 8, 6)
    o[#o+1] = D2.Text(auc.cx+sw3+4,   uy, "SPD",  pal.muted, 8, 6)
    o[#o+1] = D2.Text(auc.cx+sw3*2+8, uy, "SPEC", pal.muted, 8, 6)
    uy = uy + 11
    local rowY = uy
    uy = ctx.Dropdown(auc.cx,          rowY, sw3, "req_str",  D.STAT_RANKS, "D")
    ctx.Dropdown(auc.cx+sw3+4,         rowY, sw3, "req_spd",  D.STAT_RANKS, "D")
    ctx.Dropdown(auc.cx+sw3*2+8,       rowY, sw3, "req_spec", D.STAT_RANKS, "D")
    uy = uy + 5

    uy = ctx.Label(auc.cx, uy, "Search Personality :")
    uy = ctx.Dropdown(auc.cx, uy, auc.cw, "req_pers", D.PERSONALITIES, "Any")
    uy = uy + 8

    -- §§ AUTO CHEST
    uy = ctx.Section(auc.cx, uy, auc.cw, "Auto Chest")
    for _, chest in ipairs(D.CHEST_ITEMS) do
        local k = "autoChest_"..chest:lower():gsub("[^%a%d]","_")
        uy = ctx.Checkbox(auc.cx, uy, k, chest)
    end
    uy = uy + 8

    -- §§ AUTO USE ESSENCE
    uy = ctx.Section(auc.cx, uy, auc.cw, "Auto Use Essence")
    for _, ess in ipairs(D.ESSENCE_ITEMS) do
        local k = "autoEss_"..ess:lower():gsub("[^%a%d]","_")
        uy = ctx.Checkbox(auc.cx, uy, k, ess)
    end
    uy = uy + 6

    auc.finalize(uy)
end

-- ══════════════════════════════════════════════════════════════════
-- TAB: TELEPORT
-- ══════════════════════════════════════════════════════════════════
local function buildTeleport(ctx)
    local cx, cy, cw = ctx.cx, ctx.cy, ctx.cw
    local sy = cy

    -- ┌─ BUS STOPS ─────────────────────────────────────────────┐
    local bsC = ctx.Card(cx, sy, cw, "BUS STOPS")
    local by = bsC.cy
    by = ctx.Label(bsC.cx, by, "Select a bus stop (1 – 19) :")
    by = ctx.Dropdown(bsC.cx, by, bsC.cw, "tp_bus", D.BUS_STOPS, "Bus Stop 1")
    by = ctx.Button(bsC.cx, by, bsC.cw, "Teleport to Bus Stop", function()
        local idx = (ctx.FT and fT["tp_bus_sel"]) or 1
        teleportTo(D.BUS_STOPS[idx] or D.BUS_STOPS[1])
    end)
    sy = bsC.finalize(by) + 8

    -- ┌─ MOB SPAWN ─────────────────────────────────────────────┐
    local msC = ctx.Card(cx, sy, cw, "MOB SPAWN")
    local my = msC.cy
    my = ctx.Label(msC.cx, my, "Select mob spawn area :")
    my = ctx.Dropdown(msC.cx, my, msC.cw, "tp_mob", D.MOB_SPAWNS, "Select mob spawn")
    my = ctx.Button(msC.cx, my, msC.cw, "Teleport to Mob Spawn", function()
        local idx = fT["tp_mob_sel"] or 1
        teleportTo(D.MOB_SPAWNS[idx] or D.MOB_SPAWNS[1])
    end)
    sy = msC.finalize(my) + 8

    -- ┌─ NPC TELEPORT ──────────────────────────────────────────┐
    -- NPCs split by category — not a flat list
    local npC = ctx.Card(cx, sy, cw, "NPC TELEPORT")
    local ny = npC.cy

    local function npcSection(key, items, sectionLabel)
        ny = ctx.Section(npC.cx, ny, npC.cw, sectionLabel)
        ny = ctx.Dropdown(npC.cx, ny, npC.cw, "tp_"..key, items, "Select NPC")
        ny = ctx.Button(npC.cx, ny, npC.cw, "Teleport", function()
            local idx = fT["tp_"..key.."_sel"] or 1
            teleportTo(items[idx] or items[1])
        end)
        ny = ny + 5
    end

    npcSection("mq",   D.NPC_MAIN_QUEST, "Main Quest NPCs")
    npcSection("sq",   D.NPC_SIDE_QUEST, "Side Quest NPCs")
    npcSection("raid", D.NPC_RAID,       "Raid NPCs")
    npcSection("util", D.NPC_UTILITY,    "Utility / Other NPCs")
    npcSection("fight",D.NPC_FIGHT,      "Fighting Style NPCs")

    npC.finalize(ny)
end

-- ══════════════════════════════════════════════════════════════════
-- MODULE INIT
-- ══════════════════════════════════════════════════════════════════
function BL.Init(api)
    -- Store API refs for future use if needed
    local _UI = api.UI
end

BL.Tabs = {
    {name="Main",     buildFn=buildMain},
    {name="Items",    buildFn=buildItems},
    {name="Teleport", buildFn=buildTeleport},
}

return BL