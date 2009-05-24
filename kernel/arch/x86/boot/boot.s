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
extern _boot

; extern for kmain
extern kmain

; other definitions

%define STACK_SIZE				0x4000

; define the starting point for this module
global start
global _start

	; the multiboot header needs to be aligned at
	; a 32 bit boundary
	align 4

	multiboot_header:

	dd MULTIBOOT_HEADER_MAGIC
	dd MULTIBOOT_HEADER_FLAGS
	dd -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)
	dd multiboot_header
	dd _boot
	dd _edata
	dd _end
	dd _start

; the 32 bit entry
start:
_start:

	; disable interrupts
	cli

	; establish stack (point to bottom)
	mov esp, stack+STACK_SIZE

	; pass multiboot information
	push ebx
	push eax

	; enable SSE
	mov ecx, cr0
	btr ecx, 2	; clear CR0.EM bit
	bts ecx, 1	; set CR0.MP bit
	mov cr0, ecx

	mov ecx, cr4
	bts ecx, 9	; set CR4.OSFXSR bit
	bts ecx, 10	; set CR4.OSXMMEXCPT bit
	mov cr4, ecx

	; call kmain
	call kmain

_halt:

	cli

	hlt
	jmp _halt

	nop
	nop

section .bss
align 32
stack:
	resb STACK_SIZE

