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

const Self = @This();

const FreeMemoryData = struct {
    addr: u64,
    size: u64,

    fn compare(a: FreeMemoryData, b: FreeMemoryData) rb_tree.Order {
        return if (a.addr < b.addr) .lt else if (a.addr > b.addr) .gt else .eq;
    }
};

const FreeMemory = rb_tree.Tree(FreeMemoryData, FreeMemoryData.compare);
const FreeMemoryNodeCache = cache.Cache(FreeMemory.Node);

freeMemory: FreeMemory = .{},
freeMemoryNodeCache: FreeMemoryNodeCache = .{},

/// Marks memory as used
pub fn markMemoryUsed(self: *Self, addrOrNull: ?u64, size: u64) ?u64 {
    if (addrOrNull) |addr| {
        const node = self.freeMemory.searchMax(.{ .addr = addr, .size = 0 }) orelse return null;
        if (node.data.addr + node.data.size >= addr + size) {
            // trim before
            if (node.data.addr != addr) {
                var newSize = node.data.size;
                node.data.size = addr + node.data.addr;
                newSize -= node.data.size;

                // trim after
                newSize -= size;
                if (newSize != 0) {
                    const newNode = self.freeMemoryNodeCache.acquire();
                    newNode.data.addr = addr + size;
                    newNode.data.size = newSize;
                    self.freeMemory.insert(newNode);
                }
            } else {
                // trim after
                node.data.size -= size;
                if (node.data.size != 0) {
                    node.data.addr = addr + size;
                } else {
                    self.freeMemory.delete(node);
                    self.freeMemoryNodeCache.release(node);
                }
            }

            return addr;
        }
    } else {
        var nodeOrNull = self.free.searchMin(.{ .addr = 0, .size = 0 });
        while (nodeOrNull) |node| {
            // first-fit
            if (node.data.size >= size) {
                node.data.size -= size;
                const addr = node.data.addr + node.data.size;
                if (node.data.size == 0) {
                    self.freeMemory.delete(node);
                    self.freeMemoryNodeCache.release(node);
                }
                return addr;
            }
            nodeOrNull = node.pred();
        }
    }

    return null;
}

/// Marks memory as free
pub fn markMemoryFree(self: *Self, addr: u64, size: u64) void {
    const nodeOrNull = self.freeMemory.searchMax(.{ .addr = addr, .size = 0 });
    if (nodeOrNull) |node| {
        // coalesce before
        if (node.data.addr + node.data.size == addr) {
            node.data.size += size;

            // coalesce in-between
            if (node.succ()) |nextNode| {
                if (nextNode.data.addr == node.data.addr + node.data.size) {
                    self.freeMemory.delete(nextNode);
                    node.data.size += nextNode.data.size;
                    self.freeMemoryNodeCache.release(nextNode);
                }
            }

            return;
        }

        // coalesce after
        if (node.succ()) |nextChunk| {
            if (nextChunk.data.addr == addr + size) {
                node.data.addr = addr;
                node.data.size += nextChunk.data.size;
                return;
            }
        }
    }

    const newNode = self.freeMemoryNodeCache.acquire();
    newNode.data.addr = addr;
    newNode.data.size = size;
    self.freeMemory.insert(newNode);
}
