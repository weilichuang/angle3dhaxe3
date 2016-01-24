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

import de.polygonal.core.math.Coord2.Coord2f;
import de.polygonal.core.util.Assert.assert;
import de.polygonal.core.math.Mathematics.M;

/**
	Fast and accurate sine/cosine approximations.
	
	Example:
	<pre>
	var sin = TrigApprox.hqSin(angle);
	var cos = TrigApprox.hqCos(angle);
	</pre>
**/
class TrigApprox
{
	/**
		Computes a low-precision sine approximation from an angle `x` measured in radians.
		The input angle has to be in the range [-PI,PI].
	**/
	inline public static function lqSin(x:Float):Float
	{
		assert(x >= -Math.PI && x <= Math.PI);
		
		if (x < 0)
			return 1.27323954 * x + .405284735 * x * x;
		else
			return 1.27323954 * x - .405284735 * x * x;
	}
	
	/**
		Computes a low-precision cosine approximation from an angle `x` measured in radians.
		The input angle has to be in the range [-PI,PI].
	**/
	inline public static function lqCos(x:Float):Float
	{
		assert(x >= -Math.PI && x <= Math.PI);
		
		x += M.PI_OVER_2; if (x > M.PI) x -= M.PI2;
		
		if (x < 0)
			return 1.27323954 * x + .405284735 * x * x
		else
			return 1.27323954 * x - .405284735 * x * x;
	}
	
	/**
		Computes a high-precision sine approximation from an angle `x` measured in radians.
		The input angle has to be in the range [-PI,PI].
	**/
	inline public static function hqSin(x:Float):Float
	{
		assert(x >= -Math.PI && x <= Math.PI);
		
		if (x <= 0)
		{
			var s = 1.27323954 * x + .405284735 * x * x;
			if (s < 0)
				return .225 * (s *-s - s) + s;
			else
				return .225 * (s * s - s) + s;
		}
		else
		{
			var s = 1.27323954 * x - .405284735 * x * x;
			if (s < 0)
				return .225 * (s *-s - s) + s;
			else
				return .225 * (s * s - s) + s;
		}
	}
	
	/**
		Computes a high-precision cosine approximation from an angle `x` in radians.
		The input angle has to be in the range [-PI,PI].
	**/
	inline public static function hqCos(x:Float):Float
	{
		assert(x >= -Math.PI && x <= Math.PI, Printf.format("x out of range (%.3f)", [x]));
		
		x += M.PI_OVER_2; if (x > M.PI) x -= M.PI2;
		
		if (x < 0)
		{
			var c = 1.27323954 * x + .405284735 * x * x;
			if (c < 0)
				return .225 * (c *-c - c) + c;
			else
				return .225 * (c * c - c) + c;
		}
		else
		{
			var c = 1.27323954 * x - .405284735 * x * x;
			if (c < 0)
				return .225 * (c *-c - c) + c;
			else
				return .225 * (c * c - c) + c;
		}
	}	
	
	/**
		Fast arctan2 approximation.
	**/
	inline public static function arctan2(y:Float, x:Float):Float
	{
		assert(!(M.cmpZero(x, 1e-6) && M.cmpZero(y, 1e-6)));
		
		var t = M.fabs(y);
		if (x >= 0.)
		{
			if (y < 0.)
				return-(M.PI_OVER_4 - M.PI_OVER_4 * ((x - t) / (x + t)));
			else
				return (M.PI_OVER_4 - M.PI_OVER_4 * ((x - t) / (x + t)));
		}
		else
		{
			if (y < 0.)
				return-((3. * M.PI_OVER_4) - M.PI_OVER_4 * ((x + t) / (t - x)));
			else
				return ((3. * M.PI_OVER_4) - M.PI_OVER_4 * ((x + t) / (t - x)));
		}
	}
	
	/**
		Computes the floating-point sine and cosine of the argument `a`.
		This method uses a polynomial approximation.
		Borrowed from the book ESSENTIAL MATHEMATICS FOR GAMES & INTERACTIVE APPLICATIONS
		Copyright (C) 2008 by Elsevier, Inc. All rights reserved.
	**/
	inline static var INV_PIHALF = 0.6366197723675814;
	inline static var CONST_A = 1.5703125; //201 / 128
	
	inline public static function sinCos(a:Float, output:Coord2f)
	{
		if (a < 0.)
		{
			var fa = (-INV_PIHALF) * a;
			var ia:Int = cast fa;
			fa = ((-a) - CONST_A * ia) - 4.8382679e-4 * ia;
			switch (ia & 3)
			{
				case 0:
					output.y =-IvPolynomialSinQuadrant(fa);
					output.x = IvPolynomialSinQuadrant(-((fa - CONST_A) - 4.8382679e-4));
				
				case 1:
					output.y =-IvPolynomialSinQuadrant(-((fa - CONST_A) - 4.8382679e-4));
					output.x = IvPolynomialSinQuadrant(-fa);
				
				case 2:
					output.y =-IvPolynomialSinQuadrant(-fa);
					output.x = IvPolynomialSinQuadrant(((fa - CONST_A) - 4.8382679e-4));
				
				case 3:
					output.y =-IvPolynomialSinQuadrant(((fa - CONST_A) - 4.8382679e-4));
					output.x = IvPolynomialSinQuadrant(fa);
			}
		}
		else
		{
			var fa = INV_PIHALF * a;
			var ia:Int = cast fa;
			fa = (a - CONST_A * ia) - 4.8382679e-4 * ia;
			switch (ia & 3)
			{
				case 0:
					output.y = IvPolynomialSinQuadrant(fa);
					output.x = IvPolynomialSinQuadrant(-((fa - CONST_A) - 4.8382679e-4));
				
				case 1:
					output.y = IvPolynomialSinQuadrant(-((fa - CONST_A) - 4.8382679e-4));
					output.x = IvPolynomialSinQuadrant(-fa);
				
				case 2:
					output.y = IvPolynomialSinQuadrant(-fa);
					output.x = IvPolynomialSinQuadrant(((fa - CONST_A) - 4.8382679e-4));
				
				case 3:
					output.y = IvPolynomialSinQuadrant(((fa - CONST_A) - 4.8382679e-4));
					output.x = IvPolynomialSinQuadrant(fa);
			}
		}
	}
	
	inline static function IvPolynomialSinQuadrant(a:Float)
	{
		return a * (1. + a * a * (-.16666 + a * a * (.0083143 - a * a * .00018542)));
	}
}