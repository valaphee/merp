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
// limitations under the License

pub const Order = enum(i2) { lt = -1, eq = 0, gt = 1 };

/// Red-black tree, a self-balancing binary search tree.
pub fn Tree(comptime T: type, comptime compare: fn (a: T, b: T) Order) type {
    return struct {
        const Self = @This();

        pub const Node = struct {
            childL: ?*Node = null,
            childR: ?*Node = null,
            parent: ?*Node = null,
            color: Color = .r,
            data: T,

            /// Returns the next element in the tree or null if it is the last element.
            pub fn succ(node: *Node) ?*Node {
                if (node.childR) |childR| {
                    var n = childR;
                    while (n.childL) |childL|
                        n = childL;
                    return n;
                }
                var n = node;
                while (n.parent) |parent| {
                    if (n == parent.childR)
                        return parent;
                    n = parent;
                }
                return null;
            }

            /// Returns the previous element in the tree or null if it is the first element.
            pub fn pred(node: *Node) ?*Node {
                if (node.childL) |childL| {
                    var n = childL;
                    while (n.childR) |childR|
                        n = childR;
                    return n;
                }
                var n = node;
                while (n.parent) |parent| {
                    if (n == parent.childL)
                        return parent;
                    n = parent;
                }
                return null;
            }
        };

        root: ?*Node = null,

        /// Returns the node with the same value or null if there is none.
        pub fn search(tree: *Self, data: T) ?*Node {
            var next = tree.root;
            while (next) |node| {
                const order = compare(data, next.data);
                next = switch (order) {
                    .lt => node.childL,
                    .eq => break,
                    .gt => node.childR,
                };
            }
            return next;
        }

        /// Adds a new node to the tree, rebalancing it afterwards.
        pub fn insert(tree: *Self, node: *Node) void {
            node.childL = null;
            node.childR = null;

            var order: Order = undefined;
            var parent = tree.root orelse {
                node.color = .b;
                node.parent = null;
                tree.root = node;
                return;
            };
            while (true) {
                order = compare(node.data, parent.data);
                parent = switch (order) {
                    .lt => parent.childL orelse {
                        node.color = .r;
                        node.parent = parent;
                        parent.childL = node;
                        break;
                    },
                    .eq => unreachable, // TODO
                    .gt => parent.childR orelse {
                        node.color = .r;
                        node.parent = parent;
                        parent.childR = node;
                        break;
                    },
                };
            }

            while (parent.color == .r) {
                var grandparent = parent.parent.?;
                if (parent == grandparent.childL) {
                    if (grandparent.childR != null and grandparent.childR.?.color == .r) {
                        grandparent.childR.?.color = .b;
                        parent.color = .b;
                        grandparent.color = .r;
                        parent = grandparent.parent orelse break;
                    } else {
                        if (node == parent.childR) {
                            rotateL(tree, parent);
                            parent = parent.parent.?;
                            grandparent = parent.parent.?;
                        }
                        parent.color = .b;
                        grandparent.color = .r;
                        rotateR(tree, grandparent);
                    }
                } else {
                    if (grandparent.childL != null and grandparent.childL.?.color == .r) {
                        grandparent.childL.?.color = .b;
                        parent.color = .b;
                        grandparent.color = .r;
                        parent = grandparent.parent orelse break;
                    } else {
                        if (node == parent.childL) {
                            rotateR(tree, parent);
                            parent = parent.parent.?;
                            grandparent = parent.parent.?;
                        }
                        parent.color = .b;
                        grandparent.color = .r;
                        rotateL(tree, grandparent);
                    }
                }
            }
            tree.root.?.color = .b;
        }

        /// Removes a node from the tree, rebalancing it afterwards.
        pub fn delete(tree: *Self, node: *Node) void {
            var target: *Node = undefined;
            if (node.childL == null or node.childR == null) {
                target = node;
            } else {
                target = node.succ().?;
            }
            const targetChild: ?*Node = if (target.childL == null) target.childR else target.childL;
            if (targetChild != null) {
                targetChild.?.parent = target;
            }
            var nextMaybe: ?*Node = null;
            if (target.parent) |targetParent| {
                if (targetParent.childL == target) {
                    targetParent.childL = targetChild;
                    nextMaybe = targetParent.childR;
                } else {
                    targetParent.childR = targetChild;
                    nextMaybe = targetParent.childR;
                }
            } else {
                tree.root = targetChild;
            }
            const rebalance = target.color == .b;
            if (target != node) {
                if (node.parent) |parent| {
                    target.parent = parent;
                    if (parent.childL == node) {
                        parent.childL = target;
                    } else {
                        parent.childR = target;
                    }
                } else {
                    target.parent = null;
                    tree.root = target;
                }
                target.childL = node.childL;
                target.childL.?.parent = target;
                target.childR = node.childR;
                if (target.childR) |yRight| {
                    yRight.parent = target;
                }
                target.color = node.color;
            }
            if (rebalance and tree.root != null) {
                if (targetChild != null) {
                    targetChild.?.color = .b;
                } else {
                    var next = nextMaybe.?;
                    while (true) {
                        var parent = next.parent.?;
                        if (parent.childR == next) {
                            if (next.color == .r) {
                                next.color = .b;
                                parent.color = .r;
                                rotateL(tree, parent);
                                next = next.childL.?.childR.?;
                                parent = next.parent.?;
                            }

                            if (if (next.childL) |child| child.color == .b else true and if (next.childR) |child| child.color == .b else true) {
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
                                    rotateR(tree, next);
                                    next = next.parent.?;
                                    parent = next.parent.?;
                                }
                                next.color = parent.color;
                                parent.color = .b;
                                next.childR.?.color = .b;
                                rotateL(tree, parent);
                                break;
                            }
                        } else {
                            if (next.color == .r) {
                                next.color = .b;
                                parent.color = .r;
                                rotateR(tree, parent);
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
                                    rotateL(tree, next);
                                    next = next.parent.?;
                                    parent = next.parent.?;
                                }
                                next.color = parent.color;
                                parent.color = .b;
                                next.childL.?.color = .b;
                                rotateR(tree, parent);
                                break;
                            }
                        }
                    }
                }
            }
        }

        fn replace(tree: *Self, old: *Node, new: *Node) void {
            new.parent = old.parent;
            if (old.parent) |parent| {
                if (old == parent.childL) {
                    parent.childL = new;
                } else {
                    parent.childR = new;
                }
            } else {
                tree.root = new;
            }
        }

        fn rotateL(tree: *Self, node: *Node) void {
            const childR = node.childR.?;
            tree.replace(node, childR);
            node.childR = childR.childL;
            if (childR.childL) |childL| {
                childL.parent = node;
            }
            childR.childL = node;
            node.parent = childR;
        }

        fn rotateR(tree: *Self, node: *Node) void {
            const childL = node.childL.?;
            tree.replace(node, childL);
            node.childL = childL.childR;
            if (childL.childR) |childR| {
                childR.parent = node;
            }
            childL.childR = node;
            node.parent = childL;
        }
    };
}

const Color = enum(u1) { r, b };

const U8Tree = Tree(u8, compareU8);

fn compareU8(a: u8, b: u8) Order {
    return if (a < b) .lt else if (a > b) .gt else .eq;
}

test "insert" {
    var tree = U8Tree{};
    var nodes: [7]U8Tree.Node = undefined;
    nodes[0].data = 0;
    nodes[1].data = 2;
    nodes[2].data = 1;
    nodes[3].data = 3;
    nodes[4].data = 4;
    nodes[5].data = 5;
    nodes[6].data = 6;
    tree.insert(&nodes[0]);
    tree.insert(&nodes[1]);
    tree.insert(&nodes[2]);
    tree.insert(&nodes[3]);
    tree.insert(&nodes[4]);
    tree.insert(&nodes[5]);
    tree.insert(&nodes[6]);
    // TODO: check if all properties are fulfilled
}

test "delete" {
    var tree = U8Tree{};
    var nodes: [7]U8Tree.Node = undefined;
    nodes[0].data = 0;
    nodes[1].data = 2;
    nodes[2].data = 1;
    nodes[3].data = 3;
    nodes[4].data = 4;
    nodes[5].data = 5;
    nodes[6].data = 6;
    tree.insert(&nodes[0]);
    tree.insert(&nodes[1]);
    tree.insert(&nodes[2]);
    tree.insert(&nodes[3]);
    tree.insert(&nodes[4]);
    tree.insert(&nodes[5]);
    tree.insert(&nodes[6]);
    tree.delete(&nodes[2]);
    tree.insert(&nodes[2]);
    // TODO: check if all properties are fulfilled
}
