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

const builtin = @import("builtin");

pub fn Crc(comptime Width: type, polyArg: Width, initArg: Width, refIn: bool, refOut: bool, xorOut: bool) type {
    return struct {
        const Self = @This();

        value: Width,

        pub fn init() Self {
            return .{ .value = if (refIn) @bitReverse(initArg) else initArg };
        }

        pub fn update(self: *Self, data: []const u8) void {
            _ = self;
            _ = data;
        }

        pub fn fini(self: Self) Width {
            return (if (refIn != refOut) @bitReverse(self.value) else self.value) ^ xorOut;
        }
    };
}
