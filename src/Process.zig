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

const Order = @import("adt/rb_tree.zig").Order;
const RbTree = @import("adt/rb_tree.zig").Tree;
const Cache = @import("cache.zig").Cache;

const Self = @This();

const UsedMemoryData = struct {
    addr: usize,
    size: usize,

    fn compare(a: UsedMemoryData, b: UsedMemoryData) isize {
        return if (a.addr < b.addr) .lt else if (a.addr > b.addr) .gt else .eq;
    }
};

const UsedMemory = RbTree(UsedMemoryData, UsedMemoryData.compare);
var usedMemoryNodeCache: Cache(UsedMemory.Node) = .{};

id: usize,

usedMemory: UsedMemory = .{},

pub fn acquireMemory(self: *Self, addrOrNull: ?usize, size: usize) ?usize {
    _ = self;
    _ = addrOrNull;
    _ = size;
}

pub fn releaseMemory(self: *Self, addr: usize) void {
    _ = self;
    _ = addr;
}

pub fn run(self: *Self) noreturn {
    _ = self;
}
