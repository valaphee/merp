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

    fn compare(l: UsedMemoryData, r: UsedMemoryData) i8 {
        return if (l.addr < r.addr) -1 else if (l.addr > r.addr) 1 else 0;
    }
};

const UsedMemory = Set(UsedMemoryData, UsedMemoryData.compare);
var usedMemoryNodeCache: Cache(UsedMemory.Node) = .{};

id: usize,

usedMemory: UsedMemory = .{},

state: cpu.State = undefined,

pub fn acquireMemory(process: *Process, addrOrNull: ?usize, size: usize) ?usize {
    _ = process;
    _ = addrOrNull;
    _ = size;
}

pub fn releaseMemory(process: *Process, addr: usize) void {
    _ = process;
    _ = addr;
}

pub fn run(process: *Process) noreturn {
    cpu.installProcess(process);
}
