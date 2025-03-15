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

///////////////////////////////////////////////////////////////////////////////
// Externs
///////////////////////////////////////////////////////////////////////////////

const cpu = @import("cpu.zig");

///////////////////////////////////////////////////////////////////////////////
// Globals
///////////////////////////////////////////////////////////////////////////////

const PRI = 0x20;
const SEC = 0xA0;

const ICW1_IC4: u8 = 1 << 0;
const ICW1: u8 = 1 << 4;

const ICW4_8086: u8 = 1 << 0;

const OCW2_EOI: u8 = 1 << 5;

const OCW3_RIS: u8 = 1 << 0;
const OCW3_RR: u8 = 1 << 1;
const OCW3: u8 = 1 << 3;

///////////////////////////////////////////////////////////////////////////////
// Methods
///////////////////////////////////////////////////////////////////////////////

pub fn init() void {
    // ICW1: init + mode
    cpu.out(PRI | 0, ICW1 | ICW1_IC4);
    cpu.out(SEC | 0, ICW1 | ICW1_IC4);
    // ICW2: map IRQs to 0x20-0x2F
    cpu.out(PRI | 1, @as(u8, 0x20));
    cpu.out(SEC | 1, @as(u8, 0x20 + 8));
    // ICW3: secondary PIC is connected to IR2 of the primary PIC
    cpu.out(PRI | 1, @as(u8, 1 << 2));
    cpu.out(SEC | 1, @as(u8, 2));
    // ICW4: use 8086 mode
    cpu.out(PRI | 1, ICW4_8086);
    cpu.out(SEC | 1, ICW4_8086);
}

pub fn eoi(irq: u8) void {
    if (irq >= 8)
        cpu.out(SEC | 0, OCW2_EOI);
    cpu.out(PRI | 0, OCW2_EOI);
}
