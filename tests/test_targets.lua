package.path = "mods/shared/?/?.lua;" .. package.path
local Targets = require("WMTargets")
local Runtime = require("WMRuntime")
local tracker = Targets.new()
local a, b, c = gear("A"), gear("B"), gear("C")
a.location, b.location, c.location = { X = 100, Y = 0, Z = 0 }, { X = 1000, Y = 0, Z = 0 }, { X = 2000, Y = 0, Z = 0 }
pawns[2].location = { X = 2000, Y = 0, Z = 0 }
local p1, p2 = { index = 1, pawn = pawns[1] }, { index = 2, pawn = pawns[2] }
tracker:refresh()
assert(tracker:select(p1).entry.id == Runtime.identity(a))
assert(tracker:select(p2).entry.id == Runtime.identity(c), "Automatic target is relative to each player")
assert(tracker:next(p1).entry.id == Runtime.identity(b))
pawns[1].location = { X = 1900, Y = 0, Z = 0 }
assert(tracker:select(p1).entry.id == Runtime.identity(b), "Moving must not replace a manual target")
tracker:refresh()
assert(tracker:select(p1).entry.id == Runtime.identity(b), "Refresh keeps identity, not a list index")
b.valid = false
tracker:refresh()
assert(tracker:select(p1).entry.id == Runtime.identity(c), "Disappearance advances to the next stable entry")
assert(tracker:next(p1).entry.id == Runtime.identity(a), "Manual cycle wraps")
assert(tracker:select(p2).entry.id == Runtime.identity(c), "Cycling one player preserves the other")
tracker:auto(1)
assert(tracker:select(p1).entry.id == Runtime.identity(c))
tracker:reset()
assert(tracker:select(p1) == nil)

-- Narrative completion must follow the active save, including refresh after collection.
local save = object("VehicleSaveGame", "Active")
local collected = false
save.CollectedNarrativeItems = {
    ForEach = function(_, callback)
        if collected then
            callback({ TagName = FName("Narrative.Test") })
        end
    end,
}
local subsystem = object("VehicleSaveGameSubsystem", "Subsystem", instance)
subsystem.CurrentSaveGame = save
local narrative = object("BP_NarrativeItem_C", "N")
narrative.actor, narrative.NarrativeTagId = true, { TagName = FName("Narrative.Test") }
narrative.location = { X = 1900, Y = 0, Z = 0 }
tracker:refresh()
assert(tracker:select(p1).entry.id == Runtime.identity(narrative))
local sorted = tracker:rows(p1, true)
assert(sorted[1].entry.type == "Gear" and sorted[#sorted].entry.type == "Narrative")
assert(tracker:rows(p1, false)[1].entry.id == Runtime.identity(narrative))
collected = true
tracker:refresh()
assert(tracker:select(p1).entry.id == Runtime.identity(c), "Collected narrative target is removed")
subsystem.CurrentSaveGame = nil
tracker:refresh()
assert(not tracker.narrative_known)
a.valid, c.valid = false, false
tracker:refresh()
assert(tracker:next(p1) == nil, "Empty manual cycle is safe")
