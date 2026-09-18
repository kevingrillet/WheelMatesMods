-- Safe first-load probe: leave gameplay state untouched.
local ModName = "ModKit"

-- Keep startup diagnostics readable in the UE4SS console.
local function log(message)
    print(string.format("[%s] %s\n", ModName, message))
end

log("Loaded in diagnostic mode.")
log("No actor, save, input, or render state is modified.")
