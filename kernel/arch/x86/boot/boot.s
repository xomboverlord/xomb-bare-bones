; boot.s

; entry is from bootloader

section .text
bits 32

; multiboot definitions
%define MULTIBOOT_HEADER_MAGIC	0x1BADB002
%define MULTIBOOT_HEADER_FLAGS	0x00010003

; where is the kernel?
%define KERNEL_VMA_BASE			0x00100000
%define KERNEL_LMA_BASE			0x00100000

; the gdt entry to use for the kernel
%define CS_KERNEL				0x10
%define CS_KERNEL32				0x08

; externs given by the linker script
extern _edata
extern _end

; extern to the load.s
extern start64
extern stack

; other definitions

%define STACK_SIZE				0x4000

; define the starting point for this module
global start
global _start
start:
_start:

	; Stash values for multiboot we won't touch until 64 bit mode
	mov esi, ebx
	mov edi, eax

	jmp start32

	; the multiboot header needs to be aligned at
	; a 32 bit boundary
	align 4

	multiboot_header:

	dd MULTIBOOT_HEADER_MAGIC
	dd MULTIBOOT_HEADER_FLAGS
	dd -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)
	dd multiboot_header
	dd _start
	dd _edata
	dd _end
	dd _start

; the 32 bit entry
global start32
start32:

	; disable interrupts
	cli

_loop:
	jmp _loop
	nop
	nop
	nop
	nop
	nop
	nop
