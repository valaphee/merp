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

var system = @import("System.zig"){};

export fn main(
    multibootMagic: u32,
    multibootInfoAddr: u32,
) callconv(.C) noreturn {
    if (multibootMagic != c.MULTIBOOT_BOOTLOADER_MAGIC) {
        @trap();
    }

    const multibootInfo: *const c.multiboot_info = @ptrFromInt(multibootInfoAddr);
    if (multibootInfo.flags & c.MULTIBOOT_INFO_MEM_MAP == 0) {
        @trap();
    }

    const multibootMmapUnsized: [*]const u8 = @ptrFromInt(multibootInfo.mmap_addr);
    var multibootMmap = multibootMmapUnsized[0..multibootInfo.mmap_length];
    while (multibootMmap.len != 0) {
        const multibootMmapEntry: *const c.multiboot_mmap_entry = @ptrCast(multibootMmap);
        multibootMmap = multibootMmap[(multibootMmapEntry.size + 4)..];
        if (multibootMmapEntry.type == c.MULTIBOOT_MEMORY_AVAILABLE) {
            system.markFree(multibootMmapEntry.addr, multibootMmapEntry.len);
        }
    }

    @trap();
}
