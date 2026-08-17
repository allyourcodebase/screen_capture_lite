const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("upstream", .{});

    const mod = b.addModule("screen_capture_lite", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });

    const lib = b.addLibrary(.{
        .name = "screen_capture_lite",
        .linkage = .static,
        .root_module = mod,
    });
    lib.installHeader(upstream.path("include/ScreenCapture_C_API.h"), "ScreenCapture_C_API.h");
    b.installArtifact(lib);

    mod.addIncludePath(upstream.path("include"));
    mod.addIncludePath(upstream.path("include/internal"));
    mod.addCSourceFiles(.{
        .root = upstream.path("src_cpp"),
        .files = &.{
            "ScreenCapture.c",
            "ScreenCapture.cpp",
            "SCCommon.cpp",
            "ThreadManager.cpp",
        },
    });

    switch (target.result.os.tag) {
        else => {},
        .linux => {
            mod.addIncludePath(upstream.path("include/linux"));
            mod.addCSourceFiles(.{
                .root = upstream.path("src_cpp/linux"),
                .files = &.{
                    "X11MouseProcessor.cpp",
                    "X11FrameProcessor.cpp",
                    "GetMonitors.cpp",
                    "GetWindows.cpp",
                    "ThreadRunner.cpp",
                },
            });

            const x11_headers = b.lazyDependency("x11-headers", .{}) orelse return;
            mod.addIncludePath(x11_headers.path("."));
            const unix_headers = b.lazyDependency("wio-unix-headers", .{}) orelse return;
            mod.addIncludePath(unix_headers.path("include"));

            mod.linkSystemLibrary("X11", .{});
            mod.linkSystemLibrary("Xinerama", .{});
            mod.linkSystemLibrary("Xi", .{});
            mod.linkSystemLibrary("Xfixes", .{});
            mod.linkSystemLibrary("Xext", .{});
            // mod.linkSystemLibrary("Xrandr", .{});
            // mod.linkSystemLibrary("Xcursor", .{});
        },
    }

    const test_exe = b.addExecutable(.{
        .name = "test",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });
    test_exe.root_module.addIncludePath(upstream.path("include"));
    // test_exe.root_module.addIncludePath(upstream.path("include/internal"));
    test_exe.root_module.addCSourceFile(.{
        .file = upstream.path("Example_CPP/Screen_Capture_Example.cpp"),
    });
    test_exe.root_module.linkLibrary(lib);
    // test_exe.root_module.linkSystemLibrary("X11", .{});
    // test_exe.root_module.linkSystemLibrary("Xinerama", .{});
    // test_exe.root_module.linkSystemLibrary("Xi", .{});
    // test_exe.root_module.linkSystemLibrary("Xfixes", .{});
    // test_exe.root_module.linkSystemLibrary("Xtst", .{});

    const test_step = b.step("test", "build test program");
    test_step.dependOn(&b.addRunArtifact(test_exe).step);
}
