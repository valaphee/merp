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

const c = @cImport(@cInclude("multiboot.h"));
const cpu = @import("x86/cpu.zig");

var system = @import("System.zig"){};

// TODO: remove when exports from includes are visible to assembly
comptime {
    @export(&cpu.gdt, .{ .name = "gdt", .linkage = .strong });
    @export(&cpu.idt, .{ .name = "idt", .linkage = .strong });
}

export fn main(
    multibootMagic: u32,
    multibootInfoAddr: u32,
) callconv(.C) void {
    if (multibootMagic != c.MULTIBOOT_BOOTLOADER_MAGIC) {
        @trap(); // TODO
    }

    const multibootInfo: *const c.multiboot_info = @ptrFromInt(multibootInfoAddr);
    if (multibootInfo.flags & c.MULTIBOOT_INFO_MEM_MAP == 0) {
        @trap(); // TODO
    }

    const multibootMmapUnsized: [*]const u8 = @ptrFromInt(multibootInfo.mmap_addr);
    var multibootMmap = multibootMmapUnsized[0..multibootInfo.mmap_length];
    while (multibootMmap.len != 0) {
        const multibootMmapEntry: *const c.multiboot_mmap_entry = @ptrCast(multibootMmap);
        if (multibootMmapEntry.type == c.MULTIBOOT_MEMORY_AVAILABLE) {
            system.markMemoryFree(multibootMmapEntry.addr, multibootMmapEntry.len);
        }
        multibootMmap = multibootMmap[(@sizeOf(c.multiboot_uint32_t) + multibootMmapEntry.size)..];
    }

    @trap(); // TODO
}
