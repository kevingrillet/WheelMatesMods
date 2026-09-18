local Runtime = require("WMRuntime")
local Collectibles = require("WMCollectibles")
local M = {}

-- Session-scoped identities only: no persistent catalogue or UObject state across maps.
function M.new()
    local self = { entries = {}, selections = {}, narrative_known = false, minigames = {} }

    function self:reset()
        self.entries, self.selections, self.narrative_known, self.minigames = {}, {}, false, {}
    end

    local function state(index)
        if not self.selections[index] then
            self.selections[index] = { mode = "AUTO" }
        end
        return self.selections[index]
    end

    function self:refresh(full)
        local snapshot = Collectibles.scan(full and {} or {
            narrative_classes = { "BP_NarrativeItem_C", "BP_Collectable_Microchip_C" },
        })
        local entries, seen = {}, {}
        self.minigames = {}
        for _, group in ipairs({ snapshot.gears, snapshot.narrative, snapshot.minigames }) do
            for _, item in ipairs(group) do
                local ref = Runtime.reference(item.actor)
                local ok, location = pcall(function()
                    return item.actor:K2_GetActorLocation()
                end)
                if ref and ok and location then
                    local id = ref.path .. "@" .. tostring(ref.address)
                    local entry = {
                        id = id,
                        order = item.type .. ":" .. id,
                        reference = ref,
                        type = item.type,
                        label = item.label,
                        progress = item.progress,
                        location = { X = location.X, Y = location.Y, Z = location.Z },
                    }
                    if item.type == "Mini-game" then
                        self.minigames[#self.minigames + 1] = entry
                    end
                    if not seen[id] and (item.type ~= "Mini-game" or item.progress == "No result") then
                        seen[id] = true
                        entries[#entries + 1] = entry
                    end
                end
            end
        end
        table.sort(entries, function(a, b)
            return a.order < b.order
        end)
        self.entries, self.narrative_known = entries, snapshot.narrative_known
    end

    function self:rows(player, sort_by_type)
        local rows = {}
        local origin = player.pawn:K2_GetActorLocation()
        for _, entry in ipairs(self.entries) do
            -- Plain scalar snapshot: no cached actor userdata is dereferenced by the HUD.
            local location = entry.location
            local dx, dy, dz = location.X - origin.X, location.Y - origin.Y, location.Z - origin.Z
            rows[#rows + 1] = {
                entry = entry,
                delta = {
                    dx = dx,
                    dy = dy,
                    dz = dz,
                    distance_squared = dx * dx + dy * dy + dz * dz,
                },
            }
        end
        table.sort(rows, function(a, b)
            if sort_by_type and a.entry.type ~= b.entry.type then
                return a.entry.type < b.entry.type
            end
            if a.delta.distance_squared ~= b.delta.distance_squared then
                return a.delta.distance_squared < b.delta.distance_squared
            end
            return a.entry.order < b.entry.order
        end)
        return rows
    end

    function self:select(player, rows)
        local selection = state(player.index)
        rows = rows or self:rows(player, false)
        if selection.mode == "AUTO" then
            local first = rows[1]
            selection.id = first and first.entry.id or nil
            selection.order = first and first.entry.order or nil
            return first, selection.mode
        end
        table.sort(rows, function(a, b)
            return a.entry.order < b.entry.order
        end)
        for _, row in ipairs(rows) do
            if row.entry.id == selection.id then
                return row, selection.mode
            end
        end
        -- If the manual target disappeared, continue after its former stable key.
        local next_row = rows[1]
        for _, row in ipairs(rows) do
            if selection.order and row.entry.order > selection.order then
                next_row = row
                break
            end
        end
        selection.id = next_row and next_row.entry.id or nil
        selection.order = next_row and next_row.entry.order or selection.order
        return next_row, selection.mode
    end

    function self:next(player)
        local current = self:select(player)
        local rows = self:rows(player, false)
        table.sort(rows, function(a, b)
            return a.entry.order < b.entry.order
        end)
        local selected = rows[1]
        if current then
            for index, row in ipairs(rows) do
                if row.entry.id == current.entry.id then
                    selected = rows[index % #rows + 1]
                    break
                end
            end
        end
        local selection = state(player.index)
        selection.mode = "MANUAL"
        selection.id = selected and selected.entry.id or nil
        selection.order = selected and selected.entry.order or nil
        return selected
    end

    function self:auto(index)
        self.selections[index] = { mode = "AUTO" }
    end

    return self
end

return M
