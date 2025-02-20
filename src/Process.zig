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

const cache = @import("cache.zig");
const rb_tree = @import("util/rb_tree.zig");

const mmu = @import("x86/mmu.zig");

const Self = @This();

const UsedMemoryData = struct {
    addr: usize,
    size: usize,

    fn compare(a: UsedMemoryData, b: UsedMemoryData) rb_tree.Order {
        return if (a.addr < b.addr) .lt else if (a.addr > b.addr) .gt else .eq;
    }
};

const UsedMemory = rb_tree.Tree(UsedMemoryData, UsedMemoryData.compare);
const UsedMemoryNodeCache = cache.Cache(UsedMemory.Node);

nextMemory: usize = .{},
usedMemory: UsedMemory = .{},
usedMemoryNodeCache: UsedMemoryNodeCache = .{},

pageTable: mmu.PageTable = .{},

pub fn acquireMemory(self: *Self, addrOrNull: ?usize, size: usize) ?usize {
    _ = addrOrNull;

    const node = self.usedMemoryNodeCache.acquire();
    node.data.addr = self.nextMemory;
    node.data.size = size;
    self.usedMemory.insert(node);
    self.nextMemory += size;

    return node.data.addr;
}

pub fn releaseMemory(self: *Self, addr: usize) void {
    const node = self.usedMemory.search(addr) orelse return;
    self.usedMemory.delete(node);
    self.usedMemoryNodeCache.release(node);
}
