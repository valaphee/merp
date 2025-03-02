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
const cpu = @import("x86/cpu.zig");

const Machine = @import("Machine.zig");

pub export fn EfiMain(ImageHandle: c.EFI_HANDLE, SystemTable: *c.EFI_SYSTEM_TABLE) callconv(.c) c.EFI_STATUS {
    var machine = Machine{};

    const BootServices = SystemTable.BootServices.*;
    var Status = c.EFI_SUCCESS;

    var MemoryMapSize: usize = 0;
    Status = BootServices.GetMemoryMap.?(&MemoryMapSize, null, null, null, null);
    if (Status != c.EFI_BUFFER_TOO_SMALL) {
        return Status;
    }

    var MemoryMapUnsized: [*]c.EFI_MEMORY_DESCRIPTOR = undefined;
    Status = BootServices.AllocatePool.?(c.EfiBootServicesData, MemoryMapSize, @ptrCast(&MemoryMapUnsized));
    if (Status != c.EFI_SUCCESS) {
        return Status;
    }

    var MemoryMapKey: usize = undefined;
    var DescriptorSize: usize = undefined;
    var DescriptorVersion: u32 = undefined;
    Status = BootServices.GetMemoryMap.?(&MemoryMapSize, MemoryMapUnsized, &MemoryMapKey, &DescriptorSize, &DescriptorVersion);
    if (Status != c.EFI_SUCCESS) {
        return Status;
    }
    if (DescriptorSize != @sizeOf(c.EFI_MEMORY_DESCRIPTOR) or DescriptorVersion != c.EFI_MEMORY_DESCRIPTOR_VERSION) {
        return c.EFI_UNSUPPORTED;
    }

    Status = BootServices.ExitBootServices.?(ImageHandle, MemoryMapKey);
    if (Status != c.EFI_SUCCESS) {
        return Status;
    }

    const MemoryMap = MemoryMapUnsized[0 .. MemoryMapSize / @sizeOf(c.EFI_MEMORY_DESCRIPTOR)];
    for (MemoryMap) |MemoryMapDescriptor| {
        switch (MemoryMapDescriptor.Type) {
            c.EfiBootServicesCode | c.EfiBootServicesData | c.EfiConventionalMemory => machine.markMemoryFree(MemoryMapDescriptor.PhysicalStart, MemoryMapDescriptor.NumberOfPages * 4096),
            else => {},
        }
    }

    cpu.installMachine(&machine);
    machine.run();
}
