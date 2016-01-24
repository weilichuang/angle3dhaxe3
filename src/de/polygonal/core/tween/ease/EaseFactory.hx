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
package de.polygonal.core.tween.ease;

import de.polygonal.core.math.Interpolation;

class EaseFactory
{
	static var mInstance:EaseFactory;
	public  static function create(type:Ease):Interpolation<Float>
	{
		if (mInstance == null)
			mInstance = new EaseFactory();
		return mInstance.mCreate(type);
	}
	
	var mNone:NullEase;
	var mFlashEaseOut:FlashEase;
	var mFlashEaseIn:FlashEase;
	var mPowEaseIn2:PowEaseIn;
	var mPowEaseIn3:PowEaseIn;
	var mPowEaseIn4:PowEaseIn;
	var mPowEaseIn5:PowEaseIn;
	var mPowEaseOut2:PowEaseOut;
	var mPowEaseOut3:PowEaseOut;
	var mPowEaseOut4:PowEaseOut;
	var mPowEaseOut5:PowEaseOut;
	var mPowEaseInOut2:PowEaseInOut;
	var mPowEaseInOut3:PowEaseInOut;
	var mPowEaseInOut4:PowEaseInOut;
	var mPowEaseInOut5:PowEaseInOut;
	var mSinEaseIn:SinEaseIn;
	var mSinEaseOut:SinEaseOut;
	var mSinEaseInOut:SinEaseInOut;
	var mExpEaseIn:ExpEaseIn;
	var mExpEaseOut:ExpEaseOut;
	var mExpEaseInOut:ExpEaseInOut;
	var mCircularEaseIn:CircularEaseIn;
	var mCircularEaseOut:CircularEaseOut;
	var mCircularEaseInOut:CircularEaseInOut;
	var mBackEaseIn:BackEaseIn;
	var mBackEaseOut:BackEaseOut;
	var mBackEaseInOut:BackEaseInOut;
	var mElasticEaseIn:ElasticEaseIn;
	var mElasticEaseOut:ElasticEaseOut;
	var mElasticEaseInOut:ElasticEaseInOut;
	var mBounceEaseIn:BounceEaseIn;
	var mBounceEaseOut:BounceEaseOut;
	var mBounceEaseInOut:BounceEaseInOut;
	
	function new()
	{
		mNone = new NullEase();
		mFlashEaseOut = new FlashEase(100);
		mFlashEaseIn = new FlashEase(-100);
		mPowEaseIn2 = new PowEaseIn(2);
		mPowEaseIn3 = new PowEaseIn(3);
		mPowEaseIn4 = new PowEaseIn(4);
		mPowEaseIn5 = new PowEaseIn(5);
		mPowEaseOut2 = new PowEaseOut(2);
		mPowEaseOut3 = new PowEaseOut(3);
		mPowEaseOut4 = new PowEaseOut(4);
		mPowEaseOut5 = new PowEaseOut(5);
		mPowEaseInOut2 = new PowEaseInOut(2);
		mPowEaseInOut3 = new PowEaseInOut(3);
		mPowEaseInOut4 = new PowEaseInOut(4);
		mPowEaseInOut5 = new PowEaseInOut(5);
		mSinEaseIn = new SinEaseIn();
		mSinEaseOut = new SinEaseOut();
		mSinEaseInOut = new SinEaseInOut();
		mExpEaseIn = new ExpEaseIn();
		mExpEaseOut = new ExpEaseOut();
		mExpEaseInOut = new ExpEaseInOut();
		mCircularEaseIn = new CircularEaseIn();
		mCircularEaseOut = new CircularEaseOut();
		mCircularEaseInOut = new CircularEaseInOut();
		mBackEaseIn = new BackEaseIn();
		mBackEaseOut = new BackEaseOut();
		mBackEaseInOut = new BackEaseInOut();
		mElasticEaseIn = new ElasticEaseIn();
		mElasticEaseOut = new ElasticEaseOut();
		mElasticEaseInOut = new ElasticEaseInOut();
		mBounceEaseIn = new BounceEaseIn();
		mBounceEaseOut = new BounceEaseOut();
		mBounceEaseInOut = new BounceEaseInOut();
	}
	
	function mCreate(x:Ease):Interpolation<Float>
	{
		switch (x)
		{
			case None:
				return mNone;
			
			case Flash(acceleration):
				switch (acceleration)
				{
					case  100: if (mFlashEaseOut == null) mFlashEaseOut = new FlashEase(100); return mFlashEaseOut;
					case -100: if (mFlashEaseIn == null) mFlashEaseIn = new FlashEase(-100); return mFlashEaseIn;
					case    _: return new FlashEase(acceleration);
				}
			
			case PowIn(degree):
				switch (degree)
				{
					case 2: return mPowEaseIn2;
					case 3: return mPowEaseIn3;
					case 4: return mPowEaseIn4;
					case 5: return mPowEaseIn5;
				}
			
			case PowOut(degree):
				switch (degree)
				{
					case 2: return mPowEaseOut2;
					case 3: return mPowEaseOut3;
					case 4: return mPowEaseOut4;
					case 5: return mPowEaseOut5;
				}
			
			case PowInOut(degree):
				switch (degree)
				{
					case 2: return mPowEaseInOut2;
					case 3: return mPowEaseInOut3;
					case 4: return mPowEaseInOut4;
					case 5: return mPowEaseInOut5;
				}
			
			case SinIn:    return mSinEaseIn;
			case SinOut:   return mSinEaseOut;
			case SinInOut: return mSinEaseInOut;
			
			case ExpIn:    return mExpEaseIn;
			case ExpOut:   return mExpEaseOut;
			case ExpInOut: return mExpEaseInOut;
			
			case CircularIn:    return mCircularEaseIn;
			case CircularOut:   return mCircularEaseOut;
			case CircularInOut: return mCircularEaseInOut;
			
			case BackIn(overshoot):    return overshoot == .1 ? mBackEaseIn    : new BackEaseIn(overshoot);
			case BackOut(overshoot):   return overshoot == .1 ? mBackEaseOut   : new BackEaseOut(overshoot);
			case BackInOut(overshoot): return overshoot == .1 ? mBackEaseInOut : new BackEaseInOut(overshoot);
			
			case ElasticIn(amplitude, period):    return (amplitude == .0 && period == .3) ? mElasticEaseIn    : new ElasticEaseIn(amplitude, period);
			case ElasticOut(amplitude, period):   return (amplitude == .0 && period == .3) ? mElasticEaseOut   : new ElasticEaseOut(amplitude, period);
			case ElasticInOut(amplitude, period): return (amplitude == .0 && period == .3) ? mElasticEaseInOut : new ElasticEaseInOut(amplitude, period);
			
			case BounceIn:    return mBounceEaseIn;
			case BounceOut:   return mBounceEaseOut;
			case BounceInOut: return mBounceEaseInOut;
		}
		
		return null;
	}
}