local ModName = "WallHack"
local wallhack_enabled = false
local saved_render_state = {}

--- Writes one complete WallHack message to the UE4SS console.
local function log(message)
    print(string.format("[%s] %s\n", ModName, message))
end

--- Returns true only for a reflected Unreal object that is safe to inspect.
local function is_valid(object)
    return object ~= nil and object:IsValid()
end

--- Unwraps UE4SS remote parameters while accepting already concrete objects.
local function unwrap(value)
    local ok, unwrapped = pcall(function() return value:get() end)
    return ok and unwrapped or value
end

--- Iterates either a UE4SS collection or a plain Lua table lookup result.
local function for_each_object(objects, callback)
    if type(objects) == "table" then
        for _, object in pairs(objects) do callback(unwrap(object)) end
    elseif objects ~= nil and objects.ForEach ~= nil then
        objects:ForEach(function(_, object) callback(unwrap(object)) end)
    end
end

--- Returns a readable class name without allowing reflection errors to end a probe.
local function class_name(object)
    local ok, name = pcall(function() return object:GetClass():GetFullName() end)
    return ok and tostring(name) or "<unavailable>"
end

--- Returns render components belonging to every currently loaded Gear actor.
local function loaded_gear_components()
    local result = {}
    local components = FindAllOf("ActorComponent")
    for_each_object(FindAllOf("BP_Collectable_Gear_C"), function(gear)
        if not is_valid(gear) then return end
        local gear_path = string.match(gear:GetFullName(), " (.+)") or gear:GetFullName()
        for_each_object(components, function(component)
            if is_valid(component) and string.find(component:GetFullName(), gear_path, 1, true) ~= nil then
                local class = class_name(component)
                if string.find(class, "StaticMeshComponent", 1, true) ~= nil then
                    table.insert(result, component)
                end
            end
        end)
    end)
    return result
end

--- Enables or restores Custom Depth without changing collectible gameplay state.
local function toggle_wallhack()
    if wallhack_enabled then
        local restored = 0
        for _, state in pairs(saved_render_state) do
            if is_valid(state.component) then
                state.component:SetRenderCustomDepth(state.custom_depth)
                state.component:SetCustomDepthStencilValue(state.stencil)
                restored = restored + 1
            end
        end
        saved_render_state = {}
        wallhack_enabled = false
        log(string.format("Custom Depth restored on %d Gear render component(s).", restored))
        return
    end

    local applied = 0
    for _, component in ipairs(loaded_gear_components()) do
        local name = component:GetFullName()
        saved_render_state[name] = {
            component = component,
            custom_depth = component.bRenderCustomDepth,
            stencil = component.CustomDepthStencilValue,
        }
        component:SetRenderCustomDepth(true)
        component:SetCustomDepthStencilValue(1)
        applied = applied + 1
    end
    wallhack_enabled = applied > 0
    log(string.format("Custom Depth enabled on %d Gear render component(s), stencil 1.", applied))
end

RegisterKeyBind(Key.F4, { ModifierKey.CONTROL }, function() ExecuteInGameThread(toggle_wallhack) end)

log("Loaded. Ctrl+F4 toggles Gear Custom Depth.")
