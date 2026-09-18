load_mod("POCCoordinates")
load_mod("POCCompass")
keys["CTRL+F1"]()
keys["CTRL+F3"]()
for _, layout in ipairs(layouts) do
    assert(#layout.OverlayContent.children == 1)
    assert(#layout.OverlayContent.children[1].children == 2, "Both overlays must coexist")
end
keys["CTRL+F1"]()
assert(#layouts[1].OverlayContent.children[1].children == 1, "Hiding POCCoordinates must retain POCCompass")
keys["CTRL+F1"]()
reload()
load_mod("ModKit")
for _, layout in ipairs(layouts) do
    assert(#layout.OverlayContent.children[1].children == 0)
end
load_mod("POCCoordinates")
load_mod("POCCompass")
keys["CTRL+F1"]()
keys["CTRL+F3"]()
local old = layouts[1]
old.valid = false
make_layout(1)
tick(150, 5)
tick(200, 5)
assert(#layouts[1].OverlayContent.children[1].children == 2, "Recreated HUD should recover automatically")
assert(#old.OverlayContent.children[1].children == 0, "Stale HUD should be cleaned")
-- First-upgrade cleanup targets only the two legacy mod text signatures.
local legacy = object("TextBlock", "Anonymous", layouts[1].WidgetTree)
legacy:SetText(FText("COORDINATES PLAYER 1\nPosition test"))
local game_text = object("TextBlock", "GameText", layouts[1].WidgetTree)
game_text:SetText(FText("Native quest text"))
local panel = layouts[1].OverlayContent.children[1]
panel:AddChild(legacy)
panel:AddChild(game_text)
require("WMOverlay").cleanup("Coordinates")
assert(legacy.parent == nil)
assert(game_text.parent == panel, "Native game widgets must be preserved")
