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
    local root = StaticConstructObject(class, tree, FName(root_name))
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

function M.new(module, render)
    local self = { enabled = false, entries = {}, ticks = 0 }
    local function remove(entry)
        if Runtime.valid(entry.text) then
            entry.text:RemoveFromParent()
        end
    end

    function self:reconcile()
        local wanted, players = {}, Runtime.players()
        local world = Runtime.world_id()
        Runtime.each(FindAllOf("WBP_PlayerHUDLayout_Split_C"), function(layout)
            if not Runtime.in_world(layout, world) then
                return
            end
            local controller = layout:GetOwningPlayer()
            for _, player in ipairs(players) do
                if Runtime.identity(controller) == Runtime.identity(player.controller) then
                    wanted[Runtime.identity(layout)] = { layout = layout, player = player }
                    break
                end
            end
        end)
        for id, entry in pairs(self.entries) do
            if
                not wanted[id]
                or not Runtime.valid(entry.text)
                or not Runtime.valid(entry.text:GetParent())
                or not Runtime.valid(entry.root)
                or not Runtime.valid(entry.root:GetParent())
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
                    text = StaticConstructObject(
                        class,
                        Runtime.unwrap(target.layout.WidgetTree),
                        FName("WheelMatesMods_" .. module .. "_" .. target.player.index)
                    )
                    if not Runtime.valid(text) then
                        return
                    end
                    local slot = root:AddChildToVerticalBox(text)
                    slot:SetPadding({ Left = 8, Top = 4, Right = 8, Bottom = 4 })
                    text:SetRenderScale({ X = 0.65, Y = 0.65 })
                    text:SetVisibility(3) -- HitTestInvisible
                    text:SetText(FText(render(target.player)))
                    self.entries[id] =
                        { text = text, root = root, controller_id = Runtime.identity(target.player.controller) }
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

    function self:toggle()
        self.enabled = not self.enabled
        if self.enabled then
            self:reconcile()
        else
            for _, entry in pairs(self.entries) do
                remove(entry)
            end
            self.entries = {}
            M.cleanup(module)
        end
        print(string.format("[%s] Overlay %s.\n", module, self.enabled and "enabled" or "disabled"))
    end

    function self:update()
        if not self.enabled then
            return
        end
        self.ticks = self.ticks + 1
        if self.ticks % 5 == 0 then
            self:reconcile()
        end
        local players = {}
        for _, player in ipairs(Runtime.players()) do
            players[Runtime.identity(player.controller)] = player
        end
        for _, entry in pairs(self.entries) do
            local player = players[entry.controller_id]
            if player and Runtime.valid(entry.text) then
                entry.text:SetText(FText(render(player)))
            end
        end
    end

    ExecuteInGameThread(function()
        M.cleanup(module)
    end)
    return self
end

return M
