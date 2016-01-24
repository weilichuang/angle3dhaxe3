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
package de.polygonal.core.math;

import de.polygonal.core.math.Mathematics.M;

/**
	Maps a value from a source range [`srcMin`,`srcMax`] to a destination range [`dstMin`,`dstMax`].
**/
class ChangeRange implements Interpolation<Float>
{
	inline public static function map(x:Float, srcMin:Float, srcMax:Float, dstMin:Float, dstMax:Float):Float
	{
		return M.lerp(dstMin, dstMax, (x - srcMin) / (srcMax - srcMin));
	}
	
	public var srcMin:Float;
	public var srcMax:Float;
	
	public var dstMin:Float;
	public var dstMax:Float;
	
	public function new(srcMin:Float, srcMax:Float, dstMin:Float, dstMax:Float)
	{
		this.srcMin = srcMin;
		this.srcMax = srcMax;
		this.dstMin = dstMin;
		this.dstMax = dstMax;
	}
	
	public function interpolate(t:Float):Float
	{
		return M.lerp(dstMin, dstMax, (t - srcMin) / (srcMax - srcMin));
	}
}