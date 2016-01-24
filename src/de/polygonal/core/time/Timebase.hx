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
package de.polygonal.core.time;

import de.polygonal.core.event.IObserver;
import de.polygonal.core.event.Observable;
import de.polygonal.core.util.Assert.assert;
import de.polygonal.core.math.Mathematics.M;

/**
	A Timebase is a constantly ticking source of time.
**/
class Timebase
{
	/**
		Converts `seconds` seconds to ticks.
	**/
	inline public static function secondsToTicks(seconds:Float):Int
	{
		return M.round(seconds / tickRate);
	}
	
	/**
		Converts `ticks` to seconds.
	**/
	inline public static function ticksToSeconds(ticks:Int):Float
	{
		return ticks * tickRate;
	}
	
	/**
		If true, time is consumed using a fixed time step.
		
		Default is true.
	**/
	public static var useFixedTimeStep:Bool = true;
	
	/**
		The update rate measured in seconds per tick.
		
		The default update rate is 60 ticks per second (or ~16.6ms per update).
	**/
	public static var tickRate(default, null):Float = 0.01666666;
	
	/**
		Elapsed time in seconds since application start.
	**/
	public static var elapsedTime(default, null):Float = 0;
	
	/**
		Elapsed "virtual" time in seconds (includes scaling).
	**/
	public static var elapsedGameTime(default, null):Float = 0;
	
	/**
		Current frame delta time in seconds.
	**/
	public static var timeDelta(default, null):Float = 0;
	
	/**
		Current "virtual" frame delta time in seconds (includes scaling).
	**/
	public static var gameTimeDelta(default, null):Float = 0;
	
	/**
		The current time scale > 0.
	**/
	public static var timeScale:Float = 1;
	
	/**
		The total number of processed ticks since application start.
	**/
	public static var numTickCalls(default, null):Int = 0;
	
	/**
		The total number of rendered frames since application start.
	**/
	public static var numDrawCalls(default, null):Int = 0;
	
	/**
		Current frames per second (how many frames were rendered in 1 second).
		
		Updated every second.
	**/
	public static var fps(default, null):Int = 60;
	
	public static var observable(default, null):Observable = null;
	public static function attach(o:IObserver, mask:Int = 0)
	{
		assert(mInitialized, "call Timebase.init() first");
		observable.attach(o, mask);
	}
	
	public static function detach(o:IObserver, mask:Int = 0)
	{
		assert(mInitialized, "call Timebase.init() first");
		observable.detach(o, mask);
	}
	
	static var mFreezeDelay:Float;
	static var mPaused:Bool;
	
	static var mAccumulator:Float = 0;
	static var mAccumulatorLimit:Float = tickRate * 10;
	
	static var mFpsTicks:Int = 0;
	static var mFpsTime:Float = 0;
	static var mPast:Float;
	
	static var mInitialized:Bool;
	
	static var mTime:Time;
	
	//TODO auto-init
	public static function init()
	{
		if (mInitialized) return;
		mInitialized = true;
		
		observable = new Observable(100);
	}
	
	public static function setTimeSource(time:Time)
	{
		mTime = time;
		mTime.setTimingEventHandler(update);
		mPast = mTime.now();
	}
	
	/**
		Disposes the system by removing all registered observers and explicitly nullifying all references for GC'ing used resources.
		
		The system is automatically reinitialized once an observer is attached.
	**/
	public static function free()
	{
		if (!mInitialized) return;
		mInitialized = false;
		
		observable.free();
		observable = null;
	}
	
	/**
		Sets the update rate measured in ticks per second, e.g. a value of 60 indicates that `TimebaseEvent.TICK` is fired 60 times per second (or every ~16.6ms).
		
		@param max the accumulator limit in seconds. If omitted, `max` is set to ten times `ticksPerSecond`.
	**/
	public static function setTickRate(ticksPerSecond:Int, max = -1.)
	{
		tickRate = 1 / ticksPerSecond;
		mAccumulator = 0;
		mAccumulatorLimit = (max == -1. ? 10 : max * tickRate);
	}
	
	/**
		Stops the flow of time.
		
		Triggers a `TimebaseEvent.PAUSE` update.
	**/
	public static function pause()
	{
		assert(mInitialized, "call Timebase.init() first");
		if (!mPaused)
		{
			mPaused = true;
			observable.notify(TimebaseEvent.PAUSE);
		}
	}
	
	/**
		Resumes the flow of time.
		
		Triggers a `TimebaseEvent.RESUME` update.
	**/
	public static function resume()
	{
		assert(mInitialized, "call Timebase.init() first");
		if (mPaused)
		{
			mPaused = false;
			mAccumulator = 0.;
			mPast = mTime.now();
			observable.notify(TimebaseEvent.RESUME);
		}
	}
	
	/**
		Toggles (pause/resume) the flow of time.
		Triggers a `TimebaseEvent.PAUSE` or em>TimebaseEvent.RESUME` update.
	**/
	public static function togglePause()
	{
		mPaused ? resume() : pause();
	}
	
	/**
		Freezes the flow of time for `seconds`.
	
		Triggers a `TimebaseEvent.FREEZE_BEGIN` update.
	**/
	public static function freeze(seconds:Float)
	{
		assert(mInitialized, "call Timebase.init() first");
		mFreezeDelay = seconds;
		mAccumulator = 0;
		observable.notify(TimebaseEvent.FREEZE_BEGIN);
	}
	
	/**
		Performs a manual update step.
	**/
	public static function step()
	{
		assert(mInitialized, "call Timebase.init() first");
		timeDelta = tickRate;
		elapsedTime += timeDelta;
		
		assert(timeScale > 0);
		
		gameTimeDelta = tickRate * timeScale;
		elapsedGameTime += gameTimeDelta;
		
		observable.notify(TimebaseEvent.TICK, tickRate);
		numTickCalls++;
		
		observable.notify(TimebaseEvent.RENDER, 1);
		numDrawCalls++;
	}
	
	static function update()
	{
		if (mPaused) return;
		
		assert(timeScale > 0);
		
		var now = mTime.now();
		var dt = (now - mPast);
		mPast = now;
		
		timeDelta = dt;
		elapsedTime += dt;
		
		mFpsTicks++;
		mFpsTime += dt;
		if (mFpsTime >= 1)
		{
			mFpsTime = 0;
			fps = mFpsTicks;
			mFpsTicks = 0;
		}
		
		if (mFreezeDelay > 0.)
		{
			mFreezeDelay -= timeDelta;
			observable.notify(TimebaseEvent.TICK, 0.);
			observable.notify(TimebaseEvent.RENDER, 1.);
			numTickCalls++;
			numDrawCalls++;
			
			if (mFreezeDelay <= 0.)
				observable.notify(TimebaseEvent.FREEZE_END);
			return;
		}
		
		if (useFixedTimeStep)
		{
			mAccumulator += timeDelta * timeScale;
			
			//clamp accumulator to prevent "spiral of death"
			if (mAccumulator > mAccumulatorLimit)
			{
				observable.notify(TimebaseEvent.CLAMP, mAccumulator);
				mAccumulator = mAccumulatorLimit;
			}
			
			gameTimeDelta = tickRate * timeScale;
			while (mAccumulator >= tickRate)
			{
				mAccumulator -= tickRate;
				elapsedGameTime += gameTimeDelta;
				observable.notify(TimebaseEvent.TICK, tickRate);
				numTickCalls++;
				if (mPaused) break;
			}
			
			if (mPaused) return;
			
			var alpha = mAccumulator / tickRate;
			observable.notify(TimebaseEvent.RENDER, alpha);
			numDrawCalls++;
		}
		else
		{
			mAccumulator = 0;
			gameTimeDelta = dt * timeScale;
			elapsedGameTime += gameTimeDelta;
			observable.notify(TimebaseEvent.TICK, gameTimeDelta);
			numTickCalls++;
			observable.notify(TimebaseEvent.RENDER, 1.);
			numDrawCalls++;
		}
	}
}