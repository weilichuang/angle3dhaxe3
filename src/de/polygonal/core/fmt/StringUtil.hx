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

import de.polygonal.core.fmt.Ascii;
import de.polygonal.core.math.random.Random;
import de.polygonal.core.util.Assert.assert;

/**
	Various utility functions for working with strings
**/
class StringUtil
{
	/**
		Returns true if the string `x` consists of whitespace characters only.
	**/
	public static function isWhite(x:String):Bool
	{
		return ~/\S/.match(x) == false;
	}
	
	/**
		Reverses the string `x`.
	**/
	public static function reverse(x:String):String
	{
		var t = "";
		var i = x.length;
		while (--i >= 0) t += x.charAt(i);
		return t;
	}
	
	/**
		Trims the string `x` to `maxLength` by replacing surplus characters with the ellipsis character (U+2026).
		@param useThreeDots if true, uses three dots (...) instead of the ellipsis character.
		@param mode 0=prepend ellipsis, 1=append ellipsis, 2=center ellipsis.
	**/
	public static function ellipsis(x:String, maxLength:Int, mode:Int, useThreeDots = false):String
	{
		var l = x.length;
		
		if (l <= maxLength) return x;
		
		if (maxLength == 0) return useThreeDots ? "..." : "…";
		
		if (useThreeDots)
			if (maxLength < 4) return "...";
		
		switch (mode)
		{
			case 0:
				if (l > maxLength)
				{
					var ellipsisCharacter = useThreeDots ? "..." : "…";
					return ellipsisCharacter + x.substr(l + ellipsisCharacter.length - maxLength);
				}
				else
					return x;
			
			case 1:
				if (l > maxLength)
				{
					var ellipsisCharacter = useThreeDots ? "..." : "…";
					return x.substr(0, maxLength - ellipsisCharacter.length) + ellipsisCharacter;
				}
				else
					return x;
			
			case 2:
				var l = x.length;
				var a = x.split("");
				if (useThreeDots)
				{
					a[(l >> 1) - 1] = ".";
					a[(l >> 1)    ] = ".";
					a[(l >> 1) + 1] = ".";
					var side = 1;
					while (l > maxLength)
					{
						side *= -1;
						a.splice((l >> 1) + side, 1);
						a[(l >> 1) + side * -1] = ".";
						l--;
					}
				}
				else
				{
					while (l > maxLength)
					{
						a.splice(l >> 1, 1);
						l--;
					}
					a[l >> 1] = "…";
				}
				return a.join("");
		}
		
		return null;
	}
	
	/**
		Prepends a total of (`n` - `x`.length) zeros to the string `x`.
	**/
	public static function fill0(x:String, n:Int):String
	{
		var s = "";
		for (i in 0...n - x.length) s += "0";
		return s + x;
	}
	
	/**
		Converts the string `x` in binary format into a decimal number.
	**/
	public static function parseBin(x:String):Int
	{
		var b = 0;
		var j = 0;
		var i = x.length;
		while (i-- > 0)
		{
			var s = x.charAt(i);
			if (s == "0")
				j++;
			else
			if (s == "1")
			{
				b += 1 << j;
				j++;
			}
		}
		return b;
	}
	
	/**
		Converts the string `x` in hexadecimal format into a decimal number.
	**/
	public static function parseHex(x:String):Int
	{
		var h = 0;
		var j = 0;
		var i = x.length;
		while (i-- > 0)
		{
			var c = x.charCodeAt(i);
			if (c == 88 || c == 120) break;
			
			if (Ascii.isDigit(c))
			{
				h += (c - Ascii.ZERO) * (1 << j);
				j += 4;
			}
			else
			if (c >= Ascii.A && c <= Ascii.F)
			{
				h += (c - Ascii.F + 15) * (1 << j);
				j += 4;
			}
			else
			if (c >= Ascii.a && c <= Ascii.f)
			{
				h += (c - Ascii.f + 15) * (1 << j);
				j += 4;
			}
		}
		return h;
	}
	
	/**
		Generates a random key of given `chars` * `length`.
	**/
	public static function generateRandomKey(chars:String, length:Int):String
	{
		var s = "";
		for (i in 0...length)
			s += chars.charAt(Random.randRange(0, chars.length - 1));
		return s;
	}
	
	/**
		Returns true if `x` is latin script only.
	**/
	public static function isLatin(x:String):Bool
	{
		for (i in 0...x.length)
		{
			var code = x.charCodeAt(i);
			if (code > 0x036F && code != 0x20AC) //ignore euro sign
				return false;
		}
		return true;
	}
	
	/**
		Escapes all regular expression meta characters in `x`.
	**/
	public static function escapeRegExMetaChars(x:String):String
	{
		return ~/([\[\]\\\^\$\*\+\?\{\|\-\\])/g.replace(x, "\\$1");
	}
	
	/**
		Returns the byte length of the utf-8 encoded string `x`.
	**/
	public static function utf8Len(x:String):Int
	{
		var n = 0, c;
		for (i in 0...x.length)
		{
			c = x.charCodeAt(i);
			n +=
			if (c <= 0x7f) 1;
			else if (c <= 0x7ff) 2;
			else if (c <= 0xffff) 3;
			else if (c <= 0x10ffff) 4;
			else
				throw 'Invalid Unicode character : 0x${StringTools.hex(c)}';
		}
		
		return n;
	}
	
	public static function hashCode(x:String):Int
	{
		var hash = 0;
		
		var k = x.length;
		if (k == 0) return hash;
		for (i in 0...k)
		{
			var c = x.charCodeAt(i);
			hash = ((hash << 5) - hash) + c;
			
			#if js
			hash = hash & hash; // Convert to 32bit integer
			#end
		}
		
		return hash;
    }
}