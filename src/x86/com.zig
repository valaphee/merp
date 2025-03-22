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

const Self = @This();

///////////////////////////////////////////////////////////////////////////////
// Globals
///////////////////////////////////////////////////////////////////////////////

const RBR = 0;
const THR = 0;

const IER = 1;

const IIR = 2;

const FCR = 2;
const FCR_EN: u8 = 1 << 0;
const FCR_RXRST: u8 = 1 << 1;
const FCR_TXRST: u8 = 1 << 2;
const FCR_TL: u8 = 6;

const LCR = 3;
const LCR_DLAB: u8 = 1 << 7;

const MCR = 4;
const MCR_DTR: u8 = 1 << 0;
const MCR_RTS: u8 = 1 << 1;
const MCR_OUT1: u8 = 1 << 2;
const MCR_OUT2: u8 = 1 << 3;

const LSR = 5;
const LSR_DR: u8 = 1 << 0;
const LSR_THRE: u8 = 1 << 5;

const MSR = 6;

const SCR = 7;

const DLL = 0;
const DLM = 1;

///////////////////////////////////////////////////////////////////////////////
// Locals
///////////////////////////////////////////////////////////////////////////////

addr: u16,

///////////////////////////////////////////////////////////////////////////////
// Methods
///////////////////////////////////////////////////////////////////////////////

pub fn init(addr: u16) Self {
    cpu.out(addr | IER, @as(u8, 0));
    const baudrate_divisor = 115200 / 115200;
    cpu.out(addr | LCR, LCR_DLAB);
    cpu.out(addr | DLL, @as(u8, baudrate_divisor & 0xFF));
    cpu.out(addr | DLM, @as(u8, baudrate_divisor >> 8 & 0xFF));
    cpu.out(addr | LCR, @as(u8, 3));
    cpu.out(addr | FCR, FCR_EN | FCR_RXRST | FCR_TXRST | 3 << FCR_TL);
    cpu.out(addr | MCR, MCR_DTR | MCR_RTS | MCR_OUT1 | MCR_OUT2);
    return .{ .addr = addr };
}

pub fn read(self: Self) u8 {
    return cpu.in(self.addr | RBR, u8);
}

pub fn write(self: Self, value: u8) void {
    cpu.out(self.addr | THR, value);
}
