-- Exercise the reusable APIs independently of POC routes and keybinds.
package.path = "mods/shared/?/?.lua;" .. package.path
local Navigation = require("WMNavigation")
local far = gear("Far")
far.location = { X = 100, Y = 0, Z = 1000 }
local near = object("NarrativeActor", "Near")
near.location = { X = 300, Y = 0, Z = 0 }
local origin = { X = 0, Y = 0, Z = 0 }
assert(Navigation.nearest(origin, { far, near }).actor == near, "Nearest supports mixed actor types and 3D distance")
near.valid = false
assert(Navigation.nearest(origin, { far, near }).actor == far)
far.valid = false
assert(Navigation.nearest(origin, { far, near }) == nil)
assert(Navigation.direction_label(Navigation.relative_yaw({ dx = 1, dy = 0 }, 90)) == "LEFT")

local Teleport = require("WMTeleport")
local first, second = Teleport.new(print), Teleport.new(print)
assert(#loops == 0 and load_map == nil, "Consumers own lifecycle callbacks")
pawns[1].location = { X = 10, Y = 20, Z = 30 }
first:move(1, { X = 100, Y = 200, Z = 300 }, "arbitrary target")
second:return_player(1)
assert(pawns[1].location.X == 100, "Sessions do not share return state")
pawns[1].move_error = true
first:return_player(1)
pawns[1].move_error = false
first:return_player(1)
assert(pawns[1].location.X == 10, "Failed return preserves its point")
first:move(1, { X = 100, Y = 0, Z = 0 }, "first target")
first:move(1, { X = 200, Y = 0, Z = 0 }, "second target")
first:return_player(1)
assert(pawns[1].location.X == 100, "Return means the position before the last successful move")
first:move(1, { X = 200, Y = 0, Z = 0 }, "third target")
first:reset()
local moves = pawns[1].moves
first:return_player(1)
assert(pawns[1].moves == moves, "Explicit reset invalidates saved positions")
