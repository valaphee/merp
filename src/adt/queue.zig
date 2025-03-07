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

/// Queue implemented using doubly linked lists.
pub fn Queue(comptime Data: type) type {
    return struct {
        const Self = @This();

        pub const Node = struct {
            next: ?*Node = null,
            prev: ?*Node = null,
            data: Data,
        };

        head: ?*Node = null,
        tail: ?*Node = null,

        /// Preprends a node to the front of the queue.
        pub fn pushFront(self: *Self, node: *Node) void {
            node.next = self.head;
            node.prev = null;
            if (self.head) |head| {
                head.prev = node;
            } else {
                self.tail = node;
            }
            self.head = node;
        }

        /// Appends a node to the back of the queue.
        pub fn pushBack(self: *Self, node: *Node) void {
            node.prev = self.tail;
            node.next = null;
            if (self.tail) |tail| {
                tail.prev = node;
            } else {
                self.head = node;
            }
            self.tail = node;
        }

        /// Removes the specified node from the queue.
        pub fn delete(self: *Self, node: *Node) void {
            if (node.prev) |prev| {
                prev.next = node.next;
            } else {
                self.head = node.next;
            }
            if (node.next) |next| {
                next.prev = node.prev;
            } else {
                self.tail = node.prev;
            }
        }

        /// Removes the first element and returns it, or null if the queue is empty.
        pub fn popFront(self: *Self) ?*Node {
            const head = self.head orelse return null;
            self.delete(head);
            return head;
        }

        /// Removes the last element and returns it, or null if the queue is empty.
        pub fn popBack(self: *Self) ?*Node {
            const tail = self.tail orelse return null;
            self.delete(tail);
            return tail;
        }
    };
}
