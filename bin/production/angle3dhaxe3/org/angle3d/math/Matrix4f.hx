package org.angle3d.math;

import org.angle3d.math.Vector3f;
import org.angle3d.utils.Assert;
import flash.Vector;
/**
 * <code>Matrix4f</code> defines and maintains a 4x4 matrix in row major order.
 * This matrix is intended for use in a translation and rotational capacity.
 * It provides convenience methods for creating the matrix from a multitude
 * of sources.
 *
 * Matrices are stored assuming column vectors on the right, with the translation
 * in the rightmost column. Element Floating is row,column, so m03 is the zeroth
 * row, third column, which is the "x" translation part. This means that the implicit
 * storage order is column major. However, the get() and set() functions on float
 * arrays default to row major order!
 *
 * @author Mark Powell
 * @author Joshua Slack
 */
class Matrix4f
{
	public static var IDENTITY:Matrix4f = new Matrix4f();

	public var m00:Float;
	public var m01:Float;
	public var m02:Float;
	public var m03:Float;

	public var m10:Float;
	public var m11:Float;
	public var m12:Float;
	public var m13:Float;

	public var m20:Float;
	public var m21:Float;
	public var m22:Float;
	public var m23:Float;

	public var m30:Float;
	public var m31:Float;
	public var m32:Float;
	public var m33:Float;

	/**
	 *
	 * @param res
	 *
	 */
	public function new()
	{
		makeIdentity();
	}

	
	public inline function makeIdentity():Void
	{
		m00 = m11 = m22 = m33 = 1.0;
		m01 = m02 = m03 = m10 = m12 = m13 = m20 = m21 = m23 = m30 = m31 = m32 = 0;
	}

	
	public inline function makeZero():Void
	{
		m00 = m11 = m22 = m33 = 0.0;
		m01 = m02 = m03 = m10 = m12 = m13 = m20 = m21 = m23 = m30 = m31 = m32 = 0;
	}

	/**
	 * @return true if this matrix is identity
	 */
	
	public inline function isIdentity():Bool
	{
		return (m00 == 1 && m01 == 0 && m02 == 0 && m03 == 0) && (m10 == 0 && m11 == 1 && m12 == 0 && m13 == 0) && (m20 == 0 && m21 == 0 && m22 == 1 && m23 == 0) && (m30 == 0 && m31 == 0 && m32 ==
			0 && m33 == 1);
	}

	/**
	 * <code>copy</code> transfers the contents of a given matrix to this
	 * matrix.
	 *
	 * @param matrix
	 *            the matrix to copy.
	 */
	public function copyFrom(mat:Matrix4f):Matrix4f
	{
		this.m00 = mat.m00;
		this.m01 = mat.m01;
		this.m02 = mat.m02;
		this.m03 = mat.m03;

		this.m10 = mat.m10;
		this.m11 = mat.m11;
		this.m12 = mat.m12;
		this.m13 = mat.m13;

		this.m20 = mat.m20;
		this.m21 = mat.m21;
		this.m22 = mat.m22;
		this.m23 = mat.m23;

		this.m30 = mat.m30;
		this.m31 = mat.m31;
		this.m32 = mat.m32;
		this.m33 = mat.m33;

		return this;
	}

	/**
	 * 先copy第一个参数，然后乘以第二个参数
	 * @param copyM 复制copyM
	 * @param mat  乘以mat
	 *
	 */
	//TODO 耗时较久
	public function copyAndMultLocal(copyM:Matrix4f, mat:Matrix4f):Void
	{
		m00 = copyM.m00 * mat.m00 + copyM.m01 * mat.m10 + copyM.m02 * mat.m20 + copyM.m03 * mat.m30;
		m01 = copyM.m00 * mat.m01 + copyM.m01 * mat.m11 + copyM.m02 * mat.m21 + copyM.m03 * mat.m31;
		m02 = copyM.m00 * mat.m02 + copyM.m01 * mat.m12 + copyM.m02 * mat.m22 + copyM.m03 * mat.m32;
		m03 = copyM.m00 * mat.m03 + copyM.m01 * mat.m13 + copyM.m02 * mat.m23 + copyM.m03 * mat.m33;

		m10 = copyM.m10 * mat.m00 + copyM.m11 * mat.m10 + copyM.m12 * mat.m20 + copyM.m13 * mat.m30;
		m11 = copyM.m10 * mat.m01 + copyM.m11 * mat.m11 + copyM.m12 * mat.m21 + copyM.m13 * mat.m31;
		m12 = copyM.m10 * mat.m02 + copyM.m11 * mat.m12 + copyM.m12 * mat.m22 + copyM.m13 * mat.m32;
		m13 = copyM.m10 * mat.m03 + copyM.m11 * mat.m13 + copyM.m12 * mat.m23 + copyM.m13 * mat.m33;

		m20 = copyM.m20 * mat.m00 + copyM.m21 * mat.m10 + copyM.m22 * mat.m20 + copyM.m23 * mat.m30;
		m21 = copyM.m20 * mat.m01 + copyM.m21 * mat.m11 + copyM.m22 * mat.m21 + copyM.m23 * mat.m31;
		m22 = copyM.m20 * mat.m02 + copyM.m21 * mat.m12 + copyM.m22 * mat.m22 + copyM.m23 * mat.m32;
		m23 = copyM.m20 * mat.m03 + copyM.m21 * mat.m13 + copyM.m22 * mat.m23 + copyM.m23 * mat.m33;

		m30 = copyM.m30 * mat.m00 + copyM.m31 * mat.m10 + copyM.m32 * mat.m20 + copyM.m33 * mat.m30;
		m31 = copyM.m30 * mat.m01 + copyM.m31 * mat.m11 + copyM.m32 * mat.m21 + copyM.m33 * mat.m31;
		m32 = copyM.m30 * mat.m02 + copyM.m31 * mat.m12 + copyM.m32 * mat.m22 + copyM.m33 * mat.m32;
		m33 = copyM.m30 * mat.m03 + copyM.m31 * mat.m13 + copyM.m32 * mat.m23 + copyM.m33 * mat.m33;
	}

	public function clone():Matrix4f
	{
		var result:Matrix4f = new Matrix4f();
		result.copyFrom(this);
		return result;
	}

	/**
	 * Create a new Matrix4f, given data in column-major format.
	 *
	 * @param array
	 *		An array of 16 floats in column-major format (translation in elements 12, 13 and 14).
	 */
	public function setArray(matrix:Array<Float>, rowMajor:Bool = true):Void
	{
		Assert.assert(matrix.length == 16, "Array.length must be 16.");

		m00 = matrix[0];
		m11 = matrix[5];
		m22 = matrix[10];
		m33 = matrix[15];
		if (rowMajor)
		{
			m01 = matrix[1];
			m02 = matrix[2];
			m03 = matrix[3];
			m10 = matrix[4];

			m12 = matrix[6];
			m13 = matrix[7];
			m20 = matrix[8];
			m21 = matrix[9];

			m23 = matrix[11];
			m30 = matrix[12];
			m31 = matrix[13];
			m32 = matrix[14];
		}
		else
		{
			m01 = matrix[4];
			m02 = matrix[8];
			m03 = matrix[12];
			m10 = matrix[1];

			m12 = matrix[9];
			m13 = matrix[13];
			m20 = matrix[2];
			m21 = matrix[6];

			m23 = matrix[14];
			m30 = matrix[3];
			m31 = matrix[7];
			m32 = matrix[11];
		}
	}

	/**
	 * Create a new Matrix4f, given data in column-major format.
	 *
	 * @param array
	 *		An array of 16 floats in column-major format (translation in elements 12, 13 and 14).
	 */
	public function setVector(matrix:Vector<Float>, rowMajor:Bool = true):Void
	{
		Assert.assert(matrix.length == 16, "Array.length must be 16.");

		m00 = matrix[0];
		m11 = matrix[5];
		m22 = matrix[10];
		m33 = matrix[15];
		if (rowMajor)
		{
			m01 = matrix[1];
			m02 = matrix[2];
			m03 = matrix[3];
			m10 = matrix[4];

			m12 = matrix[6];
			m13 = matrix[7];
			m20 = matrix[8];
			m21 = matrix[9];

			m23 = matrix[11];
			m30 = matrix[12];
			m31 = matrix[13];
			m32 = matrix[14];
		}
		else
		{
			m01 = matrix[4];
			m02 = matrix[8];
			m03 = matrix[12];
			m10 = matrix[1];

			m12 = matrix[9];
			m13 = matrix[13];
			m20 = matrix[2];
			m21 = matrix[6];

			m23 = matrix[14];
			m30 = matrix[3];
			m31 = matrix[7];
			m32 = matrix[11];
		}
	}

	/**
	 * <code>get</code> retrieves a value from the matrix at the given
	 * position. If the position is invalid a <code>JmeException</code> is
	 * thrown.
	 *
	 * @param i
	 *            the row index.
	 * @param j
	 *            the colum index.
	 * @return the value at (i, j).
	 */
	
	public inline function getValue(row:Int, column:Int):Float
	{
		return untyped this["m" + row + column];
	}

	public function fromFrame(location:Vector3f, direction:Vector3f, up:Vector3f, left:Vector3f):Void
	{
		makeIdentity();

		var f:Vector3f = direction;
		var s:Vector3f = f.cross(up);
		var u:Vector3f = s.cross(f);

		m00 = s.x;
		m01 = s.y;
		m02 = s.z;

		m10 = u.x;
		m11 = u.y;
		m12 = u.z;

		m20 = -f.x;
		m21 = -f.y;
		m22 = -f.z;

		var transMatrix:Matrix4f = new Matrix4f();
		transMatrix.m03 = -location.x;
		transMatrix.m13 = -location.y;
		transMatrix.m23 = -location.z;
		multLocal(transMatrix);
	}

	/**
	 * <code>getColumn</code> returns one of three columns specified by the
	 * parameter. This column is returned as a <code>Vector3f</code> object.
	 *
	 * @param i
	 *            the column to retrieve. Must be between 0 and 2.
	 * @return the column specified by the index.
	 */
	public function copyColumnTo(column:Int, result:Vector4f = null):Vector4f
	{
		Assert.assert(column >= 0 && column <= 3, "Invalid column index.");

		if (result == null)
			result = new Vector4f();

		result.x = getValue(0, column);
		result.y = getValue(1, column);
		result.z = getValue(2, column);
		result.w = getValue(3, column);
		return result;
	}

	/**
	* <code>getRow</code> returns one of three rows as specified by the
	* parameter. This row is returned as a <code>Vector3f</code> object.
	*
	* @param i
	*            the row to retrieve. Must be between 0 and 2.
	* @param store
	*            the vector object to store the result in. if null, a new one
	*            is created.
	* @return the row specified by the index.
	*/
	public function copyRowTo(row:Int, result:Vector4f = null):Vector4f
	{
		Assert.assert(row >= 0 && row <= 3, "Invalid row index.");

		if (result == null)
			result = new Vector4f();

		result.x = getValue(row, 0);
		result.y = getValue(row, 1);
		result.z = getValue(row, 2);
		result.w = getValue(row, 3);
		return result;
	}

	/**
	 *
	 * <code>setColumn</code> sets a particular column of this matrix to that
	 * represented by the provided vector.
	 *
	 * @param i
	 *            the column to set.
	 * @param column
	 *            the data to set.
	 * @return this
	 */
	public function setColumn(column:Int, vector:Vector4f):Void
	{
		Assert.assert(column >= 0 && column <= 3, "Invalid column index.");

		setValue(0, column, vector.x);
		setValue(1, column, vector.y);
		setValue(2, column, vector.z);
		setValue(3, column, vector.w);
	}

	/**
	 * <code>set</code> places a given value into the matrix at the given
	 * position. If the position is invalid a <code>JmeException</code> is
	 * thrown.
	 *
	 * @param i
	 *            the row index.
	 * @param j
	 *            the colum index.
	 * @param value
	 *            the value for (i, j).
	 * @return this
	 */
	
	public inline function setValue(row:Int, column:Int, value:Float):Void
	{
		untyped this["m" + row + column] = value;
	}

	/**
	 * <code>transpose</code> locally transposes this Matrix.
	 *
	 * @return this object for chaining.
	 */
	public function transposeLocal():Matrix4f
	{
		var tmp:Float = m01;
		m01 = m10;
		m10 = tmp;

		tmp = m02;
		m02 = m20;
		m20 = tmp;

		tmp = m03;
		m03 = m30;
		m30 = tmp;

		tmp = m12;
		m12 = m21;
		m21 = tmp;

		tmp = m13;
		m13 = m31;
		m31 = tmp;

		tmp = m23;
		m23 = m32;
		m32 = tmp;

		return this;
	}

	public function fromFrustum(near:Float, far:Float, left:Float, right:Float, top:Float, bottom:Float, parallel:Bool = false):Void
	{
		makeIdentity();

		var w:Float = (right - left);
		var h:Float = (top - bottom);
		var d:Float = (far - near);

		if (parallel)
		{
			// scale
			m00 = 2.0 / w;
			//m11 = 2.0f / (bottom - top);
			m11 = 2.0 / h;
			m22 = -2.0 / d;
			m33 = 1;

			// translation
			m03 = -(right + left) / w;
			//m31 = -(bottom + top) / (bottom - top);
			m13 = -(top + bottom) / h;
			m23 = -(far + near) / d;
		}
		else
		{
			m00 = (2.0 * near) / w;
			m11 = (2.0 * near) / h;
			m32 = -1.0;
			m33 = 0.0;

			// A
			m02 = (right + left) / w;

			// B 
			m12 = (top + bottom) / h;

			// C
			m22 = -(far + near) / d;

			// D
			m23 = -2 * (far * near) / d;
		}
	}

	/**
	 * <code>fromAngleAxis</code> sets this matrix4f to the values specified
	 * by an angle and an axis of rotation.  This method creates an object, so
	 * use fromAngleNormalAxis if your axis is already normalized.
	 *
	 * @param angle
	 *            the angle to rotate (in radians).
	 * @param axis
	 *            the axis of rotation.
	 */
	public function fromAngleAxis(angle:Float, axis:Vector3f):Void
	{
		var normAxis:Vector3f = axis.clone();
		normAxis.normalizeLocal();
		fromAngleNormalAxis(angle, normAxis);
	}

	/**
	 * <code>fromAngleNormalAxis</code> sets this matrix4f to the values
	 * specified by an angle and a normalized axis of rotation.
	 *
	 * @param angle
	 *            the angle to rotate (in radians).
	 * @param axis
	 *            the axis of rotation (already normalized).
	 */
	public function fromAngleNormalAxis(angle:Float, axis:Vector3f):Void
	{
		makeIdentity();

		var fCos:Float = Math.cos(angle);
		var fSin:Float = Math.sin(angle);
		var fOneMinusCos:Float = 1.0 - fCos;
		var fX2:Float = axis.x * axis.x;
		var fY2:Float = axis.y * axis.y;
		var fZ2:Float = axis.z * axis.z;
		var fXYM:Float = axis.x * axis.y * fOneMinusCos;
		var fXZM:Float = axis.x * axis.z * fOneMinusCos;
		var fYZM:Float = axis.y * axis.z * fOneMinusCos;
		var fXSin:Float = axis.x * fSin;
		var fYSin:Float = axis.y * fSin;
		var fZSin:Float = axis.z * fSin;

		m00 = fX2 * fOneMinusCos + fCos;
		m01 = fXYM - fZSin;
		m02 = fXZM + fYSin;
		m10 = fXYM + fZSin;
		m11 = fY2 * fOneMinusCos + fCos;
		m12 = fYZM - fXSin;
		m20 = fXZM - fYSin;
		m21 = fYZM + fXSin;
		m22 = fZ2 * fOneMinusCos + fCos;
	}

	/**
	 * <code>mult</code> multiplies this matrix by a scalar.
	 *
	 * @param scalar
	 *            the scalar to multiply this matrix by.
	 */
	public function scaleLocal(value:Float):Void
	{
		m00 *= value;
		m01 *= value;
		m02 *= value;
		m03 *= value;
		m10 *= value;
		m11 *= value;
		m12 *= value;
		m13 *= value;
		m20 *= value;
		m21 *= value;
		m22 *= value;
		m23 *= value;
		m30 *= value;
		m31 *= value;
		m32 *= value;
		m33 *= value;
	}

	/**
	 * Apply a scale to this matrix.
	 *
	 * @param scale
	 *            the scale to apply
	 */
	public function scaleVecLocal(scale:Vector3f):Void
	{
		var sx:Float = scale.x;
		var sy:Float = scale.y;
		var sz:Float = scale.z;

		m00 *= sx;
		m10 *= sx;
		m20 *= sx;
		m30 *= sx;
		m01 *= sy;
		m11 *= sy;
		m21 *= sy;
		m31 *= sy;
		m02 *= sz;
		m12 *= sz;
		m22 *= sz;
		m32 *= sz;
	}

	public function scale(scalar:Float, result:Matrix4f = null):Matrix4f
	{
		if (result == null)
			result = new Matrix4f();

		result.scaleLocal(scalar);
		return result;
	}

	/**
	 * <code>mult</code> multiplies this matrix with another matrix. The
	 * result matrix will then be returned. This matrix will be on the left hand
	 * side, while the parameter matrix will be on the right.
	 *
	 * @param in2
	 *            the matrix to multiply this matrix by.
	 * @param result
	 *            where to store the result. It is safe for in2 and store to be
	 *            the same object.
	 * @return the resultant matrix
	 */
	public function mult(in2:Matrix4f, result:Matrix4f = null):Matrix4f
	{
		if (result == null)
			result = new Matrix4f();

		var temp00:Float, temp01:Float, temp02:Float, temp03:Float;
		var temp10:Float, temp11:Float, temp12:Float, temp13:Float;
		var temp20:Float, temp21:Float, temp22:Float, temp23:Float;
		var temp30:Float, temp31:Float, temp32:Float, temp33:Float;

		temp00 = m00 * in2.m00 + m01 * in2.m10 + m02 * in2.m20 + m03 * in2.m30;
		temp01 = m00 * in2.m01 + m01 * in2.m11 + m02 * in2.m21 + m03 * in2.m31;
		temp02 = m00 * in2.m02 + m01 * in2.m12 + m02 * in2.m22 + m03 * in2.m32;
		temp03 = m00 * in2.m03 + m01 * in2.m13 + m02 * in2.m23 + m03 * in2.m33;

		temp10 = m10 * in2.m00 + m11 * in2.m10 + m12 * in2.m20 + m13 * in2.m30;
		temp11 = m10 * in2.m01 + m11 * in2.m11 + m12 * in2.m21 + m13 * in2.m31;
		temp12 = m10 * in2.m02 + m11 * in2.m12 + m12 * in2.m22 + m13 * in2.m32;
		temp13 = m10 * in2.m03 + m11 * in2.m13 + m12 * in2.m23 + m13 * in2.m33;

		temp20 = m20 * in2.m00 + m21 * in2.m10 + m22 * in2.m20 + m23 * in2.m30;
		temp21 = m20 * in2.m01 + m21 * in2.m11 + m22 * in2.m21 + m23 * in2.m31;
		temp22 = m20 * in2.m02 + m21 * in2.m12 + m22 * in2.m22 + m23 * in2.m32;
		temp23 = m20 * in2.m03 + m21 * in2.m13 + m22 * in2.m23 + m23 * in2.m33;

		temp30 = m30 * in2.m00 + m31 * in2.m10 + m32 * in2.m20 + m33 * in2.m30;
		temp31 = m30 * in2.m01 + m31 * in2.m11 + m32 * in2.m21 + m33 * in2.m31;
		temp32 = m30 * in2.m02 + m31 * in2.m12 + m32 * in2.m22 + m33 * in2.m32;
		temp33 = m30 * in2.m03 + m31 * in2.m13 + m32 * in2.m23 + m33 * in2.m33;

		result.m00 = temp00;
		result.m01 = temp01;
		result.m02 = temp02;
		result.m03 = temp03;
		result.m10 = temp10;
		result.m11 = temp11;
		result.m12 = temp12;
		result.m13 = temp13;
		result.m20 = temp20;
		result.m21 = temp21;
		result.m22 = temp22;
		result.m23 = temp23;
		result.m30 = temp30;
		result.m31 = temp31;
		result.m32 = temp32;
		result.m33 = temp33;

		return result;
	}

	/**
	 * <code>mult</code> multiplies this matrix with another matrix. The
	 * results are stored internally and a handle to this matrix will
	 * then be returned. This matrix will be on the left hand
	 * side, while the parameter matrix will be on the right.
	 *
	 * @param in2
	 *            the matrix to multiply this matrix by.
	 * @return the resultant matrix
	 */
	public function multLocal(in2:Matrix4f):Void
	{
		var temp00:Float, temp01:Float, temp02:Float, temp03:Float;
		var temp10:Float, temp11:Float, temp12:Float, temp13:Float;
		var temp20:Float, temp21:Float, temp22:Float, temp23:Float;
		var temp30:Float, temp31:Float, temp32:Float, temp33:Float;

		temp00 = m00 * in2.m00 + m01 * in2.m10 + m02 * in2.m20 + m03 * in2.m30;
		temp01 = m00 * in2.m01 + m01 * in2.m11 + m02 * in2.m21 + m03 * in2.m31;
		temp02 = m00 * in2.m02 + m01 * in2.m12 + m02 * in2.m22 + m03 * in2.m32;
		temp03 = m00 * in2.m03 + m01 * in2.m13 + m02 * in2.m23 + m03 * in2.m33;

		temp10 = m10 * in2.m00 + m11 * in2.m10 + m12 * in2.m20 + m13 * in2.m30;
		temp11 = m10 * in2.m01 + m11 * in2.m11 + m12 * in2.m21 + m13 * in2.m31;
		temp12 = m10 * in2.m02 + m11 * in2.m12 + m12 * in2.m22 + m13 * in2.m32;
		temp13 = m10 * in2.m03 + m11 * in2.m13 + m12 * in2.m23 + m13 * in2.m33;

		temp20 = m20 * in2.m00 + m21 * in2.m10 + m22 * in2.m20 + m23 * in2.m30;
		temp21 = m20 * in2.m01 + m21 * in2.m11 + m22 * in2.m21 + m23 * in2.m31;
		temp22 = m20 * in2.m02 + m21 * in2.m12 + m22 * in2.m22 + m23 * in2.m32;
		temp23 = m20 * in2.m03 + m21 * in2.m13 + m22 * in2.m23 + m23 * in2.m33;

		temp30 = m30 * in2.m00 + m31 * in2.m10 + m32 * in2.m20 + m33 * in2.m30;
		temp31 = m30 * in2.m01 + m31 * in2.m11 + m32 * in2.m21 + m33 * in2.m31;
		temp32 = m30 * in2.m02 + m31 * in2.m12 + m32 * in2.m22 + m33 * in2.m32;
		temp33 = m30 * in2.m03 + m31 * in2.m13 + m32 * in2.m23 + m33 * in2.m33;

		this.m00 = temp00;
		this.m01 = temp01;
		this.m02 = temp02;
		this.m03 = temp03;
		this.m10 = temp10;
		this.m11 = temp11;
		this.m12 = temp12;
		this.m13 = temp13;
		this.m20 = temp20;
		this.m21 = temp21;
		this.m22 = temp22;
		this.m23 = temp23;
		this.m30 = temp30;
		this.m31 = temp31;
		this.m32 = temp32;
		this.m33 = temp33;
	}

	/**
	 * <code>mult</code> multiplies a vector about a rotation matrix and adds
	 * translation. The resulting vector is returned.
	 *
	 * @param vec
	 *            vec to multiply against.
	 * @param result
	 *            a vector to store the result in. Created if null is passed.
	 * @return the rotated vector.
	 */
	public function multVec(vec:Vector3f, result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;
		result.x = m00 * vx + m01 * vy + m02 * vz + m03;
		result.y = m10 * vx + m11 * vy + m12 * vz + m13;
		result.z = m20 * vx + m21 * vy + m22 * vz + m23;

		return result;
	}

	/**
	 * <code>mult</code> multiplies a vector about a rotation matrix. The
	 * resulting vector is returned.
	 *
	 * @param vec
	 *            vec to multiply against.
	 * @param store
	 *            a vector to store the result in.  created if null is passed.
	 * @return the rotated vector.
	 */
	public function multVecAcross(vec:Vector3f, result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;
		result.x = m00 * vx + m10 * vy + m20 * vz + m30;
		result.y = m01 * vx + m11 * vy + m21 * vz + m31;
		result.z = m02 * vx + m12 * vy + m22 * vz + m32;
		return result;
	}

	/**
	 * <code>multNormal</code> multiplies a vector about a rotation matrix, but
	 * does not add translation. The resulting vector is returned.
	 *
	 * @param vec
	 *            vec to multiply against.
	 * @param store
	 *            a vector to store the result in. Created if null is passed.
	 * @return the rotated vector.
	 */
	public function multNormal(vec:Vector3f, result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;

		result.x = m00 * vx + m01 * vy + m02 * vz;
		result.y = m10 * vx + m11 * vy + m12 * vz;
		result.z = m20 * vx + m21 * vy + m22 * vz;

		return result;
	}

	public function multNormalAcross(vec:Vector3f, result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;
		result.x = m00 * vx + m10 * vy + m20 * vz;
		result.y = m01 * vx + m11 * vy + m21 * vz;
		result.z = m02 * vx + m12 * vy + m22 * vz;

		return result;
	}

	/**
	 * <code>mult</code> multiplies a vector about a rotation matrix and adds
	 * translation. The w value is returned as a result of
	 * multiplying the last column of the matrix by 1.0
	 *
	 * @param vec
	 *            vec to multiply against.
	 * @param result
	 *            a vector to store the result in.
	 * @return the W value
	 */
	public function multProj(vec:Vector3f, result:Vector3f):Float
	{
		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;
		result.x = m00 * vx + m01 * vy + m02 * vz + m03;
		result.y = m10 * vx + m11 * vy + m12 * vz + m13;
		result.z = m20 * vx + m21 * vy + m22 * vz + m23;
		return m30 * vx + m31 * vy + m32 * vz + m33;
	}

	/**
	 * <code>mult</code> multiplies a <code>Vector4f</code> about a rotation
	 * matrix. The resulting vector is returned.
	 *
	 * @param vec
	 *            vec to multiply against.
	 * @param store
	 *            a vector to store the result in. Created if null is passed.
	 * @return the rotated vector.
	 */
	public function multVec4(vec:Vector4f, result:Vector4f = null):Vector4f
	{
		if (result == null)
			result = new Vector4f();

		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z, vw:Float = vec.w;

		result.x = m00 * vx + m01 * vy + m02 * vz + m03 * vw;
		result.y = m10 * vx + m11 * vy + m12 * vz + m13 * vw;
		result.z = m20 * vx + m21 * vy + m22 * vz + m23 * vw;
		result.w = m30 * vx + m31 * vy + m32 * vz + m33 * vw;

		return result;
	}

	/**
	 * <code>mult</code> multiplies a vector about a rotation matrix. The
	 * resulting vector is returned.
	 *
	 * @param vec
	 *            vec to multiply against.
	 * @param store
	 *            a vector to store the result in.  created if null is passed.
	 * @return the rotated vector.
	 */
	public function multVec4Across(vec:Vector4f, result:Vector4f = null):Vector4f
	{
		if (result == null)
			result = new Vector4f();

		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z, vw:Float = vec.w;
		result.x = m00 * vx + m10 * vy + m20 * vz + m30 * vw;
		result.y = m01 * vx + m11 * vy + m21 * vz + m31 * vw;
		result.z = m02 * vx + m12 * vy + m22 * vz + m32 * vw;
		result.z = m03 * vx + m13 * vy + m23 * vz + m33 * vw;

		return result;
	}

	/**
	* <code>mult</code> multiplies a quaternion about a matrix. The
	* resulting vector is returned.
	*
	* @param vec
	*            vec to multiply against.
	* @param store
	*            a quaternion to store the result in.  created if null is passed.
	* @return store = this * vec
	*/
	public function multQuat(quat:Quaternion, result:Quaternion = null):Quaternion
	{
		if (result == null)
			result = new Quaternion();

		var vx:Float = quat.x, vy:Float = quat.y, vz:Float = quat.z, vw:Float = quat.w;
		result.x = m00 * vx + m10 * vy + m20 * vz + m30 * vw;
		result.y = m01 * vx + m11 * vy + m21 * vz + m31 * vw;
		result.z = m02 * vx + m12 * vy + m22 * vz + m32 * vw;
		result.w = m03 * vx + m13 * vy + m23 * vz + m33 * vw;

		return result;
	}

	// XXX: This tests more solid than converting the q to a matrix and multiplying... why?
	public function multQuatLocal(rotation:Quaternion):Void
	{
		var axis:Vector3f = new Vector3f();
		var angle:Float = rotation.toAngleAxis(axis);
		var matrix4:Matrix4f = new Matrix4f();
		matrix4.fromAngleAxis(angle, axis);
		multLocal(matrix4);
	}

	/**
	 * Inverts this matrix and stores it in the given store.
	 *
	 * @return The store
	 */
	public function invert(result:Matrix4f = null):Matrix4f
	{
		if (result == null)
			result = new Matrix4f();

		var fA0:Float = m00 * m11 - m01 * m10;
		var fA1:Float = m00 * m12 - m02 * m10;
		var fA2:Float = m00 * m13 - m03 * m10;
		var fA3:Float = m01 * m12 - m02 * m11;
		var fA4:Float = m01 * m13 - m03 * m11;
		var fA5:Float = m02 * m13 - m03 * m12;
		var fB0:Float = m20 * m31 - m21 * m30;
		var fB1:Float = m20 * m32 - m22 * m30;
		var fB2:Float = m20 * m33 - m23 * m30;
		var fB3:Float = m21 * m32 - m22 * m31;
		var fB4:Float = m21 * m33 - m23 * m31;
		var fB5:Float = m22 * m33 - m23 * m32;
		var fDet:Float = fA0 * fB5 - fA1 * fB4 + fA2 * fB3 + fA3 * fB2 - fA4 * fB1 + fA5 * fB0;

		if (FastMath.abs(fDet) <= 0)
		{
			result.makeIdentity();
			//Logger.warn("This matrix cannot be inverted");
			return result;
		}

		var fInvDet:Float = 1.0 / fDet;

		var f00:Float = (m11 * fB5 - m12 * fB4 + m13 * fB3) * fInvDet;
		var f10:Float = (-m10 * fB5 + m12 * fB2 - m13 * fB1) * fInvDet;
		var f20:Float = (m10 * fB4 - m11 * fB2 + m13 * fB0) * fInvDet;
		var f30:Float = (-m10 * fB3 + m11 * fB1 - m12 * fB0) * fInvDet;
		var f01:Float = (-m01 * fB5 + m02 * fB4 - m03 * fB3) * fInvDet;
		var f11:Float = (m00 * fB5 - m02 * fB2 + m03 * fB1) * fInvDet;
		var f21:Float = (-m00 * fB4 + m01 * fB2 - m03 * fB0) * fInvDet;
		var f31:Float = (m00 * fB3 - m01 * fB1 + m02 * fB0) * fInvDet;
		var f02:Float = (m31 * fA5 - m32 * fA4 + m33 * fA3) * fInvDet;
		var f12:Float = (-m30 * fA5 + m32 * fA2 - m33 * fA1) * fInvDet;
		var f22:Float = (m30 * fA4 - m31 * fA2 + m33 * fA0) * fInvDet;
		var f32:Float = (-m30 * fA3 + m31 * fA1 - m32 * fA0) * fInvDet;
		var f03:Float = (-m21 * fA5 + m22 * fA4 - m23 * fA3) * fInvDet;
		var f13:Float = (m20 * fA5 - m22 * fA2 + m23 * fA1) * fInvDet;
		var f23:Float = (-m20 * fA4 + m21 * fA2 - m23 * fA0) * fInvDet;
		var f33:Float = (m20 * fA3 - m21 * fA1 + m22 * fA0) * fInvDet;

		result.m00 = f00;
		result.m01 = f01;
		result.m02 = f02;
		result.m03 = f03;
		result.m10 = f10;
		result.m11 = f11;
		result.m12 = f12;
		result.m13 = f13;
		result.m20 = f20;
		result.m21 = f21;
		result.m22 = f22;
		result.m23 = f23;
		result.m30 = f30;
		result.m31 = f31;
		result.m32 = f32;
		result.m33 = f33;

		return result;
	}

	/**
	 * Inverts this matrix locally.
	 *
	 * @return this
	 */
	public inline function invertLocal():Matrix4f
	{
		return invert(this);
	}

	/**
	 * Places the adjoint of this matrix in store (creates store if null.)
	 *
	 * @param store
	 *            The matrix to store the result in.  If null, a new matrix is created.
	 * @return store
	 */
	public function adjoint(result:Matrix4f = null):Matrix4f
	{
		if (result == null)
			result = new Matrix4f();

		var fA0:Float = m00 * m11 - m01 * m10;
		var fA1:Float = m00 * m12 - m02 * m10;
		var fA2:Float = m00 * m13 - m03 * m10;
		var fA3:Float = m01 * m12 - m02 * m11;
		var fA4:Float = m01 * m13 - m03 * m11;
		var fA5:Float = m02 * m13 - m03 * m12;
		var fB0:Float = m20 * m31 - m21 * m30;
		var fB1:Float = m20 * m32 - m22 * m30;
		var fB2:Float = m20 * m33 - m23 * m30;
		var fB3:Float = m21 * m32 - m22 * m31;
		var fB4:Float = m21 * m33 - m23 * m31;
		var fB5:Float = m22 * m33 - m23 * m32;

		var f00:Float = m11 * fB5 - m12 * fB4 + m13 * fB3;
		var f10:Float = -m10 * fB5 + m12 * fB2 - m13 * fB1;
		var f20:Float = m10 * fB4 - m11 * fB2 + m13 * fB0;
		var f30:Float = -m10 * fB3 + m11 * fB1 - m12 * fB0;
		var f01:Float = -m01 * fB5 + m02 * fB4 - m03 * fB3;
		var f11:Float = m00 * fB5 - m02 * fB2 + m03 * fB1;
		var f21:Float = -m00 * fB4 + m01 * fB2 - m03 * fB0;
		var f31:Float = m00 * fB3 - m01 * fB1 + m02 * fB0;
		var f02:Float = m31 * fA5 - m32 * fA4 + m33 * fA3;
		var f12:Float = -m30 * fA5 + m32 * fA2 - m33 * fA1;
		var f22:Float = m30 * fA4 - m31 * fA2 + m33 * fA0;
		var f32:Float = -m30 * fA3 + m31 * fA1 - m32 * fA0;
		var f03:Float = -m21 * fA5 + m22 * fA4 - m23 * fA3;
		var f13:Float = m20 * fA5 - m22 * fA2 + m23 * fA1;
		var f23:Float = -m20 * fA4 + m21 * fA2 - m23 * fA0;
		var f33:Float = m20 * fA3 - m21 * fA1 + m22 * fA0;

		result.m00 = f00;
		result.m01 = f01;
		result.m02 = f02;
		result.m03 = f03;
		result.m10 = f10;
		result.m11 = f11;
		result.m12 = f12;
		result.m13 = f13;
		result.m20 = f20;
		result.m21 = f21;
		result.m22 = f22;
		result.m23 = f23;
		result.m30 = f30;
		result.m31 = f31;
		result.m32 = f32;
		result.m33 = f33;

		return result;
	}

	public function setTransform(position:Vector3f, scale:Vector3f, rotMat:Matrix3f):Void
	{
		// Ordering:
		//    1. Scale
		//    2. Rotate
		//    3. Translate

		// set_up inline matrix with scale, rotation and translation
		m00 = scale.x * rotMat.m00;
		m01 = scale.y * rotMat.m01;
		m02 = scale.z * rotMat.m02;
		m03 = position.x;
		m10 = scale.x * rotMat.m10;
		m11 = scale.y * rotMat.m11;
		m12 = scale.z * rotMat.m12;
		m13 = position.y;
		m20 = scale.x * rotMat.m20;
		m21 = scale.y * rotMat.m21;
		m22 = scale.z * rotMat.m22;
		m23 = position.z;

		// No projection term
		m30 = 0;
		m31 = 0;
		m32 = 0;
		m33 = 1;
	}

	/**
	 * <code>determinant</code> generates the determinate of this matrix.
	 *
	 * @return the determinate
	 */
	public function determinant():Float
	{
		var fA0:Float = m00 * m11 - m01 * m10;
		var fA1:Float = m00 * m12 - m02 * m10;
		var fA2:Float = m00 * m13 - m03 * m10;
		var fA3:Float = m01 * m12 - m02 * m11;
		var fA4:Float = m01 * m13 - m03 * m11;
		var fA5:Float = m02 * m13 - m03 * m12;
		var fB0:Float = m20 * m31 - m21 * m30;
		var fB1:Float = m20 * m32 - m22 * m30;
		var fB2:Float = m20 * m33 - m23 * m30;
		var fB3:Float = m21 * m32 - m22 * m31;
		var fB4:Float = m21 * m33 - m23 * m31;
		var fB5:Float = m22 * m33 - m23 * m32;
		var fDet:Float = fA0 * fB5 - fA1 * fB4 + fA2 * fB3 + fA3 * fB2 - fA4 * fB1 + fA5 * fB0;
		return fDet;
	}

	public function add(mat:Matrix4f, result:Matrix4f = null):Matrix4f
	{
		if (result == null)
			result = new Matrix4f();

		result.m00 = m00 + mat.m00;
		result.m01 = m01 + mat.m01;
		result.m02 = m02 + mat.m02;
		result.m03 = m03 + mat.m03;
		result.m10 = m10 + mat.m10;
		result.m11 = m11 + mat.m11;
		result.m12 = m12 + mat.m12;
		result.m13 = m13 + mat.m13;
		result.m20 = m20 + mat.m20;
		result.m21 = m21 + mat.m21;
		result.m22 = m22 + mat.m22;
		result.m23 = m23 + mat.m23;
		result.m30 = m30 + mat.m30;
		result.m31 = m31 + mat.m31;
		result.m32 = m32 + mat.m32;
		result.m33 = m33 + mat.m33;
		return result;
	}

	/**
	 * <code>add</code> adds the values of a parameter matrix to this matrix.
	 *
	 * @param mat
	 *            the matrix to add to this.
	 */
	public function addLocal(mat:Matrix4f):Void
	{
		m00 += mat.m00;
		m01 += mat.m01;
		m02 += mat.m02;
		m03 += mat.m03;
		m10 += mat.m10;
		m11 += mat.m11;
		m12 += mat.m12;
		m13 += mat.m13;
		m20 += mat.m20;
		m21 += mat.m21;
		m22 += mat.m22;
		m23 += mat.m23;
		m30 += mat.m30;
		m31 += mat.m31;
		m32 += mat.m32;
		m33 += mat.m33;
	}

	public function getTranslation(result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		result.x = m03;
		result.y = m13;
		result.z = m23;
		return result;
	}


	//TODO 这个名字和计算不符合，需修改
	public function setScale(scale:Vector3f):Void
	{
		m00 *= scale.x;
		m11 *= scale.y;
		m22 *= scale.z;
	}

	/**
	 * <code>setTranslation</code> will set_the matrix's translation values.
	 *
	 * @param translation
	 *            the new values for the translation.
	 */
	public inline function setTranslation(trans:Vector3f):Void
	{
		m03 = trans.x;
		m13 = trans.y;
		m23 = trans.z;
	}

	/**
	 * sets this matrix to that of a rotation about
	 * three axes (x, y, z). Where each axis has a specified rotation in
	 * degrees. These rotations are expressed in a single <code>Vector3f</code>
	 * object.
	 *
	 * @param rx rotationX
	 * @param ry rotationY
	 * @param rz rotationZ
	 */
	public function setAngles(rx:Float, ry:Float, rz:Float):Void
	{
		var sr:Float, sp:Float, sy:Float, cr:Float, cp:Float, cy:Float;

		sy = Math.sin(rz);
		cy = Math.cos(rz);
		sp = Math.sin(ry);
		cp = Math.cos(ry);
		sr = Math.sin(rx);
		cr = Math.cos(rx);

		// matrix = (Z * Y) * X
		m00 = cp * cy;
		m10 = cp * sy;
		m20 = -sp;
		m01 = sr * sp * cy + cr * -sy;
		m11 = sr * sp * sy + cr * cy;
		m21 = sr * cp;
		m02 = (cr * sp * cy + -sr * -sy);
		m12 = (cr * sp * sy + -sr * cy);
		m22 = cr * cp;
	}

	/**
	 * <code>setRotationQuaternion</code> builds a rotation from a
	 * <code>Quaternion</code>.
	 *
	 * @param quat
	 *            the quaternion to build the rotation from.
	 * @throws NullPointerException
	 *             if quat is null.
	 */
	public inline function setQuaternion(quat:Quaternion):Void
	{
		quat.toMatrix4f(this);
	}

	/**
	 *
	 * <code>translateVect</code> translates a given Vector3f by the
	 * translation part of this matrix.
	 *
	 * @param data
	 *            the Vector3f to be translated.
	 */
	public inline function translateVect(vec:Vector3f):Void
	{
		vec.x += m03;
		vec.y += m13;
		vec.z += m23;
	}

	/**
	 *
	 * <code>inverseRotateVect</code> rotates a given Vector3f by the rotation
	 * part of this matrix.
	 *
	 * @param vec
	 *            the Vector3f to be rotated.
	 */
	public function inverseRotateVect(vec:Vector3f):Void
	{
		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;

		vec.x = vx * m00 + vy * m10 + vz * m20;
		vec.y = vx * m01 + vy * m11 + vz * m21;
		vec.z = vx * m02 + vy * m12 + vz * m22;
	}

	public function rotateVect(vec:Vector3f):Void
	{
		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;

		vec.x = vx * m00 + vy * m01 + vz * m02;
		vec.y = vx * m10 + vy * m11 + vz * m12;
		vec.z = vx * m20 + vy * m21 + vz * m22;
	}

	public function toQuaternion(result:Quaternion = null):Quaternion
	{
		if (result == null)
			result = new Quaternion();

		result.fromMatrix4f(this);
		return result;
	}

	public function toMatrix3f(mat:Matrix3f = null):Matrix3f
	{
		if (mat == null)
			mat = new Matrix3f();

		mat.m00 = m00;
		mat.m01 = m01;
		mat.m02 = m02;
		mat.m10 = m10;
		mat.m11 = m11;
		mat.m12 = m12;
		mat.m20 = m20;
		mat.m21 = m21;
		mat.m22 = m22;
		return mat;
	}

	public function toUniform(result:Vector<Float>, rowMajor:Bool = true):Void
	{
		if (rowMajor)
		{
			result[0] = m00;
			result[1] = m01;
			result[2] = m02;
			result[3] = m03;

			result[4] = m10;
			result[5] = m11;
			result[6] = m12;
			result[7] = m13;

			result[8] = m20;
			result[9] = m21;
			result[10] = m22;
			result[11] = m23;

			result[12] = m30;
			result[13] = m31;
			result[14] = m32;
			result[15] = m33;

		}
		else
		{
			result[0] = m00;
			result[4] = m01;
			result[8] = m02;
			result[12] = m03;

			result[1] = m10;
			result[5] = m11;
			result[9] = m12;
			result[13] = m13;

			result[2] = m20;
			result[6] = m21;
			result[10] = m22;
			result[14] = m23;

			result[3] = m30;
			result[7] = m31;
			result[11] = m32;
			result[15] = m33;
		}
	}

	public function toString():String
	{
		return "Matrix4f\n[" + 
			m00 + "\t" + m01 + "\t" + m02 + "\t" + m03 + "\n " + 
			m10 + "\t" + m11 + "\t" + m12 + "\t" + m13 + "\n " + 
			m20 + "\t" + m21 + "\t" + m22 + "\t" + m23 + "\n " + m30 + "\t" +
			m31 + "\t" + m32 + "\t" + m33 + "]";
	}
}

