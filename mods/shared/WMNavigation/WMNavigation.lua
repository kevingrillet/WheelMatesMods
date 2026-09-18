local Runtime = require("WMRuntime")
local M = {}

function M.direction_label(relative_yaw)
    if relative_yaw >= -22.5 and relative_yaw < 22.5 then
        return "AHEAD"
    end
    if relative_yaw >= 22.5 and relative_yaw < 67.5 then
        return "AHEAD-RIGHT"
    end
    if relative_yaw >= 67.5 and relative_yaw < 112.5 then
        return "RIGHT"
    end
    if relative_yaw >= 112.5 and relative_yaw < 157.5 then
        return "BEHIND-RIGHT"
    end
    if relative_yaw >= -67.5 and relative_yaw < -22.5 then
        return "AHEAD-LEFT"
    end
    if relative_yaw >= -112.5 and relative_yaw < -67.5 then
        return "LEFT"
    end
    if relative_yaw >= -157.5 and relative_yaw < -112.5 then
        return "BEHIND-LEFT"
    end
    return "BEHIND"
end

function M.nearest(origin, actors)
    local nearest, nearest_distance_squared = nil, nil
    for _, actor in ipairs(actors) do
        if Runtime.valid(actor) then
            local location = actor:K2_GetActorLocation()
            local dx, dy, dz = location.X - origin.X, location.Y - origin.Y, location.Z - origin.Z
            local distance_squared = dx * dx + dy * dy + dz * dz
            if nearest_distance_squared == nil or distance_squared < nearest_distance_squared then
                nearest = { actor = actor, dx = dx, dy = dy, dz = dz, distance_squared = distance_squared }
                nearest_distance_squared = distance_squared
            end
        end
    end
    return nearest
end

function M.relative_yaw(target, yaw)
    return (math.deg(math.atan(target.dy, target.dx)) - yaw + 180) % 360 - 180
end

function M.vertical_label(dz, tolerance)
    if dz > tolerance then
        return "UP"
    end
    if dz < -tolerance then
        return "DOWN"
    end
    return "LEVEL"
end

return M
