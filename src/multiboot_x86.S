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

    .section .init, "aw"

    .global _start
_start:
    .code32
    // save multiboot args
    mov edi, eax
    mov esi, ebx

    // enable PAE
    mov eax, cr4
    or  eax, 0x00000020 // CR4.PAE
    mov cr4, eax

    // enable paging
    // 0'000'000'0000 - 0'000'777'7777: 000'000'000'000'0000 - 000'000'000'777'7777
    // 3'000'000'0000 - 3'000'777'7777: 000'000'000'000'0000 - 000'000'000'777'7777
    mov eax                    , offset ptl2 - 0xC0000000
    mov dword ptr [eax + 0x000], 0x83
    mov eax                    , offset ptl3 - 0xC0000000
    mov dword ptr [eax + 0x000], offset ptl2 - 0xC0000000 + 0x3
    mov dword ptr [eax + 0x018], offset ptl2 - 0xC0000000 + 0x3
    mov cr3, eax
    mov eax, cr0
    or  eax, 0x80000000 // CR0.PG
    mov cr0, eax

    // update gdt
    lgdt gdtr
    mov  ax, (2 << 3) // KDATA
    mov  es, ax
    mov  ss, ax
    mov  ds, ax
    mov  fs, ax
    mov  gs, ax
    //ljmp  (1 << 3), 1f
    .byte 0xEA
    .4byte 1f
    .2byte (1 << 3) // KCODE

1:  lidt idtr

    // call main with multiboot args
    mov  esp, offset stackTop
    push esi
    push edi
    call main

gdtr:
    .2byte (7 * 8) - 1
    .4byte gdt
idtr:
    .2byte (256 * 8) - 1
    .4byte idt

    .section .bss

    .align 4096
stack:
    .zero 4096
stackTop:
ptl2:
    .zero 4096
ptl3:
    .zero 32
