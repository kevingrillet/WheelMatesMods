-- Resolve workshop helpers even when UE4SS loads this mod from an additional ModsFolderPaths entry.
local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
local mods_root = assert(source:match("^(.*)/[^/]+/[Ss]cripts/main%.lua$"), "Cannot resolve workshop mods directory")
package.path = mods_root .. "/shared/?/?.lua;" .. package.path

local ModName = "POCCheckList"
local Collectibles = require("WMCollectibles")

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

--- Runs the player-facing, compact and position-oriented checklist.
local function report_checklist()
    log("Compact checklist (read-only)")
    table_header(ChecklistColumns)
    local snapshot = Collectibles.scan()
    local function rows(entries)
        for _, entry in ipairs(entries) do
            table_row(ChecklistColumns, { entry.type, entry.status, entry.label, actor_location_text(entry.actor) })
        end
    end
    rows(snapshot.minigames)
    rows(snapshot.gears)
    if #snapshot.gears > 0 then
        table_row(
            ChecklistColumns,
            { "Gear total", string.format("%d missing", #snapshot.gears), "Loaded in this level", "-" }
        )
    end
    if snapshot.narrative_known then
        rows(snapshot.narrative)
        table_row(ChecklistColumns, {
            "Narrative total",
            string.format("%d missing", #snapshot.narrative),
            string.format("%d loaded", snapshot.narrative_loaded),
            "-",
        })
    else
        table_row(ChecklistColumns, { "Narrative", "Unknown", "Active save unavailable", "Try again after loading" })
    end
    table_border(ChecklistColumns)
    log("Compact checklist complete.")
end

RegisterKeyBind(Key.F2, { ModifierKey.CONTROL }, function()
    ExecuteInGameThread(report_checklist)
end)

log("Loaded. Ctrl+F2: compact missing-item checklist (read-only).")
