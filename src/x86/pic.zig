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

const cpu = @import("cpu.zig");

///////////////////////////////////////////////////////////////////////////////
// Globals
///////////////////////////////////////////////////////////////////////////////

const MASTER = 0x20;
const MASTER_IRQ = 0x20;
const SLAVE = 0xA0;
const SLAVE_IRQ = MASTER_IRQ + 8;

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
    cpu.out(MASTER | 0, ICW1 | ICW1_IC4);
    cpu.out(SLAVE | 0, ICW1 | ICW1_IC4);
    cpu.out(MASTER | 1, @as(u8, MASTER_IRQ));
    cpu.out(SLAVE | 1, @as(u8, SLAVE_IRQ));
    cpu.out(MASTER | 1, @as(u8, 1 << 2));
    cpu.out(SLAVE | 1, @as(u8, 2));
    cpu.out(MASTER | 1, ICW4_8086);
    cpu.out(SLAVE | 1, ICW4_8086);
}

pub fn next(irq: u8) void {
    if (irq >= SLAVE_IRQ)
        cpu.out(SLAVE | 0, OCW2_EOI);
    cpu.out(MASTER | 0, OCW2_EOI);
}
