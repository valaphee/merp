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

const rb_tree = @import("util/rb_tree.zig");

const Self = @This();

const Free = struct {
    addr: u64,
    size: u64,

    fn compare(a: Free, b: Free) rb_tree.Order {
        return if (a.addr < b.addr) .lt else if (a.addr > b.addr) .gt else .eq;
    }
};

const FreeList = rb_tree.Tree(Free, Free.compare);

free: FreeList = .{},

pub fn markUsed(self: *Self, addrOrNull: ?u64, size: u64) ?u64 {
    if (addrOrNull) |addr| {
        const chunk = self.free.searchMax(.{ .addr = addr, .size = 0 }) orelse return null;
        if (chunk.data.addr + chunk.data.size >= addr + size) {
            // trim before
            if (chunk.data.addr != addr) {
                var chunk_size = chunk.data.size;
                chunk.data.size = addr + chunk.data.addr;
                chunk_size -= chunk.data.size;

                // trim after
                chunk_size -= size;
                if (chunk_size != 0) {
                    // TODO alloc
                    //self.free.insert(.{ .data = .{ .addr = addr + size, .size = chunk_size } });
                }
            } else {
                // trim after
                chunk.data.size -= size;
                if (chunk.data.size != 0) {
                    chunk.data.addr = addr + size;
                } else {
                    self.free.delete(chunk);
                    // TODO dealloc
                }
            }

            return addr;
        }
    } else {
        var chunkOrNull = self.free.searchMin(.{ .addr = 0, .size = 0 });
        while (chunkOrNull) |chunk| {
            // first-fit
            if (chunk.data.size >= size) {
                chunk.data.size -= size;
                const addr = chunk.data.addr + chunk.data.size;
                if (chunk.data.size == 0) {
                    self.free.delete(chunk);
                    // TODO dealloc
                }
                return addr;
            }
            chunkOrNull = chunk.pred();
        }
    }

    return null;
}

pub fn markFree(self: *Self, addr: u64, size: u64) void {
    const chunkOrNull = self.free.searchMax(.{ .addr = addr, .size = 0 });
    if (chunkOrNull) |chunk| {
        // coalesce before
        if (chunk.data.addr + chunk.data.size == addr) {
            chunk.data.size += size;

            // coalesce in-between
            if (chunk.succ()) |nextChunk| {
                if (nextChunk.data.addr == chunk.data.addr + chunk.data.size) {
                    self.free.delete(nextChunk);
                    chunk.data.size += nextChunk.data.size;
                    // TODO dealloc
                }
            }

            return;
        }

        // coalesce after
        if (chunk.succ()) |nextChunk| {
            if (nextChunk.data.addr == addr + size) {
                chunk.data.addr = addr;
                chunk.data.size += nextChunk.data.size;
                return;
            }
        }
    }

    // TODO alloc
    //self.free.insert(.{ .data = .{ .addr = addr, .size = size } });
}
