-- Resolve workshop helpers even when UE4SS loads this mod from an additional ModsFolderPaths entry.
local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
local mods_root = assert(source:match("^(.*)/[^/]+/[Ss]cripts/main%.lua$"), "Cannot resolve workshop mods directory")
package.path = mods_root .. "/shared/?/?.lua;" .. package.path

local Runtime = require("WMRuntime")

local ModName = "TP"
local GearLocation = { X = 24778.721, Y = -58507.618, Z = 11370.294 }
local DestinationName = "RiftX Gear approach point"
local Destination = { X = 25378.721, Y = -58507.618, Z = 11470.294 }
local last_locations = {}
local current_world = nil

local function refresh_world()
    local world = Runtime.world_id()
    if world ~= current_world then
        last_locations = {}
        current_world = world
    end
    return world
end

RegisterLoadMapPostHook(function()
    last_locations = {}
    current_world = nil
end)
LoopInGameThreadWithDelay(500, function()
    refresh_world()
end)

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
    for _, player in ipairs(Runtime.players()) do
        if player.index == player_number then
            return player.pawn
        end
    end
    return nil
end

-- Refuse the fixed destination unless its matching Gear is loaded in this session.
local function is_destination_loaded()
    local gears = Runtime.gears()
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
local function move_player(player_number, target, label, is_return)
    local world = refresh_world()
    if world == nil then
        return
    end
    local pawn = local_pawn(player_number)
    if not is_valid(pawn) then
        log(string.format("Player %d is not available locally.", player_number))
        return
    end

    local current = pawn:K2_GetActorLocation()
    local previous = { X = current.X, Y = current.Y, Z = current.Z }

    -- Movement is deliberately executed on the game thread.  Sweep is disabled
    -- because the destination is placed above ground; Teleport is enabled to
    -- avoid vehicle interpolation through the level.
    local ok, result_or_error = pcall(function()
        return pawn:K2_SetActorLocation(target, false, {}, true)
    end)
    if ok and result_or_error == true then
        if is_return then
            last_locations[player_number] = nil
        else
            last_locations[player_number] = { world = world, position = previous }
        end
        log(
            string.format(
                "Player %d teleported to %s at {X=%.3f, Y=%.3f, Z=%.3f}.",
                player_number,
                label,
                target.X,
                target.Y,
                target.Z
            )
        )
    else
        log(string.format("Teleport failed for Player %d: %s", player_number, tostring(result_or_error)))
    end
end

-- Move a selected local player to the CheckList destination under test.
local function teleport_to_gear(player_number)
    if refresh_world() == nil then
        return
    end
    if not is_destination_loaded() then
        log("RiftX Gear is not loaded. Open the matching area before teleporting.")
        return
    end
    move_player(player_number, Destination, DestinationName)
end

-- Return a player to the position captured immediately before the last teleport.
local function return_player(player_number)
    local world = refresh_world()
    local last_location = last_locations[player_number]
    if last_location == nil then
        log(string.format("No return location is saved for Player %d.", player_number))
        return
    end
    if world == nil or last_location.world ~= world then
        last_locations[player_number] = nil
        log("Return cancelled: the original world is no longer active.")
        return
    end
    move_player(player_number, last_location.position, "saved return location", true)
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

RegisterKeyBind(Key.F9, { ModifierKey.CONTROL }, function()
    ExecuteInGameThread(function()
        return_player(1)
    end)
end)

log("Loaded. Ctrl+F5: left screen to RiftX Gear. Ctrl+F6: right screen. Ctrl+F7: return left. Ctrl+F9: return right.")
