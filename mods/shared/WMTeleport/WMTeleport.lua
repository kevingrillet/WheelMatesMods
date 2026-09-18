local Runtime = require("WMRuntime")
local M = {}

-- Call session methods on the game thread; the consumer owns hooks and polling.
function M.new(log)
    local self = {}
    local last_locations = {}
    local current_world = nil

    function self:refresh_world()
        local world = Runtime.world_id()
        if world ~= current_world then
            last_locations = {}
            current_world = world
        end
        return world
    end

    function self:reset()
        last_locations = {}
        current_world = nil
    end

    -- Resolve one split-screen local player's currently possessed vehicle.
    local function local_pawn(player_number)
        for _, player in ipairs(Runtime.players()) do
            if player.index == player_number then
                return player.pawn
            end
        end
        return nil
    end

    -- Save the current position and relocate one local vehicle on the game thread.
    function self:move(player_number, target, label, is_return)
        local world = self:refresh_world()
        if world == nil then
            return
        end
        local pawn = local_pawn(player_number)
        if not Runtime.valid(pawn) then
            log(string.format("Player %d is not available locally.", player_number))
            return
        end

        local current = pawn:K2_GetActorLocation()
        local previous = { X = current.X, Y = current.Y, Z = current.Z }

        -- Movement is deliberately executed on the game thread.  Sweep is disabled
        -- to preserve the prototype behavior; the caller validates placement. Teleport is enabled to
        -- avoid vehicle interpolation through the level.
        local ok, result_or_error = pcall(function()
            return pawn:K2_SetActorLocation(target, false, {}, true)
        end)
        if ok and result_or_error == true then
            if is_return then
                last_locations[player_number] = nil
            else
                last_locations[player_number] = { world = world, position = previous }
            end
            log(
                string.format(
                    "Player %d teleported to %s at {X=%.3f, Y=%.3f, Z=%.3f}.",
                    player_number,
                    label,
                    target.X,
                    target.Y,
                    target.Z
                )
            )
        else
            log(string.format("Teleport failed for Player %d: %s", player_number, tostring(result_or_error)))
        end
    end

    -- Return a player to the position captured immediately before the last teleport.
    function self:return_player(player_number)
        local world = self:refresh_world()
        local last_location = last_locations[player_number]
        if last_location == nil then
            log(string.format("No return location is saved for Player %d.", player_number))
            return
        end
        if world == nil or last_location.world ~= world then
            last_locations[player_number] = nil
            log("Return cancelled: the original world is no longer active.")
            return
        end
        self:move(player_number, last_location.position, "saved return location", true)
    end

    return self
end

return M
