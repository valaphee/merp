const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const arch = b.option(std.Target.Cpu.Arch, "arch", "Architecture to build for") orelse builtin.cpu.arch;
    const optimize = b.standardOptimizeOption(.{});

    if (arch.isX86()) {
        var featuresAdd = std.Target.Cpu.Feature.Set.empty;
        var featuresSub = std.Target.Cpu.Feature.Set.empty;
        featuresAdd.addFeature(@intFromEnum(std.Target.x86.Feature.soft_float));
        featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.x87));
        featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.mmx));
        featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.sse));
        featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.sse2));
        featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.avx));
        featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.avx2));
        const targetQuery = std.Target.Query{
            .cpu_arch = arch,
            .cpu_features_add = featuresAdd,
            .cpu_features_sub = featuresSub,
            .os_tag = std.Target.Os.Tag.freestanding,
        };
        const target = b.resolveTargetQuery(targetQuery);

        const exe = b.addExecutable(.{
            .name = "acorn",
            .root_source_file = b.path("src/multiboot.zig"),
            .target = target,
            .optimize = optimize,
            .code_model = if (arch == .x86_64) .kernel else .default,
        });
        exe.addIncludePath(b.path("src"));
        if (arch == .x86_64) {
            exe.setLinkerScript(b.path("src/multiboot_x86_64.ld"));
            exe.addAssemblyFile(b.path("src/multiboot_x86_64.S"));
        } else {
            exe.setLinkerScript(b.path("src/multiboot_x86.ld"));
            exe.addAssemblyFile(b.path("src/multiboot_x86.S"));
        }
        b.installArtifact(exe);
    }
    if (arch == .x86_64) {
        const targetQuery = std.Target.Query{
            .cpu_arch = arch,
            .os_tag = std.Target.Os.Tag.uefi,
        };
        const target = b.resolveTargetQuery(targetQuery);

        const exe = b.addExecutable(.{
            .name = "acorn",
            .root_source_file = b.path("src/uefi.zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.addIncludePath(b.path("src"));
        exe.addIncludePath(b.path("lib/edk2/MdePkg/Include"));
        exe.addIncludePath(b.path("lib/edk2/MdePkg/Include/X64"));
        b.installArtifact(exe);
    }
}
