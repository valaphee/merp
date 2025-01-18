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

//! cpu routines

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

const DescriptorType = enum {
    Code,
    Data,
    Tss,
};

const Descriptor = packed struct {
    limit_0_15: u16,
    base_0_23: u24,
    accessed: bool,
    readable_writable: bool,
    conforming_direction: bool,
    executable: bool,
    system: bool,
    dpl: u2,
    present: bool,
    limit_16_19: u4,
    _: u1 = 0,
    long_mode: bool,
    size: bool,
    granularity: bool,
    base_24_31: u8,
};

fn descriptor(
    base: usize,
    limit: u20,
    dpl: u2,
    _type: DescriptorType,
) Descriptor {
    return .{
        .limit_0_15 = limit & 0xFFFF,
        .base_0_23 = base & 0xFFFFFF,
        .accessed = true,
        .readable_writable = _type != DescriptorType.Tss,
        .conforming_direction = false,
        .executable = _type != DescriptorType.Data,
        .system = _type != DescriptorType.Tss,
        .dpl = dpl,
        .present = true,
        .limit_16_19 = limit >> 16,
        .long_mode = false,
        .size = _type != DescriptorType.Tss,
        .granularity = _type != DescriptorType.Tss,
        .base_24_31 = base >> 24,
    };
}

const DescriptorTableRegister = struct {
    size: u16,
    offset: [*]Descriptor align(2),
};

const KCODE = 1 << 3;
const KDATA = 2 << 3;
const UCODE = 3 << 3;
const UDATA = 4 << 3;
const TSS = 5 << 3;

const gdt: [6]Descriptor = .{
    undefined,
    descriptor(0x00000000, 0xFFFFF, 0, .Code), // KCODE
    descriptor(0x00000000, 0xFFFFF, 0, .Data), // KDATA
    descriptor(0x00000000, 0xFFFFF, 3, .Code), // UCODE
    descriptor(0x00000000, 0xFFFFF, 3, .Data), // UDATA
    descriptor(0x00000000, 0x00000, 0, .Tss), // TSS
};

pub fn initialize() void {
    const gdtr = DescriptorTableRegister{ .size = @sizeOf(@TypeOf(gdt)) - 1, .offset = @constCast(&gdt) };
    asm volatile (
        \\lgdt (%[gdtr])
        \\mov %[data], %%ds
        \\mov %[data], %%es
        \\mov %[data], %%fs
        \\mov %[data], %%gs
        \\mov %[data], %%ss
        \\ljmpl %[code], $1f
        \\1:
        :
        : [gdtr] "r" (&gdtr),
          [code] "X" (KCODE),
          [data] "r" (KDATA),
    );
}
