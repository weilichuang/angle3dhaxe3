/*
Copyright (c) 2012-2014 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.core.fmt;

/**
	Creates a textual representation of an object or the stack
**/
class Dump
{
	/**
		Returns a human-readable representation of `value`.
	**/
	public static function dump(value:Dynamic):String
	{
		function f(x:Dynamic, ws:String):String
		{
			var s = "\n";
			var fields = Reflect.fields(x);
			for (field in fields)
			{
				var value:Dynamic = Reflect.field(x, field);
				switch (Type.typeof(value))
				{
					case Type.ValueType.TObject:
						s += '$ws$field:';
						s += f(value, '$ws|    ');
					
					case Type.ValueType.TClass(c):
						switch (c)
						{
							case Array:
								s += '$ws$field: [Array]';
								s += f(value, '$ws|    ');
							
							case _:
								s += '$ws$field: $value [${Type.getClassName(c)}]\n';
						}
					
					case Type.ValueType.TEnum(e):
						s += '$ws$field: $value [Enum(${Type.getEnumName(e)})]\n';
					
					default:
						s += '$ws$field: $value [${Std.string(Type.typeof(value)).substr(1)}]\n';
				}
			}
			return s;
		}
		
		return f(value, "");
	}
}