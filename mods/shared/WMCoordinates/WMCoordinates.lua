local M = {}

function M.text(player_index, pawn)
    local position = pawn:K2_GetActorLocation()
    local rotation = pawn:K2_GetActorRotation()
    local velocity = pawn:GetVelocity()

    return string.format(
        "COORDINATES PLAYER %d\nPosition  X / Y / Z     %.0f / %.0f / %.0f\nRotation  Pitch / Yaw / Roll  %.1f / %.1f / %.1f\nVelocity  X / Y / Z     %.0f / %.0f / %.0f",
        player_index,
        position.X,
        position.Y,
        position.Z,
        rotation.Pitch,
        rotation.Yaw,
        rotation.Roll,
        velocity.X,
        velocity.Y,
        velocity.Z
    )
end

return M
