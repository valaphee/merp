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

///////////////////////////////////////////////////////////////////////////////
// Externs
///////////////////////////////////////////////////////////////////////////////

const builtin = @import("builtin");

const machine = @import("../machine.zig");
const Process = @import("../Process.zig");

///////////////////////////////////////////////////////////////////////////////
// Globals
///////////////////////////////////////////////////////////////////////////////

const _64 = builtin.cpu.arch == .x86_64;

pub const PhysAddr = u64; // PAE
pub const VirtAddr = usize;

const SYSENTER_CS = 0x00000174;
const SYSENTER_SP = 0x00000175;
const SYSENTER_IP = 0x00000176;

const EFER = 0xC0000080;
const EFER_SCE = 1 << 0;
const STAR = 0xC0000081;
const LSTAR = 0xC0000082;
const CSTAR = 0xC0000083;
const SF_MASK = 0xC0000084;

///////////////////////////////////////////////////////////////////////////////
// Segments
///////////////////////////////////////////////////////////////////////////////

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
        .l = _64,
        .db = !_64,
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
        .l = _64,
        .db = !_64,
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
        .p = true,
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

///////////////////////////////////////////////////////////////////////////////
// Interrupts
///////////////////////////////////////////////////////////////////////////////

const InterruptDescriptor = packed struct {
    baseLo: u16,
    cs: u16,
    ist: u3,
    _0: u5 = 0,
    type: u4,
    _1: u1 = 0,
    dpl: u2,
    p: bool,
    baseHi: if (_64) u48 else u16,
    _2: if (_64) u32 else u0 = 0,
};

export var idt: [256]InterruptDescriptor = undefined;

fn isr(comptime n: u8) fn () callconv(.Naked) noreturn {
    return struct {
        fn isr() callconv(.Naked) noreturn {
            switch (n) {
                0x08, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x11, 0x15, 0x1D, 0x1E => {},
                else => asm volatile ("push $0"),
            }
            asm volatile (
                \\ push %[n]
                \\ jmp isrCommon
                :
                : [n] "n" (n),
            );
        }
    }.isr;
}

export fn isrCommon() callconv(.Naked) noreturn {
    if (_64) asm volatile (
        \\push %rax
        \\push %rcx
        \\push %rdx
        \\push %rbx
        //push %rsp
        \\push %rbp
        \\push %rsi
        \\push %rdi
        \\push %r8
        \\push %r9
        \\push %r10
        \\push %r11
        \\push %r12
        \\push %r13
        \\push %r14
        \\push %r15
        \\mov  %rsp    , %rdi
        \\mov  stackTop, %rsp
        \\push %rdi
        \\call %[isr:P]
        :
        : [isr] "X" (&machine.isr),
    ) else asm volatile (
        \\pusha
        \\mov   %esp    , %edi
        \\mov   stackTop, %esp
        \\call  %[isr:P]
        :
        : [isr] "X" (&machine.isr),
    );
}

const isrs = blk: {
    var _isrs: [256]*const fn () callconv(.Naked) noreturn = undefined;
    for (&_isrs, 0..) |*_isr, i| {
        _isr.* = &isr(i);
    }
    break :blk _isrs;
};

const TaskStateSegment = if (_64) extern struct {
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
    iopb: u16 = @sizeOf(TaskStateSegment),
} else extern struct {
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
    iopb: u16 = @sizeOf(TaskStateSegment),
};

var tss: TaskStateSegment = undefined;

pub const Context = extern struct {
    gpr: [if (_64) 15 else 8]usize,

    int: u8 align(@alignOf(usize)),

    // Interrupt Stack Frame
    err: u32 align(@alignOf(usize)),
    ip: usize,
    cs: u16 align(@alignOf(usize)),
    fl: usize,
    sp: usize,
    ss: u16 align(@alignOf(usize)),
};

///////////////////////////////////////////////////////////////////////////////
// Methods
///////////////////////////////////////////////////////////////////////////////

pub fn init() void {
    // update tss
    tss.iopb = @sizeOf(@TypeOf(tss));

    // update gdt and load tss
    const tssAddr = @intFromPtr(&tss);
    const tssSize = @sizeOf(@TypeOf(tss)) - 1;
    gdt[TSS].baseLo = @truncate(tssAddr);
    gdt[TSS].baseHi = @truncate(tssAddr >> 24);
    if (_64) {
        gdt[TSS64].limitLo = @truncate(tssAddr >> 32);
        gdt[TSS64].baseLo = @truncate(tssAddr >> 48);
    }
    gdt[TSS].limitLo = @truncate(tssSize);
    gdt[TSS].limitHi = tssSize >> 16;
    asm volatile ("ltr %[tss]"
        :
        : [tss] "r" (@as(u16, TSS << 3 | 0)),
    );

    // update idt
    for (&idt, &isrs) |*id, _isr| {
        const isrAddr = @intFromPtr(_isr);
        id.* = .{
            .baseLo = @truncate(isrAddr),
            .baseHi = @truncate(isrAddr >> 16),
            .cs = KCODE << 3 | 0,
            .ist = 0,
            .type = 0xE,
            .dpl = 0,
            .p = true,
        };
    }

    if (_64) {
        // enable syscall
        wrmsr(EFER, rdmsr(EFER) | EFER_SCE);
        wrmsr(STAR, (KCODE << 3 | 0) << 32 | (UCODE << 3 | 3) << 48);
        wrmsr(LSTAR, 0);
        wrmsr(CSTAR, 0);
        wrmsr(SF_MASK, 0);
    } else {
        // enable sysenter
        wrmsr(SYSENTER_CS, KCODE << 3 | 0);
        wrmsr(SYSENTER_SP, 0);
        wrmsr(SYSENTER_IP, 0);
    }
}

pub fn initProcess(process: *Process) noreturn {
    tss.sp0 = @intFromPtr(&process.context) + @sizeOf(@TypeOf(process.context));
    if (_64) asm volatile (
        \\mov  %[context], %rsp
        \\pop  %r15
        \\pop  %r14
        \\pop  %r13
        \\pop  %r12
        \\pop  %r11
        \\pop  %r10
        \\pop  %r9
        \\pop  %r8
        \\pop  %rdi
        \\pop  %rsi
        \\pop  %rbp
        //pop  %rsp
        \\pop  %rbx
        \\pop  %rdx
        \\pop  %rcx
        \\pop  %rax
        \\add  $0x10     , %rsp
        \\iret
        :
        : [context] "X" (&process.context),
    ) else asm volatile (
        \\mov  %[context], %esp
        \\popa
        \\add  $0x10     , %esp
        \\iret
        :
        : [context] "X" (&process.context),
    );
    unreachable;
}

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
        else => {},
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
        else => {},
    }
}

/// Read From Model Specific Register
pub inline fn rdmsr(msr: u32) u64 {
    var valueLo: u64 = 0;
    var valueHi: u64 = 0;
    asm volatile ("rdmsr"
        : [_] "={eax}" (valueLo),
          [_] "={edx}" (valueHi),
        : [_] "{ecx}" (msr),
    );
    return valueLo | valueHi << 32;
}

/// Write to Model Specific Register
pub inline fn wrmsr(msr: u32, value: u64) void {
    asm volatile ("wrmsr"
        :
        : [_] "{ecx}" (msr),
          [_] "{eax}" (value),
          [_] "{edx}" (value >> 32),
    );
}
