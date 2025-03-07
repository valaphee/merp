// Copyright 2025 Kevin Ludwig
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.Build) void {
    const arch = b.option(std.Target.Cpu.Arch, "arch", "Architecture to build for") orelse builtin.cpu.arch;
    const optimize = b.standardOptimizeOption(.{});

    switch (arch) {
        .x86, .x86_64 => {
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
                .name = "merp",
                .root_source_file = b.path("src/multiboot.zig"),
                .target = target,
                .optimize = optimize,
                .code_model = if (arch == .x86_64) .kernel else .default,
            });
            exe.stack_size = 4096;
            exe.addIncludePath(b.path("src"));
            exe.setLinkerScript(if (arch == .x86_64) b.path("src/multiboot_x86_64.ld") else b.path("src/multiboot_x86.ld"));
            exe.addAssemblyFile(if (arch == .x86_64) b.path("src/multiboot_x86_64.S") else b.path("src/multiboot_x86.S"));
            b.installArtifact(exe);
        },
        else => {},
    }
}
