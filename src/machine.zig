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

const Queue = @import("adt/queue.zig").Queue;
const Set = @import("adt/set.zig").Set;
const Cache = @import("cache.zig").Cache;

const Process = @import("Process.zig");

const FreeMemoryData = struct {
    addr: u64,
    size: u64,
};

const FreeMemory = Set(FreeMemoryData, "addr");
var freeMemoryCache: Cache(FreeMemory.Node) = .{};

const ProcessQueue = Queue(Process);
var processCache: Cache(ProcessQueue.Node) = .{};

var freeMemory: FreeMemory = .{};

var processQueue: ProcessQueue = .{};

pub fn markMemoryUsed(addrOrNull: ?u64, size: u64) ?u64 {
    if (addrOrNull) |addr| {
        const node = freeMemory.searchMax(.{ .addr = addr, .size = 0 }) orelse return null;
        if (node.data.addr + node.data.size >= addr + size) {
            // trim before
            if (node.data.addr != addr) {
                var newSize = node.data.size;
                node.data.size = addr + node.data.addr;
                newSize -= node.data.size;

                // trim after
                newSize -= size;
                if (newSize != 0) {
                    const newNode = freeMemoryCache.acquire();
                    newNode.data = .{ .addr = addr + size, .size = newSize };
                    freeMemory.insert(newNode);
                }
            } else {
                // trim after
                node.data.size -= size;
                if (node.data.size != 0) {
                    node.data.addr = addr + size;
                } else {
                    freeMemory.delete(node);
                    freeMemoryCache.release(node);
                }
            }

            return addr;
        }
    } else {
        var nodeOrNull = freeMemory.searchMin(.{ .addr = 0, .size = 0 });
        while (nodeOrNull) |node| {
            // first-fit
            if (node.data.size >= size) {
                node.data.size -= size;
                const addr = node.data.addr + node.data.size;
                if (node.data.size == 0) {
                    freeMemory.delete(node);
                    freeMemoryCache.release(node);
                }
                return addr;
            }
            nodeOrNull = node.pred();
        }
    }

    return null;
}

pub fn markMemoryFree(addr: u64, size: u64) void {
    const nodeOrNull = freeMemory.searchMax(.{ .addr = addr, .size = 0 });
    if (nodeOrNull) |node| {
        // coalesce before
        if (node.data.addr + node.data.size == addr) {
            node.data.size += size;

            // coalesce in-between
            if (node.succ()) |nextNode| {
                if (nextNode.data.addr == node.data.addr + node.data.size) {
                    node.data.size += nextNode.data.size;
                    freeMemory.delete(nextNode);
                    freeMemoryCache.release(nextNode);
                }
            }

            return;
        }

        // coalesce after
        if (node.succ()) |nextNode| {
            if (nextNode.data.addr == addr + size) {
                node.data.addr = addr;
                node.data.size += nextNode.data.size;
                return;
            }
        }
    }

    const newNode = freeMemoryCache.acquire();
    newNode.data = .{ .addr = addr, .size = size };
    freeMemory.insert(newNode);
}

pub fn run() noreturn {
    processQueue.popFront().?.data.run();
}
