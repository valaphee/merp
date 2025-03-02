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

const Machine = @import("../Machine.zig");
const Process = @import("../Process.zig");

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

const NULL = 0;
const KCODE = 1;
const KDATA = 2;
const UCODE = 3;
const UDATA = 4;
const TSS = 5;
const TSS64 = 6;

export var gdt: [7]Descriptor = .{
    // NULL
    .{
        .baseLo = 0x000000,
        .baseHi = 0x00,
        .limitLo = 0x0000,
        .limitHi = 0x0,
        .type = 0x0,
        .s = false,
        .dpl = 0,
        .p = false,
        .l = false,
        .db = false,
        .g = false,
    },
    // KCODE
    .{
        .baseLo = 0x000000,
        .baseHi = 0x00,
        .limitLo = 0xFFFF,
        .limitHi = 0xF,
        .type = 0xB,
        .s = true,
        .dpl = 0,
        .p = true,
        .l = builtin.cpu.arch == .x86_64,
        .db = builtin.cpu.arch != .x86_64,
        .g = true,
    },
    // KDATA
    .{
        .baseLo = 0x000000,
        .baseHi = 0x00,
        .limitLo = 0xFFFF,
        .limitHi = 0xF,
        .type = 0x3,
        .s = true,
        .dpl = 0,
        .p = true,
        .l = false,
        .db = true,
        .g = true,
    },
    // UCODE
    .{
        .baseLo = 0x000000,
        .baseHi = 0x00,
        .limitLo = 0xFFFF,
        .limitHi = 0xF,
        .type = 0xB,
        .s = true,
        .dpl = 3,
        .p = true,
        .l = builtin.cpu.arch == .x86_64,
        .db = builtin.cpu.arch != .x86_64,
        .g = true,
    },
    // UDATA
    .{
        .baseLo = 0x000000,
        .baseHi = 0x00,
        .limitLo = 0xFFFF,
        .limitHi = 0xF,
        .type = 0x3,
        .s = true,
        .dpl = 3,
        .p = true,
        .l = false,
        .db = true,
        .g = true,
    },
    // TSS
    .{
        .baseLo = 0x000000,
        .baseHi = 0x00,
        .limitLo = 0x0000,
        .limitHi = 0x0,
        .type = 0x9,
        .s = false,
        .dpl = 0,
        .p = false,
        .l = false,
        .db = false,
        .g = false,
    },
    .{
        .baseLo = 0x000000,
        .baseHi = 0x00,
        .limitLo = 0x0000,
        .limitHi = 0x0,
        .type = 0x0,
        .s = false,
        .dpl = 0,
        .p = false,
        .l = false,
        .db = false,
        .g = false,
    },
};

const InterruptDescriptor = packed struct {
    baseLo: u16,
    cs: u16,
    ist: u3,
    _0: u5 = 0,
    type: u4,
    _1: u1 = 0,
    dpl: u2,
    p: bool,
    baseHi: if (builtin.cpu.arch != .x86_64) u16 else u80,
};

export var idt: [256]InterruptDescriptor = undefined;

const TaskStateSegment = if (builtin.cpu.arch != .x86_64) extern struct {
    link: u16,
    _0: u16 = 0,
    sp0: u32,
    ss0: u16,
    _1: u16 = 0,
    sp1: u32,
    ss1: u16,
    _2: u16 = 0,
    sp2: u32,
    ss2: u16,
    _3: u16 = 0,
    cr3: u32,
    eip: u32,
    eflags: u32,
    eax: u32,
    ecx: u32,
    edx: u32,
    ebx: u32,
    esp: u32,
    ebp: u32,
    esi: u32,
    edi: u32,
    es: u16,
    _4: u16 = 0,
    cs: u16,
    _5: u16 = 0,
    ss: u16,
    _6: u16 = 0,
    ds: u16,
    _7: u16 = 0,
    fs: u16,
    _8: u16 = 0,
    gs: u16,
    _9: u16 = 0,
    ldtr: u16,
    _10: u16 = 0,
    _11: u16 = 0,
    iopb: u16,
} else extern struct {
    _0: u32 = 0,
    sp0: u64 align(4),
    sp1: u64 align(4),
    sp2: u64 align(4),
    _1: u64 align(4) = 0,
    ist1: u64 align(4),
    ist2: u64 align(4),
    ist3: u64 align(4),
    ist4: u64 align(4),
    ist5: u64 align(4),
    ist6: u64 align(4),
    ist7: u64 align(4),
    _2: u64 align(4) = 0,
    _3: u16 = 0,
    iopb: u16,
};

var tss: TaskStateSegment = undefined;

pub const State = extern struct {
    gpr: [15]u64,
    int: u64,
    err: u64,
    ip: u64,
    cs: u16,
    fl: u64,
    sp: u64,
    ss: u16,
    mc: u64,
};

fn isr(comptime int: u8) fn () callconv(.Naked) noreturn {
    return struct {
        fn _() callconv(.Naked) noreturn {
            switch (int) {
                0x08, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x11, 0x15, 0x1D, 0x1E => {},
                else => asm volatile ("push $0"),
            }
            asm volatile (
                \\ push %[int]
                \\ jmp isrCommon
                :
                : [int] "n" (int),
            );
        }
    }._;
}

export fn isrCommon() callconv(.Naked) noreturn {
    asm volatile (
        \\push %r15
        \\push %r14
        \\push %r13
        \\push %r12
        \\push %r11
        \\push %r10
        \\push %r9
        \\push %r8
        \\push %rdi
        \\push %rsi
        \\push %rbp
        //push %rsp
        \\push %rbx
        \\push %rdx
        \\push %rcx
        \\push %rax
    );
}

pub fn installMachine(_: *Machine) void {
    tss.iopb = @sizeOf(@TypeOf(tss));

    const tssAddr = @intFromPtr(&tss);
    const tssSize = @sizeOf(@TypeOf(tss)) - 1;
    gdt[TSS].baseLo = @truncate(tssAddr);
    gdt[TSS].baseHi = @truncate(tssAddr >> 24);
    if (builtin.cpu.arch == .x86_64) {
        gdt[TSS64].limitLo = @truncate(tssAddr >> 32);
        gdt[TSS64].baseLo = @truncate(tssAddr >> 48);
    }
    gdt[TSS].limitLo = @truncate(tssSize);
    gdt[TSS].limitHi = tssSize >> 16;
    asm volatile ("ltr %ax"
        :
        : [tss] "{ax}" (TSS << 3),
    );

    inline for (&idt, 0..) |*id, i| {
        const isrAddr = @intFromPtr(&isr(i));
        id.baseLo = @truncate(isrAddr);
        id.baseHi = isrAddr >> 16;
        id.cs = KCODE << 3;
        id.ist = 0;
        id.type = 0xE;
        id.dpl = 0;
        id.p = true;
    }
}

pub fn installProcess(process: *Process) noreturn {
    tss.sp0 = @intFromPtr(&process.state) + @offsetOf(@TypeOf(process.state), "mc");
    asm volatile (
        \\mov %rsp, %[state]
        \\pop %rax
        \\pop %rcx
        \\pop %rdx
        \\pop %rbx
        //pop %rsp
        \\pop %rbp
        \\pop %rsi
        \\pop %rdi
        \\pop %r8
        \\pop %r9
        \\pop %r10
        \\pop %r11
        \\pop %r12
        \\pop %r13
        \\pop %r14
        \\pop %r15
        \\add %rsp, 16
        \\iret
        :
        : [state] "X" (&process.state),
    );
    unreachable;
}
