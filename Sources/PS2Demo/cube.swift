// PS2Demo/Sources/PS2Demo/cube.swift
//
// 3D Rotating Cube — all rendering logic in Swift (Float32)
// C types imported from PS2SDK headers (via CPS2 clang module)
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
    _ rotation: UnsafeMutableRawPointer
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

// Builds GSPRIMPOINT array from screen_verts + colors and calls
// gsKit_prim_list_triangle_gouraud_3d. Lives in glue.c to keep
// 128-bit gs_rgbaq/gs_xyz2 construction on the PS2-native C side.
@_extern(wasm, module: "ps2", name: "build_and_draw")
@_extern(c)
func ps2_build_and_draw(
    _ gs: GSHandle,
    _ count: Int32,
    _ screen_verts: UnsafeRawPointer,
    _ colors: UnsafeRawPointer
)

// ---------------------------------------------------------------------------
// gsKit_convert_xyz (Swift implementation — mirrors the C version in cube.c)
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
// Mesh Data — InlineArray: fixed size, stored in WASM data segment (no heap)
// ---------------------------------------------------------------------------

let POINT_COUNT: Int = 36

let cube_vertices: InlineArray<26, VECTOR> = [
    (10, 10, 10, 1),
    (10, 10, -10, 1),
    (10, -10, 10, 1),
    (10, -10, -10, 1),
    (-10, 10, 10, 1),
    (-10, 10, -10, 1),
    (-10, -10, 10, 1),
    (-10, -10, -10, 1),
    (-10, 10, 10, 1),
    (10, 10, 10, 1),
    (-10, 10, -10, 1),
    (10, 10, -10, 1),
    (-10, -10, 10, 1),
    (10, -10, 10, 1),
    (-10, -10, -10, 1),
    (-10, 10, 10, 1),
    (10, 10, 10, 1),
    (-10, 10, -10, 1),
    (-10, -10, 10, 1),
    (-10, 10, 10, 1),
    (10, 10, 10, 1),
    (-10, -10, 10, 1),
    (-10, 10, -10, 1),
    (10, 10, -10, 1),
    (10, -10, -10, 1),
    (-10, -10, -10, 1),
]

let cube_colours: InlineArray<32, VECTOR> = [
    (1, 0, 0, 1),
    (1, 0, 0, 1),
    (1, 0, 0, 1),
    (1, 0, 0, 1),
    (1, 0, 0, 1),
    (1, 0, 0, 1),
    (1, 0, 0, 1),
    (1, 0, 0, 1),
    (0, 1, 0, 1),
    (0, 1, 0, 1),
    (0, 1, 0, 1),
    (0, 1, 0, 1),
    (0, 1, 0, 1),
    (0, 1, 0, 1),
    (0, 1, 0, 1),
    (0, 1, 0, 1),
    (0, 1, 0, 1),
    (0, 1, 0, 1),
    (0, 1, 0, 1),
    (0, 1, 0, 1),
    (0, 1, 0, 1),
    (0, 1, 0, 1),
    (0, 1, 0, 1),
    (0, 0, 1, 1),
    (0, 0, 1, 1),
    (0, 0, 1, 1),
    (0, 0, 1, 1),
    (0, 0, 1, 1),
    (0, 0, 1, 1),
    (0, 0, 1, 1),
    (0, 0, 1, 1),
    (0, 0, 1, 1),
]

let cube_points: InlineArray<36, Int32> = [
    0, 1, 2,  1, 2, 3,
    4, 5, 6,  5, 6, 7,
    8, 9, 10, 9, 10, 11,
    12, 13, 14, 13, 14, 15,
    16, 17, 18, 17, 18, 19,
    20, 21, 22, 21, 22, 23,
]

// ---------------------------------------------------------------------------
// Mutable Graphics State
// ---------------------------------------------------------------------------

var g_object_rotation: VECTOR = (0.0, 0.0, 0.0, 1.0)

let blackRgbaQ: UInt64 = 0x0000000080000000

// ---------------------------------------------------------------------------
// Exposed Swift functions
// ---------------------------------------------------------------------------

@_expose(wasm, "gs_init")
@_cdecl("gs_init")
func gs_init() {
    g_object_rotation = (0.0, 0.0, 0.0, 1.0)
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

    // InlineArray — fixed-size, stored inline in WASM linear memory (no heap).
    // Size is a compile-time constant so the type carries it; no `count:` arg.
    var c_verts:      InlineArray<36, VECTOR>     = InlineArray(repeating: (0, 0, 0, 0))
    var c_colours:    InlineArray<36, VECTOR>     = InlineArray(repeating: (0, 0, 0, 0))
    var temp_verts:   InlineArray<36, vertex_f_t> = InlineArray(repeating: vertex_f_t(xyzw: (0, 0, 0, 0)))
    var screen_verts: InlineArray<36, vertex_f_t> = InlineArray(repeating: vertex_f_t(xyzw: (0, 0, 0, 0)))
    var colors:       InlineArray<36, color_t>    = InlineArray(repeating: color_t(rgbaq: 0))

    // MATRIX = float[16] imported as a 16-element Float tuple
    var local_world:  (Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32,
                       Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32)
                    = (0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0)
    var world_view:   (Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32,
                       Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32)
                    = (0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0)
    var view_screen:  (Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32,
                       Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32)
                    = (0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0)
    var local_screen: (Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32,
                       Float32, Float32, Float32, Float32, Float32, Float32, Float32, Float32)
                    = (0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0)

    // Camera and object transforms
    var object_position: VECTOR = (0.0, 0.0, 0.0, 1.0)
    var camera_position: VECTOR = (0.0, 0.0, 100.0, 1.0)
    var camera_rotation: VECTOR = (0.0, 0.0, 0.0, 1.0)

    // Expand indexed mesh into flat per-triangle arrays
    for i in 0..<POINT_COUNT {
        let vi = Int(cube_points[i])
        c_verts[i]   = cube_vertices[vi]
        c_colours[i] = cube_colours[vi]
    }

    // Build projection matrix once per frame
    withUnsafeMutableBytes(of: &view_screen) { m in
        ps2_create_view_screen(m.baseAddress!, 4.0/3.0, -0.5, 0.5, -0.5, 0.5, 1.0, 2000.0)
    }

    if ps2_gsKit_global_get_zbuffering(gs) != 0 {
        ps2_gsKit_set_test(gs, 1)
    }
    ps2_gsKit_global_set_primaaenable(gs, 1)

    // Spin the cube
    g_object_rotation.0 += 0.008
    g_object_rotation.1 += 0.012

    // Model → World
    withUnsafeMutableBytes(of: &object_position) { pos in
        withUnsafeMutableBytes(of: &g_object_rotation) { rot in
            withUnsafeMutableBytes(of: &local_world) { m in
                ps2_create_local_world(m.baseAddress!, pos.baseAddress!, rot.baseAddress!)
            }
        }
    }

    // World → View
    withUnsafeMutableBytes(of: &camera_position) { pos in
        withUnsafeMutableBytes(of: &camera_rotation) { rot in
            withUnsafeMutableBytes(of: &world_view) { m in
                ps2_create_world_view(m.baseAddress!, pos.baseAddress!, rot.baseAddress!)
            }
        }
    }

    // Concatenate → local_screen
    withUnsafeMutableBytes(of: &local_world) { lw in
        withUnsafeMutableBytes(of: &world_view) { wv in
            withUnsafeMutableBytes(of: &view_screen) { vs in
                withUnsafeMutableBytes(of: &local_screen) { ls in
                    ps2_create_local_screen(
                        ls.baseAddress!,
                        UnsafeRawPointer(lw.baseAddress!),
                        UnsafeRawPointer(wv.baseAddress!),
                        UnsafeRawPointer(vs.baseAddress!)
                    )
                }
            }
        }
    }

    // Transform vertices into clip space
    withUnsafeMutableBytes(of: &c_verts) { cv in
        withUnsafeMutableBytes(of: &local_screen) { ls in
            withUnsafeMutableBytes(of: &temp_verts) { tv in
                ps2_calculate_vertices(
                    tv.baseAddress!,
                    Int32(POINT_COUNT),
                    UnsafeRawPointer(cv.baseAddress!),
                    UnsafeRawPointer(ls.baseAddress!)
                )
            }
        }
    }

    // Clip-space → screen pixel coords (Swift port of gsKit_convert_xyz)
    withUnsafeMutableBytes(of: &temp_verts) { tv in
        withUnsafeMutableBytes(of: &screen_verts) { sv in
            _ = gsKit_convert_xyz(
                output: sv.baseAddress!.assumingMemoryBound(to: vertex_f_t.self),
                gs: gs,
                count: Int32(POINT_COUNT),
                vertices: tv.baseAddress!.assumingMemoryBound(to: vertex_f_t.self)
            )
        }
    }

    // Float colours → GS color_t (fixed-point RGBAQ)
    withUnsafeMutableBytes(of: &temp_verts) { tv in
        withUnsafeMutableBytes(of: &c_colours) { cc in
            withUnsafeMutableBytes(of: &colors) { col in
                ps2_draw_convert_rgbq(
                    col.baseAddress!,
                    Int32(POINT_COUNT),
                    UnsafeRawPointer(tv.baseAddress!),
                    UnsafeRawPointer(cc.baseAddress!),
                    0x80
                )
            }
        }
    }

    // Clear and draw — GSPRIMPOINT construction happens in glue.c (128-bit
    // gs_rgbaq/gs_xyz2 can't be built cleanly from WASM; C side does it)
    ps2_gsKit_clear(gs, blackRgbaQ)
    withUnsafeMutableBytes(of: &screen_verts) { sv in
        withUnsafeMutableBytes(of: &colors) { col in
            ps2_build_and_draw(
                gs, Int32(POINT_COUNT),
                UnsafeRawPointer(sv.baseAddress!),
                UnsafeRawPointer(col.baseAddress!)
            )
        }
    }
}
