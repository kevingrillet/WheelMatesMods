-- Resolve workshop helpers even when UE4SS loads this mod from an additional ModsFolderPaths entry.
local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
local mods_root = assert(source:match("^(.*)/[^/]+/[Ss]cripts/main%.lua$"), "Cannot resolve workshop mods directory")
package.path = mods_root .. "/shared/?/?.lua;" .. package.path

local Runtime = require("WMRuntime")
local Overlay = require("WMOverlay")
local targets, target_world = {}, nil
local refresh_ticks = 0
local VerticalTolerance = 200 -- Unreal centimetres: +/- 2 m counts as the same height.

local function refresh_targets()
    targets = Runtime.gears()
    target_world = Runtime.world_id()
end

local function direction_label(relative_yaw)
    if relative_yaw >= -22.5 and relative_yaw < 22.5 then
        return "AHEAD"
    end
    if relative_yaw >= 22.5 and relative_yaw < 67.5 then
        return "AHEAD-RIGHT"
    end
    if relative_yaw >= 67.5 and relative_yaw < 112.5 then
        return "RIGHT"
    end
    if relative_yaw >= 112.5 and relative_yaw < 157.5 then
        return "BEHIND-RIGHT"
    end
    if relative_yaw >= -67.5 and relative_yaw < -22.5 then
        return "AHEAD-LEFT"
    end
    if relative_yaw >= -112.5 and relative_yaw < -67.5 then
        return "LEFT"
    end
    if relative_yaw >= -157.5 and relative_yaw < -112.5 then
        return "BEHIND-LEFT"
    end
    return "BEHIND"
end

--- Formats the nearest loaded Gear as a player-relative direction and metric distance.
local function compass_text(player)
    local origin = player.pawn:K2_GetActorLocation()
    local rotation = player.pawn:K2_GetActorRotation()
    local nearest, nearest_distance_squared = nil, nil
    for _, actor in ipairs(targets) do
        if Runtime.valid(actor) then
            local location = actor:K2_GetActorLocation()
            local dx, dy, dz = location.X - origin.X, location.Y - origin.Y, location.Z - origin.Z
            local distance_squared = dx * dx + dy * dy + dz * dz
            if nearest_distance_squared == nil or distance_squared < nearest_distance_squared then
                nearest = { dx = dx, dy = dy, dz = dz, distance_squared = distance_squared }
                nearest_distance_squared = distance_squared
            end
        end
    end
    if nearest == nil then
        return string.format("COMPASS P%d\nNo loaded Gear target", player.index)
    end

    local bearing = math.deg(math.atan(nearest.dy, nearest.dx))
    local relative = (bearing - rotation.Yaw + 180) % 360 - 180
    local vertical = "LEVEL"
    if nearest.dz > VerticalTolerance then
        vertical = "UP"
    elseif nearest.dz < -VerticalTolerance then
        vertical = "DOWN"
    end
    return string.format(
        "COMPASS P%d\nGEAR  %s  %.0f m\n%s  Height delta %+.1f m",
        player.index,
        direction_label(relative),
        math.sqrt(nearest.distance_squared) / 100,
        vertical,
        nearest.dz / 100
    )
end

local overlay = Overlay.new("Compass", compass_text)
RegisterKeyBind(Key.F3, { ModifierKey.CONTROL }, function()
    ExecuteInGameThread(function()
        if not overlay.enabled then
            refresh_targets()
        end
        overlay:toggle()
    end)
end)
LoopInGameThreadWithDelay(200, function()
    if not overlay.enabled then
        return
    end
    refresh_ticks = refresh_ticks + 1
    if refresh_ticks % 5 == 0 or target_world ~= Runtime.world_id() then
        refresh_targets()
    end
    overlay:update()
end)
print("[Compass] Loaded. Ctrl+F3 toggles the Gear compass.\n")
