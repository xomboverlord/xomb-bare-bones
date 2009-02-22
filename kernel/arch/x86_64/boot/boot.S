/*

boot.S - bootstrap the kernel

The 32 bit bootstrap code that serves these functions:

- contains multiboot header
- contains 32 bit GDT
- contains 32 bit IDT (for debugging, can be removed later)
- contains page tables
  - lower 40MB are mapped 1-1
  - higher 40MB (from 0xffffffff80000000) are mapped from 0x0 on
  - after code in load.S runs, the lower half map should not be needed

- transitions into long mode:
  - enables PAE (physical-address-extensions)
  - setting PML4 (page-map-level-4)
  - setting EFER flags for LMA (long-mode-active) and SYSCALL-SYSRET
  - enables paging by setting the PG bit in CR0 (Control Register 0)
  - long jumps to code within load.S

- note: some addresses located within the higher half need to be converted
  to linear addresses:    the stack, _edata, _end
- this is because: the multiboot header expects linear addresses,
  the CPU expects stack at linear address, as it would for GDT, IDT, etc

*/

#define EXE_COMPAT_HACK

#define ASM     1
#include "multiboot.h"

#include "boot.h"

.globl  start, _start

.text

start:
_start:
	.code32

		/* Stash values for multiboot we won't touch until 64 bit mode */
		movl %ebx, %esi
		movl %eax, %edi

		/* jump to the 32 bit common start */
		jmp (start32)

		/* Align 32 bits boundary. */
		.align  4

		/* Multiboot header. */

multiboot_header:
		/* magic */
		.long   MULTIBOOT_HEADER_MAGIC
		/* flags */
		.long   MULTIBOOT_HEADER_FLAGS
		/* checksum */
		.long   -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)

#ifdef EXE_COMPAT_HACK

		/* header_addr */
		.long   (multiboot_header)
		/* load_addr */
		.long   (_start)
		/* load_end_addr */
		.long   (_edata-KERNEL_VMA_BASE)
		/* bss_end_addr */
		.long   (_end-KERNEL_VMA_BASE)
		/* entry_addr */
		.long   (start)
#endif

.global start32, _start32

_start32:
start32:

		/* disable interrupts (CLear Interrupt flag) */
		cli

		/* enable 64-bit page-translation-table entries by
			setting CR4.PAE=1.  Paging not enabled until after
			long mode enabled */
		movl %cr4, %eax
		bts  $5,   %eax
		movl %eax, %cr4

		/* Create long mode page table and init CR3 to point to
			the base of the PML4 page table.  */
		movl $(pml4_base), %eax
		movl %eax, %cr3

		/* Enable Long mode and SYSCALL/SYSRET instructions */
		movl $0xc0000080, %ecx
		rdmsr
		bts $8, %eax
		bts $0, %eax
		wrmsr

		/* Load the 32 bit GDT */
		lgdt	(pGDT32)

		/* Load the 32 bit IDT */
		lidt	(pIDT32)

		/* establish a stack for 32 bit code */
		mov    $((stack-KERNEL_VMA_BASE) + STACK_SIZE), %esp

		/* enable paging to activate long mode */
		movl %cr0, %eax
		bts  $31,  %eax
		movl %eax, %cr0

		// make the jump to long mode!
		ljmp $CS_KERNEL, $(start64-KERNEL_VMA_BASE)





// The following are a series of kernel structures used by the cpu
// These are temporary and will be replaced by permanent ones when the
// kernel is executed proper.






// 32 BIT GDT

	.align 4096
	.globl pGDT32
pGDT32:
	.word	GDT_END - GDT_TABLE - 1
	.quad	GDT_TABLE - KERNEL_VMA_BASE

.align 4096
GDT_TABLE:
	.quad	0x0000000000000000	/* NULL descriptor */
	.quad	0x00cf9a000000ffff	/* __KERNEL32_CS */
	.quad	0x00af9a000000ffff	/* __KERNEL_CS */
	.quad	0x0000000000000000	/* upper half of CS */
	.quad	0x00af93000000ffff	/* __KERNEL_DS */
	.quad	0x0000000000000000	/* upper half of DS */
	.quad	0x00affa000000ffff	/* __USER_CS */
	.quad	0x0000000000000000	/* upper half of CS */
	.quad	0x00aff3000000ffff	/* __USER_DS  */
	.quad	0x0000000000000000	/* upper half of DS */
	.quad	0,0			/* TSS */
	.quad	0,0			/* TSS */
	.quad	0,0			/* LDT */
	.quad	0,0			/* LDT */

	// wtf?
	.quad   0,0,0			/* three TLS descriptors */
	.quad	0x0000f40000000000	/* node/CPU stored in limit */
GDT_END:


// 32 BIT IDT

	.align 4096


	.globl pIDT32
pIDT32:


	.word	IDT_END - IDT_TABLE - 1
	.quad	IDT_TABLE - KERNEL_VMA_BASE

#define IDT_LOCATION 0x106000

.align 4096
IDT_TABLE:
	i = 0
	.rept 32
	.long 0x100000 | ((IDT_LOCATION + i) & 0xFFFF)
	.long ((IDT_LOCATION + i) & 0xFFFF0000) | 0x8E00
	i = i + 8
	.endr
IDT_END:

.align 4096

int_handler_32:

	i = 0
	.rept 32
	mov i, %eax
	iret
	i = i + 1
	.endr

int_handler_32_end:

.align 4096 // the others may not be needed, but this one MUST BE THERE
.globl pml4_base

// PML4
pml4_base:
	.quad	(level3_ident_pgt + 0x0000000000000007)
	.fill	510,8,0
	.quad   (level3_ident_pgt + 0x0000000000000007)


// --- THIS SHOULD BE ALIGNED AT 4K --- //

.align 4096
.globl level3_ident_pgt
// PDP
// PML3
level3_ident_pgt:
	.quad (level2_ident_pgt + 0x07)
	.quad 0 //(level2_ident_pgt + 0x07)
	.quad (level2_ident_pgt + 0x07)

	.rept (507)
	.quad 0
	.endr

	.quad (level2_ident_pgt + 0x07)
	.quad 0 // (level2_ident_pgt + 0x07)



// --- THIS SHOULD BE ALIGNED AT 4K --- //


.align 4096
.globl level2_ident_pgt
	// flags 0x00087
// PDE
// PML2
level2_ident_pgt:
	i = 0

// 15 TABLE ENTRIES
	.rept 15
	.quad	(level1_ident_pgt + i + 0x0000000000000007)
	i = i + 4096
	.endr

	.fill	497,8,0


// --- THIS SHOULD BE ALIGNED AT 4K --- //


// PTE
// PML1
.align 4096
.globl level1_ident_pgt
level1_ident_pgt:
	// UM
	// 40MB for bootup.
	i = 0

// 15 TABLES
	.rept (512 * 15)
	.quad	i << 12 | 0x087
	i = i + 1
	.endr






