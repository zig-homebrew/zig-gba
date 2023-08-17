const c = @import("gba/c.zig");
const system = @import("gba/system.zig");

fn RGB8(r: u8, g: u8, b: u8) u16 {
    return ((@as(u16, r) >> 3) & 0x1F) | (((@as(u16, g) >> 3) & 0x1F) << 5) | (((@as(u16, b) >> 3) & 0x1F) << 10);
}

var palette_bg = c.BG_PALETTE;
var palette_sprite = c.SPRITE_PALETTE;
const screen_fb = @as([*]volatile u16, @ptrFromInt(0x06000000));
const screen_bb = @as([*]volatile u16, @ptrFromInt(0x0600A000));

var screen = screen_fb;

var REG_VCOUNT = @as([*]volatile u16, @ptrFromInt(0x04000006));

fn vid_vsync() void {
    while (REG_VCOUNT[0] >= 160) {}
    while (REG_VCOUNT[0] < 160) {}
}

fn vid_flip() void {
    if (screen == screen_fb) {
        screen = screen_bb;
        c.SetMode(c.MODE_4 | c.BG2_ON | c.BACKBUFFER);
    } else {
        screen = screen_fb;
        c.SetMode(c.MODE_4 | c.BG2_ON);
    }
}

fn drawRainbow() void {
    var i : u16 = 0;
    // Make a rainbow gradient:
    while (i < (c.SCREEN_WIDTH * c.SCREEN_HEIGHT / 2)) : (i += 1) {
        // We cannot write each u8 individually, we need to
        // write two byte words at a time.
        const left_side = i % 255;
        const right_side = left_side;

        screen[i] = @as(u16, (left_side | (right_side << 8)));
    }
}

fn resetPalette(shift: u8) void {
    var i : u16 = 0;
    while (i < 256) : (i += 1) {
        palette_bg[i] = RGB8(255, @truncate((i + shift)%255), 0);
    }
}

export fn main(_: c_int, _: [*]const [*:0]const u8) void {
    c.irqInit();
    c.irqEnable(c.IRQ_VBLANK);
    c.consoleDemoInit();

    c.SetMode(c.MODE_4 | c.BG2_ON);

    // Setup Palette with wide range of colors:
    resetPalette(0);
    var pi : u16 = 0;
    while (pi < 256) : (pi += 1) {
        palette_bg[pi] = RGB8(255, @truncate(pi), 0);
    }

    var frame : u8 = 1;
    while (true) {
    drawRainbow();
        system.vblank_intr_wait();
        resetPalette(frame);

        if (frame == 255) {
            frame = 0;
        } else {
            frame += 4;
        }
    }
}
