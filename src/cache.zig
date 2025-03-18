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

pub fn Cache(comptime T: type) type {
    const bytesPerNode = 4096;
    const itemsPerNode = (bytesPerNode - @sizeOf(*u8) - @sizeOf(u8)) / (@sizeOf(T) + @sizeOf(u8));

    return struct {
        const Self = @This();

        const Node = struct {
            next: ?*Node = null,

            nextItem: u8,
            freeItem: [itemsPerNode]u8,
            item: [itemsPerNode]T,
        };

        var init: Node align(4096) = undefined;

        head: ?*Node = null,

        pub fn acquire(self: *Self) *T {
            if (self.head == null) {
                const node: *Node = &init;
                for (&node.freeItem, 1..) |*nextItem, i| {
                    nextItem.* = @intCast(i);
                }
                self.head = node;
            }

            var nodeOrNull = self.head;
            while (nodeOrNull) |node| {
                if (node.nextItem != (1 << 8) - 1) {
                    const item = &node.item[node.nextItem];
                    node.nextItem = node.freeItem[node.nextItem];
                    return item;
                }
                nodeOrNull = node.next;
            }

            unreachable; // TODO: new node
        }

        pub fn release(self: *Self, item: *T) void {
            var nodeOrNull = self.head;
            while (nodeOrNull) |node| {
                const itemAddr = @intFromPtr(item);
                const itemBase = @intFromPtr(&node.item[0]);
                const itemLast = @intFromPtr(&node.item[itemsPerNode - 1]);
                if (itemAddr >= itemBase or itemAddr <= itemLast) {
                    const nextItem: u8 = @intCast((itemAddr - itemBase) / @sizeOf(Node));
                    node.freeItem[nextItem] = node.nextItem;
                    node.nextItem = nextItem;
                    return;
                }
                nodeOrNull = node.next;
            }

            unreachable; // TODO: item does not belong to any node
        }
    };
}
