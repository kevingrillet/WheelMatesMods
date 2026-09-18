local target = gear("Target")
-- A loaded target must not be discarded using unvalidated render/world metadata.
target.bHidden = true
target.bActorIsBeingDestroyed = true
function target:GetWorld()
    error("Gear world lookup is not part of the loaded-target contract")
end
load_mod("POCCompass")
keys["CTRL+F3"]()
assert(layouts[1].OverlayContent.children[1].children[1]:GetText():ToString():find("GEAR  ", 1, true))
assert(queries.BP_Collectable_Gear_C == 1, "One scan for both players")
tick(200, 4)
assert(queries.BP_Collectable_Gear_C == 1)
tick(200)
assert(queries.BP_Collectable_Gear_C == 2, "Refresh only once per second")
assert(queries.Actor == nil, "No global actor scan")
local function displayed(index)
    return layouts[index].OverlayContent.children[1].children[1]:GetText():ToString()
end
target.location = { X = 300, Y = 0, Z = 400 }
pawns[2].location = { X = 0, Y = 0, Z = 800 }
tick(200)
assert(displayed(1):find("GEAR  AHEAD  5 m", 1, true), "Distance remains three-dimensional")
assert(displayed(1):find("UP  Height delta +4.0 m", 1, true))
assert(displayed(2):find("DOWN  Height delta -4.0 m", 1, true), "Height is relative to each player")
target.location.Z = 200
tick(200)
assert(displayed(1):find("LEVEL  Height delta +2.0 m", 1, true))
target.location.Z = -200
tick(200)
assert(displayed(1):find("LEVEL  Height delta -2.0 m", 1, true))
target.location.Z = 0
tick(200)
assert(displayed(1):find("LEVEL  Height delta +0.0 m", 1, true))
target.valid = false
tick(200)
assert(layouts[1].OverlayContent.children[1].children[1]:GetText():ToString():find("No loaded Gear", 1, true))
