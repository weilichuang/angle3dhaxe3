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

import de.polygonal.core.math.Limits;
import de.polygonal.core.math.Mathematics.M;
import de.polygonal.ds.Bits;
import de.polygonal.core.util.Assert.assert;

/**
	Various utility functions for formatting numbers
**/
class NumberFormat
{
	static var mHexLUT:Array<String> = null;
	
	/**
		Returns a string representation of the unsigned integer `x` in binary notation.
		
		@param byteDelimiter a character to insert between bytes.
		The default value is an empty string.
	**/
	public static function toBin(x:Int, byteDelimiter = "", leadingZeros = false):String
	{
		var n = Limits.INT_BITS - Bits.nlz(x);
		var s = ((x & 1) > 0) ? "1" : "0";
		x >>= 1;
		for (i in 1...n)
		{
			s = (((x & 1) > 0) ? "1" : "0") + ((i & 7 == 0) ? byteDelimiter : "") + s;
			x >>= 1;
		}
		
		if (leadingZeros)
			for (i in 0...Limits.INT_BITS - n)
				s = "0" + s;
		return s;
	}
	
	/**
		Returns a string representation of the unsigned integer `x` in hexadecimal notation.
	**/
	public static function toHex(x:Int):String
	{
		if (x == 0) return "0";
		var s = "";
		if (mHexLUT == null) mHexLUT = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];
		var a = mHexLUT;
		while (x != 0)
		{
			s = a[x & 0xF] + s;
			x >>>= 4;
		}
		return s;
	}
	
	/**
		Returns a string representation of the number `x` in octadecimal notation.
	**/
	public static function toOct(x:Int):String
	{
		var s = "";
		var t = x;
		do
		{
			var r = t & 7;
			s = r + s;
			t >>>= 3;
		}
		while (t > 0);
		return s;
	}
	
	/**
		Equals ``int::toString(radix)`` in ActionScript 3.0.
	**/
	public static function toRadix(x:Int, radix:Int):String
	{
		var s = "";
		var t = x;
		while (t > 0)
		{
			var r = t % radix;
			s = r + s;
			t = cast (t / radix);
		}
		return s;
	}
	
	/**
		Returns a string representation of the number `x` in fixed-point notation.
		
		@param decimalPlaces the number of decimal places.
	**/
	public static function toFixed(x:Float, decimalPlaces:Int):String
	{
		if (Math.isNaN(x))
			return "NaN";
		else
		{
			var t = M.exp(10, decimalPlaces);
			var s = Std.string(Std.int(x * t) / t);
			var i = s.indexOf(".");
			if (i != -1)
			{
				for (i in s.substr(i + 1).length...decimalPlaces)
					s += "0";
			}
			else
			{
				s += ".";
				for (i in 0...decimalPlaces)
					s += "0";
			}
			return s;
		}
	}
	
	/**
		Formats `seconds` to MM:SS.
	**/
	public static function toMMSS(seconds:Float):String
	{
		seconds = Std.int(seconds * 1000);
		var ms = seconds % 1000;
		var r = (seconds - ms) / 1000;
		var tmp = r % 60;
		return (("0" + ((r - tmp) / 60)).substr(-2)) + ":" + ("0" + tmp).substr(-2);
	}
	
	/**
		Groups the digits in the input number by using a thousands separator.
		
		E.g. the number 1024 is converted to the string "1.024".
		
		<assert>`x` is invalid</assert>
		@param thousandsSeparator a character to use as a thousands separator.
		The default value is ".".
	**/
	public static function groupDigits(x:Int, thousandsSeparator = "."):String
	{
		var s:String = x + "";
		
		if (x < 1000000)
		{
			if (x < 1000) //[0, 999]
				return s;
			else
			if (x < 10000) //[1.000, 9.999]
				return s.substr(0, 1) + thousandsSeparator + s.substr(1);
			else
			if (x < 100000) //[10.000, 99.999]
				return s.substr(0, 2) + thousandsSeparator + s.substr(2);
			else
			if (x < 1000000) //[100.000, 999.999]
				return s.substr(0, 3) + thousandsSeparator + s.substr(3);
		}
		else
		{
			if (x < 10000000) //[1.000.000, 9.999.999]
				return s.substr(0, 1) + thousandsSeparator + s.substr(1, 3) + thousandsSeparator + s.substr(4);
			else
			if (x < 100000000) //[10.000.000, 99.999.999]
				return s.substr(0, 2) + thousandsSeparator + s.substr(2, 3) + thousandsSeparator + s.substr(5);
			else
			if (x < 1000000000) //[100.000.000, 999.999.999]
				return s.substr(0, 3) + thousandsSeparator + s.substr(3, 3) + thousandsSeparator + s.substr(6);
		}
		
		if (x < 10000000000) //[1.000.000.000, 9.999.999.999]
			return s.substr(0, 1) + thousandsSeparator + s.substr(1, 3) + thousandsSeparator + s.substr(4, 3) + thousandsSeparator + s.substr(7);
		
		assert(false, 'invalid value ($x)');
		return null;
	}
	
	/**
		Cent to basic unit conversion, where one cent equals 1/100 of a basic unit.
		
		@param decimalSeparator a character to use as a decimal separator.
		The default value is ",".
		@param thousandsSeparator a character to use as a thousands separator.
		The default value is ".".
	**/
	public static function formatCent(x:Int, decimalSeparator = ",", thousandsSeparator = "."):String
	{
		var euro = Std.int(x / 100);
		if (euro == 0)
		{
			if (x < 10)
				return "0" + decimalSeparator + "0" + x;
			else
				return "0" + decimalSeparator + x;
		}
		else
		{
			var str:String;
			var cent = x - euro * 100;
			if (cent < 10)
				str = decimalSeparator + "0" + cent;
			else
				str = decimalSeparator + cent;
			if (euro >= 1000)
			{
				var num = euro;
				var add;
				while ( num >= 1000)
				{
					num = Std.int(euro / 1000);
					add = euro - num * 1000;
					if (add < 10)
						str = thousandsSeparator + "00" + add + str;
					else
					if (add < 100)
						str = thousandsSeparator + "0" + add + str;
					else
						str = thousandsSeparator + add + str;
					euro = num;
				}
				return str = num + str;
			}
			else
				str =  euro + str;
			return str;
		}
	}
}