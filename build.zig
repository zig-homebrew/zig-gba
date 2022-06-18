const std = @import("std");

const flags = .{"-lgba"};
const devkitpro = "/opt/devkitpro";

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const obj = b.addObject("zig-gba", "src/main.zig");
    obj.setOutputDir("zig-out");
    obj.linkLibC();
    obj.setLibCFile(std.build.FileSource{ .path = "libc.txt" });
    obj.addIncludeDir(devkitpro ++ "/libgba/include");
    obj.addIncludeDir(devkitpro ++ "/portlibs/libgba/include");
    obj.setTarget(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm7tdmi },
    });
    obj.setBuildMode(mode);

    const elf = b.addSystemCommand(&(.{
        devkitpro ++ "/devkitARM/bin/arm-none-eabi-gcc",
        "-g",
        "-mthumb",
        "-mthumb-interwork",
        "-Wl,-Map,zig-out/zig-gba.map",
        "-specs=" ++ devkitpro ++ "/devkitARM/arm-none-eabi/lib/gba.specs",
        "zig-out/zig-gba.o",
        "-L" ++ devkitpro ++ "/libgba/lib",
        "-L" ++ devkitpro ++ "/portlibs/libgba/lib",
    } ++ flags ++ .{
        "-o",
        "zig-out/zig-gba.elf",
    }));

    const gba = b.addSystemCommand(&.{
        devkitpro ++ "/devkitARM/bin/arm-none-eabi-objcopy",
        "-O",
        "binary",
        "zig-out/zig-gba.elf",
        "zig-out/zig-gba.gba",
    });

    const fix = b.addSystemCommand(&.{
        devkitpro ++ "/tools/bin/gbafix",
        "zig-out/zig-gba.gba",
    });
    fix.stdout_action = .ignore;

    b.default_step.dependOn(&fix.step);
    fix.step.dependOn(&gba.step);
    gba.step.dependOn(&elf.step);
    elf.step.dependOn(&obj.step);

    // run in mgba
    const run_step = b.step("run", "Run in mGBA");
    const emulator = b.addSystemCommand(&.{ "mgba", "zig-out/zig-gba.gba" });
    run_step.dependOn(&gba.step);
    run_step.dependOn(&emulator.step);
}
