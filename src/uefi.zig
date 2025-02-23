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

const c = @cImport(@cInclude("Uefi.h"));

const machine = @import("machine.zig");

pub export fn EfiMain(ImageHandle: c.EFI_HANDLE, SystemTable: *c.EFI_SYSTEM_TABLE) callconv(.c) noreturn {
    const BootServices = SystemTable.BootServices.*;

    var MemoryMapSize: usize = 0;
    if (BootServices.GetMemoryMap.?(&MemoryMapSize, null, null, null, null) != c.EFI_BUFFER_TOO_SMALL) {}

    var MemoryMapUnsized: [*]c.EFI_MEMORY_DESCRIPTOR = undefined;
    if (BootServices.AllocatePool.?(c.EfiBootServicesData, MemoryMapSize, @ptrCast(&MemoryMapUnsized)) != c.EFI_SUCCESS) {}

    var MemoryMapKey: usize = undefined;
    var DescriptorSize: usize = undefined;
    var DescriptorVersion: u32 = undefined;
    if (BootServices.GetMemoryMap.?(&MemoryMapSize, MemoryMapUnsized, &MemoryMapKey, &DescriptorSize, &DescriptorVersion) != c.EFI_SUCCESS) {}
    if (DescriptorSize != @sizeOf(c.EFI_MEMORY_DESCRIPTOR) or DescriptorVersion != c.EFI_MEMORY_DESCRIPTOR_VERSION) {}

    if (BootServices.ExitBootServices.?(ImageHandle, MemoryMapKey) != c.EFI_SUCCESS) {}

    const MemoryMap = MemoryMapUnsized[0 .. MemoryMapSize / @sizeOf(c.EFI_MEMORY_DESCRIPTOR)];
    for (MemoryMap) |MemoryMapDescriptor| {
        switch (MemoryMapDescriptor.Type) {
            c.EfiBootServicesCode | c.EfiBootServicesData | c.EfiConventionalMemory => machine.markMemoryFree(MemoryMapDescriptor.PhysicalStart, MemoryMapDescriptor.NumberOfPages * 4096),
            else => {},
        }
    }

    machine.run();
}
