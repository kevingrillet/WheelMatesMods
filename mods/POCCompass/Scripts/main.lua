-- Resolve workshop helpers even when UE4SS loads this mod from an additional ModsFolderPaths entry.
local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
local mods_root = assert(source:match("^(.*)/[^/]+/[Ss]cripts/main%.lua$"), "Cannot resolve workshop mods directory")
package.path = mods_root .. "/shared/?/?.lua;" .. package.path

local Runtime = require("WMRuntime")
local Navigation = require("WMNavigation")
local Overlay = require("WMOverlay")
local targets, target_world = {}, nil
local refresh_ticks = 0
local VerticalTolerance = 200 -- Unreal centimetres: +/- 2 m counts as the same height.

local function refresh_targets()
    targets = Runtime.gears()
    target_world = Runtime.world_id()
end

--- Formats the nearest loaded Gear as a player-relative direction and metric distance.
local function compass_text(player)
    local origin = player.pawn:K2_GetActorLocation()
    local rotation = player.pawn:K2_GetActorRotation()
    local nearest = Navigation.nearest(origin, targets)
    if nearest == nil then
        return string.format("COMPASS P%d\nNo loaded Gear target", player.index)
    end

    local relative = Navigation.relative_yaw(nearest, rotation.Yaw)
    local vertical = Navigation.vertical_label(nearest.dz, VerticalTolerance)
    return string.format(
        "COMPASS P%d\nGEAR  %s  %.0f m\n%s  Height delta %+.1f m",
        player.index,
        Navigation.direction_label(relative),
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
print("[POCCompass] Loaded. Ctrl+F3 toggles the Gear compass.\n")
