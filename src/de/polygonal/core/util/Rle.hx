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
package de.polygonal.core.util;

import de.polygonal.core.math.Limits;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.Eof;
import haxe.io.Input;

/**
 * Run-length encoder/decoder (RLE)
**/
class Rle
{
	/**
		Encodes `uncoded` into a new set of bytes.
	**/
	public static function encode(uncoded:Input):Bytes
	{
		var encoded = new BytesOutput();
		var curr, prev = Limits.INT32_MAX;
		var count = 0;
		
		try
		{
			curr = prev = uncoded.readByte();
			while (true)
			{
				if (curr == prev)
					count++;
				else
				{
					encoded.writeByte(prev);
					if (count > 1)
					{
						encoded.writeByte(prev);
						count -= 2;
						while (count >= Limits.UINT8_MAX)
						{
							encoded.writeByte(Limits.UINT8_MAX);
							count -= Limits.UINT8_MAX;
						}
						encoded.writeByte(count);
					}
					count = 1;
				}
				prev = curr;
				
				curr = uncoded.readByte();
			}
		}
		catch (end:Eof)
		{
			//this is to prevent errors when given an input of zero length
			if (count > 0)
			{
				encoded.writeByte(prev);
				if (count > 1)
				{
					encoded.writeByte(prev);
					count -= 2;
					while (count >= Limits.UINT8_MAX)
					{
						encoded.writeByte(Limits.UINT8_MAX);
						count -= Limits.UINT8_MAX;
					}
					encoded.writeByte(count);
				}
			}
		}
		
		return encoded.getBytes();
	}
	
	/**
		Decodes `encoded` into a new set of bytes.
	**/
	public static function decode(encoded:Input):Bytes
	{
		var uncoded = new BytesOutput();
		var curr, prev = Limits.INT32_MAX;
		var count = 0;
		
		try
		{
			curr = encoded.readByte();
			while (true)
			{
				uncoded.writeByte(curr);
				if (curr == prev)
				{
					do
					{
						var nCount = count = encoded.readByte();
						while (nCount > 0)
						{
							uncoded.writeByte(curr);
							nCount--;
						}
					}
					while (count == Limits.UINT8_MAX);
					curr = Limits.INT32_MAX;
				}
				
				prev = curr;
				curr = encoded.readByte();
			}
		}
		catch (end:Eof) {}
		return uncoded.getBytes();
	}
	
	/**
		Encodes `uncoded` into a string.
		
		Returns Bytes, instead of string because some platforms like flash can't handle null characters in strings.
	**/
	public static inline function encodeString(uncoded:String):Bytes
	{
		return encodeBytes(Bytes.ofString(uncoded));
	}
	
	/**
		Decodes `encoded` into a string.
		
		Takes Bytes, instead of string because some platforms like flash can't handle null characters in strings.
	**/
	public static inline function decodeString(encoded:Bytes):String
	{
		return decodeBytes(Bytes.ofString(encoded.toString())).toString();
	}
	
	/**
		Encodes `uncoded` into a a new set of bytes.
	**/
	public static inline function encodeBytes(uncoded:Bytes):Bytes
	{
		return encode(new BytesInput(uncoded));
	}
	
	/**
		Decodes `encoded` into a new set of bytes.
	**/
	public static inline function decodeBytes(encoded:Bytes):Bytes
	{
		return decode(new BytesInput(encoded));
	}
	
}