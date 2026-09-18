local function press(chord)
    keys[chord]()
    tick(200)
    if chord:find("F5", 1, true) or chord:find("F6", 1, true) then
        tick(200, 5)
    end
end
local a, b = gear("A"), gear("B")
a.location, b.location = { X = 1000, Y = 0, Z = 0 }, { X = 4000, Y = 0, Z = 0 }
pawns[2].location = { X = 4500, Y = 0, Z = 0 }
load_mod("Tweaks")
tick(200, 4)
local function text(index)
    local root = layouts[index].OverlayContent.children[1]
    if not root or #root.children == 0 then
        return ""
    end
    assert(#root.children == 1, "One combined overlay per player")
    return root.children[1]:GetText():ToString()
end
assert(text(1) == "" and text(2) == "", "Starts with all overlays off")
press("CTRL+F1")
assert(text(1):find("P1 XYZ", 1, true) and not text(1):find("\n"), "Compact coordinates are one line")
assert(text(2) == "", "P1 toggle must not show a P2 HUD")
press("CTRL+SHIFT+F3")
assert(text(2):find("P2 AUTO", 1, true) and text(2):find("5 m", 1, true))
assert(queries.BP_Collectable_Gear_C == 1, "Initial catalogue shared by both players")
tick(200, 18)
assert(queries.BP_Collectable_Gear_C == 1)
tick(200)
assert(queries.BP_Collectable_Gear_C == 2, "One shared scan per five seconds")
press("CTRL+F2")
press("CTRL+F3")
assert(text(1):find("TYPE/DIST", 1, true))
press("CTRL+F4")
assert(not text(1):find("TYPE/DIST", 1, true))
press("CTRL+F10")
assert(text(1):find("MANUAL", 1, true))
press("CTRL+F5")
assert(pawns[1].location.X == 3400 and pawns[1].location.Z == 100, "TP uses selected target approach")
assert(pawns[2].moves == nil)
press("CTRL+F6")
assert(pawns[1].location.X == 0 and pawns[1].location.Z == 0)
press("CTRL+F8")
assert(text(1):find("MANUAL", 1, true), "Explicit refresh preserves manual mode")
press("CTRL+F12")
assert(text(1):find("AUTO", 1, true))
press("CTRL+SHIFT+F5")
assert(pawns[2].location.X == 4600, "P2 uses its own nearest target and approach side")
press("CTRL+SHIFT+F6")
assert(pawns[2].location.X == 4500)
-- Hidden HUD must not block teleport/return.
press("CTRL+F1")
press("CTRL+F2")
press("CTRL+F3")
assert(text(1) == "")
press("CTRL+F5")
assert(pawns[1].location.X == 400)
load_map()
tick(200, 16)
local moves = pawns[1].moves
press("CTRL+F6")
assert(pawns[1].moves == moves, "Map hook immediately clears return")
press("CTRL+F3")
assert(text(1):find("AUTO", 1, true))
-- World polling invalidates stale UI and return even without the map hook.
press("CTRL+F5")
world = object("World", "OtherMap")
moves = pawns[1].moves
press("CTRL+F6")
assert(pawns[1].moves == moves)
-- Old native HUDs are owned by the departing world, not dereferenced during travel.
for index = 1, 2 do
    controllers[index].world, pawns[index].world = world, world
    layouts[index].valid = false
    make_layout(index)
end
tick(200, 19)
assert(text(1):find("P1 AUTO", 1, true) and text(2):find("P2 AUTO", 1, true), "New HUDs recover per-player toggles")
a.valid, b.valid = false, false
moves = pawns[1].moves
press("CTRL+F5")
assert(pawns[1].moves == moves, "Missing targets cannot teleport")
assert(text(1):find("No loaded missing target", 1, true))
reload()
load_mod("Tweaks")
tick(200, 4)
assert(text(1) == "" and text(2) == "", "Tweaks cleans its own overlays without ModKit")
press("CTRL+F1")
reload()
load_mod("ModKit")
assert(text(1) == "", "Returning to POCs cleans Tweaks overlays")
