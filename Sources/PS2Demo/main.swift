// PS2Demo/Sources/PS2Demo/main.swift
//
// Embedded Swift demo for PlayStation 2 (Emotion Engine / MIPS R5900)
// Pipeline: Swift → wasm32-unknown-none-wasm → w2c2 (C89) → mips64r5900el-ps2-elf-gcc → .elf
//
// Constraints:
//   - No Swift stdlib (Embedded mode)
//   - No Foundation, no Dispatch, no runtime reflection
//   - All PS2 I/O goes through imported C functions declared below
//   - Integer/struct math only; avoid Double (PS2 FPU is 32-bit only, non-IEEE 754)

// ---------------------------------------------------------------------------
// Host function imports (provided by ps2sdk-bridge/glue.c after w2c2 lowers)
// @_extern(wasm) generates a proper wasm import that w2c2 passes to host C.
// ---------------------------------------------------------------------------

@_extern(wasm, module: "ps2", name: "print")
@_extern(c)
func ps2_print(_ msg: UnsafeRawPointer, _ len: Int32)

@_extern(wasm, module: "ps2", name: "clear_screen")
@_extern(c)
func ps2_clear_screen()

@_extern(wasm, module: "ps2", name: "set_color")
@_extern(c)
func ps2_set_color(_ r: UInt8, _ g: UInt8, _ b: UInt8)

@_extern(wasm, module: "ps2", name: "draw_pixel")
@_extern(c)
func ps2_draw_pixel(_ x: Int32, _ y: Int32)

@_extern(wasm, module: "ps2", name: "vsync")
@_extern(c)
func ps2_vsync()

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
// Simple fixed-point math (avoid Float/Double where possible on EE)
// ---------------------------------------------------------------------------

typealias Fixed = Int32
let FP_SHIFT: Int32 = 8
let FP_ONE:   Fixed = 1 << FP_SHIFT

func fp(_ n: Int32) -> Fixed { n << FP_SHIFT }
func fp_mul(_ a: Fixed, _ b: Fixed) -> Fixed { (a * b) >> FP_SHIFT }
func fp_to_int(_ a: Fixed) -> Int32 { a >> FP_SHIFT }

// ---------------------------------------------------------------------------
// Demo: Plasma-style pattern using fixed-point sine approximation
// ---------------------------------------------------------------------------

func fp_sin(_ angle: Int32) -> Fixed {
    var a = angle & 0xFF
    let neg = a > 128
    if a > 128 { a = 256 &- a }
    let num: Int32 = a &* (128 &- a) &* 4
    let den: Int32 = 8192 &+ (a &* (128 &- a))
    let result = (num << FP_SHIFT) / den
    return neg ? -result : result
}

func fp_cos(_ angle: Int32) -> Fixed { fp_sin(angle &+ 64) }

let SCREEN_W: Int32 = 320
let SCREEN_H: Int32 = 240
let TILE_W:   Int32 = 64
let TILE_H:   Int32 = 48
let ORIGIN_X: Int32 = (SCREEN_W - TILE_W) / 2
let ORIGIN_Y: Int32 = (SCREEN_H - TILE_H) / 2

func renderPlasmaFrame(tick: Int32) {
    var y: Int32 = 0
    while y < TILE_H {
        var x: Int32 = 0
        while x < TILE_W {
            let wave1 = fp_sin((x &* 4 &+ tick) & 0xFF)
            let wave2 = fp_cos((y &* 3 &+ tick &* 2) & 0xFF)
            let combined = fp_to_int(wave1 &+ wave2 &+ fp(2))

            let idx = combined & 3
            let r: UInt8
            let g: UInt8
            let b: UInt8
            switch idx {
            case 0:  r = 255; g = 80;  b = 80
            case 1:  r = 80;  g = 255; b = 80
            case 2:  r = 80;  g = 80;  b = 255
            default: r = 255; g = 255; b = 80
            }

            ps2_set_color(r, g, b)
            ps2_draw_pixel(ORIGIN_X &+ x, ORIGIN_Y &+ y)
            x &+= 1
        }
        y &+= 1
    }
}

// ---------------------------------------------------------------------------
// Fibonacci
// ---------------------------------------------------------------------------

func fibonacci(_ n: UInt32) -> UInt32 {
    if n <= 1 { return n }
    var a: UInt32 = 0
    var b: UInt32 = 1
    var i: UInt32 = 2
    while i <= n {
        let tmp = a &+ b
        a = b
        b = tmp
        i &+= 1
    }
    return b
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

@_expose(wasm, "swift_main")
@_cdecl("swift_main")
func swift_main() {
    ps2_clear_screen()

    print_cstr("Swift Embedded -> WASM -> C89 -> PS2 EE\n")
    print_cstr("Emotion Engine / MIPS R5900 @ 294 MHz\n")
    print_cstr("w2c2 + mips64r5900el-ps2-elf-gcc\n\n")

    print_cstr("Fibonacci sequence:\n")
    _ = fibonacci(10)
    _ = fibonacci(20)
    _ = fibonacci(30)

    print_cstr("\nRendering plasma demo...\n")

    var tick: Int32 = 0
    while tick < 60 {
        renderPlasmaFrame(tick: tick)
        ps2_vsync()
        tick &+= 1
    }

    print_cstr("\nDone! Swift ran on PS2.\n")
    ps2_exit(0)
}
