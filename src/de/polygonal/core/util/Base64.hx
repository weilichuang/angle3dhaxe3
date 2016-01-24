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

import haxe.crypto.BaseCode;
import haxe.io.Bytes;
import haxe.io.BytesData;

/**
	A Base64 encoder/decoder using haxe.crypto.BaseCode
**/
class Base64
{
	static var BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	
	static var coder = new BaseCode(Bytes.ofString(BASE64_CHARS));
	
	/**
		Encodes `source` into a string in Base64 notation.
		
		@param breakLines if true, breaks lines every `maxLineLength` characters.
		Disabling this behavior violates strict Base64 specification, but makes the encoding faster.
		@param maxLineLength the maximum line length of the output. Default is 76.
	**/
	inline public static function encode(source:BytesData, breakLines = false, maxLineLength = 76):String
	{
		return encodeBytes(Bytes.ofData(source), breakLines, maxLineLength);
	}
	
	/**
		Shortcut for encoding a string into a string in Base64 notation.
		
		@param breakLines if true, breaks lines every `maxLineLength` characters.
		Disabling this behavior violates strict Base64 specification, but makes the encoding faster.
		@param maxLineLength the maximum line length of the output. Default is 76.
	**/
	inline public static function encodeString(source:String, breakLines = false, maxLineLength = 76):String
	{
		return encodeBytes(Bytes.ofString(source), breakLines, maxLineLength);
	}
	
	/**
		Decodes the Base64 encoded string `source`.
		
		@param breakLines if true, removes all newline (\n) characters from `source` before decoding it.
		Use this flag if the source was encoded with `breakLines` = true. Default is false.
	**/
	inline public static function decode(source:String, breakLines = false):BytesData
	{
		return decodeBytes(source, breakLines).getData();
	}
	
	/**
		Shortcut for decoding the Base64 encoded string `source` directly into a string.
		
		@param breakLines if true, removes all newline (\n) characters from `source` before decoding it.
		Use this flag if the source was encoded with `breakLines` = true. Default is false.
	**/
	inline public static function decodeString(source:String, breakLines = false):String
	{
		var bytes = decodeBytes(source, breakLines);
		return bytes.getString(0, bytes.length);
	}
	
	static function decodeBytes(source:String, breakLines = false)
	{
		if (breakLines)
		{
			source = ~/\r/g.replace(source, "");
			source = source.split("\n").join("");
		}
		
		var padding = source.indexOf("=");
		if (padding != -1) source = source.substring(0, padding);
		
		return coder.decodeBytes(Bytes.ofString(source));
	}
	
	static function encodeBytes(source:Bytes, breakLines = false, maxLineLength = 76):String
	{
		inline function pad(x:String)
		{
			return x + switch(x.length % 4)
			{
				case 3:  "===";
				case 2:  "==";
				case 1:  "=";
				default: "";
			};
		}
		
		inline function split(x:String, lineLength:Int)
		{
			var lines = [];
			while (x.length > lineLength)
			{
				lines.push(x.substring(0, lineLength));
				x = x.substring(lineLength);
			}
			return lines.join("\n");
		}
		
		var bytes = coder.encodeBytes(source);
		var result = pad(bytes.getString(0, bytes.length));
		return breakLines ? split(result, maxLineLength) : result;
	}
}