objects, queries, logs, keys, loops, shared = {}, {}, {}, {}, {}, {}
local address = 0
function FName(value)
    return {
        ToString = function()
            return value
        end,
    }
end
FText = FName
function print(value)
    logs[#logs + 1] = value
end
function object(class, name, outer)
    address = address + 1
    local value = { class = class, name = name, outer = outer, address = address, valid = true, children = {} }
    function value:IsValid()
        return self.valid
    end
    function value:GetFName()
        return FName(self.name)
    end
    function value:GetFullName()
        return self.class .. " " .. (self.outer and self.outer:GetFullName() .. ":" or "") .. self.name
    end
    function value:GetAddress()
        return self.address
    end
    function value:GetOuter()
        return self.outer
    end
    function value:GetWorld()
        return self.world or (self.outer and self.outer:GetWorld())
    end
    function value:GetOwningPlayer()
        return self.controller
    end
    function value:GetParent()
        return self.parent
    end
    function value:GetChildAt(index)
        return self.children[index + 1]
    end
    function value:RemoveFromParent()
        if self.parent then
            for i, child in ipairs(self.parent.children) do
                if child == self then
                    table.remove(self.parent.children, i)
                    break
                end
            end
            self.parent = nil
        end
    end
    function value:AddChild(child)
        -- Faithfully model the single-child slot that broke the old overlays.
        if self.class == "NamedSlot" and self.children[1] then
            self.children[1]:RemoveFromParent()
        end
        child:RemoveFromParent()
        self.children[#self.children + 1] = child
        child.parent = self
        return { SetPadding = function() end }
    end
    value.AddChildToVerticalBox = value.AddChild
    function value:SetText(text)
        self.text = text
    end
    function value:GetText()
        return self.text or FText("")
    end
    function value:SetRenderScale() end
    function value:SetVisibility() end
    function value:K2_GetActorLocation()
        return self.location or { X = 0, Y = 0, Z = 0 }
    end
    function value:K2_GetActorRotation()
        return { Pitch = 0, Yaw = 0, Roll = 0 }
    end
    function value:GetVelocity()
        return { X = 0, Y = 0, Z = 0 }
    end
    function value:K2_SetActorLocation(target)
        self.moves = (self.moves or 0) + 1
        if self.move_error then
            error("movement failed")
        end
        if self.move_result == false then
            return false
        end
        self.location = target
        return true
    end
    function value:SetRenderCustomDepth(depth)
        self.bRenderCustomDepth = depth
    end
    function value:SetCustomDepthStencilValue(stencil)
        if self.stencil_error then
            error("stencil failed")
        end
        self.CustomDepthStencilValue = stencil
    end
    objects[#objects + 1] = value
    return value
end
function FindAllOf(class)
    queries[class] = (queries[class] or 0) + 1
    local result = {}
    for _, value in ipairs(objects) do
        if value.valid and (value.class == class or (class == "Actor" and value.actor)) then
            result[#result + 1] = value
        end
    end
    return result
end
function StaticFindObject(path)
    if path:match("^Class /Script/UMG%.") then
        return object("Class", path:match("%.([^%.]+)$"))
    end
    for _, value in ipairs(objects) do
        if value.valid and value:GetFullName() == path then
            return value
        end
    end
end
function StaticConstructObject(class, outer, name)
    local text = name and name:ToString() or "Anonymous"
    for _, value in ipairs(objects) do
        if value.valid and value.class == class.name and value.outer == outer and value.name == text then
            error("Attempted to reconstruct a live named widget: " .. text)
        end
    end
    return object(class.name, text, outer)
end
ModRef = {}
function ModRef:GetSharedVariable(key)
    return shared[key]
end
function ModRef:SetSharedVariable(key, value)
    shared[key] = value
end
Key = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})
ModifierKey = { CONTROL = "CTRL", SHIFT = "SHIFT" }
function RegisterKeyBind(key, modifiers, callback)
    local parts = {}
    for _, modifier in ipairs(modifiers) do
        parts[#parts + 1] = modifier
    end
    table.sort(parts)
    parts[#parts + 1] = key
    local chord = table.concat(parts, "+")
    assert(keys[chord] == nil, "Duplicate keybind: " .. chord)
    keys[chord] = callback
end
function ExecuteInGameThread(callback)
    callback()
end
function LoopInGameThreadWithDelay(delay, callback)
    loops[#loops + 1] = { delay = delay, callback = callback }
end
function RegisterLoadMapPreHook(callback)
    pre_load_map = callback
end
function RegisterLoadMapPostHook(callback)
    load_map = callback
end
function tick(delay, count)
    for _ = 1, count or 1 do
        for _, loop in ipairs(loops) do
            if loop.delay == delay then
                loop.callback()
            end
        end
    end
end
function array(values)
    return {
        ForEach = function(_, fn)
            for i, value in ipairs(values) do
                fn(i, {
                    get = function()
                        return value
                    end,
                })
            end
        end,
    }
end
world = object("World", "Map")
function world:GetWorld()
    return self
end
instance = object("GameInstance", "Session")
instance.world = world
function instance:GetWorld()
    return world
end
players, pawns, controllers, layouts = {}, {}, {}, {}
for index = 1, 2 do
    local player = object("LocalPlayer", "P" .. index, instance)
    local controller = object("PlayerController", "PC" .. index)
    local pawn = object("Pawn", "Car" .. index)
    controller.world, pawn.world = world, world
    player.PlayerController, controller.Pawn = controller, pawn
    players[index], pawns[index], controllers[index] = player, pawn, controller
end
instance.LocalPlayers = array(players)
function make_layout(index)
    local layout = object("WBP_PlayerHUDLayout_Split_C", "HUD" .. index .. "_" .. address)
    layout.world, layout.controller = world, controllers[index]
    layout.WidgetTree = object("WidgetTree", "Tree", layout)
    layout.OverlayContent = object("NamedSlot", "OverlayContent", layout.WidgetTree)
    layouts[index] = layout
    return layout
end
make_layout(1)
make_layout(2)
package.preload.UEHelpers = function()
    return {
        GetWorld = function()
            return world
        end,
        GetGameInstance = function()
            return instance
        end,
    }
end
function gear(name)
    local value = object("BP_Collectable_Gear_C", name)
    value.world, value.actor = world, true
    value.location = { X = 24778.721, Y = -58507.618, Z = 11370.294 }
    for _, field in ipairs({ "StaticMesh", "Sphere" }) do
        local component = object("StaticMeshComponent", field, value)
        component.bRenderCustomDepth, component.CustomDepthStencilValue = false, 7
        value[field] = component
    end
    return value
end
function load_mod(name)
    dofile("mods/" .. name .. "/Scripts/main.lua")
end
function reload()
    keys, loops = {}, {}
    for _, module in ipairs({
        "WMRuntime",
        "WMOverlay",
        "WMRenderState",
        "WMCollectibles",
        "WMNavigation",
        "WMCoordinates",
        "WMTargets",
        "WMTeleport",
    }) do
        package.loaded[module] = nil
    end
end
function contains(text)
    for _, line in ipairs(logs) do
        if line:find(text, 1, true) then
            return true
        end
    end
    return false
end
