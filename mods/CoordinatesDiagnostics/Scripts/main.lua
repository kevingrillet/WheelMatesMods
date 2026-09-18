local UEHelpers = require("UEHelpers")

local ModName = "CoordinatesDiagnostics"

--- Writes a consistently terminated diagnostic message to the UE4SS console.
local function log(message)
    print(string.format("[%s] %s\n", ModName, message))
end

--- Returns true only for an Unreal object that is still safe to inspect.
local function is_valid(object)
    return object ~= nil and object:IsValid()
end

--- Extracts the value exposed by UE4SS remote properties where needed.
local function unwrap(value)
    local ok, unwrapped = pcall(function()
        return value:get()
    end)
    return ok and unwrapped or value
end

--- Returns a full object name without allowing a failed reflection call to stop the probe.
local function object_name(object)
    local ok, name = pcall(function() return object:GetFullName() end)
    return ok and tostring(name) or "<unavailable>"
end

--- Runs a callback over a UE4SS object lookup result, including plain Lua tables.
local function for_each_object(result, callback)
    if type(result) == "table" then
        for _, object in pairs(result) do
            callback(unwrap(object))
        end
    elseif result ~= nil and result.ForEach ~= nil then
        result:ForEach(function(_, object) callback(unwrap(object)) end)
    end
end

--- Enumerates currently available local controllers and their controlled Pawns.
local function local_players()
    local players = {}
    local game_instance = UEHelpers.GetGameInstance()
    local local_player_array = game_instance and game_instance.LocalPlayers
    if local_player_array == nil then return players end
    local_player_array:ForEach(function(index, player_param)
        local local_player = player_param:get()
        local controller = local_player and local_player.PlayerController
        local pawn = controller and controller.Pawn
        if is_valid(controller) and is_valid(pawn) then
            table.insert(players, { index = index, controller = controller, pawn = pawn })
        end
    end)
    return players
end

--- Produces a raw, step-by-step LocalPlayers inspection for UE4SS wrapper research.
local function report_local_player_chain()
    local game_instance = UEHelpers.GetGameInstance()
    log(string.format("GameInstance | Valid=%s | Object=%s", tostring(is_valid(game_instance)), game_instance and game_instance:GetFullName() or "<none>"))
    if not is_valid(game_instance) then return end

    local array_ok, local_players = pcall(function() return game_instance.LocalPlayers end)
    log(string.format("LocalPlayers property | Read=%s | LuaType=%s", tostring(array_ok), type(local_players)))
    if not array_ok or local_players == nil then return end

    local iterated, iteration_error = pcall(function()
        local_players:ForEach(function(index, player_param)
            local player_ok, local_player = pcall(function() return player_param:get() end)
            log(string.format("LocalPlayers[%s] | ParamType=%s | Unwrap=%s | Object=%s", tostring(index), type(player_param), tostring(player_ok), player_ok and object_name(local_player) or "<unavailable>"))
            if not player_ok or local_player == nil then return end

            local controller_ok, controller = pcall(function() return local_player.PlayerController end)
            log(string.format("LocalPlayers[%s].PlayerController | Read=%s | Object=%s", tostring(index), tostring(controller_ok), controller_ok and object_name(controller) or "<unavailable>"))
            if not controller_ok or not is_valid(controller) then return end

            local property_ok, property_pawn = pcall(function() return controller.Pawn end)
            local method_ok, method_pawn = pcall(function() return controller:GetPawn() end)
            local pawn_valid_ok, pawn_valid = pcall(function() return property_pawn:IsValid() end)
            log(string.format("LocalPlayers[%s].Pawn | Property=%s (%s) | IsValid=%s (%s) | GetPawn=%s (%s)", tostring(index), tostring(property_ok), property_ok and object_name(property_pawn) or "<unavailable>", tostring(pawn_valid_ok), tostring(pawn_valid), tostring(method_ok), method_ok and object_name(method_pawn) or "<unavailable>"))
        end)
    end)
    log(string.format("LocalPlayers iteration | Success=%s | Error=%s", tostring(iterated), iterated and "<none>" or tostring(iteration_error)))
end

--- Prints transform, velocity, controller, and Pawn identity for local players.
local function report_local_players()
    local reported = 0
    for _, player in ipairs(local_players()) do
        if is_valid(player.pawn) then
            local position = player.pawn:K2_GetActorLocation()
            local rotation = player.pawn:K2_GetActorRotation()
            local velocity = player.pawn:GetVelocity()
            log(string.format("Player %d | Position {X=%.3f, Y=%.3f, Z=%.3f} | Rotation {Pitch=%.3f, Yaw=%.3f, Roll=%.3f} | Velocity {X=%.3f, Y=%.3f, Z=%.3f}", player.index, position.X, position.Y, position.Z, rotation.Pitch, rotation.Yaw, rotation.Roll, velocity.X, velocity.Y, velocity.Z))
            log(string.format("Player %d | Controller=%s | Pawn=%s", player.index, player.controller and player.controller:GetFullName() or "<none>", player.pawn:GetFullName()))
            reported = reported + 1
        end
    end
    log(string.format("Reported %d local player(s).", reported))
end

--- Lists active HUD objects and relevant inherited drawing functions.
local function report_hud_topology()
    local hud_count = 0
    for_each_object(FindAllOf("HUD"), function(hud)
        if is_valid(hud) then
            hud_count = hud_count + 1
            log(string.format("HUD %d | Class=%s | Object=%s", hud_count, hud:GetClass():GetFullName(), hud:GetFullName()))
            local class = hud:GetClass()
            local depth = 0
            while is_valid(class) and depth < 8 do
                local names = {}
                class:ForEachFunction(function(function_object)
                    local name = unwrap(function_object):GetFName():ToString()
                    if string.find(name, "Draw") or string.find(name, "Canvas") or string.find(name, "Render") then
                        table.insert(names, name)
                    end
                end)
                if #names > 0 then
                    table.sort(names)
                    log(string.format("HUD functions | Class=%s | %s", class:GetFullName(), table.concat(names, ", ")))
                end
                class = class:GetSuperStruct()
                depth = depth + 1
            end
        end
    end)
    log(string.format("HUD objects found: %d.", hud_count))
end

--- Groups loaded UMG widgets by class to identify WheelMates' UI topology.
local function report_widget_topology()
    local counts = {}
    for_each_object(FindAllOf("UserWidget"), function(widget)
        if is_valid(widget) then
            local class_name = widget:GetClass():GetFName():ToString()
            counts[class_name] = (counts[class_name] or 0) + 1
        end
    end)

    local names = {}
    for class_name, _ in pairs(counts) do
        table.insert(names, class_name)
    end
    table.sort(names)
    log("Loaded UMG widgets:")
    for _, class_name in ipairs(names) do
        log(string.format("Widget | %d instance(s) | %s", counts[class_name], class_name))
    end
end

--- Inspects the active split HUD layouts to locate an existing writable panel.
local function report_split_hud_layout()
    for_each_object(FindAllOf("WBP_PlayerHUDLayout_Split_C"), function(layout)
        if not is_valid(layout) then return end
        log(string.format("Split HUD | Layout=%s | Class=%s", object_name(layout), object_name(layout:GetClass())))
        local tree_ok, tree = pcall(function() return unwrap(layout.WidgetTree) end)
        if tree_ok and tree ~= nil then
            local root_ok, root = pcall(function() return unwrap(tree.RootWidget) end)
            local root_class = root_ok and root ~= nil and object_name(root:GetClass()) or "<unavailable>"
            log(string.format("Split HUD tree | Tree=%s | Root=%s | RootClass=%s", object_name(tree), root_ok and object_name(root) or "<unavailable>", root_class))
        else
            log("Split HUD tree | unavailable")
        end
        local names = {}
        layout:GetClass():ForEachProperty(function(property)
            table.insert(names, unwrap(property):GetFName():ToString())
        end)
        table.sort(names)
        log("Split HUD properties | " .. table.concat(names, ", "))
    end)
end

RegisterKeyBind(Key.NUM_ONE, { ModifierKey.CONTROL }, report_local_player_chain)
RegisterKeyBind(Key.NUM_TWO, { ModifierKey.CONTROL }, report_hud_topology)
RegisterKeyBind(Key.NUM_THREE, { ModifierKey.CONTROL }, report_widget_topology)
RegisterKeyBind(Key.NUM_FOUR, { ModifierKey.CONTROL }, report_split_hud_layout)

log("Loaded. Ctrl+NumPad1: raw LocalPlayers chain. Ctrl+NumPad2: HUD. Ctrl+NumPad3: UMG widgets. Ctrl+NumPad4: split HUD structure.")
