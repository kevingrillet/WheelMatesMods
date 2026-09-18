local UEHelpers = require("UEHelpers")

local ModName = "Coordinates"
local overlay_enabled = false
local overlays = {}

--- Writes a consistently terminated module message to the UE4SS console.
local function log(message)
    print(string.format("[%s] %s\n", ModName, message))
end

--- Returns true only for an Unreal object that is still safe to use.
local function is_valid(object)
    return object ~= nil and object:IsValid()
end

--- Extracts the value exposed by UE4SS remote properties where needed.
local function unwrap(value)
    local ok, unwrapped = pcall(function()
        return value:get()
    end)
    return ok and unwrapped or value
end

--- Enumerates currently available local controllers and their controlled Pawns.
local function local_players()
    local players = {}
    local game_instance = UEHelpers.GetGameInstance()
    local local_player_array = game_instance and game_instance.LocalPlayers
    if local_player_array == nil then return players end
    local_player_array:ForEach(function(index, player_param)
        local local_player = player_param:get()
        local controller = local_player and local_player.PlayerController
        local pawn = controller and controller.Pawn
        if is_valid(controller) and is_valid(pawn) then
            table.insert(players, { index = index, controller = controller, pawn = pawn })
        end
    end)
    return players
end

--- Resolves the LocalPlayers record owned by an active split-screen HUD layout.
local function player_for_layout(layout, players, fallback_index)
    local owner_ok, owner = pcall(function() return layout:GetOwningPlayer() end)
    if owner_ok and is_valid(owner) then
        local owner_name = owner:GetFullName()
        for _, player in ipairs(players) do
            if player.controller:GetFullName() == owner_name then return player end
        end
    end
    return players[fallback_index]
end

--- Builds the four compact coordinate lines displayed for one local player.
local function coordinate_text(player_index, pawn)
    local position = pawn:K2_GetActorLocation()
    local rotation = pawn:K2_GetActorRotation()
    local velocity = pawn:GetVelocity()

    return string.format(
        "COORDINATES PLAYER %d\nPosition  X / Y / Z     %.0f / %.0f / %.0f\nRotation  Pitch / Yaw / Roll  %.1f / %.1f / %.1f\nVelocity  X / Y / Z     %.0f / %.0f / %.0f",
        player_index,
        position.X, position.Y, position.Z,
        rotation.Pitch, rotation.Yaw, rotation.Roll,
        velocity.X, velocity.Y, velocity.Z
    )
end

--- Updates each visible overlay using fresh Pawn state so values remain live.
local function update_overlays()
    local players_by_index = {}
    for _, player in ipairs(local_players()) do
        players_by_index[player.index] = player
    end

    for _, overlay in ipairs(overlays) do
        local player = players_by_index[overlay.player_index]
        if player and is_valid(overlay.text) then
            overlay.text:SetText(FText(coordinate_text(player.index, player.pawn)))
        end
    end
end

--- Removes all overlay widgets from their local player screens.
local function hide_overlay()
    for _, overlay in ipairs(overlays) do
        if is_valid(overlay.text) then
            overlay.text:RemoveFromParent()
        end
    end

    overlays = {}
    overlay_enabled = false
    log("In-game coordinate overlay disabled.")
end

--- Builds one lightweight UMG overlay for each active split-screen player.
local function show_overlay()
    local text_block_class = StaticFindObject("Class /Script/UMG.TextBlock")
    local hud_layouts = FindAllOf("WBP_PlayerHUDLayout_Split_C")
    if not is_valid(text_block_class) or type(hud_layouts) ~= "table" then
        log("Overlay unavailable: active split-screen HUD layouts were not found.")
        return
    end

    local created = 0
    local players = local_players()
    for index, layout in ipairs(hud_layouts) do
        local player = player_for_layout(layout, players, (#hud_layouts - index) + 1)
        local success, text_or_error = pcall(function()
            local tree = unwrap(layout.WidgetTree)
            local overlay_content = unwrap(layout.OverlayContent)
            local text = StaticConstructObject(text_block_class, tree)
            overlay_content:AddChild(text)
            text:SetRenderScale({ X = 0.65, Y = 0.65 })
            text:SetText(FText(coordinate_text(player.index, player.pawn)))
            return text
        end)
        if success and is_valid(text_or_error) then
            table.insert(overlays, { text = text_or_error, player_index = player.index })
            created = created + 1
        else
            log(string.format("HUD attachment failed for P%d: %s", index, tostring(text_or_error)))
        end
    end

    overlay_enabled = created > 0
    if overlay_enabled then
        log(string.format("In-game coordinate overlay enabled for %d local player(s).", created))
    else
        log("Overlay unavailable: no widget was created; see the preceding diagnostic message.")
    end
end

--- Toggles the live UMG coordinate overlay without touching gameplay state.
local function toggle_overlay()
    if overlay_enabled then
        hide_overlay()
    else
        show_overlay()
    end
end

RegisterKeyBind(Key.F1, { ModifierKey.CONTROL }, toggle_overlay)

--- Polls lightweight read-only actor data while the overlay is visible.
LoopInGameThreadWithDelay(150, function()
    if overlay_enabled then
        update_overlays()
    end
end)

log("Loaded. Ctrl+F1 toggles the live four-line coordinate overlay.")
