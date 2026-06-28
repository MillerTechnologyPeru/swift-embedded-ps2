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

// Per-frame buffer operations — each wraps a C-side memalign'd buffer
// that cannot be addressed as a WASM linear-memory offset.
@_extern(wasm, module: "ps2", name: "cube_calculate_vertices")
@_extern(c)
func ps2_cube_calculate_vertices(_ local_screen: UnsafeMutableRawPointer)

@_extern(wasm, module: "ps2", name: "cube_draw_convert_rgbq")
@_extern(c)
func ps2_cube_draw_convert_rgbq()

// Per-element accessors for cube_build_and_draw's Swift loop
@_extern(wasm, module: "ps2", name: "get_cube_points_count")
@_extern(c)
func ps2_get_cube_points_count() -> Int32

@_extern(wasm, module: "ps2", name: "get_cube_color_r")
@_extern(c)
func ps2_get_cube_color_r(_ i: Int32) -> UInt32

@_extern(wasm, module: "ps2", name: "get_cube_color_g")
@_extern(c)
func ps2_get_cube_color_g(_ i: Int32) -> UInt32

@_extern(wasm, module: "ps2", name: "get_cube_color_b")
@_extern(c)
func ps2_get_cube_color_b(_ i: Int32) -> UInt32

@_extern(wasm, module: "ps2", name: "get_cube_color_a")
@_extern(c)
func ps2_get_cube_color_a(_ i: Int32) -> UInt32

@_extern(wasm, module: "ps2", name: "get_cube_temp_vert_x")
@_extern(c)
func ps2_get_cube_temp_vert_x(_ i: Int32) -> Float32

@_extern(wasm, module: "ps2", name: "get_cube_temp_vert_y")
@_extern(c)
func ps2_get_cube_temp_vert_y(_ i: Int32) -> Float32

@_extern(wasm, module: "ps2", name: "get_cube_temp_vert_z")
@_extern(c)
func ps2_get_cube_temp_vert_z(_ i: Int32) -> Float32

@_extern(wasm, module: "ps2", name: "get_cube_vert_x")
@_extern(c)
func ps2_get_cube_vert_x(_ i: Int32) -> Float32

@_extern(wasm, module: "ps2", name: "get_cube_vert_y")
@_extern(c)
func ps2_get_cube_vert_y(_ i: Int32) -> Float32

@_extern(wasm, module: "ps2", name: "get_cube_vert_z")
@_extern(c)
func ps2_get_cube_vert_z(_ i: Int32) -> Float32

@_extern(wasm, module: "ps2", name: "set_cube_vert_x")
@_extern(c)
func ps2_set_cube_vert_x(_ i: Int32, _ v: Float32)

@_extern(wasm, module: "ps2", name: "set_cube_vert_y")
@_extern(c)
func ps2_set_cube_vert_y(_ i: Int32, _ v: Float32)

@_extern(wasm, module: "ps2", name: "set_cube_vert_z")
@_extern(c)
func ps2_set_cube_vert_z(_ i: Int32, _ v: Float32)

@_extern(wasm, module: "ps2", name: "set_cube_gs_vertex_rgbaq")
@_extern(c)
func ps2_set_cube_gs_vertex_rgbaq(_ i: Int32, _ r: UInt32, _ g: UInt32, _ b: UInt32, _ a: UInt32, _ q: Float32)

@_extern(wasm, module: "ps2", name: "set_cube_gs_vertex_xyz2")
@_extern(c)
func ps2_set_cube_gs_vertex_xyz2(_ i: Int32, _ x: Float32, _ y: Float32, _ z: Float32)

@_extern(wasm, module: "ps2", name: "cube_prim_list_draw")
@_extern(c)
func ps2_cube_prim_list_draw()

// ---------------------------------------------------------------------------
// Scene state accessors (state lives in glue.c as C statics)
// ---------------------------------------------------------------------------

@_extern(wasm, module: "ps2", name: "get_object_rotation")
@_extern(c)
func ps2_get_object_rotation(_ i: Int32) -> Float32

@_extern(wasm, module: "ps2", name: "set_object_rotation")
@_extern(c)
func ps2_set_object_rotation(_ i: Int32, _ v: Float32)

@_extern(wasm, module: "ps2", name: "get_object_position")
@_extern(c)
func ps2_get_object_position(_ i: Int32) -> Float32

@_extern(wasm, module: "ps2", name: "get_camera_position")
@_extern(c)
func ps2_get_camera_position(_ i: Int32) -> Float32

@_extern(wasm, module: "ps2", name: "get_camera_rotation")
@_extern(c)
func ps2_get_camera_rotation(_ i: Int32) -> Float32

@_extern(wasm, module: "ps2", name: "get_view_screen")
@_extern(c)
func ps2_get_view_screen(_ dst: UnsafeMutableRawPointer)

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

let blackRgbaQ: UInt64 = 0x0000000080000000

// ---------------------------------------------------------------------------
// Exposed Swift functions
// ---------------------------------------------------------------------------

@_expose(wasm, "_gs_flip_screen")
@_cdecl("_gs_flip_screen")
func _gs_flip_screen() {
    ps2_gsKit_flip_screen()
}

@_expose(wasm, "gs_render_cube")
@_cdecl("gs_render_cube")
func gs_render_cube() {
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

    ps2_set_object_rotation(0, ps2_get_object_rotation(0) + 0.008)
    ps2_set_object_rotation(1, ps2_get_object_rotation(1) + 0.012)

    var object_position: VECTOR = (
        ps2_get_object_position(0), ps2_get_object_position(1),
        ps2_get_object_position(2), ps2_get_object_position(3))
    var object_rotation: VECTOR = (
        ps2_get_object_rotation(0), ps2_get_object_rotation(1),
        ps2_get_object_rotation(2), ps2_get_object_rotation(3))
    var camera_position: VECTOR = (
        ps2_get_camera_position(0), ps2_get_camera_position(1),
        ps2_get_camera_position(2), ps2_get_camera_position(3))
    var camera_rotation: VECTOR = (
        ps2_get_camera_rotation(0), ps2_get_camera_rotation(1),
        ps2_get_camera_rotation(2), ps2_get_camera_rotation(3))

    withUnsafeMutableBytes(of: &view_screen) { m in
        ps2_get_view_screen(m.baseAddress!)
    }

    withUnsafeMutableBytes(of: &object_position) { pos in
        withUnsafeMutableBytes(of: &object_rotation) { rot in
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

    withUnsafeMutableBytes(of: &local_screen) { ls in
        ps2_cube_calculate_vertices(ls.baseAddress!)
    }
    cube_convert_xyz()
    ps2_cube_draw_convert_rgbq()
    cube_build_and_draw()
}

func cube_convert_xyz() {
    let n = ps2_get_cube_points_count()
    let gs = ps2_gsKit_global_get()
    let psmz = ps2_gsKit_global_get_psmz(gs)
    let z: Int32
    switch psmz {
    case 0:     z = 32  // GS_PSMZ_32
    case 1:     z = 24  // GS_PSMZ_24
    case 2, 10: z = 16  // GS_PSMZ_16, GS_PSMZ_16S
    default:    return
    }
    let center_x: Float32 = Float32(ps2_gsKit_global_get_width(gs)) / 2.0
    let center_y: Float32 = Float32(ps2_gsKit_global_get_height(gs)) / 2.0
    let max_z: UInt32 = 1 << UInt32(z - 1)
    for i in 0..<Int(n) {
        let i32 = Int32(i)
        ps2_set_cube_vert_x(i32, (ps2_get_cube_temp_vert_x(i32) + 1.0) * center_x)
        ps2_set_cube_vert_y(i32, (ps2_get_cube_temp_vert_y(i32) + 1.0) * center_y)
        ps2_set_cube_vert_z(i32, Float32(UInt32((ps2_get_cube_temp_vert_z(i32) + 1.0) * Float32(max_z))))
    }
}

func cube_build_and_draw() {
    let n = ps2_get_cube_points_count()
    let gs = ps2_gsKit_global_get()
    for i in 0..<Int(n) {
        let i32 = Int32(i)
        ps2_set_cube_gs_vertex_rgbaq(i32,
            ps2_get_cube_color_r(i32),
            ps2_get_cube_color_g(i32),
            ps2_get_cube_color_b(i32),
            ps2_get_cube_color_a(i32),
            0.0
        )
        ps2_set_cube_gs_vertex_xyz2(i32,
            ps2_get_cube_vert_x(i32),
            ps2_get_cube_vert_y(i32),
            ps2_get_cube_vert_z(i32)
        )
    }
    ps2_gsKit_clear(gs, blackRgbaQ)
    ps2_cube_prim_list_draw()
}
