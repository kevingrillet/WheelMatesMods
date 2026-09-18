-- Resolve workshop helpers even when UE4SS loads this mod from an additional ModsFolderPaths entry.
local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
local mods_root = assert(source:match("^(.*)/[^/]+/[Ss]cripts/main%.lua$"), "Cannot resolve workshop mods directory")
package.path = mods_root .. "/shared/?/?.lua;" .. package.path

local Runtime = require("WMRuntime")
local RenderState = require("WMRenderState")
local enabled = false
local applied = {}

local function log(message)
    print("[POCWallHack] " .. message .. "\n")
end

local function refresh()
    local present = {}
    for _, gear in ipairs(Runtime.gears()) do
        -- Both fields are declared by BP_Collectable_OutlineBubble_C in the jmap.
        for _, field in ipairs({ "StaticMesh", "Sphere" }) do
            local component = Runtime.unwrap(gear[field])
            if Runtime.valid(component) then
                local id = Runtime.identity(component)
                present[id] = true
                if not applied[id] then
                    local ok, err = pcall(function()
                        RenderState.capture(component)
                        component:SetRenderCustomDepth(true)
                        component:SetCustomDepthStencilValue(1)
                    end)
                    if ok then
                        applied[id] = true
                    else
                        log("Component update failed: " .. tostring(err))
                    end
                end
            end
        end
    end
    for id in pairs(applied) do
        if not present[id] then
            applied[id] = nil
        end
    end
    RenderState.prune()
end

ExecuteInGameThread(function()
    local pending = RenderState.restore()
    if pending > 0 then
        log("Some previous render states could not yet be restored; will retry.")
    end
end)

RegisterKeyBind(Key.F4, { ModifierKey.CONTROL }, function()
    ExecuteInGameThread(function()
        if enabled then
            enabled = false
            applied = {}
            local pending = RenderState.restore()
            log("Disabled; pending restorations: " .. pending)
        else
            if RenderState.restore() > 0 then
                log("Activation deferred until previous render states are restored.")
                return
            end
            enabled = true
            refresh()
            log("Custom Depth enabled; newly loaded Gears will also be included.")
        end
    end)
end)

LoopInGameThreadWithDelay(1000, function()
    if enabled then
        refresh()
    else
        RenderState.restore()
    end
end)
log("Loaded (WIP). Ctrl+F4 toggles Gear Custom Depth; visible through-wall rendering is not yet validated.")
