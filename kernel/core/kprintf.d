// This module implements the print logic for the kernel


module kernel.core.kprintf;

// Contains the interface to the VGA textmode driver.
import kernel.dev.console;

// Contains some nice logic and cool templates.
import kernel.core.util;




/* This template will generate code for printing and will do
 * all parsing of the format string at compile time
 *
 * USAGE:
 *   kprintf!("format string {specifier} ... ")(args...);
 *
 * EXAMPLES:
 *   kprintf!("Integer: {}")(10);
 *   kprintf!("{!cls}Cleared the screen.")();
 *   kprintf!("{!pos:2,3}At position (2,3)")();
 *   kprintf!("{!fg:LightBlue!bg:Gray}{}")(25);
 *   kprintf!("{!fg:Red}redness")();
 *   kprintf!("{x} Hex!")(145);
 *   kprintf!("Curly Brace: {{")();
 *
 * COMMANDS:
 *   !cls - Clears the screen.
 *   !fg  - Sets the foreground color, see the Color enum
 *            in kernel/dev/console.d.
 *   !bg  - Sets the background color, same as above.
 *   !pos - Moves the cursor to the x and y given, see example above.
 *
 * SPECIFIERS:
 *   {x}  - Prints the hex value.
 *   {u}  - Treats as unsigned.
 *   {}   - Prints common form.
 *
 * WHY IS IT COOL?
 *   - Compile time parsing of format strings
 *   - Type checking at compile time as well
 *   - That means it can tell you that you are dumb before you execute.
 *   - No need to specify type information.
 *
 *   - So we can do this and not care about the
 *      output of the function:
 *
 *   auto blah = someFunction();
 *   kprintf!("Some Arbitrary Info: {}")(blah);
 *
 *      WOWWY WOW WOW!
 *
 */

template kprintf(char[] Format)
{
	void kprintf(Args...)(Args args)
	{
		mixin(ConvertFormat!(Format, Args));
	}
}

/* This template will generate code like kprintf but will also
 * print a newline afterward.
 *
 * USAGE: See kprintf above.
 *
 */
template kprintfln(char[] Format)
{
	void kprintfln(Args...)(Args args)
	{
		mixin(ConvertFormat!(Format, Args));
		Console.putChar('\n');
	}
}































// The crazy D templating logic that implements the kprintf

private
{

	// The following are functions that implement logic for printing different primatives.

	void printInt(long i, char[] fmt)
	{
		char[20] buf;

		if(fmt.length is 0)
			Console.putString(itoa(buf, 'd', i));
		else if(fmt[0] is 'd' || fmt[0] is 'D')
			Console.putString(itoa(buf, 'd', i));
		else if(fmt[0] is 'u' || fmt[0] is 'U')
			Console.putString(itoa(buf, 'u', i));
		else if(fmt[0] is 'x' || fmt[0] is 'X')
			Console.putString(itoa(buf, 'x', i));
	}

	// Floats are not supported by the kernel, but the interface to this exists anyway.
	void printFloat(real f, char[] fmt)
	{
		Console.putString("?float?");
	}

	void printChar(dchar c, char[] fmt)
	{
		Console.putChar(c);
	}

	void printString(T)(T s, char[] fmt)
	{
		static assert(isStringType!(T));
		Console.putString(s);
	}

	void printPointer(void* p, char[] fmt)
	{
		Console.putString("0x");
		char[20] buf;
		Console.putString(itoa(buf, 'x', cast(ulong)p));
	}

	// The core template that will parse the format to find the string until a format specifier and return the length.
	template ExtractString(char[] format)
	{
		static if(format.length == 0)
		{
			const size_t ExtractString = 0;
		}
		else static if(format[0] is '{')
		{
			static if(format.length > 1 && format[1] is '{')
				const size_t ExtractString = 2 + ExtractString!(format[2 .. $]);
			else
				const size_t ExtractString = 0;
		}
		else
			const size_t ExtractString = 1 + ExtractString!(format[1 .. $]);
	}

	// Extracts the format string and returns the length of that string.
	template ExtractFormatStringImpl(char[] format)
	{
		static assert(format.length !is 0, "Unterminated format specifier");

		static if(format[0] is '}')
			const ExtractFormatStringImpl = 0;
		else
			const ExtractFormatStringImpl = 1 + ExtractFormatStringImpl!(format[1 .. $]);
	}

	// This template compares the format given (eg {x} would be "x") against the type of the argument passed.
	template CheckFormatAgainstType(char[] rawFormat, size_t idx, T)
	{
		const char[] format = rawFormat[1 .. idx];

		static if(isIntType!(T))
		{
			static assert(format == "" || format == "x" || format == "X" || format == "u" || format == "U",
					"Invalid integer format specifier '" ~ format ~ "'");
		}

		// This is an inherited attribute to describe the length of the format string
		const size_t res = idx;
	}

	// This template will compare a format with a type.
	template ExtractFormatString(char[] format, T)
	{
		const ExtractFormatString = CheckFormatAgainstType!(format, ExtractFormatStringImpl!(format), T).res;
	}

	// This will get the length of a single command
	template ExtractCommandStringImpl(char[] format)
	{
		static if (format.length == 0 || format[0] is '}')
		{
			const int ExtractCommandStringImpl = 0;
		}
		else
		{
			const int ExtractCommandStringImpl = 1 + ExtractCommandStringImpl!(format[1..$]);
		}
	}

	// This template will extract a command string, or set of command strings
	template ExtractCommandString(char[] format)
	{
		const ExtractCommandString = ExtractCommandStringImpl!(format);
	}

	// This template will take a string 's' and convert any '{{' to a single '{'.
	// This is done after parsing the format string.
	template StripDoubleLeftBrace(char[] s)
	{
		static if(s.length is 0)
			const char[] StripDoubleLeftBrace = "";
		else static if(s.length is 1)
			const char[] StripDoubleLeftBrace = s;
		else
		{
			static if(s[0 .. 2] == "{{")
				const char[] StripDoubleLeftBrace = "{" ~ StripDoubleLeftBrace!(s[2 .. $]);
			else
				const char[] StripDoubleLeftBrace = s[0] ~ StripDoubleLeftBrace!(s[1 .. $]);
		}
	}

	// Generates the code to print the string.
	template MakePrintString(char[] s)
	{
		const char[] MakePrintString = "printString(\"" ~ StripDoubleLeftBrace!(s) ~ "\", \"\");\n";
	}

	// This template will generate the code to print out the string.
	template MakePrintOther(T, char[] fmt, size_t idx)
	{
		static if(isIntType!(T))
			const char[] MakePrintOther = "printInt(args[" ~ idx.stringof ~ "], \"" ~ fmt ~ "\");\n";
		else static if(isCharType!(T))
			const char[] MakePrintOther = "printChar(args[" ~ idx.stringof ~ "], \"" ~ fmt ~ "\");\n";
		else static if(isStringType!(T))
			const char[] MakePrintOther = "printString(args[" ~ idx.stringof ~ "], \"" ~ fmt ~ "\");\n";
		else static if(isFloatType!(T))
			const char[] MakePrintOther = "printFloat(args[" ~ idx.stringof ~ "], \"" ~ fmt ~ "\");\n";
		else static if(isPointerType!(T))
			const char[] MakePrintOther = "printPointer(args[" ~ idx.stringof ~ "], \"" ~ fmt ~ "\");\n";
		else static if(isArrayType!(T))
			const char[] MakePrintOther = "printArray(args[" ~ idx.stringof ~ "], true, false);\n";
		else
			static assert(false, "I don't know how to handle argument " ~ idx.stringof ~ " of type '" ~ T.stringof ~ "'.");
	}

	// For the !fg command
	template MakePrintCommand_fg(char[] format)
	{
		static if (format.length <= 1)
		{
			static assert(false, "Not enough parameters to the !fg command.");
		}
		else
		{
			const char[] MakePrintCommand_fg = "Console.setForeColor(Color." ~ format[1..$] ~ ");\n";
		}
	}

	// For the !bg command
	template MakePrintCommand_bg(char[] format)
	{
		static if (format.length <= 1)
		{
			static assert(false, "Not enough parameters to the !bg command.");
		}
		else
		{
			const char[] MakePrintCommand_bg = "Console.setBackColor(Color." ~ format[1..$] ~ ");\n";
		}
	}

	template MakePrintCommand_pos(char[] format)
	{
		static if (format.length <= 3)
		{
			static assert(false, "Not enough parameters to the !pos command. USAGE: {!pos:x,y} where x and y are integers.");
		}
		else
		{
			const char[] MakePrintCommand_pos = "Console.setPosition(" ~ format[1..$] ~ ");\n";
		}
	}

	// Output code to do the command.
	template MakePrintCommandGenerate(char[] format)
	{
		static if (format.length >= 3 && format[0..3] == "cls")
		{
			const char[] MakePrintCommandGenerate = "Console.clearScreen();\n";
		}
		else static if (format.length >= 2 && format[0..2] == "fg")
		{
			const char[] MakePrintCommandGenerate = MakePrintCommand_fg!(format[2..$]);
		}
		else static if (format.length >= 2 && format[0..2] == "bg")
		{
			const char[] MakePrintCommandGenerate = MakePrintCommand_bg!(format[2..$]);
		}
		else static if (format.length >= 3 && format[0..3] == "pos")
		{
			const char[] MakePrintCommandGenerate = MakePrintCommand_pos!(format[3..$]);
		}
		else
		{
			static assert(false, "Unknown Command, !" ~ format ~ ", for kprintf.");
		}
	}

	// Finds the length of the command string
	template ExtractCommand(char[] format)
	{
		static if (format.length == 0 || format[0] is '}' || format[0] is '!')
		{
			const ExtractCommand = 0;
		}
		else
		{
			const ExtractCommand = 1 + ExtractCommand!(format[1..$]);
		}
	}

	// This template will take everything up to a ! or a } and generate the code for that command
	template MakePrintCommandImpl(char[] format)
	{
		static if (format.length == 0)
		{
			const char[] res = "";
		}
		else
		{
			static if (format[0] is '!')
			{
				const char[] res = MakePrintCommandImpl!(format[1..$]).res;
			}
			else
			{
				const lengthOfString = ExtractCommand!(format);

				const char[] res = MakePrintCommandGenerate!(format[0..lengthOfString]) ~
					MakePrintCommandImpl!(format[lengthOfString..$]).res;
			}
		}
	}

	// commands: !cls, !fg:color, !bg:color

	// This template parses the command string (excluding the initial !) and generates the commands necessary.
	template MakePrintCommand(char[] format)
	{
		const char[] MakePrintCommand = MakePrintCommandImpl!(format).res;
	}

	// This template implements the logic behind format extraction.
	template ConvertFormatImpl(char[] format, size_t argIdx, Types...)
	{
		static if(format.length == 0)
		{
			static assert(argIdx == Types.length, "More parameters than format specifiers");
			const char[] res = "";
		}
		else
		{
			// Look for a token that starts with a left curly brace that would signify a format specifier.
			static if (format[0] is '{' && (!(format.length > 1 && (format[1] is '{' || format[1] is '!'))))
			{
				// We have a format specifier, but no arguments to convert?
				static assert(argIdx < Types.length, "More format specifiers than parameters");

				// We will convert the string and generate code for the print.

				// Get the format string
				const lengthOfString = ExtractFormatString!(format, Types[argIdx]);

				// Generate the code and recall this template.
				const char[] res = MakePrintOther!(Types[argIdx], format[1 .. lengthOfString] , argIdx) ~
					ConvertFormatImpl!(format[lengthOfString + 1 .. $], argIdx + 1, Types).res;
			}
			else static if (format[0] is '{' && format.length > 1 && format[1] is '!')
			{
				// Command Token found, acts very similarly to a normal format specifier, expect it doesn't compare the types from the arguments.
				const lengthOfString = ExtractCommandString!(format);

				// Generate the code and recall this template.
				const char[] res = MakePrintCommand!(format[2..lengthOfString])
					~ ConvertFormatImpl!(format[lengthOfString + 1 .. $], argIdx, Types).res;
			}
			else
			{
				// We want to know how long of a string we can print out without intervention
				const lengthOfString = ExtractString!(format);

				// Then we can generate the code to print it out with the console and recall this template.
				const char[] res = MakePrintString!(format[0..lengthOfString]) ~
					ConvertFormatImpl!(format[lengthOfString..$], argIdx, Types).res;
			}
		}
	}

	// This template is the core routine. It will take the format and the arguments and generate the code to logically print out the string.
	template ConvertFormat(char[] format, Types...)
	{
		const char[] ConvertFormat = ConvertFormatImpl!(format, 0, Types).res;
	}
}



