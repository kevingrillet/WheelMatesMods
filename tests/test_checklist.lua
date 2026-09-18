local save = object("VehicleSaveGame", "Active")
save.CollectedNarrativeItems = {
    ForEach = function(_, callback)
        callback({ TagName = FName("Narrative.Test.Collected") })
    end,
}
local subsystem = object("VehicleSaveGameSubsystem", "SaveSubsystem", instance)
subsystem.CurrentSaveGame = save
local stale = object("VehicleSaveGame", "Stale")
stale.CollectedNarrativeItems = {
    ForEach = function()
        error("Must never read a stale save")
    end,
}
local item = object("NarrativeActor", "Item")
item.world, item.actor = world, true
item.NarrativeTagId = { TagName = FName("Narrative.Test.Missing") }
-- Loaded objects may not report the world identity selected by UEHelpers.
-- Their metadata must not silently empty the checklist.
local reported_world = object("World", "ActorReportedWorld")
item.world = reported_world
local collected_item = object("NarrativeActor", "CollectedItem")
collected_item.world, collected_item.actor = reported_world, true
collected_item.NarrativeTagId = { TagName = FName("Narrative.Test.Collected") }
local minigame_owner = object("Actor", "MinigameOwner")
minigame_owner.world = reported_world
local component = object("MinigameCollectableComponent", "Minigame", minigame_owner)
component.EntryPointTagGuest = { TagName = FName("Minigame.RiftX.CoinRush.Entry.Guest") }
function component:GetOwner()
    return minigame_owner
end
load_mod("CheckList")
keys.F2()
assert(contains("Narrative.Test.Missing"))
assert(contains("RiftX.CoinRush"), "Loaded mini-games must remain visible")
assert(contains("2 loaded"), "Count both collected and missing loaded narrative actors")
assert(not contains("Narrative.Test.Collected"), "Collected narrative items must remain excluded")
assert(queries.VehicleSaveGame == nil)
subsystem.CurrentSaveGame = nil
logs = {}
keys.F2()
assert(contains("Unknown"))
assert(contains("RiftX.CoinRush"), "Mini-games must remain visible when the save is unavailable")
assert(not contains("Narrative.Test.Missing"), "Unavailable save must not invent missing items")
