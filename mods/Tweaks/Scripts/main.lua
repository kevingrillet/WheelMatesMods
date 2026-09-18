-- Resolve helpers from the repository's additional UE4SS ModsFolderPaths entry.
local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
local mods_root = assert(source:match("^(.*)/[^/]+/[Ss]cripts/main%.lua$"), "Cannot resolve workshop mods directory")
package.path = mods_root .. "/shared/?/?.lua;" .. package.path

local Runtime = require("WMRuntime")
local Overlay = require("WMOverlay")
local Coordinates = require("WMCoordinates")
local Navigation = require("WMNavigation")
local Targets = require("WMTargets")
local Teleport = require("WMTeleport")
local RenderState = require("WMRenderState")

local TableRows = 10
local ScanTicks = 25 -- 5 seconds; F8 explicitly performs the broader discovery scan.
local settle_ticks = 0
-- Initial approach policy: stay 6 m beside / 1 m above the target, toward the car.
-- This preserves the POC's offset magnitude, not a collision/ground guarantee.
local Approach = {
    Gear = { horizontal = 600, vertical = 100 },
    Narrative = { horizontal = 600, vertical = 100 },
    ["Mini-game"] = { horizontal = 600, vertical = 100 },
}
local targets = Targets.new()
local states, overlays = {}, {}
local current_world, ticks = nil, 0
local needs_refresh = true
local pending_restores = 0
-- Keep cached UE4SS userdata and its uses in one persistent update callback.
-- Key callbacks enqueue scalar commands instead of starting temporary callbacks.
local commands, actions = {}, {}
local map_changed = false
local loading_map = false
local recover_hud = false
local warmup_ticks = 0

local function log(message)
    print("[Tweaks] " .. message .. "\n")
end
local teleport = Teleport.new(log)

local function state(index)
    if not states[index] then
        states[index] = { coordinates = false, checklist = false, compass = false, sort_by_type = true }
    end
    return states[index]
end

local function local_player(index)
    for _, player in ipairs(Runtime.players()) do
        if player.index == index then
            return player
        end
    end
end

local function reset_world()
    if current_world ~= nil or map_changed then
        warmup_ticks = 10
    end
    recover_hud = true
    targets:reset()
    teleport:reset()
    current_world, needs_refresh = nil, true
    settle_ticks = 3
    for _, overlay in pairs(overlays) do
        overlay:forget()
    end
end

local function sync_world()
    local world = Runtime.world_id()
    if world ~= current_world then
        if current_world ~= nil then
            commands = {}
        end
        reset_world()
        current_world = world
    end
    return world
end

local function refresh(full)
    if not sync_world() or #Runtime.players() == 0 then
        return false
    end
    local started = os.clock()
    targets:refresh(full)
    local elapsed = (os.clock() - started) * 1000
    if elapsed > 20 then
        log(string.format("Slow target scan: %.1f ms (%s)", elapsed, full and "full" or "typed"))
    end
    needs_refresh = false
    return true
end

local function short_label(value)
    value = value:gsub("[\r\n]", " ")
    if #value > 42 then
        return value:sub(1, 39) .. "..."
    end
    return value
end

local function target_text(player, row, mode)
    if not row then
        return string.format("P%d %s | No loaded missing target", player.index, mode)
    end
    local delta = row.delta
    local yaw = player.pawn:K2_GetActorRotation().Yaw
    return string.format(
        "P%d %s | %s %s | %s | %.0f m | %s %+.1f m",
        player.index,
        mode,
        row.entry.type,
        short_label(row.entry.label),
        Navigation.direction_label(Navigation.relative_yaw(delta, yaw)),
        math.sqrt(delta.distance_squared) / 100,
        Navigation.vertical_label(delta.dz, 200),
        delta.dz / 100
    )
end

local function render(player)
    local preferences = state(player.index)
    local lines = {}
    if preferences.coordinates then
        lines[#lines + 1] = Coordinates.compact(player.index, player.pawn)
    end
    local selected, mode
    local rows
    if warmup_ticks > 0 and (preferences.checklist or preferences.compass) then
        lines[#lines + 1] = string.format("P%d | Updating loaded targets...", player.index)
        return table.concat(lines, "\n")
    end
    if preferences.checklist or preferences.compass then
        rows = targets:rows(player, false)
        selected, mode = targets:select(player, rows)
    end
    if preferences.compass then
        lines[#lines + 1] = target_text(player, selected, mode)
    end
    if preferences.checklist then
        if preferences.sort_by_type then
            table.sort(rows, function(a, b)
                if a.entry.type ~= b.entry.type then
                    return a.entry.type < b.entry.type
                end
                if a.delta.distance_squared ~= b.delta.distance_squared then
                    return a.delta.distance_squared < b.delta.distance_squared
                end
                return a.entry.order < b.entry.order
            end)
        else
            table.sort(rows, function(a, b)
                return a.delta.distance_squared < b.delta.distance_squared
            end)
        end
        -- Follow the selected row's page so every target is reachable without an oversized HUD.
        local selected_index = 1
        for index, row in ipairs(rows) do
            if selected and row.entry.id == selected.entry.id then
                selected_index = index
            end
        end
        local first = math.floor((selected_index - 1) / TableRows) * TableRows + 1
        local last = math.min(first + TableRows - 1, #rows)
        lines[#lines + 1] = string.format(
            "P%d MISSING %d | %s | %s | %d-%d",
            player.index,
            #rows,
            preferences.sort_by_type and "TYPE/DIST" or "DIST",
            mode,
            #rows == 0 and 0 or first,
            last
        )
        lines[#lines + 1] = "    Type       Distance   Item"
        for index = first, last do
            local row = rows[index]
            lines[#lines + 1] = string.format(
                "%s %-10s %6.0f m   %s",
                selected and row.entry.id == selected.entry.id and ">" or " ",
                row.entry.type,
                math.sqrt(row.delta.distance_squared) / 100,
                short_label(row.entry.label)
            )
        end
        if #rows == 0 then
            lines[#lines + 1] = "No loaded missing target"
        end
    end
    if preferences.checklist and #targets.minigames > 0 then
        lines[#lines + 1] = "MINI-GAMES | saved result (not a win/completion guarantee)"
        for i, entry in ipairs(targets.minigames) do
            if i > 6 then
                lines[#lines + 1] = string.format("... %d more loaded mini-games", #targets.minigames - 6)
                break
            end
            lines[#lines + 1] = entry.progress .. " | " .. short_label(entry.label)
        end
    end
    if (preferences.checklist or preferences.compass) and not targets.narrative_known then
        lines[#lines + 1] = "Narrative: Unknown (active save unavailable)"
    end
    return table.concat(lines, "\n")
end

local function update_overlay(index)
    local preferences, overlay = state(index), overlays[index]
    local enabled = preferences.coordinates or preferences.checklist or preferences.compass
    if overlay.enabled ~= enabled then
        overlay:toggle()
    end
end

local function move_to_target(player)
    -- Re-read collection state before moving, including while the HUD is hidden.
    if not refresh() then
        return
    end
    local row = targets:select(player)
    local actor = row and Runtime.resolve(row.entry.reference)
    if not actor then
        log(string.format("P%d: no loaded missing target.", player.index))
        return
    end
    local policy = Approach[row.entry.type]
    if not policy then
        return
    end
    local ok, location = pcall(function()
        return actor:K2_GetActorLocation()
    end)
    if not ok or not location then
        return
    end
    local origin = player.pawn:K2_GetActorLocation()
    local dx, dy = origin.X - location.X, origin.Y - location.Y
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 1 then
        dx, dy, length = 1, 0, 1
    end
    local destination = {
        X = location.X + dx / length * policy.horizontal,
        Y = location.Y + dy / length * policy.horizontal,
        Z = location.Z + policy.vertical,
    }
    if teleport:move(player.index, destination, row.entry.type .. " " .. row.entry.label) then
        warmup_ticks = 5
        needs_refresh = true
    end
end

ExecuteInGameThread(function()
    -- Tweaks is self-contained; also retire UI/render changes left by the POCs.
    for _, name in ipairs({ "Coordinates", "Compass", "TweaksP1", "TweaksP2" }) do
        Overlay.cleanup(name)
    end
    pending_restores = RenderState.restore()
end)

for index = 1, 2 do
    state(index)
    overlays[index] = Overlay.new("TweaksP" .. index, render, function(player)
        return player.index == index
    end)
    local modifiers = index == 1 and { ModifierKey.CONTROL } or { ModifierKey.CONTROL, ModifierKey.SHIFT }
    actions[index] = {}
    local function bind(key, action)
        actions[index][key] = action
        RegisterKeyBind(key, modifiers, function()
            commands[#commands + 1] = { player = index, key = key }
        end)
    end
    bind(Key.F1, function(_, preferences)
        preferences.coordinates = not preferences.coordinates
    end)
    bind(Key.F2, function(_, preferences)
        preferences.checklist = not preferences.checklist
    end)
    bind(Key.F3, function(_, preferences)
        preferences.compass = not preferences.compass
    end)
    bind(Key.F4, function(_, preferences)
        preferences.sort_by_type = not preferences.sort_by_type
    end)
    bind(Key.F5, move_to_target)
    bind(Key.F6, function()
        if teleport:return_player(index) then
            warmup_ticks = 5
            needs_refresh = true
        end
    end)
    bind(Key.F8, function()
        refresh(true)
        log("Loaded targets refreshed (full discovery scan).")
    end)
    bind(Key.F10, function(player)
        local row = targets:next(player)
        log(target_text(player, row, "MANUAL"))
    end)
    bind(Key.F12, function(player)
        targets:auto(index)
        log(target_text(player, targets:select(player)))
    end)
end

RegisterLoadMapPreHook(function()
    -- This hook precedes destruction. Do not inspect or modify native objects here.
    loading_map = true
    commands = {}
end)
RegisterLoadMapPostHook(function()
    -- Load-map callbacks only invalidate queued input; no UObject or HUD access here.
    commands = {}
    map_changed = true
    loading_map = false
end)
LoopInGameThreadWithDelay(200, function()
    if loading_map then
        commands = {}
        return
    end
    ticks = ticks + 1
    if map_changed then
        reset_world()
        map_changed = false
    end
    local world = sync_world()
    if settle_ticks > 0 then
        settle_ticks = settle_ticks - 1
        commands = {}
        return
    end
    if not world then
        commands = {}
        return
    end
    if recover_hud then
        if #Runtime.players() == 0 then
            commands = {}
            return
        end
        for _, overlay in pairs(overlays) do
            overlay:recover()
        end
        recover_hud = false
    end
    if warmup_ticks > 0 then
        warmup_ticks = warmup_ticks - 1
    end
    local wants_targets = false
    for _, preferences in pairs(states) do
        wants_targets = wants_targets or preferences.checklist or preferences.compass
    end
    for _, command in ipairs(commands) do
        wants_targets = wants_targets
            or command.key == Key.F2
            or command.key == Key.F3
            or command.key == Key.F5
            or command.key == Key.F8
            or command.key == Key.F10
            or command.key == Key.F12
    end
    if
        world
        and wants_targets
        and (needs_refresh or ticks % ScanTicks == 0 or warmup_ticks == 5 or warmup_ticks == 1)
    then
        refresh()
    end
    if pending_restores > 0 and ticks % 5 == 0 then
        pending_restores = RenderState.restore()
    end
    local pending = commands
    commands = {}
    if not world then
        return
    end
    for _, command in ipairs(pending) do
        local player = local_player(command.player)
        if player and not (warmup_ticks > 0 and (command.key == Key.F5 or command.key == Key.F10)) then
            log(string.format("P%d key %s begin", command.player, tostring(command.key)))
            actions[command.player][command.key](player, state(command.player))
            if loading_map or map_changed then
                return
            end
            update_overlay(command.player)
            log(string.format("P%d key %s done", command.player, tostring(command.key)))
        else
            log(string.format("P%d: waiting for the local player.", command.player))
        end
    end
    local players = Runtime.players()
    for _, overlay in pairs(overlays) do
        overlay:update(players, world)
    end
end)
log(
    "Loaded. Ctrl: P1; Ctrl+Shift: P2. F1 coordinates, F2 checklist, F3 compass, F4 sort, F5 TP, F6 return, F8 refresh, F10 next, F12 auto."
)
