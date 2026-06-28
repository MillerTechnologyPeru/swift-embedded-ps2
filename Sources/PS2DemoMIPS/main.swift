// PS2DemoMIPS/main.swift — Embedded Swift for PS2 EE, direct MIPS compilation
//
// Pipeline: swiftc (mipsel-none-none-elf) → ELF32 MIPS-II → PCSX2
// No WASM. No w2c2. ELF32 matches what the PS2 BIOS ELF loader expects.
//
// FFI uses @_silgen_name (not @_extern(wasm,...)) — C symbols linked directly.

@_silgen_name("ps2_print")
func ps2_print(_ buf: UnsafeRawPointer, _ len: Int32)

@_silgen_name("ps2_gs_init")
func ps2_gs_init()

@_silgen_name("ps2_gs_flip")
func ps2_gs_flip()

@inline(__always)
func print_cstr(_ ptr: UnsafePointer<UInt8>) {
    var len: Int32 = 0
    var p = ptr
    while p.pointee != 0 { p += 1; len += 1 }
    ps2_print(ptr, len)
}

@_cdecl("swift_main")
public func swiftMain() {
    print_cstr("Swift Embedded -> MIPS-II -> PS2 EE\n")
    print_cstr("No WASM. No w2c2. Direct compilation.\n")
    print_cstr("Emotion Engine / MIPS R5900 @ 294 MHz\n")

    ps2_gs_init()

    var frame: Int32 = 0
    while frame < 600 {
        ps2_gs_flip()
        frame &+= 1
    }

    print_cstr("Done.\n")
    while true {}
}
