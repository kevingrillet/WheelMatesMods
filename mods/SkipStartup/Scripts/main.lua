-- Use the startup widgets' own completion path; never touch lobby cutscenes.
local allowed = {
    W_Splash_Unreal_C = true,
    W_Splash_Firevolt_C = true,
    W_PhotosensitivityDisclaimer_C = true,
}
-- UE4SS shared scalars survive Ctrl+R but reset with the game process.
local stateKey = "WheelMatesMods.SkipStartup.State.v1"
local deadlineKey = "WheelMatesMods.SkipStartup.Deadline.v1"
if ModRef:GetSharedVariable(stateKey) == "stopped" then
    print("[SkipStartup] Already finished this game session; no watcher started.\n")
    return
end
local deadline = ModRef:GetSharedVariable(deadlineKey) or (os.time() + 120)
ModRef:SetSharedVariable(deadlineKey, deadline)
local skipped = {}
local sawStartup = false
local stopped = false
local loopHandle

local function log(message)
    print("[SkipStartup] " .. message .. "\n")
end

local function stop(message)
    stopped = true
    ModRef:SetSharedVariable(stateKey, "stopped")
    CancelDelayedAction(loopHandle)
    log(message)
end

local function valid(value)
    return value ~= nil and value:IsValid()
end

local function update()
    if os.time() >= deadline then
        stop("Startup watch expired; no further action.")
        return
    end
    local found = false
    for _, player in pairs(FindAllOf("W_StartupPlayer_C") or {}) do
        -- Ignore templates and widgets retained in memory after leaving the screen.
        if valid(player) and player:IsActivated() then
            found = true
            sawStartup = true
            local active = player.ActiveStartup
            if valid(active) then
                local className = active:GetClass():GetFName():ToString()
                local id = active:GetFullName() .. "@" .. tostring(active:GetAddress())
                if allowed[className] and not skipped[id] and active.bCanSkip then
                    -- Mark before calling: Skip synchronously notifies the parent,
                    -- which may remove this widget and create the next one.
                    skipped[id] = true
                    active:Skip()
                    log("Skipped " .. className)
                end
            end
        end
    end
    if sawStartup and not found then
        stop("Startup UI closed; watcher stopped.")
    end
end

loopHandle = LoopInGameThreadWithDelay(100, function()
    if stopped then
        return
    end
    local ok, err = pcall(update)
    if not ok then
        stop("Disabled after an error: " .. tostring(err))
    end
end)
log("Enabled. Automatically skips launch screens when their skip cooldown ends.")
