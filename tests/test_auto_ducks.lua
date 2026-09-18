-- Keep map-travel simulation local; do not depend on pending shared harness edits.
function instance:GetWorld()
    return world
end
world.name = "/Game/Maps/LVL_Backyard_01.LVL_Backyard_01"
local level = object("Level", "PersistentLevel", world)
for _, pawn in ipairs(pawns) do
    pawn.outer = level
end
local pool = object("BP_Pool_01_01_prp_C", "Pool", level)
pool.location = { X = -10999.302, Y = 22480.359, Z = -429.734 }
local trigger = object("BP_Trigger_PhysicObject_RequiredCount_C", "PoolCounter", level)
trigger.location = { X = -12457.658, Y = 25431.457, Z = -1085 }
local function duck(variant, name, outer)
    local actor = object("BP_PhysicsActor_RubberDuck_0" .. variant .. "_prp_C", name, outer or level)
    actor.StaticMesh = object("StaticMeshComponent", "Mesh", actor)
    function actor.StaticMesh:SetPhysicsLinearVelocity(velocity, add)
        assert(not add and velocity.X == 0 and velocity.Y == 0 and velocity.Z == 0)
        self.linear_reset = true
    end
    function actor.StaticMesh:SetPhysicsAngularVelocityInDegrees()
        self.angular_reset = true
    end
    actor.Targetable = object("TargetableComponent", "Targetable", actor)
    function actor.Targetable:GetHolderByComponentIndex(index)
        assert(index == 0)
        return self.holder
    end
    return actor
end
local first, second = duck(1, "First"), duck(2, "Second")
local delivered, held = duck(1, "Delivered"), duck(2, "Held")
held.Targetable.holder = pawns[1]
trigger.OverlappedActors = { delivered }
-- Live streamed actors must not depend on a matching Outer/GetWorld chain.
function trigger:GetOuter()
    error("Ownership metadata is not a loaded actor filter")
end
function first:GetOuter()
    error("Ownership metadata is not a loaded actor filter")
end
local unrelated = object("BP_PhysicsActor_PlasticBucket_C", "Bucket", level)
load_mod("AutoDucks")
pawns[1].location = { X = 10, Y = 20, Z = 30 }
keys["CTRL+F7"]()
assert(first.moves == 1 and second.moves == 1, "Both skins must move")
assert(delivered.moves == nil and held.moves == nil, "Preserve delivered and held ducks")
assert(unrelated.moves == nil, "Do not move unrelated props")
assert(pawns[1].moves == nil and pawns[2].moves == nil, "Vehicles must stay in place")
assert(first.StaticMesh.linear_reset and first.StaticMesh.angular_reset)
assert(math.abs((first.location.X + second.location.X) / 2 - 10) < 0.001)
assert(math.abs((first.location.Y + second.location.Y) / 2 - 20) < 0.001)
assert(first.location.Z == 130)
pawns[2].location = { X = 10000, Y = 20000, Z = 300 }
keys["CTRL+SHIFT+F7"]()
assert(math.abs((first.location.X + second.location.X) / 2 - 10000) < 0.001)
assert(first.location.Z == 400)
assert(contains("already in pool 1, held 1"))

world = object("World", "OtherMap")
local scans = queries.BP_PhysicsActor_RubberDuck_01_prp_C
keys["CTRL+F7"]()
assert(first.moves == 2 and contains("Unavailable on this map"), "Stale landmarks cannot authorize another map")
assert(queries.BP_PhysicsActor_RubberDuck_01_prp_C == scans, "Wrong map must not scan ducks")
world = level.outer
pool.valid = false
trigger.location.X = 0
keys["CTRL+F7"]()
assert(first.moves == 3, "Confirmed map and unique counter do not require decorative pool or dump coordinates")
local other = object("BP_Trigger_PhysicObject_RequiredCount_C", "OtherCounter", level)
keys["CTRL+F7"]()
assert(first.moves == 3 and contains("missing or ambiguous"), "Do not guess between multiple unmatched counters")
trigger.location.X = -12457.658
keys["CTRL+F7"]()
assert(first.moves == 4, "A unique position match disambiguates multiple counters")
other.valid = false
trigger.valid = false
keys["CTRL+F7"]()
assert(first.moves == 4, "A missing counter must not move delivered ducks")
trigger.valid = true
trigger.OverlappedActors = nil
keys["CTRL+F7"]()
assert(first.moves == 4 and contains("Action stopped"), "Unknown pool state must stop movement")
trigger.OverlappedActors = { delivered }
first.move_result = false
second.StaticMesh.SetPhysicsLinearVelocity = function()
    error("Physics API failed")
end
keys["CTRL+F7"]()
assert(contains("failed 1, physics warnings 1"), "Report partial failures accurately")
first.Targetable.GetHolderByComponentIndex = function()
    error("Holder state unreadable")
end
local before = first.moves
keys["CTRL+F7"]()
assert(first.moves == before and contains("unreadable 1"))
first.valid, second.valid, delivered.valid, held.valid = false, false, false, false
keys["CTRL+F7"]()
assert(contains("moved 0"), "An empty duck scan is harmless")
