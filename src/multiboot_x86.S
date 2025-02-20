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

    .intel_syntax

    .section .init, "a"

    .global _start
_start:
    .code32
    // save multiboot arguments
    mov edi, eax
    mov esi, ebx

    // enable PAE
    mov eax, cr4
    or  eax, 0x00000020 // CR4.PAE
    mov cr4, eax

    // setup page table
    // 0'000'000'0000 - 0'000'777'7777: 000'000'000'000'0000 - 000'000'000'777'7777
    // 3'000'000'0000 - 3'000'777'7777: 000'000'000'000'0000 - 000'000'000'777'7777
    mov eax                   , offset ptl2 - 0xC0000000
    mov long ptr [eax + 0x000], 0x83
    mov eax                   , offset ptl3 - 0xC0000000
    mov long ptr [eax + 0x000], offset ptl2 - 0xC0000000 + 0x3
    mov long ptr [eax + 0x018], offset ptl2 - 0xC0000000 + 0x3
    mov cr3, eax

    // enable paging
    mov eax, cr0
    or  eax, 0x80000000 // CR0.PG
    mov cr0, eax

    // update segmentation
    lgdt gdtr
    mov  ax, (2 << 3) // KDATA
    mov  ds, ax
    mov  es, ax
    mov  ss, ax
    mov  fs, ax
    mov  gs, ax
    //ljmp  (1 << 3), 2f
    .byte 0xEA
    .long 2f
    .short (1 << 3) // KCODE
2:
    lidt idtr

    // setup stack and call main with multiboot arguments
    mov  esp, offset stack_top
    mov  ebp, esp
    push esi
    push edi
    call main

gdtr:
    .short (7 * 8) - 1
    .long gdt
idtr:
    .short (256 * 8) - 1
    .long idt


    .section .bss

    .align 4096
stack_bottom:
    .zero 4096
stack_top:
ptl2:
    .zero 4096
ptl3:
    .zero 32
