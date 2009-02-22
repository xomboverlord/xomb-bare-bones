/*

boot.h

- Contains information pertinant to the bootstrap about where
  the kernel is located

*/

/* the code section for the kernel
   0x10 = code section 2 ( right shift it by 3 ) */
#define CS_KERNEL 0x10
#define CS_KERNEL32 0x8

/* the location, in physical address (LMA) and virtual (VMA) */
/* these should correspond to linker.ld */

#define KERNEL_LMA_BASE 0x100000
#define KERNEL_VMA_BASE (0xffffffff80000000)
#define KERNEL_LOCATION (KERNEL_VMA_BASE + KERNEL_LMA_BASE)

