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
import de.polygonal.core.util.Assert.assert;

/**
	A 2x2 matrix.
	Matrix operations are applied on the left. E.g. given a matrix M and vector V, matrix*vector is M*V, where V is treated as a column vector.
**/
class Mat22
{
	/**
		@return `c` = `a`*`b`.
	**/
	inline public static function matrixProduct(a:Mat22, b:Mat22, c:Mat22):Mat22
	{
		var b11 = b.m11; var b12 = b.m12;
		var b21 = b.m21; var b22 = b.m22;
		var t1, t2;
		t1 = a.m11;
		t2 = a.m12;
		c.m11 = t1 * b11 + t2 * b21;
		c.m12 = t1 * b12 + t2 * b22;
		t1 = a.m21;
		t2 = a.m22;
		c.m21 = t1 * b11 + t2 * b21;
		c.m22 = t1 * b12 + t2 * b22;
		return c;
	}
	
	public var m11:Float; public var m12:Float;
	public var m21:Float; public var m22:Float;
	
	public function new(?col1:Vec2, ?col2:Vec2)
	{
		if (col1 == null)
		{
			m11 = 1;
			m21 = 0;
		}
		else
		{
			m11 = col1.x;
			m21 = col1.y;
		}
			
		if (col2 == null)
		{
			m12 = 0;
			m22 = 1;
		}
		else
		{
			m12 = col2.x;
			m22 = col2.y;
		}
	}
	/**
		Returns the column at index `i`
	**/
	inline public function getCol(i:Int, output:Vec2):Vec2
	{
		assert(i >= 0 && i < 2, "i >= 0 && i < 2");
		
		switch (i)
		{
			case 0:
				output.x = m11;
				output.y = m21;
			
			case 1:
				output.x = m12;
				output.y = m22;
		}
		
		return output;
	}
	
	/**
		Assigns the values of `other` to this.
	**/
	inline public function set(other:Mat22):Mat22
	{
		m11 = other.m11; m12 = other.m12;
		m21 = other.m21; m22 = other.m22;
		return this;
	}
	
	inline public function setCol1(x:Float, y:Float)
	{
		m11 = x;
		m21 = y;
	}
	
	inline public function setCol2(x:Float, y:Float)
	{
		m12 = x;
		m22 = y;
	}
	
	/**
		Assign two columns.
	**/
	inline public function setCols(u:Vec2, v:Vec2):Mat22
	{
		m11 = u.x; m12 = v.x;
		m21 = u.y; m22 = v.y;
		return this;
	}
	
	/**
		Set to identity matrix.
	**/
	inline public function setIdentity():Mat22
	{
		m11 = 1; m12 = 0;
		m21 = 0; m22 = 1;
		return this;
	}
	
	/**
		Zero out all matrix elements.
	**/
	inline public function setZero():Mat22
	{
		m11 = 0; m12 = 0;
		m21 = 0; m22 = 0;
		return this;
	}
	
	/**
		Extracts the angle of rotation around the z-axis.
		The angle is computed as atan2(sin(alpha), cos(alpha)) = atan2(>m21>, >m11>).
		*The matrix must be a rotation matrix*.
	**/
	inline public function getAngle():Float
	{
		return Math.atan2(m21, m11);
	}
	
	/**
		Set as rotation matrix, rotating by `angle` radians.
	**/
	inline public function setAngle(angle:Float)
	{
		var c = Math.cos(angle);
		var s = Math.sin(angle);
		m11 = c; m12 =-s;
		m21 = s; m22 = c;
	}
	
	/**
		Set as rotation matrix, rotating by approximate `angle` radians.
	**/
	inline public function setApproxAngle(angle:Float)
	{
		var s = Math.sin(angle);
		var c = Math.cos(angle);
		m11 = c; m12 =-s;
		m21 = s; m22 = c;
	}
	
	/**
		Multiplies all matrix elements by the scalar `x`.
	**/
	inline public function timesScalar(x:Float)
	{
		m11 *= x; m12 *= x;
		m21 *= x; m22 *= x;
	}
	
	/**
		Matrix - column vector multiplication (M*V): `rhs`' = this * `rhs`.
	**/
	inline public function timesVector(rhs:Vec2):Vec2
	{
		var x = rhs.x;
		var y = rhs.y;
		rhs.x = m11 * x + m12 * y;
		rhs.y = m21 * x + m22 * y;
		return rhs;
	}
	
	/**
		Multiply vector x,y with first row
	**/
	inline public function mulx(x:Float, y:Float):Float
	{
		return x * m11 + y * m12;
	}
	
	/**
		Multiply vector x,y with second row
	**/
	inline public function muly(x:Float, y:Float):Float
	{
		return x * m21 + y * m22;
	}
	
	/**
		Same as `timesVector()`, but without modifying `rhs`.
		@param output stores the result.
	**/
	inline public function timesVectorConst(rhs:Vec2, output:Vec2):Vec2
	{
		var x = rhs.x;
		var y = rhs.y;
		output.x = m11 * x + m12 * y;
		output.y = m21 * x + m22 * y;
		return output;
	}
	
	/**
		Matrix - row vector multiplication (M^t*V): `lhs`' = `lhs`*this.
	**/
	inline public function vectorTimes(lhs:Vec2):Vec2
	{
		var x = lhs.x;
		var y = lhs.y;
		lhs.x = x * m11 + y * m21;
		lhs.y = x * m12 + y * m22;
		return lhs;
	}
	
	/**
		Computes the matrix transpose and returns this matrix.
	**/
	inline public function transpose():Mat22
	{
		var tmp = m21; m21 = m12; m12 = tmp;
		return this;
	}
	
	/**
		Same as `transpose()`, but without modifying this matrix.
		@param output stores the result.
	**/
	inline public function transposeConst(output:Mat22):Mat22
	{
		output.m11 = m11; output.m12 = m21;
		output.m21 = m12; output.m22 = m22;
		return output;
	}
	
	/**
		R = M*D
	**/
	inline public function timesDiagonal(rhs:Vec2):Mat22
	{
		//|m11 m12| |x 0|
		//|m21 m22| |0 y|
		var x = rhs.x;
		var y = rhs.y;
		m11 = m11 * x; m12 = m12 * y;
		m21 = m21 * x; m22 = m22 * y;
		return this;
	}
	
	/**
		R = M*DStores the result in `output`.
	**/
	inline public function timesDiagonalConst(rhs:Vec2, output:Mat22):Mat22
	{
		//|m11 m12| |x 0|
		//|m21 m22| |0 y|
		var x = rhs.x;
		var y = rhs.y;
		output.m11 = m11 * x; output.m12 = m12 * y;
		output.m21 = m21 * x; output.m22 = m22 * y;
		return output;
	}
	
	/**
		R = D*M
	**/
	inline public function diagonalTimes(lhs:Vec2):Mat22
	{
		//|x 0| |m11 m12|
		//|0 y| |m21 m22|
		var x = lhs.x;
		var y = lhs.y;
		m11 = x * m11; m12 = x * m12;
		m21 = y * m21; m22 = y * m22;
		return this;
	}
	
	/**
		Post-concatenates `lhs`: this = `lhs`*this.
	**/
	inline public function cat(lhs:Mat22):Mat22
	{
		var c11 = m11; var c12 = m12;
		var c21 = m21; var c22 = m22;
		var t1, t2;
		t1 = lhs.m11;
		t2 = lhs.m12;
		m11 = t1 * c11 + t2 * c21;
		m12 = t1 * c12 + t2 * c22;
		t1 = lhs.m21;
		t2 = lhs.m22;
		m21 = t1 * c11 + t2 * c21;
		m22 = t1 * c12 + t2 * c22;
		return this;
	}
	
	/**
		Pre-concatenates `rhs`: this = this*`rhs`.
	**/
	inline public function precat(rhs:Mat22):Mat22
	{
		var c11 = rhs.m11; var c12 = rhs.m12;
		var c21 = rhs.m21; var c22 = rhs.m22;
		var t1, t2;
		t1 = m11;
		t2 = m12;
		m11 = t1 * c11 + t2 * c21;
		m12 = t1 * c12 + t2 * c22;
		t1 = m21;
		t2 = m22;
		m21 = t1 * c11 + t2 * c21;
		m22 = t1 * c12 + t2 * c22;
		return this;
	}
	
	/**
		Inverts and returns this matrix.
		@throws de.polygonal.core.util.AssertError singular matrix (debug only).
	**/
	public function inverse():Mat22
	{
		var det = m11 * m22 - m12 * m21;
		assert(!M.cmpZero(det, M.ZERO_TOLERANCE), "singular matrix");
		var invDet = 1 / det;
		var t = m11;
		m11 =  m22 * invDet;
		m12 = -m12 * invDet;
		m21 = -m21 * invDet;
		m22 =  t * invDet;
		return this;
	}
	
	/**
		Computes the matrix inverse and stores the result in `output`.
		This matrix is left unchanged.
		@return a reference to `output`.
		@throws de.polygonal.core.util.AssertError singular matrix (debug only).
	**/
	public function inverseConst(output:Mat22):Mat22
	{
		var det = m11 * m22 - m12 * m21;
		assert(!M.cmpZero(det, M.ZERO_TOLERANCE), "singular matrix");
		var invDet = 1 / det;
		output.m11 =  m22 * invDet;
		output.m12 = -m12 * invDet;
		output.m21 = -m21 * invDet;
		output.m22 =  m11 * invDet;
		return output;
	}
	
	/**
		Applies Gram-Schmidt orthogonalization to this matrix.
		Restores the matrix to a rotation to fight the accumulation of round-off errors due to frequent concatenation with other matrices.
		*The matrix must be a rotation matrix*.
	**/
	public function orthonormalize():Mat22
	{
		var t = Math.sqrt(m11 * m11 + m21 * m21);
		m11 /= t;
		m21 /= t;
		t = m11 * m12 + m21 * m22;
		m12 -= t * m11;
		m22 -= t * m21;
		t = Math.sqrt(m12 * m12 + m22 * m22);
		m12 /= t;
		m22 /= t;
		return this;
	}
	
	/**
		Returns the max-column-sum matrix norm.
	**/
	public function norm():Float
	{
		var colSum1 = M.fabs(m11) + M.fabs(m21);
		var colSum2 = M.fabs(m12) + M.fabs(m22);
		return M.fmax(colSum1, colSum2);
	}
	
	/**
		Divides all matrix elements by the scalar `x`.
	**/
	inline public function div(x:Float)
	{
		if (M.cmpZero(x, M.ZERO_TOLERANCE))
		{
			m11 = Limits.DOUBLE_MAX; m12 = Limits.DOUBLE_MAX;
			m21 = Limits.DOUBLE_MAX; m22 = Limits.DOUBLE_MAX;
		}
		else
		{
			var fInvScalar = 1 / x;
			m11 *= fInvScalar; m12 *= fInvScalar;
			m21 *= fInvScalar; m22 *= fInvScalar;
		}
	}
	
	public function clone():Mat22
	{
		var c = new Mat22();
		c.m11 = m11; c.m12 = m12;
		c.m21 = m21; c.m22 = m22;
		return c;
	}
	
	/**
		Returns the string form of the value that the object represents.
	**/
	public function toString():String
	{
		return Printf.format("Mat22:\n" +
			"[%-+10.4f %-+10.4f]\n" +
			"[%-+10.4f %-+10.4f]", [m11, m21, m12, m22]);
	}
}