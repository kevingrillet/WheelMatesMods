-- Resolve workshop helpers even when UE4SS loads this mod from an additional ModsFolderPaths entry.
local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
local mods_root = assert(source:match("^(.*)/[^/]+/[Ss]cripts/main%.lua$"), "Cannot resolve workshop mods directory")
package.path = mods_root .. "/shared/?/?.lua;" .. package.path

-- Loader diagnostics and recovery of our own UI/render changes after reload.
local ModName = "ModKit"

-- Keep startup diagnostics readable in the UE4SS console.
local function log(message)
    print(string.format("[%s] %s\n", ModName, message))
end

local Overlay = require("WMOverlay")
local RenderState = require("WMRenderState")
ExecuteInGameThread(function()
    Overlay.cleanup("Coordinates")
    Overlay.cleanup("Compass")
    Overlay.cleanup("TweaksP1")
    Overlay.cleanup("TweaksP2")
    local pending = RenderState.restore()
    if pending > 0 then
        log("Pending WallHack restorations: " .. pending)
    end
end)
log("Loaded. Recovers this workshop's overlays/render state after reload; saves are untouched.")
