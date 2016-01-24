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

import de.polygonal.ds.Da;
import haxe.ds.StringMap;
import de.polygonal.core.util.Assert.assert;

using Reflect;

typedef LogSystemConfig =
{
	globalHandler: Array<LogHandler>,
	?redirectTraceToDebugLog: Bool,
	?keepDefaultTrace: Bool,
	?logFileName: String
}

class LogSystem
{
	public static var log:Log = null;
	
	static var mConfig:LogSystemConfig;
	
	static var mLogList:Da<Log> = null;
	static var mLogLookup:StringMap<Log> = null;
	
	static var mInitialized = false;
	
	public static function init(config:LogSystemConfig)
	{
		if (log != null) return;
		
		mConfig = config;
		mInitialized = true;
		
		log = createLog("global", false);
		
		for (i in config.globalHandler) log.addHandler(i);
		
		#if !no_traces
		if (config.hasField("redirectTraceToDebugLog") && config.field("redirectTraceToDebugLog") == true)
		{
			var keepDefaultTrace = config.hasField("keepDefaultTrace") && config.field("keepDefaultTrace") == true;
			var defaultTrace = haxe.Log.trace;
			
			//override default trace to add some sprintf sugar
			haxe.Log.trace = function(x:Dynamic, ?posInfos:haxe.PosInfos)
			{
				if (posInfos.customParams != null)
				{
					if (~/%(([+\- #0])*)?((\d+)|(\*))?(\.(\d?|(\*)))?[hlL]?[bcdieEfgGosuxX]/g.match(x))
						x = Printf.format(Std.string(x), posInfos.customParams);
					else
						x = x + "," + posInfos.customParams.join(",");
				}
				
				//TODO cpp crashing
				log.debug(x, posInfos);
				
				if (keepDefaultTrace) defaultTrace(x, posInfos);
			}
		}
		else
		{
			if (!config.keepDefaultTrace)
				haxe.Log.trace = function(x:Dynamic, ?posInfos:haxe.PosInfos) {};
		}
		#end
	}
	
	/**
		Creates a new log or returns an existing one.
	**/
	public static function createLog(name:String, addDefaultHandler = false):Log
	{
		assert(mInitialized, "Call LogSystem.init() first.");
		
		if (mLogLookup == null)
		{
			mLogLookup = new StringMap<Log>();
			mLogList = new Da<Log>();
		}
		
		if (mLogLookup.exists(name))
			return mLogLookup.get(name);
		
		var log = new Log(name);
		
		mLogLookup.set(name, log);
		
		if (addDefaultHandler && mConfig != null)
		{
			for (i in mConfig.globalHandler)
				log.addHandler(cast i);
		}
		mLogList.pushBack(log);
		return log;
	}
	
	/**
		Unregisters an existing log.
	**/
	public static function removeLog(log:Log)
	{
		var keys = mLogLookup.keys();
		for (i in keys)
		{
			if (mLogLookup.exists(i))
			{
				if (log.name == i)
				{
					mLogLookup.remove(i);
					mLogList.remove(log);
					break;
				}
			}
		}
	}
}