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
package de.polygonal.core.math.random;

import de.polygonal.core.util.Assert.assert;

/**
	A Park-Miller-Carta PRNG (pseudo random number generator).
	
	Integer implementation, using only 32 bit integer maths and no divisions.
	
	The seed value has to be in the range [0,2^31 - 1].
**/
class ParkMiller31 extends Rng
{
	/**
		Default seed value is 1.
	**/
	public function new(seed:Int = 1)
	{
		super();
		this.seed = seed;
	}
	
	override function set_seed(value:Int):Int
	{
		assert(seed >= 0 && seed < 0x7FFFFFFF);
		super.set_seed(value);
		return value;
	}
	
	/**
		Returns an integral number in the interval [0,0x7FFFFFFF).
	**/
	override public function rand():Float
	{
		var lo = 16807 * (mSeed & 0xFFFF);
		var hi = 16807 * (mSeed >>> 16);
		lo += (hi & 0x7FFF) << 16;
		lo += hi >>> 15;
		
		//check to see if the unsigned representation of lo is > MAX_VALUE
		if (lo > Limits.INT32_MAX || lo < 0) lo -= Limits.INT32_MAX;
		
		return mSeed = lo;
	}
	
	override public function randFloat():Float
	{
		return rand() / 2147483647.;
	}
}