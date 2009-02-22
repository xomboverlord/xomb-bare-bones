
/*
 * Placed in public domain.
 * Written by Hauke Duden and Walter Bright
 */

/* This is for use with variable argument lists with extern(D) linkage. */

module std.c.stdarg;

private import gcc.builtins;
alias __builtin_va_list va_list;
alias __builtin_va_end va_end;
alias __builtin_va_copy va_copy;

// The va_start and va_arg template functions are magically
// handled by the compiler.

template va_start(T)
{
	void va_start(out va_list ap, inout T parmn)
 	{
	
	}
}

template va_arg(T)
{
	T va_arg(ref va_list _argptr)
	{
		return T.init;
	}
}

