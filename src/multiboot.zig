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

var stack: [0x1000]u8 align(16) = undefined;

export fn _start() linksection(".init") callconv(.Naked) noreturn {
    const mb_magic = asm volatile (""
        : [res] "={eax}" (-> u32),
    );
    const mb_info = asm volatile (""
        : [res] "={ebx}" (-> u32),
    );

    asm volatile (
        \\ mov %[stack_top], %%esp
        \\ mov %%esp, %%ebp
        \\ push %[mb_info]
        \\ push %[mb_magic]
        \\ call %[main:P]
        :
        : [stack_top] "i" (@as([*]align(16) u8, @ptrCast(&stack)) + @sizeOf(@TypeOf(stack))),
          [mb_magic] "X" (mb_magic),
          [mb_info] "X" (mb_info),
          [main] "X" (&main),
    );
}

fn main(
    multiboot_magic: u32,
    multiboot_info: u32,
) callconv(.C) void {
    if (multiboot_magic != c.MULTIBOOT_BOOTLOADER_MAGIC) {
        return;
    }

    const multiboot_info_ptr: *c.multiboot_info = @ptrFromInt(multiboot_info);
    _ = multiboot_info_ptr;

    while (true) {}
}
