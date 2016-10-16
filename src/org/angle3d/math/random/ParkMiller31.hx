package org.angle3d.math.random;
import org.angle3d.error.Assert;

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
		Assert.assert(seed >= 0 && seed < 0x7FFFFFFF);
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
		if (lo > FastMath.INT32_MAX || lo < 0) lo -= FastMath.INT32_MAX;
		
		return mSeed = lo;
	}
	
	override public function randFloat():Float
	{
		return rand() / 2147483647.;
	}
}