gear("Target")
load_mod("Tweaks")
tick(200, 4)
keys["CTRL+SHIFT+F1"]()
keys["CTRL+SHIFT+F2"]()
tick(200)
local root = layouts[2].OverlayContent.children[1]
local original = root.children[1]
-- Simulate the old stale Kitchen block remaining in the same HUD tree.
local stale = object("TextBlock", "WheelMatesMods_TweaksP2_2_OLD", layouts[2].WidgetTree)
stale:SetText(FText("Kitchen stale block"))
root:AddChild(stale)
local world_reads = 0
local runtime = require("WMRuntime")
local real_world_id = runtime.world_id
runtime.world_id = function()
    world_reads = world_reads + 1
    return real_world_id()
end
pre_load_map()
local before = world_reads
keys["CTRL+SHIFT+F5"]()
tick(200, 10)
assert(world_reads == before, "No native world/UI access during LoadMap")
assert(pawns[2].moves == nil, "Travel discards queued teleports")
load_map()
tick(200, 4)
assert(#root.children == 1 and root.children[1] == original, "Surviving widget is reused, stale duplicate detached")
assert(original:GetText():ToString():find("Updating loaded targets", 1, true))
assert(not original:GetText():ToString():find("MISSING", 1, true), "Do not display transient candidates")
tick(200, 12)
assert(original:GetText():ToString():find("MISSING", 1, true))
-- Repeated hide/show must reuse the named object, never reconstruct it.
keys["CTRL+SHIFT+F1"]()
keys["CTRL+SHIFT+F2"]()
tick(200)
assert(#root.children == 0)
keys["CTRL+SHIFT+F1"]()
keys["CTRL+SHIFT+F2"]()
tick(200)
assert(#root.children == 1 and root.children[1] == original)
keys["CTRL+SHIFT+F5"]()
tick(200)
assert(original:GetText():ToString():find("Updating loaded targets", 1, true), "Teleport marks catalogue as pending")
tick(200, 6)
assert(original:GetText():ToString():find("MISSING", 1, true))
