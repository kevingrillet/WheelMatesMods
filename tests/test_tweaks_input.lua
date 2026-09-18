gear("Target")
load_mod("Tweaks")
tick(200, 4)
-- Once startup is finished, no key may schedule a temporary UObject work callback.
ExecuteInGameThread = function()
    error("Input must use the persistent update loop")
end
local scans = queries.BP_Collectable_Gear_C
keys["CTRL+F1"]()
keys["CTRL+F2"]()
keys["CTRL+F3"]()
assert(layouts[1].OverlayContent.children[1] == nil, "Key callbacks must not touch the HUD")
assert(queries.BP_Collectable_Gear_C == scans, "Key callbacks must not scan actors")
tick(200)
local function displayed()
    return layouts[1].OverlayContent.children[1].children[1]:GetText():ToString()
end
assert(displayed():find("XYZ", 1, true) and displayed():find("MISSING", 1, true))
pawns[1].location = { X = 700, Y = -100, Z = 30 }
tick(200, 20)
keys["CTRL+F1"]()
assert(displayed():find("XYZ", 1, true), "Input is deferred until the next update")
tick(200)
assert(not displayed():find("XYZ", 1, true), "Reported F1/F2/F3, drive, F1 sequence hides coordinates")
assert(displayed():find("MISSING", 1, true) and displayed():find("AUTO", 1, true))
-- A map callback must not invoke any HUD work or replay a pending old-map teleport.
keys["CTRL+F5"]()
local old_text = displayed()
load_map()
assert(displayed() == old_text, "Map hook only invalidates state; UI cleanup waits for the loop")
tick(200)
assert(pawns[1].moves == nil, "Discard old-map commands")
