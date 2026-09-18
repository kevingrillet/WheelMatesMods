-- Resolve workshop helpers even when UE4SS loads this mod from an additional ModsFolderPaths entry.
local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
local mods_root = assert(source:match("^(.*)/[^/]+/[Ss]cripts/main%.lua$"), "Cannot resolve workshop mods directory")
package.path = mods_root .. "/shared/?/?.lua;" .. package.path

local ModName = "CheckList"
local Runtime = require("WMRuntime")
local UEHelpers = require("UEHelpers")

local ChecklistColumns = {
    { title = "Type", width = 18 },
    { title = "Status", width = 16 },
    { title = "Tag / mini-game", width = 46 },
    { title = "Location", width = 50 },
}

--- Writes one complete and readable CheckList console line.
local function log(message)
    print(string.format("[%s] %s\n", ModName, message))
end

--- Returns true only for a reflected Unreal object that can still be inspected.
local function is_valid(object)
    return object ~= nil and object.IsValid ~= nil and object:IsValid()
end

--- Extracts values held by UE4SS remote-property wrappers.
local function unwrap(value)
    local ok, unwrapped = pcall(function()
        return value:get()
    end)
    return ok and unwrapped or value
end

--- Iterates either a UE4SS container or a plain Lua table returned by FindAllOf.
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

--- Converts a value to safe text for logs and gameplay-tag fields.
local function value_text(value)
    if value == nil then
        return "<none>"
    end
    local ok, text = pcall(function()
        return value:ToString()
    end)
    return ok and tostring(text) or tostring(value)
end

--- Converts a gameplay-tag struct or a plain tag value to readable text.
local function gameplay_tag_text(value)
    local entry = unwrap(value)
    local ok, tag_name = pcall(function()
        return entry.TagName
    end)
    return ok and value_text(tag_name) or value_text(entry)
end

--- Keeps table columns aligned even when Unreal names are unusually long.
local function table_cell(value, width)
    local text = tostring(value or "")
    if #text > width then
        text = string.sub(text, 1, width - 3) .. "..."
    end
    return string.format("%-" .. width .. "s", text)
end

--- Draws one ASCII table row.
local function table_row(columns, values)
    local cells = {}
    for index, column in ipairs(columns) do
        table.insert(cells, table_cell(values[index], column.width))
    end
    log("| " .. table.concat(cells, " | ") .. " |")
end

--- Draws an ASCII table border.
local function table_border(columns)
    local parts = {}
    for _, column in ipairs(columns) do
        table.insert(parts, string.rep("-", column.width + 2))
    end
    log("+" .. table.concat(parts, "+") .. "+")
end

--- Draws a table header with its top and separator borders.
local function table_header(columns)
    table_border(columns)
    local labels = {}
    for _, column in ipairs(columns) do
        table.insert(labels, column.title)
    end
    table_row(columns, labels)
    table_border(columns)
end

--- Formats an actor location consistently for the compact checklist.
local function actor_location_text(actor)
    local ok, location = pcall(function()
        return actor:K2_GetActorLocation()
    end)
    if not ok or location == nil then
        return "<unavailable>"
    end
    return string.format("{X=%.0f, Y=%.0f, Z=%.0f}", location.X, location.Y, location.Z)
end

--- Builds a set of narrative item tags already saved for the current player.
local function collected_narrative_tags()
    local collected = {}
    local instance = UEHelpers.GetGameInstance()
    local active_save
    for_each_object(FindAllOf("VehicleSaveGameSubsystem"), function(subsystem)
        if not Runtime.valid(subsystem) or not Runtime.valid(instance) then
            return
        end
        if Runtime.identity(subsystem:GetOuter()) ~= Runtime.identity(instance) then
            return
        end
        local save = subsystem.CurrentSaveGame
        if Runtime.valid(save) then
            active_save = save
        end
    end)
    if not active_save then
        return nil
    end
    local ok = pcall(function()
        active_save.CollectedNarrativeItems:ForEach(function(key)
            collected[gameplay_tag_text(key)] = true
        end)
    end)
    if not ok then
        return nil
    end
    return collected
end

--- Adds loaded mini-game entry points to the compact result table.
local function report_minigames()
    for_each_object(FindAllOf("MinigameCollectableComponent"), function(component)
        if not is_valid(component) then
            return
        end
        local owner = component:GetOwner()
        if not is_valid(owner) then
            return
        end
        local tag_ok, entry_tag = pcall(function()
            return component.EntryPointTagGuest
        end)
        local identifier = tag_ok and gameplay_tag_text(entry_tag) or "<unknown>"
        identifier = string.gsub(identifier, "Minigame%.", "")
        identifier = string.gsub(identifier, "%.Entry%.Guest", "")
        table_row(ChecklistColumns, { "Mini-game", "Loaded", identifier, actor_location_text(owner) })
    end)
end

--- Adds each currently loaded, therefore uncollected, Gear to the checklist.
local function report_missing_gears()
    local gears = Runtime.gears()
    local count = 0
    for_each_object(gears, function(gear)
        if not is_valid(gear) then
            return
        end
        count = count + 1
        table_row(
            ChecklistColumns,
            { "Gear", "Missing", string.format("Loaded Gear %d", count), actor_location_text(gear) }
        )
    end)
    if count > 0 then
        table_row(ChecklistColumns, { "Gear total", string.format("%d missing", count), "Loaded in this level", "-" })
    end
end

--- Adds only narrative collectibles absent from the saved collection to the table.
local function report_missing_narrative_collectables()
    local collected, loaded, missing = collected_narrative_tags(), 0, 0
    if collected == nil then
        table_row(ChecklistColumns, { "Narrative", "Unknown", "Active save unavailable", "Try again after loading" })
        return
    end
    -- Match the working loaded-object scan: per-actor world identity is not a
    -- validated filter here and rejected the narrative actors in the live game.
    for_each_object(FindAllOf("Actor"), function(actor)
        if not is_valid(actor) then
            return
        end
        local ok, tag = pcall(function()
            return actor.NarrativeTagId
        end)
        if not ok or tag == nil then
            return
        end
        local tag_text = gameplay_tag_text(tag)
        if string.sub(tag_text, 1, 10) ~= "Narrative." and string.sub(tag_text, 1, 12) ~= "Collectable." then
            return
        end
        loaded = loaded + 1
        if not collected[tag_text] then
            missing = missing + 1
            table_row(ChecklistColumns, { "Narrative", "Missing", tag_text, actor_location_text(actor) })
        end
    end)
    table_row(
        ChecklistColumns,
        { "Narrative total", string.format("%d missing", missing), string.format("%d loaded", loaded), "-" }
    )
end

--- Runs the player-facing, compact and position-oriented checklist.
local function report_checklist()
    log("Compact checklist (read-only)")
    table_header(ChecklistColumns)
    report_minigames()
    report_missing_gears()
    report_missing_narrative_collectables()
    table_border(ChecklistColumns)
    log("Compact checklist complete.")
end

RegisterKeyBind(Key.F2, { ModifierKey.CONTROL }, function()
    ExecuteInGameThread(report_checklist)
end)

log("Loaded. Ctrl+F2: compact missing-item checklist (read-only).")
