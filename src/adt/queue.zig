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

        pub fn pushFront(self: *Self, node: *Node) void {
            if (self.head) |head| {
                node.next = head;
                node.prev = null;
                self.head = node;
                head.prev = node;
            } else {
                node.next = null;
                node.prev = null;
                self.head = node;
                self.tail = node;
            }
        }

        pub fn pushBack(self: *Self, node: *Node) void {
            if (self.tail) |tail| {
                node.prev = tail;
                node.next = null;
                self.tail = node;
                tail.next = node;
            } else {
                node.next = null;
                node.prev = null;
                self.head = node;
                self.tail = node;
            }
        }

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

        pub fn popFront(self: *Self) ?*Node {
            const head = self.head orelse return null;
            self.delete(head);
            return head;
        }

        pub fn popBack(self: *Self) ?*Node {
            const tail = self.tail orelse return null;
            self.delete(tail);
            return tail;
        }
    };
}
