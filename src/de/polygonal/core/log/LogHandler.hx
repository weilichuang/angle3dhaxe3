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
package de.polygonal.core.log;

import de.polygonal.core.event.IObservable;
import de.polygonal.core.event.IObserver;
import de.polygonal.core.fmt.StringUtil;
import de.polygonal.core.log.LogLevel;
import de.polygonal.core.log.LogMessage;
import de.polygonal.core.util.Assert.assert;
import haxe.ds.StringMap;

using de.polygonal.ds.Bits;

/**
 * A log handler receives log messages from a log and exports them to various output devices.
**/
@:build(de.polygonal.core.macro.IntConsts.build(
[
	DATE, TIME, TICK, LEVEL, NAME, TAG, CLASS, CLASS_SHORT, METHOD, LINE
], true, true))
class LogHandler implements IObserver
{
	inline public static var FORMAT_RAW         = 0;
	inline public static var FORMAT_BRIEF       = TICK | LEVEL | NAME | TAG;
	inline public static var FORMAT_BRIEF_INFOS = TICK | LEVEL | NAME | TAG | LINE | CLASS | CLASS_SHORT | METHOD;
	inline public static var FORMAT_FULL        = DATE | TIME | TICK | LEVEL | NAME | TAG | LINE | CLASS | CLASS_SHORT | METHOD;
	
	public static var DEFAULT_FORMAT = FORMAT_BRIEF_INFOS;
	
	var mLevel:Int;
	var mMask:Int;
	var mBits:Int;
	var mMessage:LogMessage;
	var mTagFormat:StringMap<Int>;
	
	function new()
	{
		mLevel = 0;
		mMask = 0;
		mBits = 0;
		mMessage = null;
		mTagFormat = null;
		
		setLevel(LogLevel.DEBUG);
		setFormat(0);
		init();
	}
	
	/**
		Disposes this object by explicitly nullifying all references for GC'ing used resources.
	**/
	public function free() {}
	
	/**
		Returns the active output level(s) encoded as a bitfield.
	**/
	public function getLevel():Int
	{
		return mLevel;
	}
	
	/**
		Returns the name(s) of the active output level(s).
		@see `Log#getLevelName()`.
	**/
	public function getLevelName():String
	{
		if (mLevel.ones() > 1)
		{
			var a = new Array<String>();
			var i = LogLevel.DEBUG;
			while (i < LogLevel.ALL)
			{
				if ((mLevel & i) > 0)
					a.push(LogLevel.getName(i));
				i <<= 1;
			}
			return a.join("|");
		}
		
		return LogLevel.getName(mLevel);
	}
	
	/**
		Sets the log level `x` specifying which message levels will be ultimately handled.
		Example:
		<pre class="prettyprint">
		import de.polygonal.core.log.LogLevel;
		import de.polygonal.core.log.Log;
		import de.polygonal.core.log.handler.TraceHandler;
		class Main
		{
		    static function main() {
		        var log = Log.getLog("Foo");
		        log.setLevel(LogLevel.DEBUG); //print DEBUG, INFO, WARN and ERROR logging messages
		        var handler = new TraceHandler();
		        handler.setLevel(Level.WARN); //log allows all levels, but the handler filters out everything except Level.WARN.
		    }
		}</pre>
		@throws de.polygonal.core.util.AssertError invalid log level (debug only).
	**/
	public function setLevel(x:Int)
	{
		#if debug
		assert((x & LogLevel.ALL) > 0, "(x & LogLevel.ALL) > 0");
		#end
		
		mLevel = x;
		
		if (x.ones() > 1)
		{
			mMask = x;
			return;
		}
		
		mMask = LogLevel.ALL;
		while (x > LogLevel.DEBUG)
		{
			x >>= 1;
			mMask = mMask.clrBits(x);
		}
	}
	
	/**
		The current logging format encoded as a bitfield.
	**/
	public function getFormat():Int
	{
		return mBits;
	}
	
	/**
		Adds extra information to a logging message.
		Example:
		<pre class="prettyprint">
		import de.polygonal.core.log.LogHandler;
		import de.polygonal.core.log.handler.TraceHandler;
		class Main
		{
		    static function main() {
		        var handler = new TraceHandler();
		        handler.setFormat(LogHandler.TIME | LogHandler.NAME);</pre>
		    }
		}</pre>
	**/
	public function setFormat(flags:Int, tag:String = null)
	{
		if (flags == 0) mBits = 0;
		if (tag != null)
		{
			if (mTagFormat == null)
				mTagFormat = new StringMap();
			mTagFormat.set(tag, flags);
		}
		else
			mBits = flags;
	}
	
	public function onUpdate(type:Int, source:IObservable, userData:Dynamic)
	{
		if (type == LogEvent.LOG_MESSAGE)
		{
			mMessage = cast userData;
			
			if (mMask.hasBits(mMessage.outputLevel))
			{
				var tmp = mBits;
				if (mTagFormat != null && mTagFormat.exists(mMessage.tag))
					mBits = mTagFormat.get(mMessage.tag);
				
				output(format());
				
				mBits = tmp;
			}
		}
	}
	
	function format():String
	{
		var args:Array<String> = [];
		var vals:Array<Dynamic> = [];
		
		var fmt, val;
		
		//date & time
		fmt = "%s";
		val = "";
		if (hasBits(DATE | TIME))
		{
			var date = Date.now().toString();
			if (mBits.getBits(DATE | TIME) == DATE | TIME)
				val = date.substr(5); //mm-dd hh:mm:ss
			else
			if (hasBits(TIME))
				val = date.substr(11); //hh:mm:ss
			else
				val = date.substr(5, 5); //mm-dd
		}
		args.push(fmt);
		vals.push(val);
		
		//tick
		if (hasBits(TICK))
		{
			fmt = "%03d";
			val = "";
			if (hasBits(DATE | TIME)) fmt = " " + fmt;
			args.push(fmt);
			vals.push(de.polygonal.core.time.Timebase.numTickCalls % 1000);
		}
		
		//level
		fmt = "%s";
		val = "";
		if (hasBits(LEVEL))
		{
			val = LogLevel.getShortName(mMessage.outputLevel);
			if (hasBits(DATE | TIME | TICK)) fmt = " %s";
		}
		args.push(fmt);
		vals.push(val);
		
		//log name
		fmt = "%s";
		val = "";
		if (hasBits(NAME))
		{
			if (hasBits(LEVEL)) fmt = "/%s";
			val = mMessage.log.name;
		}
		args.push(fmt);
		vals.push(val);
		
		//message tag
		fmt = "%s";
		val = "";
		if (hasBits(TAG))
		{
			if (mMessage.tag != null)
			{
				val = mMessage.tag;
				fmt = "/%s";
			}
		}
		args.push(fmt);
		vals.push(val);
		
		//position infos
		fmt = "%s";
		if (hasBits(CLASS | METHOD | LINE))
		{
			fmt = "(";
			
			if (hasBits(CLASS))
			{
				var className = mMessage.posInfos.className;
				if (hasBits(CLASS_SHORT))
					className = className.substr(className.lastIndexOf(".") + 1);
				if (className.length > 30)
					className = StringUtil.ellipsis(className, 30, 0);
				
				fmt += "%s";
				vals.push(className);
			}
			
			if (hasBits(METHOD))
			{
				var methodName = mMessage.posInfos.methodName;
				if (methodName.length > 30) methodName = StringUtil.ellipsis(methodName, 30, 0);
				
				fmt += hasBits(CLASS) ? ".%s" : "%s";
				vals.push(methodName);
			}
			
			if (hasBits(LINE))
			{
				fmt += hasBits(CLASS | METHOD) ? " %04d" : "%04d";
				vals.push(mMessage.posInfos.lineNumber);
			}
			
			fmt += ")";
		}
		else
			vals.push("");
		args.push(fmt);
		
		//message
		fmt = mBits == 0 ? "%s" : ": %s";
		val = mMessage.msg;
		var s = val;
		if (Std.is(s, String) && s.indexOf("\n") != -1)
		{
			var pre = "";
			if (hasBits(LEVEL))
				pre = LogLevel.getShortName(mMessage.outputLevel);
			if (hasBits(NAME))
			{
				if (hasBits(LEVEL))
					pre += "/";
				pre += mMessage.log.name;
			}
			if (hasBits(TAG))
				if (mMessage.tag != null)
					pre += "/" + mMessage.tag;
			
			if (s.indexOf("\r") != -1)
				s = s.split("\r").join("");
			var tmp = [];
			for (i in s.split("\n"))
				if (i != "") tmp.push(i);
			
			if (mBits != FORMAT_RAW)
				val = "\n" + pre + ": " + tmp.join("\n" + pre + ": ");
		}
		
		args.push(fmt);
		vals.push(val);
		
		return Printf.format(args.join(""), vals);
	}
	
	function output(msg:String) {}
	
	function init()
	{
		mBits = DEFAULT_FORMAT;
	}
	
	inline function hasBits(mask:Int) return mBits.hasBits(mask);
}