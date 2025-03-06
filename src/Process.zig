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

const cpu = @import("x86/cpu.zig");

const Set = @import("adt/set.zig").Set;
const Cache = @import("cache.zig").Cache;

const Process = @This();

const UsedMemoryData = struct {
    addr: usize,
    size: usize,
};

const UsedMemory = Set(UsedMemoryData, "addr");
var usedMemoryCache: Cache(UsedMemory.Node) = .{};

usedMemory: UsedMemory = .{},

state: cpu.State = undefined,

pub fn acquireMemory(process: *Process, addrOrNull: ?usize, size: usize) ?usize {
    if (addrOrNull) |addr| {
        const node = usedMemoryCache.acquire();
        node.data = .{ .addr = addr, .size = size };
        process.usedMemory.insert(node);
    }
    return addrOrNull;
}

pub fn releaseMemory(process: *Process, addr: usize) void {
    const nodeOrNull = process.usedMemory.search(.{ .addr = addr, .size = 0 });
    if (nodeOrNull) |node| {
        process.usedMemory.delete(node);
        usedMemoryCache.release(node);
    }
}

pub fn run(process: *Process) noreturn {
    cpu.initProcess(process);
}
