/* XOmB Bare Bones
 *
 * This is the bare minimum needed for an OS written in the D language.
 *
 * Note: The kmain will be called in the higher memory region.
 *       The next step is setting up permanent kernel structures.
 *
 */

module kernel.core.kmain;

// This module contains our powerful kprintf function
import kernel.core.kprintf;

// This module contains the architecture specific modules
import architecture;



// The main function for the kernel.
// This will receive data from the boot loader.

// bootLoaderID is the unique identifier for a boot loader.
// data is a structure given by the boot loader.

// For GRUB: the identifier is the magic number.
//           data is the pointer to the multiboot structure.
extern(C) void kmain(int bootLoaderID, void *data)
{

	kprintfln!("{!cls}Welcome to {}! (version {}.{}.{})")("XOmB Bare Bones", 1,0,0);


	kprintfln!("{x} {x}")(bootLoaderID, data);


	// Ok, so we don't want to just infinite loop (if you want it to do something)
	// Replace this with your kernel logic!

	for(;;) {}

}
