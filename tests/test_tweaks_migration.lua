local target = gear("Target")
load_mod("POCCoordinates")
load_mod("POCCompass")
load_mod("POCWallHack")
keys["CTRL+F1"]()
keys["CTRL+F3"]()
keys["CTRL+F4"]()
assert(target.StaticMesh.bRenderCustomDepth)
reload()
target.StaticMesh.stencil_error = true
load_mod("Tweaks")
tick(200, 4)
local function press(chord)
    keys[chord]()
    tick(200)
end
for _, layout in ipairs(layouts) do
    assert(#layout.OverlayContent.children[1].children == 0, "Tweaks retires both POC overlays")
end
target.StaticMesh.stencil_error = false
tick(200, 5)
assert(
    not target.StaticMesh.bRenderCustomDepth and target.StaticMesh.CustomDepthStencilValue == 7,
    "Tweaks retries pending render restoration without enabling WallHack"
)
-- The selected row's page remains reachable when more than ten targets are loaded.
target.valid = false
for index = 1, 12 do
    local entry = gear(string.format("Target%02d", index))
    entry.location = { X = index * 100, Y = 0, Z = 0 }
end
press("CTRL+F8")
press("CTRL+F2")
local function displayed()
    return layouts[1].OverlayContent.children[1].children[1]:GetText():ToString()
end
assert(displayed():find("1-10", 1, true))
for _ = 1, 10 do
    press("CTRL+F10")
end
assert(displayed():find("11-12", 1, true), "Table follows selected target onto its next page")
local marked = 0
for line in displayed():gmatch("[^\n]+") do
    if line:sub(1, 1) == ">" then
        marked = marked + 1
    end
end
assert(marked == 1, "Selected target is visible exactly once")
