const std = @import("std");

pub fn build(b: *std.Build) void {
    var featuresAdd = std.Target.Cpu.Feature.Set.empty;
    featuresAdd.addFeature(@intFromEnum(std.Target.x86.Feature.soft_float));
    var featuresSub = std.Target.Cpu.Feature.Set.empty;
    featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.mmx));
    featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.sse));
    featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.sse2));
    featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.avx));
    featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.avx2));
    const targetQuery = std.Target.Query{
        .cpu_arch = std.Target.Cpu.Arch.x86,
        .cpu_features_add = featuresAdd,
        .cpu_features_sub = featuresSub,
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
    };
    const target = b.resolveTargetQuery(targetQuery);
    const optimize = b.standardOptimizeOption(.{});

    const supervisor = b.addExecutable(.{
        .name = "supervisor",
        .root_source_file = b.path("src/multiboot.zig"),
        .target = target,
        .optimize = optimize,
        .code_model = .kernel,
    });
    supervisor.addSystemIncludePath(b.path("src"));
    supervisor.setLinkerScript(b.path("src/multiboot_x86.ld"));
    b.installArtifact(supervisor);
}
