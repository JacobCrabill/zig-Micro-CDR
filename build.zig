const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(
        std.builtin.LinkMode,
        "linkage",
        "Specify static or dynamic linkage",
    ) orelse .static;

    const std_mod_options: std.Build.Module.CreateOptions = .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .pic = true,
    };

    const upstream = b.dependency("microcdr", .{});

    const std_c_flags: []const []const u8 = &.{
        "--std=c99",
        "-pthread",
        "-Wall",
        "-Wextra",
        "-pedantic",
        "-Wcast-align",
        "-Wshadow",
        "-fstrict-aliasing",
    };

    ////////////////////////////////////////////////////////////////////////////////
    // Micro-CDR Library
    ////////////////////////////////////////////////////////////////////////////////

    const microcdr = b.addLibrary(.{
        .name = "microcdr",
        .root_module = b.createModule(std_mod_options),
        .linkage = linkage,
    });

    const native_endian = @import("builtin").target.cpu.arch.endian();
    const is_littleendian: u8 = if (native_endian == .little) 1 else 0;

    const config_h = b.addConfigHeader(.{
        .style = .{ .cmake = upstream.path("include/ucdr/config.h.in") },
        .include_path = "ucdr/config.h",
    }, .{
        .PROJECT_VERSION_MAJOR = 2,
        .PROJECT_VERSION_MINOR = 0,
        .PROJECT_VERSION_PATCH = 1,
        .PROJECT_VERSION = "2.0.1",
        .CONFIG_MACHINE_ENDIANNESS = is_littleendian,
    });
    microcdr.addConfigHeader(config_h);
    microcdr.installHeader(config_h.getOutput(), "ucdr/config.h");

    microcdr.addCSourceFiles(.{
        .root = upstream.path("src/c"),
        .files = &.{
            "common.c",
            "types/basic.c",
            "types/string.c",
            "types/array.c",
            "types/sequence.c",
        },
        .flags = std_c_flags,
    });
    microcdr.addIncludePath(upstream.path("include"));
    microcdr.addIncludePath(upstream.path("src/c"));

    microcdr.installHeadersDirectory(upstream.path("include"), "", .{});

    b.installArtifact(microcdr);
}
