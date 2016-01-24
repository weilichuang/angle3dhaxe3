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

import de.polygonal.core.util.Assert.assert;
import de.polygonal.core.math.Mathematics.M;
import de.polygonal.core.util.Assert.assert;

/**
	A 4x4 matrix.
	
	Matrix operations are applied on the left.
	
	E.g. given a matrix __M__ and vector __V__, matrix times vector is __MV__, where __V__ is treated as a column vector.
**/
class Mat44
{
	/**
		Matrix multiplication: `output` = `a``b`.
		
		- `a` and `output` can refer to the same object in memory.
	**/
	public static function matrixProduct(a:Mat44, b:Mat44, output:Mat44):Mat44
	{
		var b11 = b.m11; var b12 = b.m12; var b13 = b.m13; var b14 = b.m14;
		var b21 = b.m21; var b22 = b.m22; var b23 = b.m23; var b24 = b.m24;
		var b31 = b.m31; var b32 = b.m32; var b33 = b.m33; var b34 = b.m34;
		var b41 = b.m41; var b42 = b.m42; var b43 = b.m43; var b44 = b.m44;
		var t1, t2, t3, t4;
		t1 = a.m11;
		t2 = a.m12;
		t3 = a.m13;
		t4 = a.m14;
		output.m11 = t1 * b11 + t2 * b21 + t3 * b31 + t4 * b41;
		output.m12 = t1 * b12 + t2 * b22 + t3 * b32 + t4 * b42;
		output.m13 = t1 * b13 + t2 * b23 + t3 * b33 + t4 * b43;
		output.m14 = t1 * b14 + t2 * b24 + t3 * b34 + t4 * b44;
		t1 = a.m21;
		t2 = a.m22;
		t3 = a.m23;
		t4 = a.m24;
		output.m21 = t1 * b11 + t2 * b21 + t3 * b31 + t4 * b41;
		output.m22 = t1 * b12 + t2 * b22 + t3 * b32 + t4 * b42;
		output.m23 = t1 * b13 + t2 * b23 + t3 * b33 + t4 * b43;
		output.m24 = t1 * b14 + t2 * b24 + t3 * b34 + t4 * b44;
		t1 = a.m31;
		t2 = a.m32;
		t3 = a.m33;
		t4 = a.m34;
		output.m31 = t1 * b11 + t2 * b21 + t3 * b31 + t4 * b41;
		output.m32 = t1 * b12 + t2 * b22 + t3 * b32 + t4 * b42;
		output.m33 = t1 * b13 + t2 * b23 + t3 * b33 + t4 * b43;
		output.m34 = t1 * b14 + t2 * b24 + t3 * b34 + t4 * b44;
		t1 = a.m41;
		t2 = a.m42;
		t3 = a.m43;
		t4 = a.m44;
		output.m41 = t1 * b11 + t2 * b21 + t3 * b31 + t4 * b41;
		output.m42 = t1 * b12 + t2 * b22 + t3 * b32 + t4 * b42;
		output.m43 = t1 * b13 + t2 * b23 + t3 * b33 + t4 * b43;
		output.m44 = t1 * b14 + t2 * b24 + t3 * b34 + t4 * b44;
		return output;
	}
	
	/**
		Matrix multiplication for two **affine transformations**: `output` = `a``b`.
		
		- since (m41,m42,m43,m44) is always (0,0,0,1) for an affine transformation the 4th row is left untouched for `a` and `b`.
		- `a` and `output` can refer to the same object in memory.
	**/
	public static function affineMatrixProduct(a:Mat44, b:Mat44, output:Mat44):Mat44
	{
		var b11 = b.m11; var b12 = b.m12; var b13 = b.m13; var b14 = b.m14;
		var b21 = b.m21; var b22 = b.m22; var b23 = b.m23; var b24 = b.m24;
		var b31 = b.m31; var b32 = b.m32; var b33 = b.m33; var b34 = b.m34;
		var t1, t2, t3;
		t1 = a.m11;
		t2 = a.m12;
		t3 = a.m13;
		output.m11 = t1 * b11 + t2 * b21 + t3 * b31;
		output.m12 = t1 * b12 + t2 * b22 + t3 * b32;
		output.m13 = t1 * b13 + t2 * b23 + t3 * b33;
		output.m14 = t1 * b14 + t2 * b24 + t3 * b34 + a.m14;
		t1 = a.m21;
		t2 = a.m22;
		t3 = a.m23;
		output.m21 = t1 * b11 + t2 * b21 + t3 * b31;
		output.m22 = t1 * b12 + t2 * b22 + t3 * b32;
		output.m23 = t1 * b13 + t2 * b23 + t3 * b33;
		output.m24 = t1 * b14 + t2 * b24 + t3 * b34 + a.m24;
		t1 = a.m31;
		t2 = a.m32;
		t3 = a.m33;
		output.m31 = t1 * b11 + t2 * b21 + t3 * b31;
		output.m32 = t1 * b12 + t2 * b22 + t3 * b32;
		output.m33 = t1 * b13 + t2 * b23 + t3 * b33;
		output.m34 = t1 * b14 + t2 * b24 + t3 * b34 + a.m34;
		return output;
	}
	
	/**
		Matrix multiplication for two **2d affine transformations**: `output` = `a``b`
		
		- (m41,m42,m43,m44) is always (0,0,0,1)
		- (m13,m23,m33) is always (0,0,1)
		- `a` and `output` can refer to the same object in memory.
	**/
	inline public static function affineMatrixProduct2d(a:Mat44, b:Mat44, output:Mat44):Mat44
	{
		assert(a.m41 == 0 && a.m42 == 0 && a.m43 == 0 && a.m44 == 1);
		assert(b.m41 == 0 && b.m42 == 0 && b.m43 == 0 && b.m44 == 1);
		assert(a.m31 == 0 && a.m32 == 0 && a.m33 == 1 && a.tz == 0);
		assert(b.m31 == 0 && b.m32 == 0 && b.m33 == 1 && b.tz == 0);
		assert(a != b);
		
		var b11 = b.m11; var b12 = b.m12; var b14 = b.m14;
		var b21 = b.m21; var b22 = b.m22; var b24 = b.m24;
		var t1, t2;
		
		t1 = a.m11;
		t2 = a.m12;
		output.m11 = t1 * b11 + t2 * b21;
		output.m12 = t1 * b12 + t2 * b22;
		output.m14 = t1 * b14 + t2 * b24 + a.m14;
		
		t1 = a.m21;
		t2 = a.m22;
		output.m21 = t1 * b11 + t2 * b21;
		output.m22 = t1 * b12 + t2 * b22;
		output.m24 = t1 * b14 + t2 * b24 + a.m24;
		
		return output;
	}
	
	/**
		`output` = `m``s`, where `s` represents a scaling matrix.
		
		- `m` and `output` can refer to the same object in memory.
	**/
	inline public static function catMatrixAndScale(m:Mat44, s:Mat44, output:Mat44):Mat44
	{
		var t;
		t = s.m11;
		output.m11 = m.m11 * t;
		output.m21 = m.m21 * t;
		output.m31 = m.m31 * t;
		output.m41 = m.m41 * t;
		t = s.m22;
		output.m12 = m.m12 * t;
		output.m22 = m.m22 * t;
		output.m32 = m.m32 * t;
		output.m42 = m.m42 * t;
		t = s.m33;
		output.m13 = m.m13 * t;
		output.m23 = m.m23 * t;
		output.m33 = m.m33 * t;
		output.m43 = m.m43 * t;
		t = s.m44;
		output.m14 = m.m14 * t;
		output.m24 = m.m24 * t;
		output.m34 = m.m34 * t;
		output.m44 = m.m44 * t;
		return output;
	}
	
	/**
		`output` = `s``m`, where `s` represents a scaling matrix.
		
		- `m` and `output` can refer to the same object in memory.
	**/
	inline public static function catScaleAndMatrix(s:Mat44, m:Mat44, output:Mat44):Mat44
	{
		var t;
		t = s.m11;
		output.m11 = t * m.m11;
		output.m12 = t * m.m12;
		output.m13 = t * m.m13;
		output.m14 = t * m.m14;
		t = s.m22;
		output.m21 = t * m.m21;
		output.m22 = t * m.m22;
		output.m23 = t * m.m23;
		output.m24 = t * m.m24;
		t = s.m33;
		output.m31 = t * m.m31;
		output.m32 = t * m.m32;
		output.m33 = t * m.m33;
		output.m34 = t * m.m34;
		t = s.m44;
		output.m41 = t * m.m41;
		output.m42 = t * m.m42;
		output.m43 = t * m.m43;
		output.m44 = t * m.m44;
		return output;
	}
	
	public var m11:Float; public var m12:Float; public var m13:Float; public var m14:Float;
	public var m21:Float; public var m22:Float; public var m23:Float; public var m24:Float;
	public var m31:Float; public var m32:Float; public var m33:Float; public var m34:Float;
	public var m41:Float; public var m42:Float; public var m43:Float; public var m44:Float;
	
	public var sx(get_sx, set_sx):Float;
	inline function get_sx():Float
	{
		return m11;
	}
	inline function set_sx(value:Float):Float
	{
		return m11 = value;
	}
	
	public var sy(get_sy, set_sy):Float;
	inline function get_sy():Float
	{
		return m22;
	}
	inline function set_sy(value:Float):Float
	{
		return m22 = value;
	}
	
	public var sz(get_sz, set_sz):Float;
	inline function get_sz():Float
	{
		return m33;
	}
	inline function set_sz(value:Float):Float
	{
		return m33 = value;
	}
	
	public var tx(get_tx, set_tx):Float;
	inline function get_tx():Float
	{
		return m14;
	}
	inline function set_tx(value:Float):Float
	{
		return m14 = value;
	}
	
	public var ty(get_ty, set_ty):Float;
	inline function get_ty():Float
	{
		return m24;
	}
	inline function set_ty(value:Float):Float
	{
		return m24 = value;
	}
	
	public var tz(get_tz, set_tz):Float;
	inline function get_tz():Float
	{
		return m34;
	}
	inline function set_tz(value:Float):Float
	{
		return m34 = value;
	}
	
	/**
		Creates a 4x4 identity matrix.
	**/
	public function new()
	{
		setAsIdentity();
	}

	/**
		Copies the values of `other` to this.
	**/
	inline public function of(other:Mat44):Mat44
	{
		m11 = other.m11; m12 = other.m12; m13 = other.m13; m14 = other.m14;
		m21 = other.m21; m22 = other.m22; m23 = other.m23; m24 = other.m24;
		m31 = other.m31; m32 = other.m32; m33 = other.m33; m34 = other.m34;
		m41 = other.m41; m42 = other.m42; m43 = other.m43; m44 = other.m44;
		return this;
	}
	
	/**
		Set to identity matrix.
	**/
	public function setAsIdentity():Mat44
	{
		m11 = 1; m12 = 0; m13 = 0; m14 = 0;
		m21 = 0; m22 = 1; m23 = 0; m24 = 0;
		m31 = 0; m32 = 0; m33 = 1; m34 = 0;
		m41 = 0; m42 = 0; m43 = 0; m44 = 1;
		return this;
	}
	
	/**
		Set as scaling matrix, scaling by `x`, `y`, `z`.
	**/
	public function setAsScale(x:Float, y:Float, z:Float):Mat44
	{
		m11 = x; m12 = 0; m13 = 0; m14 = 0;
		m21 = 0; m22 = y; m23 = 0; m24 = 0;
		m31 = 0; m32 = 0; m33 = z; m34 = 0;
		m41 = 0; m42 = 0; m43 = 0; m44 = 1;
		return this;
	}
	
	/**
		Set as translation matrix, translating by `x`, `y`, `z`.
	**/
	public function setAsTranslate(x:Float, y:Float, z:Float):Mat44
	{
		m11 = 1; m12 = 0; m13 = 0; m14 = x;
		m21 = 0; m22 = 1; m23 = 0; m24 = y;
		m31 = 0; m32 = 0; m33 = 1; m34 = z;
		m41 = 0; m42 = 0; m43 = 0; m44 = 1;
		return this;
	}
	
	/**
		Set as rotation matrix, rotating by `angle` radians around the x-axis.
		
		The (x,y,z) coordinate system is assumed to be right-handed, so `angle` > 0 indicates a CCW rotation in the yz-plane.
	**/
	public function setAsRotateX(angle:Float):Mat44
	{
		var s = Math.sin(angle);
		var c = Math.cos(angle);
		m11 = 1; m12 = 0; m13 = 0; m14 = 0;
		m21 = 0; m22 = c; m23 =-s; m24 = 0;
		m31 = 0; m32 = s; m33 = c; m34 = 0;
		m41 = 0; m42 = 0; m43 = 0; m44 = 1;
		return this;
	}
	
	/**
		Set as rotation matrix, rotating by `angle` radians around y-axis.
		
		The (x,y,z) coordinate system is assumed to be right-handed, so angle > 0 indicates a CCW rotation in the zx-plane.
	**/
	public function setAsRotateY(angle:Float):Mat44
	{
		var s = Math.sin(angle);
		var c = Math.cos(angle);
		m11 = c; m12 = 0; m13 = s; m14 = 0;
		m21 = 0; m22 = 1; m23 = 0; m24 = 0;
		m31 =-s; m32 = 0; m33 = c; m34 = 0;
		m41 = 0; m42 = 0; m43 = 0; m44 = 1;
		return this;
	}
	
	/**
		Set as rotation matrix, rotating by `angle` radians around z-axis.
		
		The (x,y,z) coordinate system is assumed to be right-handed, so `angle` > 0 indicates a CCW rotation in the xy-plane.
	**/
	public function setAsRotateZ(angle:Float):Mat44
	{
		var s = Math.sin(angle);
		var c = Math.cos(angle);
		m11 = c; m12 =-s; m13 = 0; m14 = 0;
		m21 = s; m22 = c; m23 = 0; m24 = 0;
		m31 = 0; m32 = 0; m33 = 1; m34 = 0;
		m41 = 0; m42 = 0; m43 = 0; m44 = 1;
		return this;
	}
	
	/**
		Sets the matrix to a rotation matrix by euler angles.
	**/
	public function setAsRotationEulerAngles(zAngle:Float, yAngle:Float, xAngle:Float)
	{
		var sx = Math.sin(xAngle);
		var cx = Math.cos(xAngle);
		var sy = Math.sin(yAngle);
		var cy = Math.cos(yAngle);
		var sz = Math.sin(zAngle);
		var cz = Math.cos(zAngle);
		
		m11 = (cy * cz);
		m12 =-(cy * sz);
		m13 = sy;
		m14 = 0;
		m21 =  (sx * sy * cz) + (cx * sz);
		m22 = -(sx * sy * sz) + (cx * cz);
		m23 = -(sx * cy);
		m24 = 0;
		m31 = -(cx * sy * cz) + (sx * sz);
		m32 =  (cx * sy * sz) + (sx * cz);
		m33 =  (cx * cy);
		m34 = 0;
		m41 = 0;
		m42 = 0;
		m43 = 0;
		m44 = 1;
		return this;
	}
	
	/**
		__RM__, where __R__ is a rotation matrix rotating by `angle` radians around the x-axis, 
	**/
	public function catRotateX(angle:Float):Mat44
	{
		var s = Math.sin(angle);
		var c = Math.cos(angle);
		var t = m21;
		var u = m31;
		m21 = c * t - s * u;
		m31 = s * t + c * u;
		m41 = u;
		t = m22;
		u = m32;
		m22 = c * t - s * u;
		m32 = s * t + c * u;
		m42 = u;
		t = m23;
		u = m33;
		m23 = c * t - s * u;
		m33 = s * t + c * u;
		m43 = u;
		t = m24;
		u = m34;
		m24 = c * t - s * u;
		m34 = s * t + c * u;
		return this;
	}
	
	/**
		__MR__, where __R__ is a rotation matrix rotating by `angle` radians around the x-axis, 
	**/
	public function precatRotateX(angle:Float):Mat44
	{
		var s = Math.sin(angle);
		var c = Math.cos(angle);
		var t = m12, u = m13;
		m12 = t * c + u * s;
		m13 = t *-s + u * c;
		t = m22;
		u = m23;
		m22 = t * c + u * s;
		m23 = t *-s + u * c;
		t = m32;
		u = m33;
		m32 = t * c + u * s;
		m33 = t *-s + u * c;
		m42 = t * c + u * s;
		m43 = t *-s + u * c;
		return this;
	}
	
	/**
		__RM__, where __R__ is a rotation matrix rotating by `angle` radians around the y-axis, 
	**/
	public function catRotateY(angle:Float):Mat44
	{
		var s = Math.sin(angle);
		var c = Math.cos(angle);
		var t = m11;
		var u = m31;
		m11 = c * t + s * u;
		m31 =-s * t + c * u;
		m41 = u;
		t = m12;
		u = m32;
		m12 = c * t + s * u;
		m32 =-s * t + c * u;
		m42 = u;
		t = m13;
		u = m33;
		m13 = c * t + s * u;
		m33 =-s * t + c * u;
		m43 = u;
		t = m14;
		u = m34;
		m14 = c * t + s * u;
		m34 =-s * t + c * u;
		return this;
	}
	
	/**
		__MR__, where __R__ is a rotation matrix rotating by `angle` radians around the y-axis, 
	**/
	public function precatRotateY(angle:Float):Mat44
	{
		var s = Math.sin(angle);
		var c = Math.cos(angle);
		var t = m11;
		var u = m13;
		m11 = t * c + u *-s;
		m13 = t * s + u * c;
		var t = m21;
		var u = m23;
		m21 = t * c + u *-s;
		m23 = t * s + u * c;
		var t = m31;
		var u = m33;
		m31 = t * c + u *-s;
		m33 = t * s + u * c;
		m41 = t * c + u *-s;
		m43 = t * s + u * c;
		return this;
	}
	
	/**
		__RM__, where __R__ is a rotation matrix rotating by `angle` radians around the z-axis, 
	**/
	public function catRotateZ(angle:Float)
	{
		/*
		|cosΦ -sinΦ 0 0| |m11 m12 m13 tx|
		|sinΦ  cosΦ 0 0| |m21 m22 m23 ty|
		|0        0 1 0| |m31 m32 m33 tz|
		|0        0 0 1| |  0   0   0  1|
		*/
		var s = Math.sin(angle);
		var c = Math.cos(angle);
		
		var u = m11;
		var v = m21;
		m11 = (c * u) - (s * v);
		m21 = (s * u) + (c * v);
		
		u = m12;
		v = m22;
		m12 = (c * u) - (s * v);
		m22 = (s * u) + (c * v);
		
		u = m13;
		v = m23;
		m13 = (c * u) - (s * v);
		m23 = (s * u) + (c * v);
		
		u = m14;
		v = m24;
		m14 = (c * u) - (s * v);
		m24 = (s * u) + (c * v);
	}
	
	/**
		__MR__, where __R__ is a rotation matrix rotating by `angle` radians around the z-axis, 
	**/
	public function precatRotateZ(angle:Float):Mat44
	{
		/*
		|cosΦ -sinΦ 0 0| |m11 m12 m13 tx|
		|sinΦ  cosΦ 0 0| |m21 m22 m23 ty|
		|0        0 1 0| |m31 m32 m33 tz|
		|0        0 0 1| |  0   0   0  1|
		*/
		
		var t11 = m11; var t12 = m12; var t13 = m13; var t14 = m14;
		var t21 = m21; var t22 = m22; var t23 = m23; var t24 = m24;
		var t31 = m31; var t32 = m32; var t33 = m33; var t34 = m34;
		var s = Math.sin(angle);
		var c = Math.cos(angle);
		m11 = t11 *   c + t12 * s;
		m12 = t11 *  -s + t12 * c;
		m14 = t11 * t14 + t12 * t24 + t13 * t34;
		m21 = t21 *   c + t22 * s;
		m22 = t21 *  -s + t22 * c;
		m24 = t21 * t14 + t22 * t24 + t23 * t34;
		m31 = t31 *   c + t32 * s;
		m32 = t31 *  -s + t32 * c;
		m34 = t31 * t14 + t32 * t24 + t33 * t34;
		return this;
	}
	
	/**
		Matrix multiplication: this = `lhs` · this.
	**/
	inline public function cat(lhs:Mat44):Mat44
	{
		var c11 = m11; var c12 = m12; var c13 = m13; var c14 = m14;
		var c21 = m21; var c22 = m22; var c23 = m23; var c24 = m24;
		var c31 = m31; var c32 = m32; var c33 = m33; var c34 = m34;
		var c41 = m41; var c42 = m42; var c43 = m43; var c44 = m44;
		var t1, t2, t3, t4;
		t1 = lhs.m11;
		t2 = lhs.m12;
		t3 = lhs.m13;
		t4 = lhs.m14;
		m11 = t1 * c11 + t2 * c21 + t3 * c31 + t4 * c41;
		m12 = t1 * c12 + t2 * c22 + t3 * c32 + t4 * c42;
		m13 = t1 * c13 + t2 * c23 + t3 * c33 + t4 * c43;
		m14 = t1 * c14 + t2 * c24 + t3 * c34 + t4 * c44;
		t1 = lhs.m21;
		t2 = lhs.m22;
		t3 = lhs.m23;
		t4 = lhs.m24;
		m21 = t1 * c11 + t2 * c21 + t3 * c31 + t4 * c41;
		m22 = t1 * c12 + t2 * c22 + t3 * c32 + t4 * c42;
		m23 = t1 * c13 + t2 * c23 + t3 * c33 + t4 * c43;
		m24 = t1 * c14 + t2 * c24 + t3 * c34 + t4 * c44;
		t1 = lhs.m31;
		t2 = lhs.m32;
		t3 = lhs.m33;
		t4 = lhs.m34;
		m31 = t1 * c11 + t2 * c21 + t3 * c31 + t4 * c41;
		m32 = t1 * c12 + t2 * c22 + t3 * c32 + t4 * c42;
		m33 = t1 * c13 + t2 * c23 + t3 * c33 + t4 * c43;
		m34 = t1 * c14 + t2 * c24 + t3 * c34 + t4 * c44;
		t1 = lhs.m41;
		t2 = lhs.m42;
		t3 = lhs.m43;
		t4 = lhs.m44;
		m41 = t1 * c11 + t2 * c21 + t3 * c31 + t4 * c41;
		m42 = t1 * c12 + t2 * c22 + t3 * c32 + t4 * c42;
		m43 = t1 * c13 + t2 * c23 + t3 * c33 + t4 * c43;
		m44 = t1 * c14 + t2 * c24 + t3 * c34 + t4 * c44;
		return this;
	}
	
	/**
		Matrix multiplication: this = this · `rhs`.
	**/
	inline public function precat(rhs:Mat44):Mat44
	{
		var c11 = rhs.m11; var c12 = rhs.m12; var c13 = rhs.m13; var c14 = rhs.m14;
		var c21 = rhs.m21; var c22 = rhs.m22; var c23 = rhs.m23; var c24 = rhs.m24;
		var c31 = rhs.m31; var c32 = rhs.m32; var c33 = rhs.m33; var c34 = rhs.m34;
		var c41 = rhs.m41; var c42 = rhs.m42; var c43 = rhs.m43; var c44 = rhs.m44;
		var t1, t2, t3, t4;
		t1 = m11;
		t2 = m12;
		t3 = m13;
		t4 = m14;
		m11 = t1 * c11 + t2 * c21 + t3 * c31 + t4 * c41;
		m12 = t1 * c12 + t2 * c22 + t3 * c32 + t4 * c42;
		m13 = t1 * c13 + t2 * c23 + t3 * c33 + t4 * c43;
		m14 = t1 * c14 + t2 * c24 + t3 * c34 + t4 * c44;
		t1 = m21;
		t2 = m22;
		t3 = m23;
		t4 = m24;
		m21 = t1 * c11 + t2 * c21 + t3 * c31 + t4 * c41;
		m22 = t1 * c12 + t2 * c22 + t3 * c32 + t4 * c42;
		m23 = t1 * c13 + t2 * c23 + t3 * c33 + t4 * c43;
		m24 = t1 * c14 + t2 * c24 + t3 * c34 + t4 * c44;
		t1 = m31;
		t2 = m32;
		t3 = m33;
		t4 = m34;
		m31 = t1 * c11 + t2 * c21 + t3 * c31 + t4 * c41;
		m32 = t1 * c12 + t2 * c22 + t3 * c32 + t4 * c42;
		m33 = t1 * c13 + t2 * c23 + t3 * c33 + t4 * c43;
		m34 = t1 * c14 + t2 * c24 + t3 * c34 + t4 * c44;
		t1 = m41;
		t2 = m42;
		t3 = m43;
		t4 = m44;
		m41 = t1 * c11 + t2 * c21 + t3 * c31 + t4 * c41;
		m42 = t1 * c12 + t2 * c22 + t3 * c32 + t4 * c42;
		m43 = t1 * c13 + t2 * c23 + t3 * c33 + t4 * c43;
		m44 = t1 * c14 + t2 * c24 + t3 * c34 + t4 * c44;
		return this;
	}
	
	/**
		__SM__, where __S__ is a scaling matrix, scaling by `x`, `y`, `z`.
	**/
	inline public function catScale(x:Float, y:Float, z:Float)
	{
		/*
		|x 0 0 0| |m11 m12 m13 tx|
		|0 y 0 0| |m21 m22 m23 ty|
		|0 0 z 0| |m31 m32 m33 tz|
		*/
		m11 *= x;
		m12 *= x;
		m13 *= x;
		m14 *= x;
		
		m21 *= y;
		m22 *= y;
		m23 *= y;
		m24 *= y;
		
		m31 *= z;
		m32 *= z;
		m33 *= z;
		m34 *= z;
	}
	
	/**
		__MS__, where __S__ is a scaling matrix, scaling by `x`, `y`, `z`.
	**/
	inline public function precatScale(x:Float, y:Float, z:Float)
	{
		/*
		|m11 m12 m13 tx| |x 0 0 0|
		|m21 m22 m23 ty| |0 y 0 0|
		|m31 m32 m33 tz| |0 0 z 0|
		|  0   0   0  1| |0 0 0 1|
		*/
		m11 *= x;
		m12 *= y;
		m13 *= z;
		
		m21 *= x;
		m22 *= y;
		m23 *= z;
		
		m31 *= x;
		m32 *= y;
		m33 *= z;
	}
	
	/**
		__TM__, where __T__ is a translation matrix, translating by `x`, `y`, `z`.
	**/
	inline public function catTranslate(tx:Float, ty:Float, tz:Float):Mat44
	{
		/*
		|1 0 0 tx| |m11 m12 m13 m14|
		|0 1 0 ty| |m21 m22 m23 m24|
		|0 0 1 tz| |m31 m32 m33 m34|
		|0 0 0  1| |  0   0   0   1|
		*/
		m14 += tx;
		m24 += ty;
		m34 += tz;
		return this;
	}
	
	/**
		__MT__, where __T__ is a translation matrix, translating by `x`, `y`, `z`.
	**/
	inline public function precatTranslate(tx:Float, ty:Float, tz:Float):Mat44
	{
		/*
		|m11 m12 m13 m14| |1 0 0 tx|
		|m21 m22 m23 m24| |0 1 0 ty|
		|m31 m32 m33 m34| |0 0 1 tz|
		|  0   0   0   1| |0 0 0 t1|
		*/
		m14 = m11 * tx + m12 * ty + m13 * tz + m14;
		m24 = m21 * tx + m22 * ty + m23 * tz + m24;
		m34 = m31 * tx + m32 * ty + m33 * tz + m34;
		return this;
	}
	
	/**
		Matrix multiplication: this = this · `rhs`.
	**/
	public function timesMatrix(rhs:Mat44)
	{
		var b11 = rhs.m11; var b12 = rhs.m12; var b13 = rhs.m13; var b14 = rhs.m14;
		var b21 = rhs.m21; var b22 = rhs.m22; var b23 = rhs.m23; var b24 = rhs.m24;
		var b31 = rhs.m31; var b32 = rhs.m32; var b33 = rhs.m33; var b34 = rhs.m34;
		var b41 = rhs.m41; var b42 = rhs.m42; var b43 = rhs.m43; var b44 = rhs.m44;
		var t1 = m11;
		var t2 = m12;
		var t3 = m13;
		var t4 = m14;
		m11 = t1 * b11 + t2 * b21 + t3 * b31 + t4 * b41;
		m12 = t1 * b12 + t2 * b22 + t3 * b32 + t4 * b42;
		m13 = t1 * b13 + t2 * b23 + t3 * b33 + t4 * b43;
		m14 = t1 * b14 + t2 * b24 + t3 * b34 + t4 * b44;
		t1 = m21;
		t2 = m22;
		t3 = m23;
		t4 = m24;
		m21 = t1 * b11 + t2 * b21 + t3 * b31 + t4 * b41;
		m22 = t1 * b12 + t2 * b22 + t3 * b32 + t4 * b42;
		m23 = t1 * b13 + t2 * b23 + t3 * b33 + t4 * b43;
		m24 = t1 * b14 + t2 * b24 + t3 * b34 + t4 * b44;
		t1 = m31;
		t2 = m32;
		t3 = m33;
		t4 = m34;
		m31 = t1 * b11 + t2 * b21 + t3 * b31 + t4 * b41;
		m32 = t1 * b12 + t2 * b22 + t3 * b32 + t4 * b42;
		m33 = t1 * b13 + t2 * b23 + t3 * b33 + t4 * b43;
		m34 = t1 * b14 + t2 * b24 + t3 * b34 + t4 * b44;
		t1 = m41;
		t2 = m42;
		t3 = m43;
		t4 = m44;
		m41 = t1 * b11 + t2 * b21 + t3 * b31 + t4 * b41;
		m42 = t1 * b12 + t2 * b22 + t3 * b32 + t4 * b42;
		m43 = t1 * b13 + t2 * b23 + t3 * b33 + t4 * b43;
		m44 = t1 * b14 + t2 * b24 + t3 * b34 + t4 * b44;
	}
	
	/**
		Matrix - column vector multiplication: `rhs` = this · `rhs`.
	**/
	inline public function timesVector(rhs:Vec3):Vec3
	{
		var x = rhs.x;
		var y = rhs.y;
		var z = rhs.z;
		var w = rhs.w;
		rhs.x = m11 * x + m12 * y + m13 * z + m14 * w;
		rhs.y = m21 * x + m22 * y + m23 * z + m24 * w;
		rhs.z = m31 * x + m32 * y + m33 * z + m34 * w;
		rhs.w = m41 * x + m42 * y + m43 * z + m44 * w;
		return rhs;
	}
	
	/**
		Matrix - column vector multiplication: `output` = this · `rhs`.
	**/
	inline public function timesVectorConst(rhs:Vec3, output:Vec3):Vec3
	{
		var x = rhs.x;
		var y = rhs.y;
		var z = rhs.z;
		var w = rhs.w;
		output.x = m11 * x + m12 * y + m13 * z + m14 * w;
		output.y = m21 * x + m22 * y + m23 * z + m24 * w;
		output.z = m31 * x + m32 * y + m33 * z + m34 * w;
		output.w = m41 * x + m42 * y + m43 * z + m44 * w;
		return output;
	}
	
	/**
		Matrix - column vector multiplication: `output` = this · `rhs`.
		
		The method treats this matrix as an __affine transformation matrix__ and `rhs` as an __2d vector__.
	**/
	inline public function timesVectorAffine2d(rhs:Vec3):Vec3
	{
		var x = rhs.x;
		var y = rhs.y;
		rhs.x = m11 * x + m12 * y;
		rhs.y = m21 * x + m22 * y;
		return rhs;
	}
	
	/**
		Transposes this matrix.
	**/
	inline public function transpose():Mat44
	{
		var t;
		t = m21; m21 = m12; m12 = t;
		t = m31; m31 = m13; m13 = t;
		t = m32; m32 = m23; m23 = t;
		t = m41; m41 = m14; m14 = t;
		t = m42; m42 = m24; m24 = t;
		t = m43; m43 = m34; m34 = t;
		return this;
	}
	
	/**
		Inverts and returns this matrix.
	**/
	public function inverse():Mat44
	{
		var a0 = m11 * m22 - m12 * m21;
		var a1 = m11 * m23 - m13 * m21;
		var a2 = m11 * m24 - m14 * m21;
		var a3 = m12 * m23 - m13 * m22;
		var a4 = m12 * m24 - m14 * m22;
		var a5 = m13 * m24 - m14 * m23;
		var b0 = m31 * m42 - m32 * m41;
		var b1 = m31 * m43 - m33 * m41;
		var b2 = m31 * m44 - m34 * m41;
		var b3 = m32 * m43 - m33 * m42;
		var b4 = m32 * m44 - m34 * m42;
		var b5 = m33 * m44 - m34 * m43;
		var det = a0 * b5 - a1 * b4 + a2 * b3 + a3 * b2 - a4 * b1 + a5 * b0;
		assert(!M.cmpZero(det, M.ZERO_TOLERANCE), "singular matrix");
		var invDet = 1 / det;
		var t11 = ( m22 * b5 - m23 * b4 + m24 * b3) * invDet;
		var t21 = (-m21 * b5 + m23 * b2 - m24 * b1) * invDet;
		var t31 = ( m21 * b4 - m22 * b2 + m24 * b0) * invDet;
		var t41 = (-m21 * b3 + m22 * b1 - m23 * b0) * invDet;
		var t12 = (-m12 * b5 + m13 * b4 - m14 * b3) * invDet;
		var t22 = ( m11 * b5 - m13 * b2 + m14 * b1) * invDet;
		var t32 = (-m11 * b4 + m12 * b2 - m14 * b0) * invDet;
		var t42 = ( m11 * b3 - m12 * b1 + m13 * b0) * invDet;
		var t13 = ( m42 * a5 - m43 * a4 + m44 * a3) * invDet;
		var t23 = (-m41 * a5 + m43 * a2 - m44 * a1) * invDet;
		var t33 = ( m41 * a4 - m42 * a2 + m44 * a0) * invDet;
		var t43 = (-m41 * a3 + m42 * a1 - m43 * a0) * invDet;
		var t14 = (-m32 * a5 + m33 * a4 - m34 * a3) * invDet;
		var t24 = ( m31 * a5 - m33 * a2 + m34 * a1) * invDet;
		var t34 = (-m31 * a4 + m32 * a2 - m34 * a0) * invDet;
		var t44 = ( m31 * a3 - m32 * a1 + m33 * a0) * invDet;
		m11 = t11; m12 = t12; m13 = t13; m14 = t14;
		m21 = t21; m22 = t22; m23 = t23; m24 = t24;
		m31 = t31; m32 = t32; m33 = t33; m34 = t34;
		m41 = t41; m42 = t42; m43 = t43; m44 = t44;
		return this;
	}
	
	/**
		Computes the matrix inverse and stores the result in `output`.
	**/
	public function inverseConst(output:Mat44):Mat44
	{
		var a0 = m11 * m22 - m12 * m21;
		var a1 = m11 * m23 - m13 * m21;
		var a2 = m11 * m24 - m14 * m21;
		var a3 = m12 * m23 - m13 * m22;
		var a4 = m12 * m24 - m14 * m22;
		var a5 = m13 * m24 - m14 * m23;
		var b0 = m31 * m42 - m32 * m41;
		var b1 = m31 * m43 - m33 * m41;
		var b2 = m31 * m44 - m34 * m41;
		var b3 = m32 * m43 - m33 * m42;
		var b4 = m32 * m44 - m34 * m42;
		var b5 = m33 * m44 - m34 * m43;
		var det = a0 * b5 - a1 * b4 + a2 * b3 + a3 * b2 - a4 * b1 + a5 * b0;
		assert(!M.cmpZero(det, M.ZERO_TOLERANCE), "singular matrix");
		var invDet = 1 / det;
		output.m11 = ( m22 * b5 - m23 * b4 + m24 * b3) * invDet;
		output.m21 = (-m21 * b5 + m23 * b2 - m24 * b1) * invDet;
		output.m31 = ( m21 * b4 - m22 * b2 + m24 * b0) * invDet;
		output.m41 = (-m21 * b3 + m22 * b1 - m23 * b0) * invDet;
		output.m12 = (-m12 * b5 + m13 * b4 - m14 * b3) * invDet;
		output.m22 = ( m11 * b5 - m13 * b2 + m14 * b1) * invDet;
		output.m32 = (-m11 * b4 + m12 * b2 - m14 * b0) * invDet;
		output.m42 = ( m11 * b3 - m12 * b1 + m13 * b0) * invDet;
		output.m13 = ( m42 * a5 - m43 * a4 + m44 * a3) * invDet;
		output.m23 = (-m41 * a5 + m43 * a2 - m44 * a1) * invDet;
		output.m33 = ( m41 * a4 - m42 * a2 + m44 * a0) * invDet;
		output.m43 = (-m41 * a3 + m42 * a1 - m43 * a0) * invDet;
		output.m14 = (-m32 * a5 + m33 * a4 - m34 * a3) * invDet;
		output.m24 = ( m31 * a5 - m33 * a2 + m34 * a1) * invDet;
		output.m34 = (-m31 * a4 + m32 * a2 - m34 * a0) * invDet;
		output.m44 = ( m31 * a3 - m32 * a1 + m33 * a0) * invDet;
		return output;
	}
	
	/**
		Copies all 16 matrix elements of the `input` array.
		
		if `columnMajor` is true, 4 consecutive vector elements are interpreted as colums of the matrix, otherwise as the rows of the matrix.
	**/
	public function ofArray(values:Array<Float>, columnMajor = false):Mat44
	{
		if (columnMajor)
		{
			m11 = values[ 0]; m12 = values[ 4]; m13 = values[ 8]; m14 = values[12];
			m21 = values[ 1]; m22 = values[ 5]; m23 = values[ 9]; m24 = values[13];
			m31 = values[ 2]; m32 = values[ 6]; m33 = values[10]; m34 = values[14];
			m41 = values[ 3]; m42 = values[ 7]; m43 = values[11]; m44 = values[15];
		}
		else
		{
			m11 = values[ 0]; m12 = values[ 1]; m13 = values[ 2]; m14 = values[ 3];
			m21 = values[ 4]; m22 = values[ 5]; m23 = values[ 6]; m24 = values[ 7];
			m31 = values[ 8]; m32 = values[ 9]; m33 = values[10]; m34 = values[11];
			m41 = values[12]; m42 = values[13]; m43 = values[14]; m44 = values[15];
		}
		return this;
	}
	
	/**
		Writes all 16 matrix elements to the `output` array.
		
		If `columnMajor` is true, elements will be stored in column-major format, otherwise in row-major format.
	**/
	public function toArray(output:Array<Float>, offset = -1, columnMajor = false):Array<Float>
	{
		if (offset == -1)
		{
			if (columnMajor)
			{
				output[ 0] = m11; output[ 4] = m12; output[ 8] = m13; output[12] = m14;
				output[ 1] = m21; output[ 5] = m22; output[ 9] = m23; output[13] = m24;
				output[ 2] = m31; output[ 6] = m32; output[10] = m33; output[14] = m34;
				output[ 3] = m41; output[ 7] = m42; output[11] = m43; output[15] = m44;
			}
			else
			{
				output[ 0] = m11; output[ 1] = m12; output[ 2] = m13; output[ 3] = m14;
				output[ 4] = m21; output[ 5] = m22; output[ 6] = m23; output[ 7] = m24;
				output[ 8] = m31; output[ 9] = m32; output[10] = m33; output[11] = m34;
				output[12] = m41; output[13] = m42; output[14] = m43; output[15] = m44;
			}
		}
		else
		{
			if (columnMajor)
			{
				output[offset + 0] = m11; output[offset + 4] = m12; output[offset +  8] = m13; output[offset + 12] = m14;
				output[offset + 1] = m21; output[offset + 5] = m22; output[offset +  9] = m23; output[offset + 13] = m24;
				output[offset + 2] = m31; output[offset + 6] = m32; output[offset + 10] = m33; output[offset + 14] = m34;
				output[offset + 3] = m41; output[offset + 7] = m42; output[offset + 11] = m43; output[offset + 15] = m44;
			}
			else
			{
				output[offset +  0] = m11; output[offset +  1] = m12; output[offset +  2] = m13; output[offset +  3] = m14;
				output[offset +  4] = m21; output[offset +  5] = m22; output[offset +  6] = m23; output[offset +  7] = m24;
				output[offset +  8] = m31; output[offset +  9] = m32; output[offset + 10] = m33; output[offset + 11] = m34;
				output[offset + 12] = m41; output[offset + 13] = m42; output[offset + 14] = m43; output[offset + 15] = m44;
			}
		}
		return output;
	}
	
	#if flash10
	var mScratchVector:flash.Vector<Float>;
	
	/**
		Writes all 16 matrix elements to the vector x.
		
		If `columnMajor` is true, elements will be stored in column-major format, otherwise in row-major format.
	**/
	public function toVector(x:flash.Vector<Float>, offset = -1, columnMajor = false):flash.Vector<Float>
	{
		if (offset == -1)
		{
			if (columnMajor)
			{
				x[ 0] = m11; x[ 4] = m12; x[ 8] = m13; x[12] = m14;
				x[ 1] = m21; x[ 5] = m22; x[ 9] = m23; x[13] = m24;
				x[ 2] = m31; x[ 6] = m32; x[10] = m33; x[14] = m34;
				x[ 3] = m41; x[ 7] = m42; x[11] = m43; x[15] = m44;
			}
			else
			{
				x[ 0] = m11; x[ 1] = m12; x[ 2] = m13; x[ 3] = m14;
				x[ 4] = m21; x[ 5] = m22; x[ 6] = m23; x[ 7] = m24;
				x[ 8] = m31; x[ 9] = m32; x[10] = m33; x[11] = m34;
				x[12] = m41; x[13] = m42; x[14] = m43; x[15] = m44;
			}
		}
		else
		{
			if (columnMajor)
			{
				x[offset + 0] = m11; x[offset + 4] = m12; x[offset +  8] = m13; x[offset + 12] = m14;
				x[offset + 1] = m21; x[offset + 5] = m22; x[offset +  9] = m23; x[offset + 13] = m24;
				x[offset + 2] = m31; x[offset + 6] = m32; x[offset + 10] = m33; x[offset + 14] = m34;
				x[offset + 3] = m41; x[offset + 7] = m42; x[offset + 11] = m43; x[offset + 15] = m44;
			}
			else
			{
				x[offset +  0] = m11; x[offset +  1] = m12; x[offset +  2] = m13; x[offset +  3] = m14;
				x[offset +  4] = m21; x[offset +  5] = m22; x[offset +  6] = m23; x[offset +  7] = m24;
				x[offset +  8] = m31; x[offset +  9] = m32; x[offset + 10] = m33; x[offset + 11] = m34;
				x[offset + 12] = m41; x[offset + 13] = m42; x[offset + 14] = m43; x[offset + 15] = m44;
			}
		}
		return x;
	}
	
	/**
		Copies all 16 matrix elements from this matrix to the given matrix x.
		If x is omitted, a new Matrix3D object is created on the fly.
	**/
	public function toMatrix3D(x:flash.geom.Matrix3D = null):flash.geom.Matrix3D
	{
		if (x == null) x = new flash.geom.Matrix3D();
		if (mScratchVector == null)
			mScratchVector = new flash.Vector<Float>(16, true);
		x.rawData = toVector(mScratchVector);
		return x;
	}
	
	/**
		Copies all 16 matrix elements from the given matrix x into this matrix.
		if x is omitted, a new Matrix3D object is created on the fly.
	**/
	public function ofMatrix3D(x:flash.geom.Matrix3D = null):Mat44
	{
		if (x == null) x = new flash.geom.Matrix3D();
		var t = x.rawData;
		m11 = t[ 0]; m12 = t[ 1]; m13 = t[ 2]; m14 = t[ 3];
		m21 = t[ 4]; m22 = t[ 5]; m23 = t[ 6]; m24 = t[ 7];
		m31 = t[ 8]; m32 = t[ 9]; m33 = t[10]; m34 = t[11];
		m41 = t[12]; m42 = t[13]; m43 = t[14]; m44 = t[15];
		return this;
	}
	
	/**
		Copies all 16 matrix elements from the vector x.
		
		If columnMajor is true, 4 consecutive vector elements are interpreted as colums of the matrix, otherwise as the rows of the matrix.
	**/
	public function ofVector(x:flash.Vector<Float>, columnMajor = false):Mat44
	{
		if (columnMajor)
		{
			m11 = x[ 0]; m12 = x[ 4]; m13 = x[ 8]; m14 = x[12];
			m21 = x[ 1]; m22 = x[ 5]; m23 = x[ 9]; m24 = x[13];
			m31 = x[ 2]; m32 = x[ 6]; m33 = x[10]; m34 = x[14];
			m41 = x[ 3]; m42 = x[ 7]; m43 = x[11]; m44 = x[15];
		}
		else
		{
			m11 = x[ 0]; m12 = x[ 1]; m13 = x[ 2]; m14 = x[ 3];
			m21 = x[ 4]; m22 = x[ 5]; m23 = x[ 6]; m24 = x[ 7];
			m31 = x[ 8]; m32 = x[ 9]; m33 = x[10]; m34 = x[11];
			m41 = x[12]; m42 = x[13]; m43 = x[14]; m44 = x[15];
		}
		return this;
	}
	#end
	
	public function clone():Mat44
	{
		var x = new Mat44();
		x.m11 = m11; x.m12 = m12; x.m13 = m13; x.m14 = m14;
		x.m21 = m21; x.m22 = m22; x.m23 = m23; x.m24 = m24;
		x.m31 = m31; x.m32 = m32; x.m33 = m33; x.m34 = m34;
		x.m41 = m41; x.m42 = m42; x.m43 = m43; x.m44 = m44;
		return x;
	}
	
	public function toString():String
	{
		var s = "{ Mat44\n";
		s += Printf.format("  %-+10.4f %-+10.4f %-+10.4f %-+10.4f\n", [m11, m12, m13, m14]);
		s += Printf.format("  %-+10.4f %-+10.4f %-+10.4f %-+10.4f\n", [m21, m22, m23, m24]);
		s += Printf.format("  %-+10.4f %-+10.4f %-+10.4f %-+10.4f\n", [m31, m32, m33, m34]);
		s += Printf.format("  %-+10.4f %-+10.4f %-+10.4f %-+10.4f\n", [m41, m42, m43, m44]);
		s += " }";
		return s;
	}
}