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

const Machine = @This();
const Process = @import("Process.zig");

const FreeMemoryData = struct {
    addr: u64,
    size: u64,

    fn compare(l: FreeMemoryData, r: FreeMemoryData) i8 {
        return if (l.addr < r.addr) -1 else if (l.addr > r.addr) 1 else 0;
    }
};

const FreeMemory = Set(FreeMemoryData, FreeMemoryData.compare);
var freeMemoryNodeCache: Cache(FreeMemory.Node) = .{};

fn compareProcesses(l: ProcessQueue.Node, r: ProcessQueue.Node) i8 {
    return if (l.data.id < r.data.id) -1 else if (l.data.id > r.data.id) 1 else 0;
}

const ProcessQueue = Queue(Process);
const Processes = Set(ProcessQueue.Node, compareProcesses);
var processNodeCache: Cache(Processes.Node) = .{};

freeMemory: FreeMemory = .{},

processes: Processes = .{},
processQueue: ProcessQueue = .{},
//process: ProcessQueue.Node = .{},

pub fn markMemoryUsed(machine: *Machine, addrOrNull: ?u64, size: u64) ?u64 {
    if (addrOrNull) |addr| {
        const node = machine.freeMemory.searchMax(.{ .addr = addr, .size = 0 }) orelse return null;
        if (node.data.addr + node.data.size >= addr + size) {
            // trim before
            if (node.data.addr != addr) {
                var newSize = node.data.size;
                node.data.size = addr + node.data.addr;
                newSize -= node.data.size;

                // trim after
                newSize -= size;
                if (newSize != 0) {
                    const newNode = freeMemoryNodeCache.acquire();
                    newNode.data.addr = addr + size;
                    newNode.data.size = newSize;
                    machine.freeMemory.insert(newNode);
                }
            } else {
                // trim after
                node.data.size -= size;
                if (node.data.size != 0) {
                    node.data.addr = addr + size;
                } else {
                    machine.freeMemory.delete(node);
                    freeMemoryNodeCache.release(node);
                }
            }

            return addr;
        }
    } else {
        var nodeOrNull = machine.freeMemory.searchMin(.{ .addr = 0, .size = 0 });
        while (nodeOrNull) |node| {
            // first-fit
            if (node.data.size >= size) {
                node.data.size -= size;
                const addr = node.data.addr + node.data.size;
                if (node.data.size == 0) {
                    machine.freeMemory.delete(node);
                    freeMemoryNodeCache.release(node);
                }
                return addr;
            }
            nodeOrNull = node.pred();
        }
    }

    return null;
}

pub fn markMemoryFree(machine: *Machine, addr: u64, size: u64) void {
    const nodeOrNull = machine.freeMemory.searchMax(.{ .addr = addr, .size = 0 });
    if (nodeOrNull) |node| {
        // coalesce before
        if (node.data.addr + node.data.size == addr) {
            node.data.size += size;

            // coalesce in-between
            if (node.succ()) |nextNode| {
                if (nextNode.data.addr == node.data.addr + node.data.size) {
                    node.data.size += nextNode.data.size;
                    machine.freeMemory.delete(nextNode);
                    freeMemoryNodeCache.release(nextNode);
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

    const newNode = freeMemoryNodeCache.acquire();
    newNode.data.addr = addr;
    newNode.data.size = size;
    machine.freeMemory.insert(newNode);
}

pub fn run(machine: *Machine) noreturn {
    while (true) {
        if (machine.processQueue.popFront()) |process| {
            //machine.process = process;
            process.data.run();
        }
        asm volatile ("hlt");
    }
}
