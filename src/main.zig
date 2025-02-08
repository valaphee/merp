// Copyright 2024 Kevin Ludwig
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

var stack: [0x1000]u8 align(16) = undefined;

export fn _start() callconv(.Naked) noreturn {
    switch (builtin.cpu.arch) {
        .aarch64, .aarch64_be => {
            asm volatile (
                \\ mov sp, %[stack_top]
                \\ bl %[main]
                :
                : [stack_top] "X" (@as([*]align(16) u8, @ptrCast(&stack)) + @sizeOf(@TypeOf(stack))),
                  [main] "X" (&main),
            );
        },
        .riscv32, .riscv64 => {
            asm volatile (
                \\ la sp, %[stack_top]
                \\ call %[main]
                :
                : [stack_top] "i" (@as([*]align(16) u8, @ptrCast(&stack)) + @sizeOf(@TypeOf(stack))),
                  [main] "X" (&main),
            );
        },
        else => {},
    }
}

fn main() callconv(.C) void {}
