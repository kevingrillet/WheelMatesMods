local Runtime = require("WMRuntime")
local UEHelpers = require("UEHelpers")
local M = {}

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
    local entry = Runtime.unwrap(value)
    local ok, tag_name = pcall(function()
        return entry.TagName
    end)
    return ok and value_text(tag_name) or value_text(entry)
end

--- Builds a set of narrative item tags already saved for the current player.
local function collected_narrative_tags()
    local collected = {}
    local instance = UEHelpers.GetGameInstance()
    local active_save
    Runtime.each(FindAllOf("VehicleSaveGameSubsystem"), function(subsystem)
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

-- A fresh loaded-object snapshot. Consumers own refresh cadence and presentation.
-- Unknown completion must never become Missing; mini-games remain Loaded only.
function M.scan()
    local result = { gears = {}, narrative = {}, minigames = {}, narrative_loaded = 0 }
    Runtime.each(FindAllOf("MinigameCollectableComponent"), function(component)
        if not Runtime.valid(component) then
            return
        end
        local owner = component:GetOwner()
        if not Runtime.valid(owner) then
            return
        end
        local ok, tag = pcall(function()
            return component.EntryPointTagGuest
        end)
        local label = ok and gameplay_tag_text(tag) or "<unknown>"
        label = label:gsub("Minigame%.", ""):gsub("%.Entry%.Guest", "")
        result.minigames[#result.minigames + 1] =
            { actor = owner, type = "Mini-game", status = "Loaded", label = label }
    end)
    for index, actor in ipairs(Runtime.gears()) do
        result.gears[#result.gears + 1] =
            { actor = actor, type = "Gear", status = "Missing", label = string.format("Loaded Gear %d", index) }
    end
    local collected = collected_narrative_tags()
    result.narrative_known = collected ~= nil
    if not result.narrative_known then
        return result
    end
    Runtime.each(FindAllOf("Actor"), function(actor)
        if not Runtime.valid(actor) then
            return
        end
        local ok, tag = pcall(function()
            return actor.NarrativeTagId
        end)
        if not ok or tag == nil then
            return
        end
        local text = gameplay_tag_text(tag)
        if text:sub(1, 10) ~= "Narrative." and text:sub(1, 12) ~= "Collectable." then
            return
        end
        result.narrative_loaded = result.narrative_loaded + 1
        if not collected[text] then
            result.narrative[#result.narrative + 1] =
                { actor = actor, type = "Narrative", status = "Missing", label = text }
        end
    end)
    return result
end

return M
