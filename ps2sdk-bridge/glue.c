/*
 * ps2sdk-bridge/glue.c — PS2 graphics + w2c2 host glue (gsKit version)
 *
 * w2c2 import naming: {module}__{name}(void* instance, ...)
 */

#include <kernel.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>

#include <tamtypes.h>
#include <gsKit.h>
#include <gsInline.h>
#include <dmaKit.h>
#include <draw.h>
#include <draw3d.h>
#include <math3d.h>

#include "w2c2_base.h"
#include "PS2Demo.h"

/* -------------------------------------------------------------------------
 * Graphics state
 * ------------------------------------------------------------------------- */

static GSGLOBAL *g_gsGlobal = NULL;
static VECTOR g_object_position = { 0.00f, 0.00f, 0.00f, 1.00f };
static VECTOR g_object_rotation = { 0.00f, 0.00f, 0.00f, 1.00f };
static VECTOR g_camera_position = { 0.00f, 0.00f, 100.00f, 1.00f };
static VECTOR g_camera_rotation = { 0.00f, 0.00f, 0.00f, 1.00f };

static const u64 BLACK_RGBAQ = GS_SETREG_RGBAQ(0x00,0x00,0x00,0x80,0x00);

/* Cube mesh data (from gsKit cube example) */
#define VERTEX_COUNT 24
#define POINT_COUNT 36

static VECTOR vertices[VERTEX_COUNT] = {
 {  10.00f,  10.00f,  10.00f, 1.00f },
 {  10.00f,  10.00f, -10.00f, 1.00f },
 {  10.00f, -10.00f,  10.00f, 1.00f },
 {  10.00f, -10.00f, -10.00f, 1.00f },
 { -10.00f,  10.00f,  10.00f, 1.00f },
 { -10.00f,  10.00f, -10.00f, 1.00f },
 { -10.00f, -10.00f,  10.00f, 1.00f },
 { -10.00f, -10.00f, -10.00f, 1.00f },
 { -10.00f,  10.00f,  10.00f, 1.00f },
 {  10.00f,  10.00f,  10.00f, 1.00f },
 { -10.00f,  10.00f, -10.00f, 1.00f },
 {  10.00f,  10.00f, -10.00f, 1.00f },
 { -10.00f, -10.00f,  10.00f, 1.00f },
 {  10.00f, -10.00f,  10.00f, 1.00f },
 { -10.00f, -10.00f, -10.00f, 1.00f },
 {  10.00f, -10.00f, -10.00f, 1.00f },
 { -10.00f,  10.00f,  10.00f, 1.00f },
 {  10.00f,  10.00f,  10.00f, 1.00f },
 { -10.00f, -10.00f,  10.00f, 1.00f },
 {  10.00f, -10.00f,  10.00f, 1.00f },
 { -10.00f,  10.00f, -10.00f, 1.00f },
 {  10.00f,  10.00f, -10.00f, 1.00f },
 { -10.00f, -10.00f, -10.00f, 1.00f },
 {  10.00f, -10.00f, -10.00f, 1.00f }
};

static VECTOR colours[VERTEX_COUNT] = {
 { 1.00f, 0.00f, 0.00f, 1.00f },
 { 1.00f, 0.00f, 0.00f, 1.00f },
 { 1.00f, 0.00f, 0.00f, 1.00f },
 { 1.00f, 0.00f, 0.00f, 1.00f },
 { 1.00f, 0.00f, 0.00f, 1.00f },
 { 1.00f, 0.00f, 0.00f, 1.00f },
 { 1.00f, 0.00f, 0.00f, 1.00f },
 { 1.00f, 0.00f, 0.00f, 1.00f },
 { 0.00f, 1.00f, 0.00f, 1.00f },
 { 0.00f, 1.00f, 0.00f, 1.00f },
 { 0.00f, 1.00f, 0.00f, 1.00f },
 { 0.00f, 1.00f, 0.00f, 1.00f },
 { 0.00f, 1.00f, 0.00f, 1.00f },
 { 0.00f, 1.00f, 0.00f, 1.00f },
 { 0.00f, 1.00f, 0.00f, 1.00f },
 { 0.00f, 1.00f, 0.00f, 1.00f },
 { 0.00f, 0.00f, 1.00f, 1.00f },
 { 0.00f, 0.00f, 1.00f, 1.00f },
 { 0.00f, 0.00f, 1.00f, 1.00f },
 { 0.00f, 0.00f, 1.00f, 1.00f },
 { 0.00f, 0.00f, 1.00f, 1.00f },
 { 0.00f, 0.00f, 1.00f, 1.00f },
 { 0.00f, 0.00f, 1.00f, 1.00f },
 { 0.00f, 0.00f, 1.00f, 1.00f }
};

static int points[POINT_COUNT] = {
  0,  1,  2,
  1,  2,  3,
  4,  5,  6,
  5,  6,  7,
  8,  9, 10,
  9, 10, 11,
 12, 13, 14,
 13, 14, 15,
 16, 17, 18,
 17, 18, 19,
 20, 21, 22,
 21, 22, 23
};

/* -------------------------------------------------------------------------
 * gsKit initialization
 * ------------------------------------------------------------------------- */

/* Custom vertex conversion (from gsKit cube example) */
static int gsKit_convert_xyz(vertex_f_t *output, GSGLOBAL* gsGlobal, int count, vertex_f_t *vertices)
{
    int z;
    unsigned int max_z;

    switch(gsGlobal->PSMZ){
    case GS_PSMZ_32:
        z = 32;
        break;
    case GS_PSMZ_24:
        z = 24;
        break;
    case GS_PSMZ_16:
    case GS_PSMZ_16S:
        z = 16;
        break;
    default:
        return -1;
    }

    float center_x = gsGlobal->Width / 2;
    float center_y = gsGlobal->Height / 2;
    max_z = 1 << (z - 1);

    int i;
    for (i = 0; i < count; i++)
    {
        output[i].x = ((vertices[i].x + 1.0f) * center_x);
        output[i].y = ((vertices[i].y + 1.0f) * center_y);
        output[i].z = (unsigned int)((vertices[i].z + 1.0f) * max_z);
    }

    return 0;
}

void gs_init(void) {
    g_gsGlobal = gsKit_init_global();
    g_gsGlobal->PrimAlphaEnable = GS_SETTING_ON;
    gsKit_set_primalpha(g_gsGlobal, GS_SETREG_ALPHA(0, 1, 0, 1, 0), 0);

    dmaKit_init(D_CTRL_RELE_OFF, D_CTRL_MFD_OFF, D_CTRL_STS_UNSPEC,
                D_CTRL_STD_OFF, D_CTRL_RCYC_8, 1 << DMA_CHANNEL_GIF);
    dmaKit_chan_init(DMA_CHANNEL_GIF);

    gsKit_set_clamp(g_gsGlobal, GS_CMODE_REPEAT);
    gsKit_vram_clear(g_gsGlobal);
    gsKit_init_screen(g_gsGlobal);
    gsKit_mode_switch(g_gsGlobal, GS_ONESHOT);
}

/* -------------------------------------------------------------------------
 * Render functions
 * ------------------------------------------------------------------------- */

void gs_flip_screen(void) {
    gsKit_queue_exec(g_gsGlobal);
    gsKit_sync_flip(g_gsGlobal);
}

void gs_render_cube(void) {
    MATRIX local_world;
    MATRIX world_view;
    MATRIX view_screen;
    MATRIX local_screen;

    VECTOR *temp_vertices;
    VECTOR *verts;
    color_t *colors;
    GSPRIMPOINT *gs_vertices = (GSPRIMPOINT *)memalign(128, sizeof(GSPRIMPOINT) * POINT_COUNT);
    VECTOR *c_verts = (VECTOR *)memalign(128, sizeof(VECTOR) * POINT_COUNT);
    VECTOR *c_colours = (VECTOR *)memalign(128, sizeof(VECTOR) * POINT_COUNT);

    int i;
    for (i = 0; i < POINT_COUNT; i++) {
        c_verts[i][0] = vertices[points[i]][0];
        c_verts[i][1] = vertices[points[i]][1];
        c_verts[i][2] = vertices[points[i]][2];
        c_verts[i][3] = vertices[points[i]][3];
        c_colours[i][0] = colours[points[i]][0];
        c_colours[i][1] = colours[points[i]][1];
        c_colours[i][2] = colours[points[i]][2];
        c_colours[i][3] = colours[points[i]][3];
    }

    temp_vertices = memalign(128, sizeof(VECTOR) * POINT_COUNT);
    verts = memalign(128, sizeof(VECTOR) * POINT_COUNT);
    colors = memalign(128, sizeof(color_t) * POINT_COUNT);

    create_view_screen(view_screen, 4.0f/3.0f, -0.5f, 0.5f, -0.5f, 0.5f, 1.00f, 2000.00f);

    if (g_gsGlobal->ZBuffering == GS_SETTING_ON)
        gsKit_set_test(g_gsGlobal, GS_ZTEST_ON);
    g_gsGlobal->PrimAAEnable = GS_SETTING_ON;

    /* Spin the cube */
    g_object_rotation[0] += 0.008f;
    g_object_rotation[1] += 0.012f;

    create_local_world(local_world, g_object_position, g_object_rotation);
    create_world_view(world_view, g_camera_position, g_camera_rotation);
    create_local_screen(local_screen, local_world, world_view, view_screen);

    calculate_vertices(temp_vertices, POINT_COUNT, c_verts, local_screen);
    gsKit_convert_xyz((vertex_f_t*)verts, g_gsGlobal, POINT_COUNT, (vertex_f_t*)temp_vertices);
    draw_convert_rgbq(colors, POINT_COUNT, (vertex_f_t*)temp_vertices, (color_f_t*)c_colours, 0x80);

    for (i = 0; i < POINT_COUNT; i++) {
        gs_vertices[i].rgbaq = color_to_RGBAQ(colors[i].r, colors[i].g, colors[i].b, colors[i].a, 0.0f);
        gs_vertices[i].xyz2 = vertex_to_XYZ2(g_gsGlobal, verts[i][0], verts[i][1], verts[i][2]);
    }

    gsKit_clear(g_gsGlobal, BLACK_RGBAQ);
    gsKit_prim_list_triangle_gouraud_3d(g_gsGlobal, POINT_COUNT, gs_vertices);

    free(temp_vertices);
    free(verts);
    free(colors);
    free(gs_vertices);
    free(c_verts);
    free(c_colours);
}

/* -------------------------------------------------------------------------
 * PS2 host imports (w2c2)
 * ------------------------------------------------------------------------- */

void ps2__print(void* inst, U32 wasm_ptr, U32 len) {
    wasmMemory *mem = PS2Demo_memory((PS2DemoInstance*)inst);
    if (len == 0) return;
    const char *str = (const char*)(mem->data + wasm_ptr);
    U32 j;
    for (j = 0; j < len; j++) putchar((unsigned char)str[j]);
    fflush(stdout);
}

void ps2__gs_init(void* inst) {
    (void)inst;
    gs_init();
}

void ps2__gs_render_cube(void* inst) {
    (void)inst;
    gs_render_cube();
}

void ps2__gs_flip_screen(void* inst) {
    (void)inst;
    gs_flip_screen();
}

void ps2__exit(void* inst, U32 code) {
    (void)inst;
    printf("swift_main exited with code %u\n", (unsigned)code);
    SleepThread();
}

/* -------------------------------------------------------------------------
 * WASI stubs
 * ------------------------------------------------------------------------- */

U32 wasi_snapshot_preview1__args_sizes_get(void* inst, U32 argc_ptr, U32 argv_buf_size_ptr) {
    wasmMemory *mem = PS2Demo_memory((PS2DemoInstance*)inst);
    i32_store(mem, argc_ptr, 0);
    i32_store(mem, argv_buf_size_ptr, 0);
    return 0;
}

U32 wasi_snapshot_preview1__args_get(void* inst, U32 argv_ptr, U32 argv_buf_ptr) {
    (void)inst; (void)argv_ptr; (void)argv_buf_ptr;
    return 0;
}

void wasi_snapshot_preview1__proc_exit(void* inst, U32 code) {
    ps2__exit(inst, code);
}

/* -------------------------------------------------------------------------
 * trap
 * ------------------------------------------------------------------------- */
void trap(Trap t) {
    printf("WASM TRAP %d\n", (int)t);
    SleepThread();
    while (1) {}
}

/* -------------------------------------------------------------------------
 * EE main
 * ------------------------------------------------------------------------- */
int main(int argc, char** argv) {
    (void)argc; (void)argv;

    printf("swift-embedded-ps2 booting...\n");
    printf("Initializing gsKit...\n");
    gs_init();
    printf("GS initialized. Running swift_main...\n");

    static PS2DemoInstance instance;
    PS2DemoInstantiate(&instance, NULL);
    PS2Demo_swift_main(&instance);

    SleepThread();
    return 0;
}