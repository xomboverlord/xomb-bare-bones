/*

load.S

The 64 bit code that serves these functions:

- sets up stack
- transfers %rip to higher half
- clears cpu flags
- calls kmain with multiboot information

*/

#define ASM     1

#include "multiboot.h"
#include "boot.h"


	.text
	.code64

.globl  start64, _start64

	start64:
	_start64:


		/* Initialize the 64 bit stack pointer. */
		movq $((stack - KERNEL_VMA_BASE) + STACK_SIZE), %rsp

		/* set up the stack for the return */
		pushq $CS_KERNEL
		pushq $long_entry

		/* Go into canonical higher half */
		/* This trick is borrowed from the linux kernel,
		   /arch/x86_64/kernel/head.S */

		lretq

long_entry:

		/* From here on out, we are running instructions
		   Within the higher half (0xffffffff80000000 ... )

		   We can safely unmap the lower half, we do not
		   need an identity mapping of the lower half. */

		movq $(stack + STACK_SIZE), %rsp

		/* Set cpu flags */
		pushq $0
		lss (%rsp), %eax
		popf

		/* Sets the Input/Output Permission Level to 3, so
		that it will not check the IO permissions bitmap when access is requested. */

		pushf
		popq %rax
		or $0x3000, %rax
		pushq %rax
		popf

		addq $(KERNEL_VMA_BASE), %rsi

		/* Push the pointer to the Multiboot information structure. */
		pushq   %rsi
		/* Push the magic value. */
		pushq   %rdi

		/* Now enter the kmain function... */
		call    EXT_C(kmain)



		/* We should not get here */

loop:

		hlt
		jmp     loop

// --- STACK --- //
.globl stack
.align 4096

	// Our stack area.
stack:
	.rept STACK_SIZE
	.long 0
	.endr

