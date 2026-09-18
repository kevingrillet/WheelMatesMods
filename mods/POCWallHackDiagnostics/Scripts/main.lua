local UEHelpers = require("UEHelpers")

local ModName = "POCWallHackDiagnostics"

--- Writes one complete diagnostic message to the UE4SS console.
local function log(message)
    print(string.format("[%s] %s\n", ModName, message))
end

--- Returns true only for an Unreal object that is still safe to inspect.
local function is_valid(object)
    return object ~= nil and object:IsValid()
end

--- Unwraps UE4SS remote parameters while accepting already concrete objects.
local function unwrap(value)
    local ok, unwrapped = pcall(function()
        return value:get()
    end)
    return ok and unwrapped or value
end

--- Iterates either a UE4SS collection or a plain Lua table lookup result.
local function for_each_object(objects, callback)
    if type(objects) == "table" then
        for _, object in pairs(objects) do
            callback(unwrap(object))
        end
    elseif objects ~= nil and objects.ForEach ~= nil then
        objects:ForEach(function(_, object)
            callback(unwrap(object))
        end)
    end
end

--- Returns a readable class name without allowing reflection errors to end a probe.
local function class_name(object)
    local ok, name = pcall(function()
        return object:GetClass():GetFullName()
    end)
    return ok and tostring(name) or "<unavailable>"
end

--- Returns player Pawns through the LocalPlayers chain verified in WheelMates.
local function local_player_pawns()
    local pawns = {}
    local game_instance = UEHelpers.GetGameInstance()
    if not is_valid(game_instance) then
        return pawns
    end

    local players = game_instance.LocalPlayers
    if players == nil then
        return pawns
    end
    players:ForEach(function(index, player_param)
        local player = unwrap(player_param)
        local controller = player ~= nil and player.PlayerController or nil
        local pawn = controller ~= nil and controller.Pawn or nil
        if is_valid(pawn) then
            table.insert(pawns, { index = index, pawn = pawn })
        end
    end)
    return pawns
end

--- Reports depth/stencil values already used by the local player vehicle meshes.
local function report_player_outline_state()
    local components = FindAllOf("ActorComponent")
    local players = local_player_pawns()
    if #players == 0 then
        log("Outline probe unavailable: no ready local player pawn was found.")
        return
    end

    log("Player outline probe (read-only)")
    for _, player in ipairs(players) do
        local pawn_name = player.pawn:GetFullName()
        local pawn_path = string.match(pawn_name, " (.+)") or pawn_name
        local matched = 0
        log(string.format("Player %d | %s", player.index, pawn_name))
        for_each_object(components, function(component)
            if not is_valid(component) then
                return
            end
            if string.find(component:GetFullName(), pawn_path, 1, true) == nil then
                return
            end
            if string.find(class_name(component), "StaticMeshComponent", 1, true) == nil then
                return
            end
            matched = matched + 1
            local depth_ok, depth = pcall(function()
                return component.bRenderCustomDepth
            end)
            local stencil_ok, stencil = pcall(function()
                return component.CustomDepthStencilValue
            end)
            log(
                string.format(
                    "  Mesh %d | CustomDepth=%s | Stencil=%s | %s",
                    matched,
                    depth_ok and tostring(depth) or "<unavailable>",
                    stencil_ok and tostring(stencil) or "<unavailable>",
                    component:GetFullName()
                )
            )
        end)
        log(string.format("  Static mesh component(s): %d", matched))
    end
    log("Player outline probe complete.")
end

--- Reports loaded Gear components and their current render-buffer settings.
local function report_gear_render_components()
    local components = FindAllOf("ActorComponent")
    local gear_count = 0
    log("Gear render probe (read-only)")
    for_each_object(FindAllOf("BP_Collectable_Gear_C"), function(gear)
        if not is_valid(gear) then
            return
        end
        gear_count = gear_count + 1
        local gear_name = gear:GetFullName()
        local gear_path = string.match(gear_name, " (.+)") or gear_name
        local component_count = 0
        log(string.format("Gear %d | %s", gear_count, gear_name))
        for_each_object(components, function(component)
            if not is_valid(component) then
                return
            end
            if string.find(component:GetFullName(), gear_path, 1, true) == nil then
                return
            end
            if string.find(class_name(component), "StaticMeshComponent", 1, true) == nil then
                return
            end
            component_count = component_count + 1
            local depth_ok, depth = pcall(function()
                return component.bRenderCustomDepth
            end)
            local stencil_ok, stencil = pcall(function()
                return component.CustomDepthStencilValue
            end)
            log(
                string.format(
                    "  Mesh %d | CustomDepth=%s | Stencil=%s | %s",
                    component_count,
                    depth_ok and tostring(depth) or "<unavailable>",
                    stencil_ok and tostring(stencil) or "<unavailable>",
                    component:GetFullName()
                )
            )
        end)
        log(string.format("  Static mesh component(s): %d", component_count))
    end)
    log(string.format("Gear render probe complete: %d loaded Gear actor(s).", gear_count))
end

RegisterKeyBind(Key.F8, { ModifierKey.CONTROL }, function()
    ExecuteInGameThread(report_player_outline_state)
end)
RegisterKeyBind(Key.F4, { ModifierKey.CONTROL, ModifierKey.SHIFT }, function()
    ExecuteInGameThread(report_gear_render_components)
end)

log("Loaded. Ctrl+F8 probes player outlines. Ctrl+Shift+F4 probes Gear rendering. Read-only.")
