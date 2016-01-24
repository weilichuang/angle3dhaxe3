﻿/*
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
package de.polygonal.core.log;

import de.polygonal.ds.Bits;

/**
	A set of standard logging levels that can be used to filter logging output.
**/
class LogLevel
{
	/**
		A message level providing tracing information.
		
		Value 0x01.
	**/
	inline public static var DEBUG = Bits.BIT_01;
	
	/**
		A message level for informational messages.
		
		Value 0x02.
	**/
	inline public static var INFO = Bits.BIT_02;
	
	/**
		A message level indicating a potential problem.
		
		Value 0x04.
	**/
	inline public static var WARN = Bits.BIT_03;
	
	/**
		A message level indicating a serious failure.
		
		Value 0x08.
	**/
	inline public static var ERROR = Bits.BIT_04;
	
	/**
		A special level that can be used to turn off logging.
		
		Value 0x10.
	**/
	inline public static var OFF = Bits.BIT_05;
	
	/**
		A bitfield of all log levels.
		
		Value b11111.
	**/
	inline public static var ALL = LogLevel.DEBUG | LogLevel.INFO | LogLevel.WARN | LogLevel.ERROR | LogLevel.OFF;

	/**
		Returns the human-readable name of a log level.
	**/
	public static function getName(level:Int):String
	{
		return
		switch (Bits.ntz(level))
		{
			case 0: "DEBUG";
			case 1: "INFO";
			case 2: "WARN";
			case 3: "ERROR";
			case 4: "OFF";
			case _: "?";
		}
	}
	
	public static function getShortName(level:Int):String
	{
		return
		switch (Bits.ntz(level))
		{
			case 0: "D";
			case 1: "I";
			case 2: "W";
			case 3: "E";
			case 4: "O";
			case _: "?";
		}
	}
}