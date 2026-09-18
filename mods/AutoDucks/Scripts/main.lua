local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
local mods_root = assert(source:match("^(.*)/[^/]+/[Ss]cripts/main%.lua$"), "Cannot resolve workshop mods directory")
package.path = mods_root .. "/shared/?/?.lua;" .. package.path

local Runtime = require("WMRuntime")
local UEHelpers = require("UEHelpers")
local Classes = { "BP_PhysicsActor_RubberDuck_01_prp_C", "BP_PhysicsActor_RubberDuck_02_prp_C" }
local Map = "World /Game/Maps/LVL_Backyard_01.LVL_Backyard_01"
local Trigger = { X = -12457.658, Y = 25431.457, Z = -1085.000 }

local function log(message)
    print("[AutoDucks] " .. message .. "\n")
end

-- The map is checked separately. Accept valid loaded candidates, matching the
-- working POCs: actor ownership metadata must not reject real streamed actors.
local function pool_counter()
    local candidates, matches = {}, {}
    Runtime.each(FindAllOf("BP_Trigger_PhysicObject_RequiredCount_C"), function(actor)
        if Runtime.valid(actor) then
            candidates[#candidates + 1] = actor
            local ok, p = pcall(function()
                return actor:K2_GetActorLocation()
            end)
            if ok and p then
                local dx, dy, dz = p.X - Trigger.X, p.Y - Trigger.Y, p.Z - Trigger.Z
                if dx * dx + dy * dy + dz * dz < 100 * 100 then
                    matches[#matches + 1] = actor
                end
            end
        end
    end)
    if #matches == 1 then
        return matches[1]
    end
    if #candidates == 1 then
        log("Using the only loaded count trigger; its position differs from the dump or could not be read.")
        return candidates[1]
    end
    log(
        string.format(
            "Backyard confirmed, but pool counter is missing or ambiguous: %d loaded, %d position matches.",
            #candidates,
            #matches
        )
    )
    return nil
end

local function gather(index)
    local instance = UEHelpers.GetGameInstance()
    if not Runtime.valid(instance) then
        log("No active game instance.")
        return
    end
    local world = instance:GetWorld()
    if not Runtime.valid(world) then
        log("No active world.")
        return
    end
    -- Exact runtime name supplied by the user's September 18 failure log.
    if world:GetFullName() ~= Map then
        log("Unavailable on this map: expected LVL_Backyard_01, got " .. world:GetFullName())
        return
    end
    local pawn
    for _, player in ipairs(Runtime.players()) do
        if player.index == index then
            pawn = player.pawn
        end
    end
    if not Runtime.valid(pawn) then
        log("Player " .. index .. " is unavailable in the active world.")
        return
    end
    local trigger = pool_counter()
    if not trigger then
        return
    end

    -- Fail closed if the pool membership cannot be read: do not pull out ducks
    -- already delivered. The count trigger remains responsible for progression.
    local delivered = {}
    assert(trigger.OverlappedActors ~= nil, "Pool membership is unavailable")
    Runtime.each(trigger.OverlappedActors, function(actor)
        if Runtime.valid(actor) then
            delivered[Runtime.identity(actor)] = true
        end
    end)
    local candidates, seen = {}, {}
    local kept, held, unreadable = 0, 0, 0
    for _, class in ipairs(Classes) do
        Runtime.each(FindAllOf(class), function(duck)
            if not Runtime.valid(duck) then
                return
            end
            local id = Runtime.identity(duck)
            if seen[id] then
                return
            end
            seen[id] = true
            if delivered[id] then
                kept = kept + 1
                return
            end
            local ok, busy = pcall(function()
                assert(Runtime.valid(duck.Targetable), "Missing Targetable")
                return Runtime.valid(duck.Targetable:GetHolderByComponentIndex(0))
            end)
            if not ok then
                unreadable = unreadable + 1
            elseif busy then
                held = held + 1
            elseif Runtime.valid(duck.StaticMesh) then
                candidates[#candidates + 1] = { actor = duck, id = id }
            else
                unreadable = unreadable + 1
            end
        end)
    end
    table.sort(candidates, function(a, b)
        return a.id < b.id
    end)
    local center = pawn:K2_GetActorLocation()
    local count = #candidates
    -- At least 3 m from the vehicle and 2 m between adjacent ducks.
    local radius = count > 1 and math.max(300, 100 / math.sin(math.pi / count)) or 300
    local moved, failed, physics_warnings = 0, 0, 0
    for i, entry in ipairs(candidates) do
        local angle = 2 * math.pi * (i - 1) / count
        local target =
            { X = center.X + radius * math.cos(angle), Y = center.Y + radius * math.sin(angle), Z = center.Z + 100 }
        local ok, result = pcall(function()
            return entry.actor:K2_SetActorLocation(target, false, {}, true)
        end)
        if ok and result == true then
            moved = moved + 1
            local physics_ok = pcall(function()
                local mesh = entry.actor.StaticMesh
                mesh:SetPhysicsLinearVelocity({ X = 0, Y = 0, Z = 0 }, false, FName("None"))
                mesh:SetPhysicsAngularVelocityInDegrees({ X = 0, Y = 0, Z = 0 }, false, FName("None"))
            end)
            if not physics_ok then
                physics_warnings = physics_warnings + 1
            end
        else
            failed = failed + 1
        end
    end
    log(
        string.format(
            "Player %d: moved %d, already in pool %d, held %d, unreadable %d, failed %d, physics warnings %d.",
            index,
            moved,
            kept,
            held,
            unreadable,
            failed,
            physics_warnings
        )
    )
end

for index = 1, 2 do
    local modifiers = index == 1 and { ModifierKey.CONTROL } or { ModifierKey.CONTROL, ModifierKey.SHIFT }
    RegisterKeyBind(Key.F7, modifiers, function()
        ExecuteInGameThread(function()
            local ok, err = pcall(gather, index)
            if not ok then
                log("Action stopped: " .. tostring(err))
            end
        end)
    end)
end
log("Loaded. Ctrl+F7: Player 1; Ctrl+Shift+F7: Player 2. Only the duck pool map is supported.")
