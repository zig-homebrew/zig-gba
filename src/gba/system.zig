const std = @import("std");

pub fn call(comptime number: usize) void {
    const swi = comptime std.fmt.comptimePrint("SWI      {}\n", .{number});
    asm volatile (swi ::: "r0", "r1", "r2", "r3");
}

pub fn halt() void {
    call(2);
}

pub fn stop() void {
    call(3);
}

pub fn vblank_intr_wait() void {
    call(5);
}

pub fn sound_driver_main() void {
    call(28);
}

pub fn sound_driver_vsync() void {
    call(29);
}

pub fn sound_channel_clear() void {
    call(30);
}

pub fn sound_driver_vsync_off() void {
    call(40);
}

pub fn sound_driver_vsync_on() void {
    call(41);
}
