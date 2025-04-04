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

const cpu = @import("x86/cpu.zig");

const Cache = @import("cache.zig").Cache;
const Set = @import("adt/set.zig").Set;

const Process = @This();

///////////////////////////////////////////////////////////////////////////////
// Globals
///////////////////////////////////////////////////////////////////////////////

const UsedMemoryData = struct {
    addr: cpu.VirtAddr,
    size: cpu.VirtAddr,
};

const UsedMemory = Set(UsedMemoryData, "addr");
var usedMemoryCache: Cache(UsedMemory.Node) = .{};

///////////////////////////////////////////////////////////////////////////////
// Locals
///////////////////////////////////////////////////////////////////////////////

usedMemory: UsedMemory = .{},
pageTable: cpu.PhysAddr = 0,

context: cpu.Context = undefined,

///////////////////////////////////////////////////////////////////////////////
// Methods
///////////////////////////////////////////////////////////////////////////////

pub fn acquireMemory(process: *Process, addr: cpu.VirtAddr, size: cpu.VirtAddr) void {
    const node = usedMemoryCache.acquire();
    node.data = .{ .addr = addr, .size = size };
    process.usedMemory.insert(node);
}

pub fn releaseMemory(process: *Process, addr: cpu.VirtAddr) void {
    const node = process.usedMemory.search(.{ .addr = addr, .size = 0 }) orelse return;
    process.usedMemory.delete(node);
}

pub fn run(process: *Process) noreturn {
    cpu.initProcess(process);
}
