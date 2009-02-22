//Config options

bool enable_kgdb = false;
bool remote_debug = true;	// Its like debugging for the debugger

// Kernel options
// Make sure this is the same as the value in boot.h
const ulong KERNEL_VM_BASE = 0xFFFFFFFF80000000;

// Debugging options
// Setting DEBUG_ALL to true will cause *ALL* debug
// flags to turn on.  If you only want to see some
// debug messages, turn DEBUG_ALL off, and only
// turn on the debug messages you wish to see.
const auto DEBUG_ALL = false;

// Individual debug options
const auto DEBUG_PAGING = false;
const auto DEBUG_PAGEFAULTS = false;
const auto DEBUG_PMEM = false;
const auto DEBUG_INTERRUPTS = false;
const auto DEBUG_MPTABLE = false;
const auto DEBUG_LAPIC = false;
const auto DEBUG_IOAPIC = false;
const auto DEBUG_APENTRY = false;
const auto DEBUG_KBD = false;
const auto DEBUG_SCHEDULER = false;
