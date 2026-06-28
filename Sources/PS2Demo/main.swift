// PS2Demo/Sources/PS2Demo/main.swift
//
// Embedded Swift demo for PlayStation 2 (Emotion Engine / MIPS R5900)
// Pipeline: Swift → wasm32-unknown-none-wasm → w2c2 (C89) → mips64r5900el-ps2-elf-gcc → .elf
//
// Demo: 3D Rotating Cube using gsKit graphics library
// Rendering implemented in Swift (cube.swift); per-frame buffer ops delegated to C via WASM imports.

@_extern(wasm, module: "ps2", name: "print")
@_extern(c)
func ps2_print(_ msg: UnsafeRawPointer, _ len: Int32)

@_extern(wasm, module: "ps2", name: "gs_init")
@_extern(c)
func ps2_gs_init()

@_extern(wasm, module: "ps2", name: "gs_flip_screen")
@_extern(c)
func ps2_gs_flip_screen()

@_extern(wasm, module: "ps2", name: "exit")
@_extern(c)
func ps2_exit(_ code: Int32)

// ---------------------------------------------------------------------------
// Minimal string helper (no stdlib, no String type)
// ---------------------------------------------------------------------------

func print_cstr(_ ptr: UnsafePointer<UInt8>) {
    var len: Int32 = 0
    var p = ptr
    while p.pointee != 0 { p += 1; len += 1 }
    ps2_print(ptr, len)
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

@_expose(wasm, "swift_main")
@_cdecl("swift_main")
func swift_main() {
    print_cstr("Swift Embedded -> WASM -> C89 -> PS2 EE\n")
    print_cstr("3D Rotating Cube using gsKit\n")
    print_cstr("Emotion Engine / MIPS R5900 @ 294 MHz\n\n")

    print_cstr("Initializing graphics...\n")
    ps2_gs_init()

    print_cstr("Rendering cube (Swift implementation)...\n")

    var frame: Int32 = 0
    while frame < 600 {
        gs_render_cube()
        ps2_gs_flip_screen()
        frame &+= 1
    }

    print_cstr("\nDone!\n")
    ps2_exit(0)
}
