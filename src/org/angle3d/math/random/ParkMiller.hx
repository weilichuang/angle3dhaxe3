package org.angle3d.math.random;
import org.angle3d.error.Assert;

/**
	A Park-Miller-Carta PRNG (pseudo random number generator).
	
	Uses double-precision floating point to prevent overflow. Recommended since the fastest on most platforms.
	
	The seed value has to be in the range [0,2^31 - 1].
**/
class ParkMiller extends Rng
{
	var mSeedf:Float;
	
	/**
		Default seed value is 1.
	**/
	public function new(seed:Int = 1)
	{
		super();
		this.seed = seed;
	}
	
	override function get_seed():Int return Std.int(mSeedf);
	
	override function set_seed(value:Int):Int
	{
		Assert.assert(value >= 0 && value < FastMath.INT32_MAX);
		mSeedf = value;
		super.set_seed(value);
		return value;
	}
	
	/**
		Returns an integral number in the interval [0,0x7FFFFFFF).
	**/
	override public function rand():Float
	{
		mSeedf = (mSeedf * 16807.) % 2147483647.;
		return mSeedf;
	}
	
	override public function randFloat():Float
	{
		return rand() / 2147483647.;
	}
}