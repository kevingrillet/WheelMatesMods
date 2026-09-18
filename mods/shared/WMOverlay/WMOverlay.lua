local Runtime = require("WMRuntime")
local M = {}
local root_name = "WheelMatesMods_OverlayRoot"

local function name(object)
    return object:GetFName():ToString()
end

-- Also migrate the anonymous TextBlocks made by the original prototypes.
-- Restrict this to our exact text prefixes inside the game's split HUD tree.
local function owned(text, module)
    local prefix = "WheelMatesMods_" .. module .. "_"
    if name(text):sub(1, #prefix) == prefix then
        return true
    end
    if module ~= "Coordinates" and module ~= "Compass" then
        return false
    end
    if not text:GetFullName():find("WBP_PlayerHUDLayout_Split", 1, true) then
        return false
    end
    local value = text:GetText():ToString()
    if module == "Coordinates" then
        return value:match("^COORDINATES PLAYER %d+\nPosition") ~= nil
    end
    return module == "Compass" and value:match("^COMPASS P%d+\n") ~= nil
end

function M.cleanup(module)
    Runtime.each(FindAllOf("TextBlock"), function(text)
        if Runtime.valid(text) then
            local ok, matches = pcall(owned, text, module)
            if ok and matches then
                text:RemoveFromParent()
            end
        end
    end)
end

-- StaticConstructObject with an already-live name can replace the native object.
-- Reuse it instead; Lua mocks used to hide this by returning the old instance.
local function existing(class, tree, widget_name)
    local found
    local tree_id = Runtime.identity(tree)
    Runtime.each(FindAllOf(class), function(widget)
        if Runtime.valid(widget) and name(widget) == widget_name and Runtime.identity(widget:GetOuter()) == tree_id then
            found = widget
        end
    end)
    return found
end

local function container(layout)
    local content = Runtime.unwrap(layout.OverlayContent)
    local tree = Runtime.unwrap(layout.WidgetTree)
    if not Runtime.valid(content) or not Runtime.valid(tree) then
        return nil
    end
    local child = content:GetChildAt(0)
    if Runtime.valid(child) and name(child) == root_name then
        return child
    end
    local class = StaticFindObject("Class /Script/UMG.VerticalBox")
    if not Runtime.valid(class) then
        return nil
    end
    local root = existing("VerticalBox", tree, root_name) or StaticConstructObject(class, tree, FName(root_name))
    if not Runtime.valid(root) then
        return nil
    end
    -- OverlayContent is a NamedSlot (one child), not a multi-child Overlay.
    -- Preserve unrelated content when installing the common multi-child root.
    if Runtime.valid(child) then
        child:RemoveFromParent()
    end
    content:AddChild(root)
    if Runtime.valid(child) then
        root:AddChildToVerticalBox(child)
    end
    root:SetVisibility(4) -- SelfHitTestInvisible: preserve unrelated interactive children.
    return root
end

function M.new(module, render, accepts_player)
    local self = { enabled = false, entries = {}, ticks = 0 }
    local function remove(entry)
        local text = Runtime.resolve(entry.text_ref)
        if text then
            text:RemoveFromParent()
        end
    end

    function self:reconcile(frame_players, frame_world)
        local wanted, players = {}, frame_players or Runtime.players()
        local world = frame_world or Runtime.world_id()
        Runtime.each(FindAllOf("WBP_PlayerHUDLayout_Split_C"), function(layout)
            if not Runtime.in_world(layout, world) then
                return
            end
            local controller = layout:GetOwningPlayer()
            for _, player in ipairs(players) do
                if
                    (not accepts_player or accepts_player(player))
                    and Runtime.identity(controller) == Runtime.identity(player.controller)
                then
                    wanted[Runtime.identity(layout)] = { layout = layout, player = player }
                    break
                end
            end
        end)
        for id, entry in pairs(self.entries) do
            local text, root = Runtime.resolve(entry.text_ref), Runtime.resolve(entry.root_ref)
            if
                not wanted[id]
                or not Runtime.valid(text)
                or not Runtime.valid(text:GetParent())
                or not Runtime.valid(root)
                or not Runtime.valid(root:GetParent())
                or entry.controller_id ~= Runtime.identity(wanted[id].player.controller)
            then
                remove(entry)
                self.entries[id] = nil
            end
        end
        for id, target in pairs(wanted) do
            if not self.entries[id] then
                local text
                local ok, err = pcall(function()
                    local root = container(target.layout)
                    if not Runtime.valid(root) then
                        return
                    end
                    local class = StaticFindObject("Class /Script/UMG.TextBlock")
                    local tree = Runtime.unwrap(target.layout.WidgetTree)
                    local widget_name = "WheelMatesMods_" .. module .. "_" .. target.player.index
                    text = existing("TextBlock", tree, widget_name)
                        or StaticConstructObject(class, tree, FName(widget_name))
                    if not Runtime.valid(text) then
                        return
                    end
                    local slot = root:AddChildToVerticalBox(text)
                    slot:SetPadding({ Left = 8, Top = 4, Right = 8, Bottom = 4 })
                    text:SetRenderScale({ X = 0.65, Y = 0.65 })
                    text:SetVisibility(3) -- HitTestInvisible
                    text:SetText(FText(render(target.player)))
                    self.entries[id] = {
                        text_ref = Runtime.reference(text),
                        root_ref = Runtime.reference(root),
                        controller_id = Runtime.identity(target.player.controller),
                        last_text = nil,
                    }
                end)
                if not ok then
                    if Runtime.valid(text) then
                        text:RemoveFromParent()
                    end
                    print(string.format("[%s] HUD attachment failed: %s\n", module, tostring(err)))
                end
            end
        end
    end

    -- Travel may already have destroyed the old world. Drop scalar references only.
    function self:forget()
        self.entries = {}
        self.ticks = 0
    end

    -- Called only after travel has settled, using freshly enumerated live widgets.
    function self:recover()
        M.cleanup(module)
        self:forget()
    end

    function self:clear()
        for _, entry in pairs(self.entries) do
            remove(entry)
        end
        self.entries = {}
        M.cleanup(module)
    end

    function self:toggle()
        self.enabled = not self.enabled
        if self.enabled then
            self:reconcile()
        else
            self:clear()
        end
        print(string.format("[%s] Overlay %s.\n", module, self.enabled and "enabled" or "disabled"))
    end

    function self:update(frame_players, frame_world)
        if not self.enabled then
            return
        end
        self.ticks = self.ticks + 1
        if self.ticks % (frame_players and 10 or 5) == 0 or next(self.entries) == nil then
            self:reconcile(frame_players, frame_world)
        end
        local players = {}
        for _, player in ipairs(frame_players or Runtime.players()) do
            players[Runtime.identity(player.controller)] = player
        end
        for _, entry in pairs(self.entries) do
            local player = players[entry.controller_id]
            local text = Runtime.resolve(entry.text_ref)
            if player and text then
                local value = render(player)
                if value ~= entry.last_text then
                    text:SetText(FText(value))
                    entry.last_text = value
                end
            end
        end
    end

    ExecuteInGameThread(function()
        M.cleanup(module)
    end)
    return self
end

return M
