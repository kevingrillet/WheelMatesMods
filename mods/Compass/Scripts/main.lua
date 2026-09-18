local UEHelpers = require("UEHelpers")

local ModName = "Compass"
local compass_enabled = false
local overlays = {}

--- Writes a consistently terminated Compass message to the UE4SS console.
local function log(message)
    print(string.format("[%s] %s\n", ModName, message))
end

--- Returns true only for an Unreal object that is safe to inspect.
local function is_valid(object)
    return object ~= nil and object:IsValid()
end

--- Safely unwraps a UE4SS remote property without assuming every value is wrapped.
local function unwrap(value)
    local ok, unwrapped = pcall(function() return value:get() end)
    return ok and unwrapped or value
end

--- Enumerates ready local players through UE4SS' supported LocalPlayers iterator.
local function local_players()
    local players = {}
    local game_instance = UEHelpers.GetGameInstance()
    local array = game_instance and game_instance.LocalPlayers
    if array == nil then return players end
    array:ForEach(function(index, player_param)
        local local_player = player_param:get()
        local controller = local_player and local_player.PlayerController
        local pawn = controller and controller.Pawn
        if is_valid(controller) and is_valid(pawn) then
            table.insert(players, { index = index, controller = controller, pawn = pawn })
        end
    end)
    return players
end

--- Finds the LocalPlayers entry that owns a given active HUD layout.
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

--- Finds uncollected Gear actors that are currently loaded in the active level.
local function loaded_gear_targets()
    local targets = {}
    local actors = FindAllOf("Actor")
    if type(actors) ~= "table" then return targets end
    for _, actor in pairs(actors) do
        if is_valid(actor) and string.find(string.lower(actor:GetFullName()), "bp_collectable_gear", 1, true) then
            table.insert(targets, { label = "GEAR", actor = actor })
        end
    end
    return targets
end

--- Converts a target bearing relative to a vehicle's yaw into a short direction label.
local function direction_label(relative_yaw)
    if relative_yaw >= -22.5 and relative_yaw < 22.5 then return "AHEAD" end
    if relative_yaw >= 22.5 and relative_yaw < 67.5 then return "AHEAD-RIGHT" end
    if relative_yaw >= 67.5 and relative_yaw < 112.5 then return "RIGHT" end
    if relative_yaw >= 112.5 and relative_yaw < 157.5 then return "BEHIND-RIGHT" end
    if relative_yaw >= -67.5 and relative_yaw < -22.5 then return "AHEAD-LEFT" end
    if relative_yaw >= -112.5 and relative_yaw < -67.5 then return "LEFT" end
    if relative_yaw >= -157.5 and relative_yaw < -112.5 then return "BEHIND-LEFT" end
    return "BEHIND"
end

--- Formats the nearest loaded Gear as a player-relative direction and metric distance.
local function compass_text(player)
    local origin = player.pawn:K2_GetActorLocation()
    local rotation = player.pawn:K2_GetActorRotation()
    local nearest, nearest_distance_squared = nil, nil
    for _, target in ipairs(loaded_gear_targets()) do
        local location = target.actor:K2_GetActorLocation()
        local dx, dy, dz = location.X - origin.X, location.Y - origin.Y, location.Z - origin.Z
        local distance_squared = dx * dx + dy * dy + dz * dz
        if nearest_distance_squared == nil or distance_squared < nearest_distance_squared then
            nearest = { target = target, dx = dx, dy = dy, distance_squared = distance_squared }
            nearest_distance_squared = distance_squared
        end
    end
    if nearest == nil then return string.format("COMPASS P%d\nNo loaded Gear target", player.index) end

    local bearing = math.deg(math.atan(nearest.dy, nearest.dx))
    local relative = (bearing - rotation.Yaw + 180) % 360 - 180
    return string.format("COMPASS P%d\nGEAR  %s  %.0f m", player.index, direction_label(relative), math.sqrt(nearest.distance_squared) / 100)
end

--- Refreshes each visible local-player compass overlay.
local function update_overlays()
    local current = {}
    for _, player in ipairs(local_players()) do current[player.index] = player end
    for _, overlay in ipairs(overlays) do
        local player = current[overlay.player_index]
        if player and is_valid(overlay.text) then
            overlay.text:SetText(FText(compass_text(player)))
            pcall(function() overlay.text:SynchronizeProperties() end)
        end
    end
end

--- Removes all Compass widgets from the local players' screens.
local function hide_compass()
    for _, overlay in ipairs(overlays) do if is_valid(overlay.text) then overlay.text:RemoveFromParent() end end
    overlays = {}
    compass_enabled = false
    log("Compass disabled.")
end

--- Creates one compact UMG compass widget for each active local player.
local function show_compass()
    local text_class = StaticFindObject("Class /Script/UMG.TextBlock")
    local hud_layouts = FindAllOf("WBP_PlayerHUDLayout_Split_C")
    if not is_valid(text_class) or type(hud_layouts) ~= "table" then
        log("Compass unavailable: active split-screen HUD layouts were not found.")
        return
    end
    local created = 0
    local players = local_players()
    for index, layout in ipairs(hud_layouts) do
        local player = player_for_layout(layout, players, (#hud_layouts - index) + 1)
        local ok, text_or_error = pcall(function()
            local tree = unwrap(layout.WidgetTree)
            local overlay_content = unwrap(layout.OverlayContent)
            local text = StaticConstructObject(text_class, tree)
            overlay_content:AddChild(text)
            text:SetRenderScale({ X = 0.65, Y = 0.65 })
            text:SetRenderTranslation({ X = 0, Y = 105 })
            text:SetText(FText(compass_text(player)))
            pcall(function() text:SynchronizeProperties() end)
            return text
        end)
        if ok and is_valid(text_or_error) then
            table.insert(overlays, { text = text_or_error, player_index = player.index })
            created = created + 1
        else
            log(string.format("Compass HUD attachment failed for P%d: %s", index, tostring(text_or_error)))
        end
    end
    compass_enabled = created > 0
    log(string.format("Compass enabled for %d local player(s).", created))
end

--- Toggles the read-only Compass prototype.
local function toggle_compass()
    if compass_enabled then hide_compass() else show_compass() end
end

RegisterKeyBind(Key.F3, { ModifierKey.CONTROL }, toggle_compass)
LoopInGameThreadWithDelay(200, function() if compass_enabled then update_overlays() end end)
log("Loaded. Ctrl+F3 toggles the Gear Compass prototype.")
