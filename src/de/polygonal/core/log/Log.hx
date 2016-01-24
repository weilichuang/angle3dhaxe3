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

import de.polygonal.core.event.Observable;
import de.polygonal.core.util.Assert.assert;

using de.polygonal.ds.Bits;

/**
	A lightweight log
	
	Logging messages are passed to registered ``LogHandler`` objects.
**/
class Log
{
	static var mCounter = 0;
	
	public var name(default, null):String;
	
	public var inclTag:EReg = null;
	public var exclTag:EReg = null;
	
	var mObservable:Observable;
	var mMask:Int;
	var mLevel:Int;
	var mMessage:LogMessage;
	var mTagFilter:EReg;
	
	public function new(name:String)
	{
		this.name = name;
		
		mMask = 0;
		mLevel = 0;
		mObservable = new Observable();
		mMessage = new LogMessage();
		setLevel(LogLevel.DEBUG);
	}
	
	/**
		Adds the handler `x` to this log.
		
		Once registered, `x` receives logging messages.
	**/
	public function addHandler(x:LogHandler)
	{
		#if log
		for (observer in mObservable) if (observer == x) return;
		mObservable.attach(x, 0);
		#end
	}
	
	/**
		Removes the handler `x` from this log.
	**/
	public function removeHandler(x:LogHandler)
	{
		#if log
		mObservable.detach(x);
		#end
	}
	
	/**
		Removes all handlers  from this log.
	**/
	public function removeAllHandlers()
	{
		#if log
		for (handler in mObservable.getObserverList()) removeHandler(cast handler);
		#end
	}
	
	/**
		A list of all registered log handlers.
	**/
	public function getLogHandlers():Array<LogHandler>
	{
		return cast mObservable.getObserverList();
	}
	
	/**
		Returns the name(s) of the active log level(s).
		
		Example:
		<pre class="prettyprint">
		class Main
		{
		    static function main() {
		        var log = de.polygonal.core.log.Log.getLog("Foo");
		        log.setLevel(LogLevel.INFO);
		        trace(log.getLevelName()); //INFO
		        log.setLevel(LogLevel.INFO | LogLevel.WARN);
		        trace(log.getLevelName()); //INFO|WARN
		    }
		}</pre>
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
		Returns the active log level(s) encoded as a bitfield.
	**/
	public function getLevel():Int
	{
		return mLevel;
	}
	
	/**
		Sets the log level `x` for controlling logging output.
		Enabling logging at a given level also enables logging at all higher levels.
		Each log level is specified by a bit flag in the range 0x01 (`LogLevel.DEBUG`) to 0x08 (`LogLevel.ERROR`).
		LogLevel.OFF can be used to turn off logging. The default log level is `LogLevel.DEBUG`.
		
		Example:
		<pre class="prettyprint">
		import de.polygonal.core.log.LogLevel;
		class Main
		{
		    static function main() {
		        var log = de.polygonal.core.log.Log.getLog("Foo");
		        log.setLevel(LogLevel.DEBUG);                 //print DEBUG, INFO, WARN and ERROR log messages
		        log.setLevel(LogLevel.WARN);                  //print WARN and ERROR log messages
		        log.setLevel(LogLevel.INFO | LogLevel.ERROR); //print INFO and ERROR log messages
		        log.setLevel(LogLevel.OFF);                   //print nothing
		    }
		}</pre>
		@throws de.polygonal.core.util.AssertError invalid log level (debug only).
	**/
	#if !log inline #end
	public function setLevel(x:Int)
	{
		#if log
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
		#end
	}
	
	/**
		Logs a `LogLevel.DEBUG` message.
		@param msg the log message.
	**/
	#if !log inline #end
	public function d(msg:String, ?tag:String, ?posInfos:haxe.PosInfos)
	{
		#if log
		if (mObservable.size() > 0)
			if (mMask.hasBits(LogLevel.DEBUG)) output(LogLevel.DEBUG, msg, tag, posInfos);
		#end
	}
	
	/**
		Logs a `LogLevel.DEBUG` message.
		@param msg the log message.
	**/
	#if !log inline #end
	public function debug(msg:String, ?tag:String, ?posInfos:haxe.PosInfos)
	{
		#if log
		if (mObservable.size() > 0)
			if (mMask.hasBits(LogLevel.DEBUG)) output(LogLevel.DEBUG, msg, tag, posInfos);
		#end
	}
	
	/**
		Logs a `LogLevel.INFO` message.
		@param msg the log message.
	**/
	#if !log inline #end
	public function i(msg:String, ?tag:String, ?posInfos:haxe.PosInfos)
	{
		#if log
		if (mObservable.size() > 0)
			if (mMask.hasBits(LogLevel.INFO)) output(LogLevel.INFO, msg, tag, posInfos);
		#end
	}
	
	/**
		Logs a `LogLevel.INFO` message.
		@param msg the log message.
	**/
	#if !log inline #end
	public function info(msg:String, ?tag:String, ?posInfos:haxe.PosInfos)
	{
		#if log
		if (mObservable.size() > 0)
			if (mMask.hasBits(LogLevel.INFO)) output(LogLevel.INFO, msg, tag, posInfos);
		#end
	}
	
	/**
		Logs a `LogLevel.WARN` message.
		@param msg the log message.
	**/
	#if !log inline #end
	public function w(msg:String, ?tag:String, ?posInfos:haxe.PosInfos)
	{
		#if log
		if (mObservable.size() > 0)
			if (mMask.hasBits(LogLevel.WARN)) output(LogLevel.WARN, msg, tag, posInfos);
		#end
	}
	
	/**
		Logs a `LogLevel.WARN` message.
		@param msg the log message.
	**/
	#if !log inline #end
	public function warn(msg:String, ?tag:String, ?posInfos:haxe.PosInfos)
	{
		#if log
		if (mObservable.size() > 0)
			if (mMask.hasBits(LogLevel.WARN)) output(LogLevel.WARN, msg, tag, posInfos);
		#end
	}
	
	/**
		Logs a `LogLevel.ERROR` message.
		@param msg the log message.
	**/
	#if !log inline #end
	public function e(msg:String, ?tag:String, ?posInfos:haxe.PosInfos)
	{
		#if log
		if (mObservable.size() > 0)
			if (mMask.hasBits(LogLevel.ERROR)) output(LogLevel.ERROR, msg, tag, posInfos);
		#end
	}
	
	/**
		Logs a `LogLevel.ERROR` message.
		@param msg the log message.
	**/
	#if !log inline #end
	public function error(msg:String, ?tag:String, ?posInfos:haxe.PosInfos)
	{
		#if log
		if (mObservable.size() > 0)
			if (mMask.hasBits(LogLevel.ERROR)) output(LogLevel.ERROR, msg, tag, posInfos);
		#end
	}

	function output(level:Int, msg:String, tag:String, ?posInfos:haxe.PosInfos)
	{
		if (inclTag != null)
			if (!inclTag.match(tag))
				return;
		
		if (exclTag != null)
			if (exclTag.match(tag))
				return;
		
		mCounter++; if (mCounter == 1000) mCounter = 0;
		
		if (msg == null) msg = "null";
		
		mMessage.id = mCounter;
		mMessage.msg = msg;
		mMessage.tag = tag;
		mMessage.log = this;
		mMessage.outputLevel = level;
		mMessage.posInfos = posInfos;
		mObservable.notify(LogEvent.LOG_MESSAGE, mMessage);
	}
}