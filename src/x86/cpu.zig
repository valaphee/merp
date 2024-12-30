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

//! Utilities for x86

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
