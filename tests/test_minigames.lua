package.path = "mods/shared/?/?.lua;" .. package.path
local Collectibles = require("WMCollectibles")
local Targets = require("WMTargets")
local save = object("VehicleSaveGame", "Active")
save.CollectedNarrativeItems = { ForEach = function() end }
local played = { ["Minigame.Map.Played"] = true }
save.LastMinigameResultById = {
    ForEach = function(_, callback)
        for id in pairs(played) do
            callback({ TagName = FName(id) })
        end
    end,
}
local subsystem = object("VehicleSaveGameSubsystem", "Subsystem", instance)
subsystem.CurrentSaveGame = save
local function minigame(name)
    local owner = object("Actor", name)
    local component = object("MinigameCollectableComponent", name .. "Component", owner)
    component.MinigameId = { TagName = FName("Minigame.Map." .. name) }
    component.EntryPointTagGuest = { TagName = FName("Minigame.Map." .. name .. ".Entry.Guest") }
    function component:GetOwner()
        return owner
    end
    return owner, component
end
minigame("Played")
local missing, component = minigame("New")
local tracker = Targets.new()
tracker:refresh()
assert(#tracker.minigames == 2, "Played and unrecorded loaded mini-games are displayed")
assert(#tracker.entries == 1 and tracker.entries[1].type == "Mini-game")
assert(tracker.entries[1].progress == "No result")
assert(tracker.entries[1].actor == nil, "The snapshot must not retain any native actor wrapper")
played["Minigame.Map.New"] = true
tracker:refresh()
assert(#tracker.entries == 0, "A saved result removes the mini-game from missing targets")
played["Minigame.Map.New"] = nil
component.MinigameId = nil
tracker:refresh()
assert(#tracker.entries == 0, "A missing identifier is Unknown, not unplayed")
component.MinigameId = { TagName = FName("Minigame.Map.New") }
save.LastMinigameResultById = nil
tracker:refresh()
assert(#tracker.entries == 0, "Unavailable result map is Unknown")
for _, game in ipairs(tracker.minigames) do
    assert(game.progress == "Unknown")
end
local scan = Collectibles.scan()
assert(scan.minigames[1].status == "Loaded", "POC reporting remains a loaded-object report")
