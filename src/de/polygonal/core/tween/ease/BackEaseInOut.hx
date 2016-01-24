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
import de.polygonal.core.math.Mathematics.M;

/**
	Back easing in+out
	
	See Robert Penner Easing Equations.
**/
class BackEaseInOut implements Interpolation<Float>
{
	public var overshoot:Float;
	
	/**
		@param overshoot overshoot amount.
		Default value of 0.1 produces an overshoot of 10%.
	**/
	public function new(overshoot = .1)
	{
		this.overshoot = M.lerp(0, 17.0158, overshoot) * 1.525;
	}
	
	/**
		Computes the easing value using the given parameter `t` in the interval [0,1].
	**/
	public function interpolate(t:Float):Float
	{
		if (t < .5)
			return .5 * (4 * t * t * ((overshoot + 1) * 2 * t - overshoot));
		else
		{
			t = t * 2 - 2;
			return .5 * (t * t * ((overshoot + 1) * t + overshoot) + 2);
		}
	}
}