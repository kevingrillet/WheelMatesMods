local UEHelpers = require("UEHelpers")

local ModName = "TP"
local GearLocation = { X = 24778.721, Y = -58507.618, Z = 11370.294 }
local DestinationName = "RiftX Gear approach point"
local Destination = { X = 25378.721, Y = -58507.618, Z = 11470.294 }
local last_locations = {}

-- Write one self-contained line to the UE4SS console.
local function log(message)
    print(string.format("[%s] %s\n", ModName, message))
end

-- Verify a reflected Unreal object before accessing it.
local function is_valid(object)
    return object ~= nil and object.IsValid ~= nil and object:IsValid()
end

-- Resolve one split-screen local player's currently possessed vehicle.
local function local_pawn(player_number)
    local game_instance = UEHelpers.GetGameInstance()
    if not is_valid(game_instance) then
        return nil
    end

    local players = game_instance.LocalPlayers
    if players == nil then
        return nil
    end

    local result = nil
    players:ForEach(function(index, player_param)
        if result ~= nil or index ~= player_number then
            return
        end

        local local_player = player_param:get()
        local controller = local_player and local_player.PlayerController
        local pawn = controller and controller.Pawn
        if is_valid(pawn) then
            result = pawn
        end
    end)
    return result
end

-- Refuse the fixed destination unless its matching Gear is loaded in this session.
local function is_destination_loaded()
    local gears = FindAllOf("BP_Collectable_Gear_C")
    if gears == nil then
        return false
    end

    local found = false
    local function inspect_gear(gear)
        if found or not is_valid(gear) then
            return
        end

        local ok, location = pcall(function()
            return gear:K2_GetActorLocation()
        end)
        if not ok or location == nil then
            return
        end

        local delta_x = location.X - GearLocation.X
        local delta_y = location.Y - GearLocation.Y
        local delta_z = location.Z - GearLocation.Z
        if (delta_x * delta_x) + (delta_y * delta_y) + (delta_z * delta_z) < 1000000 then
            found = true
        end
    end
    if type(gears) == "table" then
        for _, gear in pairs(gears) do
            inspect_gear(gear)
        end
    elseif gears.ForEach ~= nil then
        gears:ForEach(function(_, gear_param)
            inspect_gear(gear_param:get())
        end)
    end
    return found
end

-- Save the current position and relocate one local vehicle on the game thread.
local function move_player(player_number, target, label)
    local pawn = local_pawn(player_number)
    if not is_valid(pawn) then
        log(string.format("Player %d is not available locally.", player_number))
        return
    end

    local current = pawn:K2_GetActorLocation()
    last_locations[player_number] = { X = current.X, Y = current.Y, Z = current.Z }

    -- Movement is deliberately executed on the game thread.  Sweep is disabled
    -- because the destination is placed above ground; Teleport is enabled to
    -- avoid vehicle interpolation through the level.
    local ok, result_or_error = pcall(function()
        return pawn:K2_SetActorLocation(target, false, {}, true)
    end)
    if ok then
        log(string.format(
            "Player %d teleported to %s at {X=%.3f, Y=%.3f, Z=%.3f}.",
            player_number,
            label,
            target.X,
            target.Y,
            target.Z
        ))
    else
        log(string.format("Teleport failed for Player %d: %s", player_number, tostring(result_or_error)))
    end
end

-- Move a selected local player to the CheckList destination under test.
local function teleport_to_gear(player_number)
    if not is_destination_loaded() then
        log("RiftX Gear is not loaded. Open the matching area before teleporting.")
        return
    end
    move_player(player_number, Destination, DestinationName)
end

-- Return a player to the position captured immediately before the last teleport.
local function return_player(player_number)
    local last_location = last_locations[player_number]
    if last_location == nil then
        log(string.format("No return location is saved for Player %d.", player_number))
        return
    end
    move_player(player_number, last_location, "saved return location")
end

RegisterKeyBind(Key.F5, { ModifierKey.CONTROL }, function()
    ExecuteInGameThread(function()
        teleport_to_gear(2)
    end)
end)

RegisterKeyBind(Key.F6, { ModifierKey.CONTROL }, function()
    ExecuteInGameThread(function()
        teleport_to_gear(1)
    end)
end)

RegisterKeyBind(Key.F7, { ModifierKey.CONTROL }, function()
    ExecuteInGameThread(function()
        return_player(2)
    end)
end)

log("Loaded. Ctrl+F5: left screen to RiftX Gear. Ctrl+F6: right screen. Ctrl+F7: return left screen.")
