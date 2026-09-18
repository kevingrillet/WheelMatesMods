local target = gear("Target")
target.bHidden = true
target.bActorIsBeingDestroyed = true
function target:GetWorld()
    error("A valid loaded Gear should not require a world lookup")
end
load_mod("POCTP")
pawns[1].location = { X = 10, Y = 20, Z = 30 }
keys["CTRL+F5"]()
assert(pawns[2].moves == nil, "Player 1 chord must not move Player 2")
pawns[1].move_result = false
logs = {}
keys["CTRL+F5"]()
assert(contains("Teleport failed"))
assert(not contains("teleported to"))
pawns[1].move_result = true
keys["CTRL+F6"]()
assert(pawns[1].location.X == 10, "A failed teleport must preserve the original return point")
local moves = pawns[1].moves
keys["CTRL+F6"]()
assert(pawns[1].moves == moves, "A successful return consumes its point")
keys["CTRL+F5"]()
load_map()
moves = pawns[1].moves
keys["CTRL+F6"]()
assert(pawns[1].moves == moves, "Travel invalidates return even before polling")
keys["CTRL+F5"]()
world = object("World", "OtherMap")
keys["CTRL+F6"]()
assert(pawns[1].location.X ~= 10, "Never return into a different world")
-- Restore matching world and exercise the second local player.
world = pawns[2].world
pawns[2].location = { X = 77, Y = 0, Z = 0 }
local first_player_moves = pawns[1].moves
keys["CTRL+SHIFT+F5"]()
keys["CTRL+SHIFT+F6"]()
assert(pawns[2].location.X == 77)

assert(pawns[1].moves == first_player_moves, "Shift chord must only move Player 2")
assert(keys["CTRL+F7"] == nil and keys["CTRL+F9"] == nil, "Old separate-player keys are retired")
