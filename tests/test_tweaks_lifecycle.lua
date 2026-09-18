local save = object("VehicleSaveGame", "Active")
save.CollectedNarrativeItems = { ForEach = function() end }
local subsystem = object("VehicleSaveGameSubsystem", "Subsystem", instance)
subsystem.CurrentSaveGame = save
local target = gear("Target")
load_mod("Tweaks")
tick(200, 10)
assert(queries.Actor == nil and queries.BP_Collectable_Gear_C == nil, "No catalogue scans with everything hidden")
require("UEHelpers").GetWorld = function()
    error("Avoid the UEHelpers controller scan")
end
keys["CTRL+F1"]()
tick(200)
assert(queries.Actor == nil and queries.BP_Collectable_Gear_C == nil, "Coordinates alone never scan collectibles")
keys["CTRL+F2"]()
tick(200)
assert(queries.Actor == nil and queries.BP_NarrativeItem_C == 1, "Use typed narrative scans")
local scans = queries.BP_Collectable_Gear_C
local old_get_location = target.K2_GetActorLocation
function target:K2_GetActorLocation()
    error("HUD must use scalar positions between scans")
end
tick(200, 5)
assert(queries.BP_Collectable_Gear_C == scans)
target.K2_GetActorLocation = old_get_location
keys["CTRL+F8"]()
tick(200)
assert(queries.Actor == 1, "Full discovery is available explicitly on F8")
-- Dead wrappers throw even on IsValid: the mod must drop them instead of inspecting them.
for travel = 1, 2 do
    local old = layouts[1]
    local text = old.OverlayContent.children[1].children[1]
    for _, value in ipairs({ old, text, target }) do
        value.valid = false
        value.IsValid = function()
            error("Dereferenced a destroyed world's wrapper")
        end
    end
    world = object("World", "Map" .. travel)
    controllers[1].world, controllers[2].world = world, world
    pawns[1].world, pawns[2].world = world, world
    make_layout(1)
    make_layout(2)
    target = gear("Target" .. travel)
    load_map()
    tick(200, 22)
    local root = layouts[1].OverlayContent.children[1]
    assert(root and #root.children == 1, "HUD recovers after each of two map changes")
    assert(root.children[1]:GetText():ToString():find("MISSING", 1, true))
end
