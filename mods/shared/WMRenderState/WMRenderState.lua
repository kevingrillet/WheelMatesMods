local Runtime = require("WMRuntime")
local M = {}
local shared_key = "WheelMatesMods.WallHack.RenderState.v1"

-- Shared scalars survive reload. Re-resolve paths rather than retain UObject wrappers.
local function read()
    local result = {}
    for line in (ModRef:GetSharedVariable(shared_key) or ""):gmatch("[^\n]+") do
        local path, address, depth, stencil = line:match("^(.-)\t([^\t]+)\t([01])\t(%d+)$")
        if path then
            result[path] = { address = address, depth = depth == "1", stencil = tonumber(stencil) }
        end
    end
    return result
end

local function write(states)
    local lines = {}
    for path, state in pairs(states) do
        lines[#lines + 1] =
            table.concat({ path, state.address, state.depth and "1" or "0", tostring(state.stencil) }, "\t")
    end
    ModRef:SetSharedVariable(shared_key, table.concat(lines, "\n"))
end

function M.capture(component)
    local states = read()
    local path = component:GetFullName()
    local address = tostring(component:GetAddress())
    if states[path] and states[path].address == address then
        return
    end
    states[path] =
        { address = address, depth = component.bRenderCustomDepth, stencil = component.CustomDepthStencilValue }
    -- Persist before either setter so partial failures remain reversible.
    write(states)
end

function M.restore()
    local states, pending = read(), 0
    for path, state in pairs(states) do
        local ok = pcall(function()
            local component = StaticFindObject(path)
            if Runtime.valid(component) and tostring(component:GetAddress()) == state.address then
                component:SetRenderCustomDepth(state.depth)
                component:SetCustomDepthStencilValue(state.stencil)
            end
        end)
        if ok then
            states[path] = nil
        else
            pending = pending + 1
        end
    end
    write(states)
    return pending
end

function M.prune()
    local states = read()
    for path, state in pairs(states) do
        local component = StaticFindObject(path)
        if not Runtime.valid(component) or tostring(component:GetAddress()) ~= state.address then
            states[path] = nil
        end
    end
    write(states)
end

return M
