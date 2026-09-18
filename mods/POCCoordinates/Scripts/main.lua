-- Resolve workshop helpers even when UE4SS loads this mod from an additional ModsFolderPaths entry.
local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
local mods_root = assert(source:match("^(.*)/[^/]+/[Ss]cripts/main%.lua$"), "Cannot resolve workshop mods directory")
package.path = mods_root .. "/shared/?/?.lua;" .. package.path

local Overlay = require("WMOverlay")

local Coordinates = require("WMCoordinates")

local overlay = Overlay.new("Coordinates", function(player)
    return Coordinates.text(player.index, player.pawn)
end)
RegisterKeyBind(Key.F1, { ModifierKey.CONTROL }, function()
    ExecuteInGameThread(function()
        overlay:toggle()
    end)
end)
LoopInGameThreadWithDelay(150, function()
    overlay:update()
end)
print("[POCCoordinates] Loaded. Ctrl+F1 toggles coordinates.\n")
