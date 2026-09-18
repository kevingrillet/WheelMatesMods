local first = gear("First")
first.Sphere.bRenderCustomDepth = true
first.Sphere.CustomDepthStencilValue = 42
load_mod("WallHack")
keys.F4()
assert(first.StaticMesh.bRenderCustomDepth and first.StaticMesh.CustomDepthStencilValue == 1)
local second = gear("Streamed")
tick(1000)
assert(second.StaticMesh.bRenderCustomDepth, "Include newly streamed actors")
reload()
load_mod("ModKit") -- WallHack may be disabled in the new manifest.
assert(not first.StaticMesh.bRenderCustomDepth and first.StaticMesh.CustomDepthStencilValue == 7)
assert(first.Sphere.bRenderCustomDepth and first.Sphere.CustomDepthStencilValue == 42)
assert(not second.StaticMesh.bRenderCustomDepth)
load_mod("WallHack")
first.StaticMesh.stencil_error = true
keys.F4()
assert(first.StaticMesh.bRenderCustomDepth)
keys.F4()
first.StaticMesh.stencil_error = false
tick(1000)
assert(
    not first.StaticMesh.bRenderCustomDepth and first.StaticMesh.CustomDepthStencilValue == 7,
    "Retry restoration after a partial setter failure"
)
-- An object recreated at the same path is not the original component.
local state = require("WMRenderState")
state.capture(first.StaticMesh)
first.StaticMesh.valid = false
local replacement = object("StaticMeshComponent", "StaticMesh", first)
replacement.bRenderCustomDepth, replacement.CustomDepthStencilValue = true, 99
state.restore()
assert(replacement.CustomDepthStencilValue == 99)
