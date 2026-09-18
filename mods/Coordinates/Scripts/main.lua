-- Resolve workshop helpers even when UE4SS loads this mod from an additional ModsFolderPaths entry.
local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
local mods_root = assert(source:match("^(.*)/[^/]+/[Ss]cripts/main%.lua$"), "Cannot resolve workshop mods directory")
package.path = mods_root .. "/shared/?/?.lua;" .. package.path

local Overlay = require("WMOverlay")

local function coordinate_text(player_index, pawn)
    local position = pawn:K2_GetActorLocation()
    local rotation = pawn:K2_GetActorRotation()
    local velocity = pawn:GetVelocity()

    return string.format(
        "COORDINATES PLAYER %d\nPosition  X / Y / Z     %.0f / %.0f / %.0f\nRotation  Pitch / Yaw / Roll  %.1f / %.1f / %.1f\nVelocity  X / Y / Z     %.0f / %.0f / %.0f",
        player_index,
        position.X,
        position.Y,
        position.Z,
        rotation.Pitch,
        rotation.Yaw,
        rotation.Roll,
        velocity.X,
        velocity.Y,
        velocity.Z
    )
end

local overlay = Overlay.new("Coordinates", function(player)
    return coordinate_text(player.index, player.pawn)
end)
RegisterKeyBind(Key.F1, { ModifierKey.CONTROL }, function()
    ExecuteInGameThread(function()
        overlay:toggle()
    end)
end)
LoopInGameThreadWithDelay(150, function()
    overlay:update()
end)
print("[Coordinates] Loaded. Ctrl+F1 toggles coordinates.\n")
