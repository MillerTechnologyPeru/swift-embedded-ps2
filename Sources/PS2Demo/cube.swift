// PS2Demo/Sources/PS2Demo/cube.swift
//
// 3D Rotating Cube — all rendering logic in Swift (Float32)
// C types imported via CPS2 clang module map
// FFI calls go through WASM imports → w2c2 → C host glue (glue.c)

import CPS2

// ---------------------------------------------------------------------------
// GS handle (PS2 address space — NOT a WASM pointer)
// ---------------------------------------------------------------------------

typealias GSHandle = UInt32

// ---------------------------------------------------------------------------
// FFI Bindings (WASM imports → w2c2 → C host functions in glue.c)
// ---------------------------------------------------------------------------

@_extern(wasm, module: "ps2", name: "gsKit_flip_screen")
@_extern(c)
func ps2_gsKit_flip_screen()

@_extern(wasm, module: "ps2", name: "gsKit_global_get")
@_extern(c)
func ps2_gsKit_global_get() -> GSHandle

@_extern(wasm, module: "ps2", name: "gsKit_global_get_width")
@_extern(c)
func ps2_gsKit_global_get_width(_ gs: GSHandle) -> Int32

@_extern(wasm, module: "ps2", name: "gsKit_global_get_height")
@_extern(c)
func ps2_gsKit_global_get_height(_ gs: GSHandle) -> Int32

@_extern(wasm, module: "ps2", name: "gsKit_global_get_psmz")
@_extern(c)
func ps2_gsKit_global_get_psmz(_ gs: GSHandle) -> Int32

@_extern(wasm, module: "ps2", name: "gsKit_global_get_zbuffering")
@_extern(c)
func ps2_gsKit_global_get_zbuffering(_ gs: GSHandle) -> Int32

@_extern(wasm, module: "ps2", name: "gsKit_global_set_primaaenable")
@_extern(c)
func ps2_gsKit_global_set_primaaenable(_ gs: GSHandle, _ value: Int32)

@_extern(wasm, module: "ps2", name: "gsKit_set_test")
@_extern(c)
func ps2_gsKit_set_test(_ gs: GSHandle, _ test: Int32)

@_extern(wasm, module: "ps2", name: "gsKit_clear")
@_extern(c)
func ps2_gsKit_clear(_ gs: GSHandle, _ color: UInt64)

@_extern(wasm, module: "ps2", name: "gsKit_prim_list_triangle_gouraud_3d")
@_extern(c)
func ps2_gsKit_prim_list_triangle_gouraud_3d(
    _ gs: GSHandle, _ count: Int32, _ vertices: UnsafeRawPointer
)

@_extern(wasm, module: "ps2", name: "create_view_screen")
@_extern(c)
func ps2_create_view_screen(
    _ matrix: UnsafeMutableRawPointer,
    _ aspect: Float32, _ left: Float32, _ right: Float32,
    _ top: Float32, _ bottom: Float32,
    _ near: Float32, _ far: Float32
)

@_extern(wasm, module: "ps2", name: "create_local_world")
@_extern(c)
func ps2_create_local_world(
    _ matrix: UnsafeMutableRawPointer,
    _ position: UnsafeRawPointer,
    _ rotation: UnsafeRawPointer
)

@_extern(wasm, module: "ps2", name: "create_world_view")
@_extern(c)
func ps2_create_world_view(
    _ matrix: UnsafeMutableRawPointer,
    _ position: UnsafeRawPointer,
    _ rotation: UnsafeRawPointer
)

@_extern(wasm, module: "ps2", name: "create_local_screen")
@_extern(c)
func ps2_create_local_screen(
    _ result: UnsafeMutableRawPointer,
    _ local_world: UnsafeRawPointer,
    _ world_view: UnsafeRawPointer,
    _ view_screen: UnsafeRawPointer
)

@_extern(wasm, module: "ps2", name: "calculate_vertices")
@_extern(c)
func ps2_calculate_vertices(
    _ output: UnsafeMutableRawPointer,
    _ count: Int32,
    _ input: UnsafeRawPointer,
    _ matrix: UnsafeRawPointer
)

@_extern(wasm, module: "ps2", name: "draw_convert_rgbq")
@_extern(c)
func ps2_draw_convert_rgbq(
    _ colors: UnsafeMutableRawPointer,
    _ count: Int32,
    _ vertices: UnsafeRawPointer,
    _ colour_f: UnsafeRawPointer,
    _ q: Int32
)

@_extern(wasm, module: "ps2", name: "color_to_rgbaq")
@_extern(c)
func ps2_color_to_rgbaq(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8, _ q: Float32) -> UInt64

@_extern(wasm, module: "ps2", name: "vertex_to_xyz2")
@_extern(c)
func ps2_vertex_to_xyz2(_ gs: GSHandle, _ x: Float32, _ y: Float32, _ z: Float32) -> UInt64

// ---------------------------------------------------------------------------
// gsKit_convert_xyz (Swift implementation)
// ---------------------------------------------------------------------------

func gsKit_convert_xyz(
    output: UnsafeMutablePointer<vertex_f_t>,
    gs: GSHandle,
    count: Int32,
    vertices: UnsafePointer<vertex_f_t>
) -> Int32 {
    let psmz = ps2_gsKit_global_get_psmz(gs)
    var z: Int32 = 0
    var max_z: UInt32 = 0

    switch psmz {
    case 32: z = 32
    case 24: z = 24
    case 16, 17: z = 16
    default: return -1
    }

    let center_x: Float32 = Float32(ps2_gsKit_global_get_width(gs)) / 2.0
    let center_y: Float32 = Float32(ps2_gsKit_global_get_height(gs)) / 2.0
    max_z = 1 << (z - 1)

    for i in 0..<Int(count) {
        output[i].x = (vertices[i].x + 1.0) * center_x
        output[i].y = (vertices[i].y + 1.0) * center_y
        output[i].z = (vertices[i].z + 1.0) * Float32(max_z)
    }
    return 0
}

// ---------------------------------------------------------------------------
// Mesh Data (static globals — compile-time constants)
// ---------------------------------------------------------------------------

let VERTEX_COUNT: Int = 24
let POINT_COUNT: Int = 36

var cube_vertices: [VECTOR] = [
    VECTOR(x: 10, y: 10, z: 10, w: 1),
    VECTOR(x: 10, y: 10, z: -10, w: 1),
    VECTOR(x: 10, y: -10, z: 10, w: 1),
    VECTOR(x: 10, y: -10, z: -10, w: 1),
    VECTOR(x: -10, y: 10, z: 10, w: 1),
    VECTOR(x: -10, y: 10, z: -10, w: 1),
    VECTOR(x: -10, y: -10, z: 10, w: 1),
    VECTOR(x: -10, y: -10, z: -10, w: 1),
    VECTOR(x: -10, y: 10, z: 10, w: 1),
    VECTOR(x: 10, y: 10, z: 10, w: 1),
    VECTOR(x: -10, y: 10, z: -10, w: 1),
    VECTOR(x: 10, y: 10, z: -10, w: 1),
    VECTOR(x: -10, y: -10, z: 10, w: 1),
    VECTOR(x: 10, y: -10, z: 10, w: 1),
    VECTOR(x: -10, y: -10, z: -10, w: 1),
    VECTOR(x: 10, y: -10, z: -10, w: 1),
    VECTOR(x: -10, y: 10, z: 10, w: 1),
    VECTOR(x: 10, y: 10, z: 10, w: 1),
    VECTOR(x: -10, y: -10, z: 10, w: 1),
    VECTOR(x: 10, y: -10, z: 10, w: 1),
    VECTOR(x: -10, y: 10, z: -10, w: 1),
    VECTOR(x: 10, y: 10, z: -10, w: 1),
    VECTOR(x: -10, y: -10, z: -10, w: 1),
    VECTOR(x: 10, y: -10, z: -10, w: 1),
]

var cube_colours: [VECTOR] = [
    VECTOR(x: 1, y: 0, z: 0, w: 1),
    VECTOR(x: 1, y: 0, z: 0, w: 1),
    VECTOR(x: 1, y: 0, z: 0, w: 1),
    VECTOR(x: 1, y: 0, z: 0, w: 1),
    VECTOR(x: 1, y: 0, z: 0, w: 1),
    VECTOR(x: 1, y: 0, z: 0, w: 1),
    VECTOR(x: 1, y: 0, z: 0, w: 1),
    VECTOR(x: 1, y: 0, z: 0, w: 1),
    VECTOR(x: 0, y: 1, z: 0, w: 1),
    VECTOR(x: 0, y: 1, z: 0, w: 1),
    VECTOR(x: 0, y: 1, z: 0, w: 1),
    VECTOR(x: 0, y: 1, z: 0, w: 1),
    VECTOR(x: 0, y: 1, z: 0, w: 1),
    VECTOR(x: 0, y: 1, z: 0, w: 1),
    VECTOR(x: 0, y: 1, z: 0, w: 1),
    VECTOR(x: 0, y: 1, z: 0, w: 1),
    VECTOR(x: 0, y: 0, z: 1, w: 1),
    VECTOR(x: 0, y: 0, z: 1, w: 1),
    VECTOR(x: 0, y: 0, z: 1, w: 1),
    VECTOR(x: 0, y: 0, z: 1, w: 1),
    VECTOR(x: 0, y: 0, z: 1, w: 1),
    VECTOR(x: 0, y: 0, z: 1, w: 1),
    VECTOR(x: 0, y: 0, z: 1, w: 1),
    VECTOR(x: 0, y: 0, z: 1, w: 1),
]

let cube_points: [Int32] = [
    0, 1, 2,  1, 2, 3,
    4, 5, 6,  5, 6, 7,
    8, 9, 10, 9, 10, 11,
    12, 13, 14, 13, 14, 15,
    16, 17, 18, 17, 18, 19,
    20, 21, 22, 21, 22, 23
]

// ---------------------------------------------------------------------------
// Mutable Graphics State
// ---------------------------------------------------------------------------

var g_object_rotation = VECTOR(x: 0, y: 0, z: 0, w: 1)

var blackRgbaQ: UInt64 {
    0x0000000080000000
}

// ---------------------------------------------------------------------------
// Exposed Swift functions
// ---------------------------------------------------------------------------

@_expose(wasm, "gs_init")
@_cdecl("gs_init")
func gs_init() {
    g_object_rotation = VECTOR(x: 0, y: 0, z: 0, w: 1)
}

@_expose(wasm, "gs_flip_screen")
@_cdecl("gs_flip_screen")
func gs_flip_screen() {
    ps2_gsKit_flip_screen()
}

@_expose(wasm, "gs_render_cube")
@_cdecl("gs_render_cube")
func gs_render_cube() {
    let gs = ps2_gsKit_global_get()
    let n = POINT_COUNT

    // Stack-local working buffers (live in WASM linear memory)
    var c_verts: [VECTOR] = Array(repeating: VECTOR(x: 0, y: 0, z: 0, w: 0), count: n)
    var c_colours: [VECTOR] = Array(repeating: VECTOR(x: 0, y: 0, z: 0, w: 0), count: n)
    var temp_verts: [VECTOR] = Array(repeating: VECTOR(x: 0, y: 0, z: 0, w: 0), count: n)
    var screen_verts: [vertex_f_t] = Array(repeating: vertex_f_t(x: 0, y: 0, z: 0), count: n)
    var colors: [color_t] = Array(repeating: color_t(r: 0, g: 0, b: 0, a: 0), count: n)
    var gs_vertices: [GSPRIMPOINT] = Array(
        repeating: GSPRIMPOINT(rgbaq: 0, xyz2: 0, uv: 0), count: n)

    // Matrices
    var local_world = MATRIX()
    var world_view = MATRIX()
    var view_screen = MATRIX()
    var local_screen = MATRIX()

    // Camera / object transforms (constant per frame)
    let object_position = VECTOR(x: 0, y: 0, z: 0, w: 1)
    let camera_position = VECTOR(x: 0, y: 0, z: 100, w: 1)
    let camera_rotation = VECTOR(x: 0, y: 0, z: 0, w: 1)

    // Expand indexed mesh into per-triangle arrays
    for i in 0..<n {
        let vi = Int(cube_points[i])
        c_verts[i] = cube_vertices[vi]
        c_colours[i] = cube_colours[vi]
    }

    // Projection
    withUnsafeMutableBytes(of: &view_screen) { m in
        ps2_create_view_screen(m.baseAddress!, 4.0/3.0, -0.5, 0.5, -0.5, 0.5, 1.0, 2000.0)
    }

    if ps2_gsKit_global_get_zbuffering(gs) != 0 {
        ps2_gsKit_set_test(gs, 1)
    }
    ps2_gsKit_global_set_primaaenable(gs, 1)

    // Spin the cube
    g_object_rotation.x += 0.008
    g_object_rotation.y += 0.012

    // Model → World → View → Screen
    withUnsafeMutableBytes(of: &object_position) { pos in
        withUnsafeMutableBytes(of: &g_object_rotation) { rot in
            withUnsafeMutableBytes(of: &local_world) { m in
                ps2_create_local_world(m.baseAddress!, pos.baseAddress!, rot.baseAddress!)
            }
        }
    }

    withUnsafeMutableBytes(of: &camera_position) { pos in
        withUnsafeMutableBytes(of: &camera_rotation) { rot in
            withUnsafeMutableBytes(of: &world_view) { m in
                ps2_create_world_view(m.baseAddress!, pos.baseAddress!, rot.baseAddress!)
            }
        }
    }

    withUnsafeMutableBytes(of: &local_world) { lw in
        withUnsafeMutableBytes(of: &world_view) { wv in
            withUnsafeMutableBytes(of: &view_screen) { vs in
                withUnsafeMutableBytes(of: &local_screen) { ls in
                    ps2_create_local_screen(ls.baseAddress!, lw.baseAddress!, wv.baseAddress!, vs.baseAddress!)
                }
            }
        }
    }

    // Transform vertices through the combined matrix
    c_verts.withUnsafeMutableBufferPointer { cv in
        withUnsafeMutableBytes(of: &local_screen) { ls in
            temp_verts.withUnsafeMutableBufferPointer { tv in
                ps2_calculate_vertices(
                    UnsafeMutableRawPointer(tv.baseAddress!),
                    Int32(n),
                    UnsafeRawPointer(cv.baseAddress!),
                    ls.baseAddress!
                )
            }
        }
    }

    // Normalised → screen pixel coords (Swift)
    temp_verts.withUnsafeBufferPointer { tv in
        screen_verts.withUnsafeMutableBufferPointer { sv in
            _ = gsKit_convert_xyz(
                output: sv.baseAddress!,
                gs: gs,
                count: Int32(n),
                vertices: tv.baseAddress!
            )
        }
    }

    // Convert float colours to GS RGBAQ
    temp_verts.withUnsafeBufferPointer { tv in
        c_colours.withUnsafeBufferPointer { cc in
            colors.withUnsafeMutableBufferPointer { col in
                ps2_draw_convert_rgbq(
                    UnsafeMutableRawPointer(col.baseAddress!),
                    Int32(n),
                    UnsafeRawPointer(tv.baseAddress!),
                    UnsafeRawPointer(cc.baseAddress!),
                    0x80
                )
            }
        }
    }

    // Build GS primitive vertex list
    for i in 0..<n {
        gs_vertices[i].rgbaq = ps2_color_to_rgbaq(colors[i].r, colors[i].g, colors[i].b, colors[i].a, 0.0)
        gs_vertices[i].xyz2 = ps2_vertex_to_xyz2(gs, screen_verts[i].x, screen_verts[i].y, screen_verts[i].z)
        gs_vertices[i].uv = 0
    }

    // Draw
    ps2_gsKit_clear(gs, blackRgbaQ)
    gs_vertices.withUnsafeBufferPointer { gv in
        ps2_gsKit_prim_list_triangle_gouraud_3d(gs, Int32(n), UnsafeRawPointer(gv.baseAddress!))
    }
}
