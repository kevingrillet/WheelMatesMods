local UEHelpers = require("UEHelpers")
local M = {}

function M.valid(object)
    if object == nil then
        return false
    end
    local ok, valid = pcall(function()
        return object:IsValid()
    end)
    return ok and valid
end

function M.unwrap(value)
    local ok, result = pcall(function()
        return value:get()
    end)
    if ok then
        return result
    end
    return value
end

function M.each(objects, callback)
    if type(objects) == "table" then
        for _, object in pairs(objects) do
            callback(M.unwrap(object))
        end
    elseif objects ~= nil then
        objects:ForEach(function(_, object)
            callback(M.unwrap(object))
        end)
    end
end

-- Store identities as scalars, never transient UObject pointers in shared variables.
function M.identity(object)
    if not M.valid(object) then
        return nil
    end
    return object:GetFullName() .. "@" .. tostring(object:GetAddress())
end

function M.world_id()
    -- GetWorld in UEHelpers scans all PlayerControllers on each call.
    local instance = UEHelpers.GetGameInstance()
    return M.valid(instance) and M.identity(instance:GetWorld()) or nil
end

function M.in_world(object, world_id)
    return world_id ~= nil and M.valid(object) and M.identity(object:GetWorld()) == world_id
end

function M.players()
    local result = {}
    local instance = UEHelpers.GetGameInstance()
    if not M.valid(instance) or instance.LocalPlayers == nil then
        return result
    end
    instance.LocalPlayers:ForEach(function(index, value)
        local player = M.unwrap(value)
        if not M.valid(player) then
            return
        end
        local controller = player.PlayerController
        if not M.valid(controller) then
            return
        end
        local pawn = controller.Pawn
        if M.valid(pawn) then
            result[#result + 1] = { index = index, controller = controller, pawn = pawn }
        end
    end)
    return result
end

-- FindAllOf provides the loaded candidates. Visibility and per-actor world
-- metadata are not validated collection-state filters in WheelMates.
-- Keep the working prototype's IsValid contract, shared across local players.
function M.gears()
    local result = {}
    M.each(FindAllOf("BP_Collectable_Gear_C"), function(gear)
        if M.valid(gear) then
            result[#result + 1] = gear
        end
    end)
    return result
end

function M.reference(object)
    if not M.valid(object) then
        return nil
    end
    return { path = object:GetFullName(), address = object:GetAddress() }
end

function M.resolve(reference)
    if not reference then
        return nil
    end
    local object = StaticFindObject(reference.path)
    if M.valid(object) and object:GetAddress() == reference.address then
        return object
    end
    return nil
end

return M
