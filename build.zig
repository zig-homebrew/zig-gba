const std = @import("std");
const builtin = @import("builtin");

const emulator = "mgba";
const flags = .{"-lgba"};
const devkitpro = "/opt/devkitpro";

pub fn build(b: *std.build.Builder) void {
    const target = std.zig.CrossTarget{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm7tdmi },
    };
    const optimize = b.standardOptimizeOption(.{});

    const obj = b.addObject(.{
        .name = "zig-gba",
        .root_source_file = .{ .path = "src/main.zig" },
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    obj.setLibCFile(std.build.FileSource{ .path = "libc.txt" });
    obj.addIncludePath(devkitpro ++ "/libgba/include");
    obj.addIncludePath(devkitpro ++ "/portlibs/gba/include");
    obj.addIncludePath(devkitpro ++ "/portlibs/armv4/include");

    const extension = if (builtin.target.os.tag == .windows) ".exe" else "";
    const elf = b.addSystemCommand(&.{
        devkitpro ++ "/devkitARM/bin/arm-none-eabi-gcc" ++ extension,
        "-g",
        "-mthumb",
        "-mthumb-interwork",
    });
    _ = elf.addPrefixedOutputFileArg("-Wl,-Map,", "zig-gba.map");
    elf.addPrefixedFileSourceArg("-specs=", .{ .path = devkitpro ++ "/devkitARM/arm-none-eabi/lib/gba.specs" });
    elf.addFileSourceArg(obj.getOutputSource());
    elf.addArgs(&.{
        "-L" ++ devkitpro ++ "/libgba/lib",
        "-L" ++ devkitpro ++ "/portlibs/gba/lib",
        "-L" ++ devkitpro ++ "/portlibs/armv4/lib",
    });
    elf.addArgs(&flags);
    elf.addArg("-o");
    const elf_file = elf.addOutputFileArg("zig-gba.elf");

    const gba = b.addSystemCommand(&.{
        devkitpro ++ "/devkitARM/bin/arm-none-eabi-objcopy" ++ extension,
        "-O",
        "binary",
    });
    gba.addFileSourceArg(elf_file);
    const gba_file = gba.addOutputFileArg("zig-gba.gba");

    const fix = b.addSystemCommand(&.{devkitpro ++ "/tools/bin/gbafix" ++ extension});
    fix.addFileSourceArg(gba_file);

    const install = b.addInstallBinFile(gba_file, "zig-gba.gba");

    b.default_step.dependOn(&install.step);
    install.step.dependOn(&fix.step);
    fix.step.dependOn(&gba.step);
    gba.step.dependOn(&elf.step);
    elf.step.dependOn(&obj.step);

    const run_step = b.step("run", "Run in mGBA");
    const mgba = b.addSystemCommand(&.{emulator});
    mgba.addFileSourceArg(gba_file);
    run_step.dependOn(&install.step);
    run_step.dependOn(&mgba.step);
}
