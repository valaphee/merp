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
    addr: usize,
    size: usize,

    fn compare(a: Free, b: Free) rb_tree.Order {
        return if (a.addr < b.addr) .lt else if (a.addr > b.addr) .gt else .eq;
    }
};

const FreeList = rb_tree.Tree(Free, Free.compare);

free: FreeList = .{},

pub fn mark_used(self: *Self, addr: ?usize, size: usize) usize {
    _ = self;
    _ = addr;
    _ = size;
}

pub fn mark_free(self: *Self, addr: usize, size: usize) usize {
    _ = self;
    _ = addr;
    _ = size;
}
