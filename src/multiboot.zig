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

const multiboot = @cImport(@cInclude("multiboot.h"));

const com = @import("x86/com.zig");
const cpu = @import("x86/cpu.zig");
const pic = @import("x86/pic.zig");

const multiboot_flags = multiboot.MULTIBOOT_PAGE_ALIGN | multiboot.MULTIBOOT_MEMORY_INFO;
export const multiboot_header linksection(".multiboot") = multiboot.multiboot_header{
    .magic = multiboot.MULTIBOOT_HEADER_MAGIC,
    .flags = multiboot_flags,
    .checksum = @bitCast(-(multiboot.MULTIBOOT_HEADER_MAGIC + multiboot_flags)),
};

var stack: [0x1000]u8 align(16) = undefined;

export fn _start() callconv(.Naked) noreturn {
    // call main with multiboot arguments
    asm volatile (
        \\ mov %[stack_top], %%esp
        \\ mov %%esp, %%ebp
        \\ push %%ebx
        \\ push %%eax
        \\ call %[main:P]
        :
        : [stack_top] "i" (@as([*]align(16) u8, @ptrCast(&stack)) + @sizeOf(@TypeOf(stack))),
          [main] "X" (&main),
    );
}

fn main(
    multiboot_magic: u32,
    multiboot_info: u32,
) callconv(.C) void {
    if (multiboot_magic != multiboot.MULTIBOOT_BOOTLOADER_MAGIC) {
        return;
    }

    const multiboot_info_ptr: *multiboot.multiboot_info = @ptrFromInt(multiboot_info);
    _ = multiboot_info_ptr;

    while (true) {}
}
