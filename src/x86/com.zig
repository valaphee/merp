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

//! Driver for the 16550 UART
//!
//! https://www.ti.com/lit/ds/symlink/tl16c750.pdf
const cpu = @import("cpu.zig");

const COM1 = 0x3F8;

/// Receiver Buffer Register (RO)
const RBR = 0;
/// Transmitter Holding Register (WO)
const THR = 0;

/// Interrupt Enable Register
const IER = 1;

/// Interrupt Ident. Register (RO)
const IIR = 2;

/// FIFO Control Register (WO)
const FCR = 2;
/// FIFO Enable
const FCR_EN: u8 = 1 << 0;
/// Receiver FIFO Reset
const FCR_RXRST: u8 = 1 << 1;
/// Transmitter FIFO Reset
const FCR_TXRST: u8 = 1 << 2;
/// Receiver Trigger
const FCR_TL: u8 = 6;

/// Line Control Register
const LCR = 3;
/// Divisor Latch Access Bit
const LCR_DLAB: u8 = 1 << 7;

/// Modem Control Register
const MCR = 4;
/// Data Terminal Ready
const MCR_DTR: u8 = 1 << 0;
/// Request to Send
const MCR_RTS: u8 = 1 << 1;
const MCR_OUT1: u8 = 1 << 2;
const MCR_OUT2: u8 = 1 << 3;

/// Line Status Register
const LSR = 5;
const LSR_DR: u8 = 1 << 0;
const LSR_THRE: u8 = 1 << 5;

/// Modem Status Register
const MSR = 6;

/// Scratch Register
const SCR = 7;

/// Divisor Latch (LSB)
const DLL = 0;
/// Divisor Latch (MSB)
const DLM = 1;

/// Initialize the COM port
pub fn initialize() void {
    // Disable all interrupts
    cpu.out(COM1 | IER, @as(u8, 0));
    // Set baudrate, data, parity and stop bits
    const baudrate_divisor = 115200 / 1;
    cpu.out(COM1 | LCR, LCR_DLAB);
    cpu.out(COM1 | DLL, @as(u8, baudrate_divisor & 0xFF));
    cpu.out(COM1 | DLM, @as(u8, baudrate_divisor >> 8 & 0xFF));
    cpu.out(COM1 | LCR, @as(u8, 3));
    // Enable and reset FIFO, set trigger level to 14 bytes
    cpu.out(COM1 | FCR, FCR_EN | FCR_RXRST | FCR_TXRST | 3 << FCR_TL);
    // Set DSR, RTS and enable IRQs
    cpu.out(COM1 | MCR, MCR_DTR | MCR_RTS | MCR_OUT1 | MCR_OUT2);
}

/// Read from COM port
pub fn read() u8 {
    while (cpu.in(COM1 | LSR, u8) & LSR_DR == 0) {}
    return cpu.in(COM1 | RBR, u8);
}

/// Write to COM port
pub fn write(value: u8) void {
    while (cpu.in(COM1 | LSR, u8) & LSR_THRE == 0) {}
    cpu.out(COM1 | THR, value);
}
