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

//! 8259 PIC (programmable interrupt controller) driver
//!
//! https://pdos.csail.mit.edu/6.828/2005/readings/hardware/8259A.pdf

const cpu = @import("cpu.zig");

const MASTER = 0x20;
const SLAVE = 0xA0;

/// IC4 needed
const ICW1_IC4: u8 = 1 << 0;
const ICW1: u8 = 1 << 4;

/// 8086-mode
const ICW4_8086: u8 = 1 << 0;

/// End of Interrupt
const OCW2_EOI: u8 = 1 << 5;

/// Interrupt Service Register
const OCW3_RIS: u8 = 1 << 0;
/// Read Register
const OCW3_RR: u8 = 1 << 1;
const OCW3: u8 = 1 << 3;

/// Initialize the PICs
pub fn initialize() void {
    // ICW1: init + mode
    cpu.out(MASTER | 0, ICW1 | ICW1_IC4);
    cpu.out(SLAVE | 0, ICW1 | ICW1_IC4);
    // ICW2: map IRQs to 0x20-0x2F
    cpu.out(MASTER | 1, @as(u8, 0x20));
    cpu.out(SLAVE | 1, @as(u8, 0x20 + 8));
    // ICW3: slave PIC is connected to IR2 of the master PIC
    cpu.out(MASTER | 1, @as(u8, 0b0000_0100));
    cpu.out(SLAVE | 1, @as(u8, 2));
    // ICW4: use 8086 mode
    cpu.out(MASTER | 1, ICW4_8086);
    cpu.out(SLAVE | 1, ICW4_8086);
}

/// Acknowledge an IRQ
pub fn acknowledge(irq: u8) void {
    if (irq >= 8)
        cpu.out(SLAVE | 0, OCW2_EOI);
    cpu.out(MASTER | 0, OCW2_EOI);
}

/// Check if an IRQ was spurious
pub fn is_spurious(irq: u8) bool {
    // When a spurious IRQ occurs the PIC will answer with the lowest priority IRQ number,
    // and then the ISR can be checked if the PIC actually issued the IRQ.
    switch (irq) {
        7 => {
            cpu.out(MASTER | 0, OCW3 | OCW3_RR | OCW3_RIS);
            if (cpu.in(MASTER | 0, u8) & 0x80 == 0) {
                return true;
            }
        },
        15 => {
            cpu.out(SLAVE | 0, OCW3 | OCW3_RR | OCW3_RIS);
            if (cpu.in(SLAVE | 0, u8) & 0x80 == 0) {
                return true;
            }
        },
    }
    return false;
}
