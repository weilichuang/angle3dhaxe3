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

import de.polygonal.core.math.Mathematics.M;

class Interval
{
	public var duration(get_duration, set_duration):Float;
	inline function get_duration():Float
	{
		return mDuration;
	}
	inline function set_duration(x:Float):Float
	{
		mDuration = x;
		reset();
		return x;
	}
	
	public var alpha(get_alpha, never):Float;
	inline function get_alpha():Float
	{
		return M.fmin(mMin / mMax, 1);
	}
	
	public var finished(get_finished, never):Bool;
	inline function get_finished():Bool
	{
		return alpha >= 1;
	}
	
	public var remainingSeconds(get_remainingSeconds, never):Float;
	inline function get_remainingSeconds():Float
	{
		return mMax - mMin;
	}
	
	public var hold:Bool;
	
	var mMin:Float;
	var mMax:Float;
	var mDuration:Float;
	
	public function new(duration:Float = 0)
	{
		this.duration = duration;
	}
	
	inline public function reset()
	{
		mMin = 0;
		mMax = duration;
	}
	
	inline public function advance(dt:Float):Float
	{
		if (!hold) mMin += dt;
		return alpha;
	}
}