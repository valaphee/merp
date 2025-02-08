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

/// Input from Port
pub inline fn in(port: u16, _type: type) _type {
    return switch (_type) {
        u8 => asm volatile ("in %[port], %[data]"
            : [data] "={al}" (-> _type),
            : [port] "N{dx}" (port),
        ),
        u16 => asm volatile ("in %[port], %[data]"
            : [data] "={ax}" (-> _type),
            : [port] "N{dx}" (port),
        ),
        u32 => asm volatile ("in %[port], %[data]"
            : [data] "={eax}" (-> _type),
            : [port] "N{dx}" (port),
        ),
        else => @compileError("Expected u8, u16 or u32, found: " ++ @typeName(_type)),
    };
}

/// Output to Port
pub inline fn out(port: u16, data: anytype) void {
    switch (@TypeOf(data)) {
        u8 => asm volatile ("out %[data], %[port]"
            :
            : [port] "N{dx}" (port),
              [data] "{al}" (data),
        ),
        u16 => asm volatile ("out %[data], %[port]"
            :
            : [port] "N{dx}" (port),
              [data] "{ax}" (data),
        ),
        u32 => asm volatile ("out %[data], %[port]"
            :
            : [port] "N{dx}" (port),
              [data] "{eax}" (data),
        ),
        else => @compileError("Expected u8, u16 or u32, found: " ++ @typeName(@TypeOf(data))),
    }
}

const Descriptor = packed struct {
    limitLo: u16,
    baseLo: u24,
    type: u4,
    s: bool,
    dpl: u2,
    p: bool,
    limitHi: u4,
    _: u1 = 0,
    l: bool,
    db: bool,
    g: bool,
    baseHi: u8,
};

// TODO: remove pub when exports from includes are visible to assembly
pub var gdt: [7]Descriptor = .{ .{
    .p = false,
    .baseLo = 0x000000,
    .baseHi = 0x00,
    .limitLo = 0x0000,
    .limitHi = 0x0,
    .type = 0x0,
    .s = false,
    .dpl = 0,
    .l = false,
    .db = false,
    .g = false,
}, .{
    .p = true,
    .baseLo = 0x000000,
    .baseHi = 0x00,
    .limitLo = 0xFFFF,
    .limitHi = 0xF,
    .type = 0xB,
    .s = true,
    .dpl = 0,
    .l = builtin.cpu.arch == .x86_64,
    .db = builtin.cpu.arch == .x86,
    .g = true,
}, .{
    .p = true,
    .baseLo = 0x000000,
    .baseHi = 0x00,
    .limitLo = 0xFFFF,
    .limitHi = 0xF,
    .type = 0x3,
    .s = true,
    .dpl = 0,
    .l = false,
    .db = true,
    .g = true,
}, .{
    .p = true,
    .baseLo = 0x000000,
    .baseHi = 0x00,
    .limitLo = 0xFFFF,
    .limitHi = 0xF,
    .type = 0xB,
    .s = true,
    .dpl = 3,
    .l = builtin.cpu.arch == .x86_64,
    .db = builtin.cpu.arch == .x86,
    .g = true,
}, .{
    .p = true,
    .baseLo = 0x000000,
    .baseHi = 0x00,
    .limitLo = 0xFFFF,
    .limitHi = 0xF,
    .type = 0x3,
    .s = true,
    .dpl = 3,
    .l = false,
    .db = true,
    .g = true,
}, .{
    .p = false,
    .baseLo = 0x000000,
    .baseHi = 0x00,
    .limitLo = 0x0000,
    .limitHi = 0x0,
    .type = 0x9,
    .s = false,
    .dpl = 0,
    .l = false,
    .db = false,
    .g = false,
}, .{
    .p = false,
    .baseLo = 0x000000,
    .baseHi = 0x00,
    .limitLo = 0x0000,
    .limitHi = 0x0,
    .type = 0x9,
    .s = false,
    .dpl = 0,
    .l = false,
    .db = false,
    .g = false,
} };

const InterruptDescriptor = packed struct {
    baseLo: u16,
    ss: u16,
    ist: u3,
    _0: u5 = 0,
    type: u4,
    _1: u1 = 0,
    dpl: u2,
    p: bool,
    baseHi: u16,
};

// TODO: remove pub when exports from includes are visible to assembly
pub var idt: [48]InterruptDescriptor = [_]InterruptDescriptor{.{
    .baseLo = 0x0000,
    .baseHi = 0x0000,
    .ss = 0,
    .ist = 0,
    .type = 0,
    .dpl = 0,
    .p = false,
}} ** 48;
