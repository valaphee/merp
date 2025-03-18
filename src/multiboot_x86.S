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

    .set BASE, 0xC0000000

    .section .init, "aw"

    .global _start
_start:
    .code32
    // save multiboot args
    mov %eax, %edi
    mov %ebx, %esi

    // check cpuid
    mov   $0x00000001, %eax
    cpuid
    test  $1 << 6    , %edx // PAE
    jnz   2f
    mov   $1f, %esi
    jmp   panic
1:  .asciz "cpuid 0000_0001h: !(edx & PAE)"

2:  // enable PAE
    mov %cr4       , %eax
    or  $0x00000020, %eax  // CR4.PAE
    mov %eax       , %cr4

    // enable paging
    // 0'000'000'0000 - 0'000'777'7777: 000'000'000'000'0000 - 000'000'000'777'7777
    // 3'000'000'0000 - 3'000'777'7777: 000'000'000'000'0000 - 000'000'000'777'7777
    mov  $ptl2 - BASE      , %eax
    movl              $0x83, 0x000(%eax)
    mov  $ptl3 - BASE      , %eax
    movl $ptl2 - BASE + 0x3, 0x000(%eax)
    movl $ptl2 - BASE + 0x3, 0x018(%eax)
    mov  %eax              , %cr3

    mov %cr0       , %eax
    or  $0x80000000, %eax // CR0.PG
    mov %eax       , %cr0

    // load gdt and idt
    lgdt gdtr
    mov  $2 << 3 | 0, %ax // KDATA
    mov  %ax        , %es
    mov  %ax        , %ss
    mov  %ax        , %ds
    mov  %ax        , %fs
    mov  %ax        , %gs
    ljmp $1 << 3 | 0, $1f // KCODE

1:  lidt idtr

    // jump to main with multiboot args
    mov  $stackTop, %esp
    push %esi
    push %edi
    jmp  main

panic:
    // disable cursor
    mov $0x3D4, %dx
    mov $0x0A , %al
    out %al   , %dx
    mov $0x3D5, %dx
    mov $0x20 , %al
    out %al   , %dx

    // clear screen
    mov $0xB8000      , %edi
    mov $(80 * 25) / 2, %ecx
    mov $0x4F204F20   , %eax
    rep stosl

    // print screen
    mov   $0xB8000, %edi
    mov   $0x4F   , %ah
1:  lodsb
    test  %al     , %al
    je    1f
    stosw
    jmp   1b

    // halt
1:  hlt
    jmp   1b

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
    .global stackTop
stackTop:
ptl2:
    .zero 4096
ptl3:
    .zero 32
