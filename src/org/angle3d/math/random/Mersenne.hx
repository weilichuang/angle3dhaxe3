package org.angle3d.math.random;

import haxe.ds.Vector;

/**
	Mersenne Twister random number generator.

	Taken from the book "Essential Mathematics for Games And Interactive Applications".

	Copyright (C) 2008 by Elsevier, Inc. All rights reserved.

	This class uses the Mersenne Twister type MT19937, it does not use the faster SIMD-oriented Mersenne Twister as that requires 64-bit integers.
**/
class Mersenne extends Rng {
	inline static var kN = 624;
	inline static var kM = 397;
	inline static var kR = 31;
	inline static var kA = 0x9908B0DF;
	inline static var kU = 11;
	inline static var kS = 7;
	inline static var kT = 15;
	inline static var kL = 18;
	inline static var kB = 0x9D2C5680;
	inline static var kC = 0xEFC60000;
	inline static var kLowerMask = ((0x00000001) << kR) - 1;
	inline static var kUpperMask = 0xFFFFFFFF << kR;
	inline static var kTwistMask = 0x00000001;

	var mStateVector:Array<UInt>;
	var mKmag01:Array<UInt>;

	var mCurrentEntry:Int;

	/**
		Default seed value is 5489.
	**/
	public function new(seed = 5489) {
		super();

		mStateVector = new Array<UInt>(kN);

		mKmag01 = new Array<UInt>(2);

		mKmag01.set(0, 0);
		mKmag01.set(1, kA);

		this.seed = seed;
	}

	public function free() {
		mStateVector = null;
		mKmag01 = null;
	}

	override function set_seed(value:Int):Int {
		super.set_seed(value);

		setState(0, seed);

		#if js
		for (i in 1...kN) {
			setState(i, add32(mul32(0x6C078965, ui32(getState(i - 1) ^ (getState(i - 1) >>> 30))), i));
			setState(i, ui32(getState(i) & 0xFFFFFFFF));
		}
		#else
		for (i in 1...kN) setState(i, (0x6C078965 * (getState(i - 1) ^ (getState(i - 1) >>> 30)) + i));
		#end

		mCurrentEntry = kN;

		return value;
	}

	/**
		Initialize by an array of `keys`.
	**/
	public function initByArray(keys:Array<Int>) {
		var i = 1, j = 0;

		this.seed = 19650218;

		var length = keys.length;

		var k = (kN > length ? kN : length);

		while (k > 0) {
			#if js
			setState(i, add32(add32(ui32(getState(i) ^ mul32(ui32(getState(i-1) ^ (getState(i - 1) >>> 30)), 1664525)), keys[j]), j));
			setState(i, ui32(getState(i) & 0xFFFFFFFF));
			#else
			setState(i, (getState(i) ^ ((getState(i - 1) ^ (getState(i - 1) >>> 30)) * 1664525)) + keys[j] + j);
			#end

			i++;
			j++;

			if (i >= kN) {
				setState(0, getState(kN-1));
				i = 1;
			}

			if (j >= length) j = 0;
			k--;
		}

		k = kN - 1;
		while (k > 0) {
			#if js
			setState(i, sub32(ui32((getState(i)) ^ mul32(ui32(getState(i - 1) ^ (getState(i - 1) >>> 30)), 1566083941)), i));
			setState(i, ui32(getState(i) & 0xFFFFFFFF));
			#else
			setState(i, (getState(i) ^ ((getState(i - 1) ^ (getState(i - 1) >>> 30)) * 1566083941)) - i);
			#end

			i++;
			if (i >= kN) {
				setState(0, getState(kN - 1));
				i = 1;
			}

			k--;
		}

		setState(0, 0x80000000);
	}

	/**
		Returns an integral number in the interval [0,0xFFFFFFFF].
	**/
	override public function rand():Float {
		if (mCurrentEntry >= kN) {
			var temp:Int;

			for (k in 0...kN - kM) {
				#if js
				temp = ui32(((getState(k) & kUpperMask) | (getState(k + 1) & kLowerMask)));
				setState(k, ui32(getState(k + kM) ^ (temp >>> 1) ^ getMag01(temp & kTwistMask)));
				#else
				temp = ((getState(k) & kUpperMask) | (getState(k + 1) & kLowerMask));
				setState(k, getState(k + kM) ^ (temp >>> 1) ^ getMag01(temp & kTwistMask));
				#end
			}

			for (k in kN - kM...kN - 1) {
				#if js
				temp = ui32((getState(k) & kUpperMask) | (getState(k + 1) & kLowerMask));
				setState(k, ui32(getState(k + (kM - kN)) ^ (temp >>> 1) ^ getMag01(temp & kTwistMask)));
				#else
				temp = ((getState(k) & kUpperMask) | (getState(k + 1) & kLowerMask));
				setState(k, getState(k + (kM - kN)) ^ (temp >>> 1) ^ getMag01(temp & kTwistMask));
				#end
			}

			#if js
			temp = ui32((getState(kN - 1) & kUpperMask) | (getState(0) & kLowerMask));
			setState(kN - 1, ui32(getState(kM - 1) ^ (temp >>> 1) ^ getMag01(temp & kTwistMask)));
			#else
			temp = ((getState(kN - 1) & kUpperMask) | (getState(0) & kLowerMask));
			setState(kN - 1, getState(kM - 1) ^ (temp >>> 1) ^ getMag01(temp & kTwistMask));
			#end

			mCurrentEntry = 0;
		}

		var y = getState(mCurrentEntry++);

		#if js
		y = ui32(y ^ (y >>> kU));
		y = ui32(y ^ ((y << kS) & kB));
		y = ui32(y ^ ((y << kT) & kC));
		y = ui32(y ^ (y >>> kL));
		#else
		y ^= y >>> kU;
		y ^= (y << kS) & kB;
		y ^= (y << kT) & kC;
		y ^= y >>> kL;
		#end

		#if cpp
		return y < 0 ? (y + 4294967296.0) : y;
		#else
		return y >>> 0;
		#end
	}

	override public function randFloat():Float {
		return rand() * (1. / 4294967296.);
	}

	inline function getMag01(i:Int) {
		return mKmag01.get(i);
	}

	inline function getState(i:Int) {
		return mStateVector.get(i);
	}

	inline function setState(i:Int, x:Int) {
		mStateVector.set(i, x);
	}

	#if js
	inline function ui32(x) {
		return x < 0 ? (x ^ 0x80000000) + 0x80000000 : x;
	}
	inline function add32(a, b) {
		return ui32((a + b) & 0xFFFFFFFF);
	}
	inline function sub32(a, b) {
		return a < b ? ui32((Std.int(4294967296) - (b - a)) & 0xFFFFFFFF) : a - b;
	}
	inline function mul32(a, b) {
		var sum = 0;
		for (i in 0...32) {
			if (((a >>> i) & 0x1) != 0)
				sum = add32(sum, ui32(b << i));
		}
		return sum;
	}
	#end
}