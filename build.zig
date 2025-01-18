const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const kernel = b.addExecutable(.{
        .name = "kernel",
        .root_source_file = b.path("src/multiboot.zig"),
        .target = target,
        .optimize = optimize,
        .code_model = .kernel,
    });
    kernel.addSystemIncludePath(b.path("src"));
    kernel.setLinkerScript(b.path("src/multiboot.ld"));
    b.installArtifact(kernel);
}
