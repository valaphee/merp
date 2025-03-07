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

/// Set that further provides total natural ordering accomplished by using red-black trees.
pub fn Set(comptime Data: type, comptime orderBy: []const u8) type {
    return struct {
        const Self = @This();

        pub const Node = struct {
            childL: ?*Node = null,
            childR: ?*Node = null,
            parent: ?*Node = null,
            color: enum { b, r } = .r,
            data: Data,

            /// Returns the next larger node, or null if this is the last node.
            pub fn succ(node: *Node) ?*Node {
                if (node.childR) |childR| {
                    var next = childR;
                    while (next.childL) |childL| next = childL;
                    return next;
                }
                var next = node;
                while (next.parent) |parent| {
                    if (next == parent.childL) return parent;
                    next = parent;
                }
                return null;
            }

            /// Returns the next smaller node, or null if this is the first node.
            pub fn pred(node: *Node) ?*Node {
                if (node.childL) |childL| {
                    var next = childL;
                    while (next.childR) |childR| next = childR;
                    return next;
                }
                var next = node;
                while (next.parent) |parent| {
                    if (next == parent.childR) return parent;
                    next = parent;
                }
                return null;
            }
        };

        root: ?*Node = null,

        /// Returns the first node with the specified value, or null if there is no such node in the set.
        pub fn search(self: *Self, data: Data) ?*Node {
            var nextOrNull = self.root;
            while (nextOrNull) |next| {
                const order = compare(data, next.data);
                if (order == 0) break;
                nextOrNull = if (order < 0) next.childL else next.childR;
            }
            return nextOrNull;
        }

        /// Returns the least node with a value greater than the specified value, or null if there is no such node in the set.
        pub fn searchMin(self: *Self, data: Data) ?*Node {
            var nextOrNull = self.root;
            var result: ?*Node = null;
            while (nextOrNull) |next| {
                const order = compare(data, next.data);
                if (order <= 0) {
                    result = next;
                    nextOrNull = next.childL;
                } else {
                    nextOrNull = next.childR;
                }
            }
            return result;
        }

        /// Returns the greatest node with a value less than the specified value, or null if there is no such node in the set.
        pub fn searchMax(self: *Self, data: Data) ?*Node {
            var nextOrNull = self.root;
            var result: ?*Node = null;
            while (nextOrNull) |next| {
                const order = compare(data, next.data);
                if (order >= 0) {
                    result = next;
                    nextOrNull = next.childR;
                } else {
                    nextOrNull = next.childL;
                }
            }
            return result;
        }

        /// Adds the specified node to the set.
        pub fn insert(self: *Self, node: *Node) void {
            node.childL = null;
            node.childR = null;

            var order: i8 = undefined;
            var parent = self.root orelse {
                node.color = .b;
                node.parent = null;
                self.root = node;
                return;
            };
            while (true) {
                order = compare(node.data, parent.data);
                parent = if (order < 0) parent.childL orelse {
                    node.color = .r;
                    node.parent = parent;
                    parent.childL = node;
                    break;
                } else parent.childR orelse {
                    node.color = .r;
                    node.parent = parent;
                    parent.childR = node;
                    break;
                };
            }

            while (parent.color == .r) {
                var grandparent = parent.parent.?;
                if (parent == grandparent.childL) {
                    if (if (grandparent.childR) |n| n.color == .r else false) {
                        grandparent.childR.?.color = .b;
                        parent.color = .b;
                        grandparent.color = .r;
                        parent = grandparent.parent orelse break;
                    } else {
                        if (node == parent.childR) {
                            rotateL(self, parent);
                            parent = parent.parent.?;
                            grandparent = parent.parent.?;
                        }
                        parent.color = .b;
                        grandparent.color = .r;
                        rotateR(self, grandparent);
                    }
                } else {
                    if (if (grandparent.childL) |n| n.color == .r else false) {
                        grandparent.childL.?.color = .b;
                        parent.color = .b;
                        grandparent.color = .r;
                        parent = grandparent.parent orelse break;
                    } else {
                        if (node == parent.childL) {
                            rotateR(self, parent);
                            parent = parent.parent.?;
                            grandparent = parent.parent.?;
                        }
                        parent.color = .b;
                        grandparent.color = .r;
                        rotateL(self, grandparent);
                    }
                }
            }
            self.root.?.color = .b;
        }

        /// Removes the specified node from the set.
        pub fn delete(self: *Self, node: *Node) void {
            const target: *Node = if (node.childL != null and node.childR != null) node.succ().? else node;
            const child: ?*Node = if (target.childL != null) target.childL else target.childR;
            if (child != null) child.?.parent = target.parent;

            var nextOrNull: ?*Node = null;
            if (target.parent) |parent| {
                if (parent.childL == target) {
                    parent.childL = child;
                    nextOrNull = parent.childR;
                } else {
                    parent.childR = child;
                    nextOrNull = parent.childL;
                }
            } else self.root = child;

            const rebalance = target.color == .b;
            if (target != node) {
                self.replace(node, target);
                target.childL = node.childL;
                target.childL.?.parent = target;
                target.childR = node.childR;
                if (target.childR) |n| n.parent = target;
                target.color = node.color;
            }
            if (!rebalance or self.root == null) return;

            if (child != null) {
                child.?.color = .b;
                return;
            }

            var next = nextOrNull.?;
            while (true) {
                var parent = next.parent.?;
                if (parent.childR == next) {
                    if (next.color == .r) {
                        next.color = .b;
                        parent.color = .r;
                        rotateL(self, parent);
                        next = next.childL.?.childR.?;
                        parent = next.parent.?;
                    }
                    if (if (next.childL) |n| n.color == .b else true and if (next.childR) |n| n.color == .b else true) {
                        next.color = .r;
                        if (parent.parent == null or parent.color == .r) {
                            parent.color = .b;
                            break;
                        }
                        const grandparent = parent.parent.?;
                        next = if (grandparent.childL == parent) grandparent.childR.? else grandparent.childL.?;
                    } else {
                        if (if (next.childR) |n| n.color == .b else true) {
                            next.childL.?.color = .b;
                            next.color = .r;
                            rotateR(self, next);
                            next = next.parent.?;
                            parent = next.parent.?;
                        }
                        next.color = parent.color;
                        parent.color = .b;
                        next.childR.?.color = .b;
                        rotateL(self, parent);
                        break;
                    }
                } else {
                    if (next.color == .r) {
                        next.color = .b;
                        parent.color = .r;
                        rotateR(self, parent);
                        next = next.childR.?.childL.?;
                        parent = next.parent.?;
                    }
                    if (if (next.childL) |n| n.color == .b else true and if (next.childR) |n| n.color == .b else true) {
                        next.color = .r;
                        if (parent.parent == null or parent.color == .r) {
                            parent.color = .b;
                            break;
                        }
                        const grandparent = parent.parent.?;
                        next = if (grandparent.childL == parent) grandparent.childR.? else grandparent.childL.?;
                    } else {
                        if (if (next.childL) |n| n.color == .b else true) {
                            next.childR.?.color = .b;
                            next.color = .r;
                            rotateL(self, next);
                            next = next.parent.?;
                            parent = next.parent.?;
                        }
                        next.color = parent.color;
                        parent.color = .b;
                        next.childL.?.color = .b;
                        rotateR(self, parent);
                        break;
                    }
                }
            }
        }

        fn compare(l: Data, r: Data) i8 {
            const lValue = @field(l, orderBy);
            const rValue = @field(r, orderBy);
            return if (lValue < rValue) -1 else if (lValue > rValue) 1 else 0;
        }

        fn replace(self: *Self, old: *Node, new: *Node) void {
            new.parent = old.parent;
            if (old.parent) |parent| {
                if (old == parent.childL) parent.childL = new else parent.childR = new;
            } else self.root = new;
        }

        fn rotateL(self: *Self, node: *Node) void {
            const childR = node.childR.?;
            self.replace(node, childR);
            node.childR = childR.childL;
            if (childR.childL) |childL| childL.parent = node;
            childR.childL = node;
            node.parent = childR;
        }

        fn rotateR(self: *Self, node: *Node) void {
            const childL = node.childL.?;
            self.replace(node, childL);
            node.childL = childL.childR;
            if (childL.childR) |childR| childR.parent = node;
            childL.childR = node;
            node.parent = childL;
        }
    };
}
