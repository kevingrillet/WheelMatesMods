local target = gear("Target")
target.bHidden = true
target.bActorIsBeingDestroyed = true
function target:GetWorld()
    error("A valid loaded Gear should not require a world lookup")
end
load_mod("TP")
pawns[2].location = { X = 10, Y = 20, Z = 30 }
keys.F5()
pawns[2].move_result = false
logs = {}
keys.F5()
assert(contains("Teleport failed"))
assert(not contains("teleported to"))
pawns[2].move_result = true
keys.F7()
assert(pawns[2].location.X == 10, "A failed teleport must preserve the original return point")
local moves = pawns[2].moves
keys.F7()
assert(pawns[2].moves == moves, "A successful return consumes its point")
keys.F5()
load_map()
moves = pawns[2].moves
keys.F7()
assert(pawns[2].moves == moves, "Travel invalidates return even before polling")
keys.F5()
world = object("World", "OtherMap")
keys.F7()
assert(pawns[2].location.X ~= 10, "Never return into a different world")
-- Restore matching world and exercise the second local player.
world = pawns[1].world
pawns[1].location = { X = 77, Y = 0, Z = 0 }
keys.F6()
keys.F9()
assert(pawns[1].location.X == 77)
