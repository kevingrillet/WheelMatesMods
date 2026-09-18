-- Resolve workshop helpers even when UE4SS loads this mod from an additional ModsFolderPaths entry.
local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
local mods_root = assert(source:match("^(.*)/[^/]+/[Ss]cripts/main%.lua$"), "Cannot resolve workshop mods directory")
package.path = mods_root .. "/shared/?/?.lua;" .. package.path

local Runtime = require("WMRuntime")

local ModName = "POCTP"
local GearLocation = { X = 24778.721, Y = -58507.618, Z = 11370.294 }
local DestinationName = "RiftX Gear approach point"
local Destination = { X = 25378.721, Y = -58507.618, Z = 11470.294 }
-- Write one self-contained line to the UE4SS console.
local function log(message)
    print(string.format("[%s] %s\n", ModName, message))
end

local Teleport = require("WMTeleport")
local session = Teleport.new(log)
RegisterLoadMapPostHook(function()
    session:reset()
end)
LoopInGameThreadWithDelay(500, function()
    session:refresh_world()
end)

-- Refuse the fixed destination unless its matching Gear is loaded in this session.
local function is_destination_loaded()
    local gears = Runtime.gears()
    if gears == nil then
        return false
    end

    local found = false
    local function inspect_gear(gear)
        if found or not Runtime.valid(gear) then
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

-- Move a selected local player to the CheckList destination under test.
local function teleport_to_gear(player_number)
    if session:refresh_world() == nil then
        return
    end
    if not is_destination_loaded() then
        log("RiftX Gear is not loaded. Open the matching area before teleporting.")
        return
    end
    session:move(player_number, Destination, DestinationName)
end

-- Player numbers match Runtime.players() and the HUD labels (LocalPlayers indices).
for player_number = 1, 2 do
    local modifiers = player_number == 1 and { ModifierKey.CONTROL } or { ModifierKey.CONTROL, ModifierKey.SHIFT }
    RegisterKeyBind(Key.F5, modifiers, function()
        ExecuteInGameThread(function()
            teleport_to_gear(player_number)
        end)
    end)
    RegisterKeyBind(Key.F6, modifiers, function()
        ExecuteInGameThread(function()
            session:return_player(player_number)
        end)
    end)
end

log("Loaded. Ctrl+F5/F6: Player 1 TP/return. Ctrl+Shift+F5/F6: Player 2 TP/return.")
