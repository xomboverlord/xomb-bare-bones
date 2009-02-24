// Written in the D programming language

module std.moduleinit;

//debug = 1;

//private
//{
//    import object;
//}
/*
enum
{
	MIctorstart = 1,    // we've started constructing it
    MIctordone = 2, // finished construction
    MIstandalone = 4,   // module ctor does not depend on other module
            // ctors being done first
    MIhasictor = 8, // has ictor member
}
*/
// Start of the module linked list

struct ModuleReference
{
	ModuleReference* next;
	ModuleInfo mod;
}

extern(C) ModuleReference* _Dmodule_ref;

//ModuleInfo[] _moduleinfo_dtors;
uint _moduleinfo_dtors_i;

// Register termination function pointers
//extern (C) int _fatexit(void *);

/*************************************
 * Initialize the modules.
 */

extern (C) void _moduleCtor()
{
}

/**********************************
 * Destruct the modules.
 */

// Starting the name with "_STD" means under linux a pointer to the
// function gets put in the .dtors segment.

extern (C) void _moduleDtor()
{
}

/**********************************
 * Run unit tests.
 */

extern (C) void _moduleUnitTests()
{
}

/**********************************
 * Run unit tests.
 */

extern (C) void _moduleIndependentCtors()
{
}
