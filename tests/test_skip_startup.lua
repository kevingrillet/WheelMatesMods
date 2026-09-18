-- Exercise the real entry point with synchronous widget replacement.
local now = 1000
os.time = function()
    return now
end
local callback, cancelled, candidates
local loopCount, queryCount = 0, 0
LoopInGameThreadWithDelay = function(delay, fn)
    assert(delay == 100)
    loopCount = loopCount + 1
    callback = fn
    return 42
end
CancelDelayedAction = function(handle)
    assert(handle == 42)
    cancelled = true
end
FindAllOf = function(class)
    assert(class == "W_StartupPlayer_C")
    queryCount = queryCount + 1
    return candidates
end
local function screen(class)
    local value = object(class, class .. "_0")
    function value:GetClass()
        return {
            GetFName = function()
                return FName(class)
            end,
        }
    end
    value.bCanSkip = false
    value.calls = 0
    function value:Skip()
        self.calls = self.calls + 1
        self.bCanSkip = false
    end
    return value
end
local player = object("W_StartupPlayer_C", "Startup")
player.activated = true
function player:IsActivated()
    return self.activated
end
local function start()
    shared = {} -- a fresh game process, unlike Ctrl+R
    cancelled = false
    dofile("mods/SkipStartup/Scripts/main.lua")
end
start()
callback()
assert(not cancelled)
candidates = { player }
callback()
assert(not cancelled)
local screens = {
    screen("W_Splash_Unreal_C"),
    screen("W_Splash_Firevolt_C"),
    screen("W_PhotosensitivityDisclaimer_C"),
}
player.ActiveStartup = screens[1]
for index, current in ipairs(screens) do
    function current:Skip()
        self.calls = self.calls + 1
        self.bCanSkip = false
        player.ActiveStartup = screens[index + 1]
    end
    callback()
    assert(current.calls == 0, "Respect each screen's cooldown")
    current.bCanSkip = true
    callback()
    assert(current.calls == 1, "Skip the active screen")
end
player.activated = false
callback()
assert(cancelled, "Stop on deactivation even if UObject remains loaded")
callback()
for _, current in ipairs(screens) do
    assert(current.calls == 1)
end

local function assert_reload_idle()
    local beforeLoops, beforeQueries = loopCount, queryCount
    dofile("mods/SkipStartup/Scripts/main.lua")
    assert(loopCount == beforeLoops, "Ctrl+R must not create a watcher after shutdown")
    assert(queryCount == beforeQueries, "Ctrl+R must not scan for startup widgets after shutdown")
end
assert_reload_idle()
assert_reload_idle()

start()
player.activated = true
local unknown = screen("BP_IntroCutScenePlayer_C")
unknown.bCanSkip = true
player.ActiveStartup = unknown
callback()
assert(unknown.calls == 0, "Never skip an unrelated class")
local retained = screen("W_Splash_Unreal_C")
retained.bCanSkip = true
player.ActiveStartup = retained
callback()
retained.bCanSkip = true
callback()
assert(retained.calls == 1, "Do not process an instance twice")

start()
local broken = screen("W_Splash_Unreal_C")
broken.bCanSkip = true
function broken:Skip()
    error("Simulated Blueprint call failure")
end
player.ActiveStartup = broken
callback()
assert(cancelled, "Disable after error instead of retrying every tick")
assert_reload_idle()

start()
candidates = nil
now = now + 100
-- Ctrl+R while still waiting retains the original deadline.
dofile("mods/SkipStartup/Scripts/main.lua")
now = now + 21
callback()
assert(cancelled, "Reload in gameplay has bounded polling")

assert_reload_idle()
start()
callback()
assert(not cancelled, "A fresh game process enables startup skipping again")
