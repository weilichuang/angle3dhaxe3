package org.angle3d.math.random;

/**
	Generates random numbers using the (platform-specific) *Math.random()* implementation.
**/
class Random {
	/**
		Returns a random integral number in the interval [0,0x7FFFFFFF).
	**/
	inline public static function rand():Int {
		return cast (frand() * FastMath.INT32_MAX);
	}

	/**
		Returns a random integral number in the interval [`min`,`max`].
	**/
	inline public static function randRange(min:Int, max:Int):Int {
		var l = min - .4999;
		var h = max + .4999;
		return Math.round(l + (h - l) * frand());
	}

	/**
		Returns a random integral number in the interval [-`range`,`range`].
	**/
	inline public static function randSymmetric(range:Int):Float {
		return randRange(-range, range);
	}

	/**
		Returns a random boolean value.
	**/
	inline public static function randBool():Bool {
		return frand() < .5;
	}

	/**
		Returns a random real number in the interval [0,1).
	**/
	inline public static function frand():Float {
		return Math.random();
	}

	/**
		Returns a random real number in the interval [`min`,`max`).
	**/
	inline public static function frandRange(min:Float, max:Float):Float {
		return min + (max - min) * frand();
	}

	/**
		Returns a random real number in the interval [-`range`,`range`).
	**/
	inline public static function frandSymmetric(range:Float):Float {
		return frandRange(-range, range);
	}
}