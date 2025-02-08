const std = @import("std");

pub fn build(b: *std.Build) void {
    const arch = b.option(std.Target.Cpu.Arch, "arch", "") orelse std.Target.Cpu.Arch.x86;

    var featuresAdd = std.Target.Cpu.Feature.Set.empty;
    var featuresSub = std.Target.Cpu.Feature.Set.empty;
    switch (arch) {
        std.Target.Cpu.Arch.x86, std.Target.Cpu.Arch.x86_64 => {
            featuresAdd.addFeature(@intFromEnum(std.Target.x86.Feature.soft_float));
            featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.x87));
            featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.mmx));
            featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.sse));
            featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.sse2));
            featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.avx));
            featuresSub.addFeature(@intFromEnum(std.Target.x86.Feature.avx2));
        },
        else => {},
    }
    const targetQuery = std.Target.Query{
        .cpu_arch = arch,
        .cpu_features_add = featuresAdd,
        .cpu_features_sub = featuresSub,
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
    };
    const target = b.resolveTargetQuery(targetQuery);
    const optimize = b.standardOptimizeOption(.{});

    switch (arch) {
        std.Target.Cpu.Arch.aarch64, std.Target.Cpu.Arch.aarch64_be => {
            const supervisor = b.addExecutable(.{
                .name = "supervisor",
                .root_source_file = b.path("src/main.zig"),
                .target = target,
                .optimize = optimize,
            });
            supervisor.addSystemIncludePath(b.path("src"));
            supervisor.setLinkerScript(b.path("src/aarch64.ld"));
            b.installArtifact(supervisor);
        },
        std.Target.Cpu.Arch.riscv32, std.Target.Cpu.Arch.riscv64 => {
            const supervisor = b.addExecutable(.{
                .name = "supervisor",
                .root_source_file = b.path("src/main.zig"),
                .target = target,
                .optimize = optimize,
            });
            supervisor.addSystemIncludePath(b.path("src"));
            supervisor.setLinkerScript(b.path("src/riscv.ld"));
            b.installArtifact(supervisor);
        },
        std.Target.Cpu.Arch.x86 => {
            const supervisor = b.addExecutable(.{
                .name = "supervisor",
                .root_source_file = b.path("src/multiboot.zig"),
                .target = target,
                .optimize = optimize,
            });
            supervisor.addSystemIncludePath(b.path("src"));
            supervisor.setLinkerScript(b.path("src/multiboot_x86.ld"));
            supervisor.addAssemblyFile(b.path("src/multiboot_x86.S"));
            b.installArtifact(supervisor);
        },
        std.Target.Cpu.Arch.x86_64 => {
            const supervisor = b.addExecutable(.{
                .name = "supervisor",
                .root_source_file = b.path("src/multiboot.zig"),
                .target = target,
                .optimize = optimize,
                .code_model = .kernel,
            });
            supervisor.addSystemIncludePath(b.path("src"));
            supervisor.setLinkerScript(b.path("src/multiboot_x86_64.ld"));
            supervisor.addAssemblyFile(b.path("src/multiboot_x86_64.S"));
            b.installArtifact(supervisor);
        },
        else => {},
    }
}
