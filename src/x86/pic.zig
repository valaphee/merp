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

//! Driver for the legacy Intel 8259 PIC (programmable interrupt controller)

const cpu = @import("cpu.zig");

const MASTER = 0x20;
const SLAVE = 0xA0;

const ICW1_IC4: u8 = 1 << 0;
const ICW1: u8 = 1 << 4;

const ICW4_8086: u8 = 1 << 0;

const OCW2_EOI: u8 = 1 << 5;

const OCW3_RIS: u8 = 1 << 0;
const OCW3_RR: u8 = 1 << 1;
const OCW3: u8 = 1 << 3;

/// Initialize the PICs
pub fn initialize() void {
    // ICW1: init + mode
    cpu.Out(MASTER, ICW1 | ICW1_IC4);
    cpu.Out(SLAVE, ICW1 | ICW1_IC4);
    // ICW2: map IRQs to 0x20-0x2F
    cpu.Out(MASTER | 1, 0x20);
    cpu.Out(SLAVE | 1, 0x20 + 8);
    // ICW3: slave PIC is connected to IR2 of the master PIC
    cpu.Out(MASTER | 1, 0b0000_0100);
    cpu.Out(SLAVE | 1, 2);
    // ICW4: use 8086 mode
    cpu.Out(MASTER | 1, ICW4_8086);
    cpu.Out(SLAVE | 1, ICW4_8086);
}

/// Acknowledge an IRQ
pub fn acknowledge(irq: u8) void {
    if (irq >= 8)
        cpu.Out(SLAVE, OCW2_EOI);
    cpu.Out(MASTER, OCW2_EOI);
}

/// Check if an IRQ was spurious
pub fn is_spurious(irq: u8) bool {
    // When a spurious IRQ occurs the PIC will answer with the lowest priority IRQ number,
    // and then the ISR can be checked if the PIC actually issued the IRQ.
    switch (irq) {
        7 => {
            cpu.Out(MASTER, OCW3 | OCW3_RR | OCW3_RIS);
            if (cpu.In(MASTER, u8) & 0x80 == 0) {
                return true;
            }
        },
        15 => {
            cpu.Out(SLAVE, OCW3 | OCW3_RR | OCW3_RIS);
            if (cpu.In(SLAVE, u8) & 0x80 == 0) {
                return true;
            }
        },
    }
    return false;
}
