// Copyright 2024 Kevin Ludwig
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

    .section .init, "aw"

    .global _start
_start:
    .code32
    // save multiboot args
    mov %eax, %edi
    mov %ebx, %esi

    // enable PAE
    mov %cr4       , %eax
    or  $0x00000020, %eax  // CR4.PAE
    mov %eax       , %cr4

    // enable long mode
    mov   $0xC0000080, %ecx // EFER
    rdmsr
    or    $0x00000100, %eax // EFER.LME
    wrmsr

    // enable paging
    // 000'000'000'000'0000 - 000'000'000'777'7777: 000'000'000'000'0000 - 000'000'000'777'7777
    // 777'776'000'000'0000 - 777'776'000'777'7777: 000'000'000'000'0000 - 000'000'000'777'7777
    mov  $ptl2  - 0xFFFFFFFF80000000      , %eax
    movl                             $0x83, 0x000(%eax)
    mov  $ptl3i - 0xFFFFFFFF80000000      , %eax
    movl $ptl2  - 0xFFFFFFFF80000000 + 0x3, 0x000(%eax)
    mov  $ptl3  - 0xFFFFFFFF80000000      , %eax
    movl $ptl2  - 0xFFFFFFFF80000000 + 0x3, 0xFF0(%eax)
    mov  $ptl4  - 0xFFFFFFFF80000000      , %eax
    movl $ptl3i - 0xFFFFFFFF80000000 + 0x3, 0x000(%eax)
    movl $ptl3  - 0xFFFFFFFF80000000 + 0x3, 0xFF8(%eax)
    mov  %eax                             , %cr3

    mov %cr0       , %eax
    or  $0x80000000, %eax // CR0.PG
    mov %eax       , %cr0

    // update gdt and idt
    lgdt gdtr32
    mov  $2 << 3, %ax // KDATA
    mov  %ax    , %es
    mov  %ax    , %ss
    mov  %ax    , %ds
    mov  %ax    , %fs
    mov  %ax    , %gs
    ljmp $1 << 3, $1f // KCODE

1:  .code64
    lgdt gdtr64
    lidt idtr

    // call main with multiboot args
    mov  $stackTop, %rsp
    call main

gdtr32:
    .2byte (7 * 8) - 1
    .4byte gdt - 0xFFFFFFFF80000000
gdtr64:
    .2byte (7 * 8) - 1
    .8byte gdt
idtr:
    .2byte (256 * 8) - 1
    .8byte idt


    .section .bss

    .align 4096
stack:
    .zero 4096
    .global stackTop
stackTop:
ptl2:
    .zero 4096
ptl3i:
    .zero 4096
ptl3:
    .zero 4096
ptl4:
    .zero 4096
