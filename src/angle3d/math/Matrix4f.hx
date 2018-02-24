package angle3d.math;

import angle3d.error.Assert;
import angle3d.types.FloatBuffer;

import angle3d.math.Vector3f;
/**
 * Matrix4f defines and maintains a 4x4 matrix in row major order.
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
 * m00 	m01	  m02	m03
 *
 * m10	m11	  m12	m13
 *
 * m20	m21	  m22	m23
 *
 * m30	m31	  m32	m33
 *
 */
class Matrix4f {
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

	public var tx(get, set) : Float;
	public var ty(get, set) : Float;
	public var tz(get, set) : Float;

	/**
	 *
	 * @param res
	 *
	 */
	public function new() {
		m00 = m11 = m22 = m33 = 1.0;
		m01 = m02 = m03 = m10 = m12 = m13 = m20 = m21 = m23 = m30 = m31 = m32 = 0;
	}

	inline function get_tx():Float return m03;
	inline function get_ty():Float return m13;
	inline function get_tz():Float return m23;
	inline function set_tx(v:Float):Float return m03 = v;
	inline function set_ty(v:Float):Float return m13 = v;
	inline function set_tz(v:Float):Float return m23 = v;

	public inline function loadIdentity():Void {
		m00 = m11 = m22 = m33 = 1.0;
		m01 = m02 = m03 = m10 = m12 = m13 = m20 = m21 = m23 = m30 = m31 = m32 = 0;
	}

	public inline function makeZero():Void {
		m00 = m11 = m22 = m33 = 0.0;
		m01 = m02 = m03 = m10 = m12 = m13 = m20 = m21 = m23 = m30 = m31 = m32 = 0;
	}

	/**
	 * @return true if this matrix is identity
	 */

	public inline function isIdentity():Bool {
		return (m00 == 1 && m01 == 0 && m02 == 0 && m03 == 0) &&
		(m10 == 0 && m11 == 1 && m12 == 0 && m13 == 0) &&
		(m20 == 0 && m21 == 0 && m22 == 1 && m23 == 0) &&
		(m30 == 0 && m31 == 0 && m32 ==0 && m33 == 1);
	}

	/**
	 * `copy` transfers the contents of a given matrix to this
	 * matrix.
	 *
	 * @param matrix
	 *            the matrix to copy.
	 */
	public inline function copyFrom(mat:Matrix4f):Matrix4f {
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
	public inline function copyMultLocal(copyM:Matrix4f, mat:Matrix4f):Void {
		var cm00 = copyM.m00; var cm01 = copyM.m01; var cm02 = copyM.m02; var cm03 = copyM.m03;
		var cm10 = copyM.m10; var cm11 = copyM.m11; var cm12 = copyM.m12; var cm13 = copyM.m13;
		var cm20 = copyM.m20; var cm21 = copyM.m21; var cm22 = copyM.m22; var cm23 = copyM.m23;
		var cm30 = copyM.m30; var cm31 = copyM.m31; var cm32 = copyM.m32; var cm33 = copyM.m33;

		var mm00 = mat.m00; var mm01 = mat.m01; var mm02 = mat.m02; var mm03 = mat.m03;
		var mm10 = mat.m10; var mm11 = mat.m11; var mm12 = mat.m12; var mm13 = mat.m13;
		var mm20 = mat.m20; var mm21 = mat.m21; var mm22 = mat.m22; var mm23 = mat.m23;
		var mm30 = mat.m30; var mm31 = mat.m31; var mm32 = mat.m32; var mm33 = mat.m33;

		m00 = cm00 * mm00 + cm01 * mm10 + cm02 * mm20 + cm03 * mm30;
		m01 = cm00 * mm01 + cm01 * mm11 + cm02 * mm21 + cm03 * mm31;
		m02 = cm00 * mm02 + cm01 * mm12 + cm02 * mm22 + cm03 * mm32;
		m03 = cm00 * mm03 + cm01 * mm13 + cm02 * mm23 + cm03 * mm33;

		m10 = cm10 * mm00 + cm11 * mm10 + cm12 * mm20 + cm13 * mm30;
		m11 = cm10 * mm01 + cm11 * mm11 + cm12 * mm21 + cm13 * mm31;
		m12 = cm10 * mm02 + cm11 * mm12 + cm12 * mm22 + cm13 * mm32;
		m13 = cm10 * mm03 + cm11 * mm13 + cm12 * mm23 + cm13 * mm33;

		m20 = cm20 * mm00 + cm21 * mm10 + cm22 * mm20 + cm23 * mm30;
		m21 = cm20 * mm01 + cm21 * mm11 + cm22 * mm21 + cm23 * mm31;
		m22 = cm20 * mm02 + cm21 * mm12 + cm22 * mm22 + cm23 * mm32;
		m23 = cm20 * mm03 + cm21 * mm13 + cm22 * mm23 + cm23 * mm33;

		m30 = cm30 * mm00 + cm31 * mm10 + cm32 * mm20 + cm33 * mm30;
		m31 = cm30 * mm01 + cm31 * mm11 + cm32 * mm21 + cm33 * mm31;
		m32 = cm30 * mm02 + cm31 * mm12 + cm32 * mm22 + cm33 * mm32;
		m33 = cm30 * mm03 + cm31 * mm13 + cm32 * mm23 + cm33 * mm33;
	}

	public function clone():Matrix4f {
		var result:Matrix4f = new Matrix4f();
		result.copyFrom(this);
		return result;
	}

	public inline function setTo(m00:Float, m01:Float, m02:Float, m03:Float,
								 m10:Float, m11:Float, m12:Float, m13:Float,
								 m20:Float, m21:Float, m22:Float, m23:Float,
								 m30:Float, m31:Float, m32:Float, m33:Float):Void {
		this.m00 = m00;
		this.m01 = m01;
		this.m02 = m02;
		this.m03 = m03;

		this.m10 = m10;
		this.m11 = m11;
		this.m12 = m12;
		this.m13 = m13;

		this.m20 = m20;
		this.m21 = m21;
		this.m22 = m22;
		this.m23 = m23;

		this.m30 = m30;
		this.m31 = m31;
		this.m32 = m32;
		this.m33 = m33;
	}

	/**
	 * Create a new Matrix4f, given data in column-major format.
	 * @param array
	 *		An array of 16 floats in column-major format (translation in elements 12, 13 and 14).
	 */
	public function setArray(matrix:Array<Float>, rowMajor:Bool = true):Matrix4f {
		#if debug
		Assert.assert(matrix.length == 16, "Array.length must be 16.");
		#end

		m00 = matrix[0];
		m11 = matrix[5];
		m22 = matrix[10];
		m33 = matrix[15];
		if (rowMajor) {
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
		} else
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

		return this;
	}

	private static var leftVector:Vector3f = new Vector3f();
	private static var upVector:Vector3f = new Vector3f();
	public function fromFrame(location:Vector3f, direction:Vector3f, up:Vector3f, left:Vector3f):Void {
		leftVector.copyFrom(direction).crossLocal(up);
		upVector.copyFrom(leftVector).crossLocal(direction);

		m00 = leftVector.x;
		m01 = leftVector.y;
		m02 = leftVector.z;
		m03 = -leftVector.dot(location);

		m10 = upVector.x;
		m11 = upVector.y;
		m12 = upVector.z;
		m13 = -upVector.dot(location);

		m20 = -direction.x;
		m21 = -direction.y;
		m22 = -direction.z;
		m23 = direction.dot(location);

		m30 = 0;
		m31 = 0;
		m32 = 0;
		m33 = 1;
	}

	/**
	 * `getColumn` returns one of three columns specified by the
	 * parameter. This column is returned as a `Vector3f` object.
	 *
	 * @param i
	 *            the column to retrieve. Must be between 0 and 2.
	 * @return the column specified by the index.
	 */
	public function copyColumnTo(column:Int, result:Vector4f = null):Vector4f {
		#if debug
		Assert.assert(column >= 0 && column <= 3, "Invalid column index.");
		#end

		if (result == null)
			result = new Vector4f();

		result.x = getElement(0, column);
		result.y = getElement(1, column);
		result.z = getElement(2, column);
		result.w = getElement(3, column);
		return result;
	}

	/**
	* `getRow` returns one of three rows as specified by the
	* parameter. This row is returned as a `Vector3f` object.
	*
	* @param i
	*            the row to retrieve. Must be between 0 and 2.
	* @param store
	*            the vector object to store the result in. if null, a new one
	*            is created.
	* @return the row specified by the index.
	*/
	public function copyRowTo(row:Int, result:Vector4f = null):Vector4f {
		#if debug
		Assert.assert(row >= 0 && row <= 3, "Invalid row index.");
		#end

		if (result == null)
			result = new Vector4f();

		result.x = getElement(row, 0);
		result.y = getElement(row, 1);
		result.z = getElement(row, 2);
		result.w = getElement(row, 3);
		return result;
	}

	/**
	 *
	 * `setColumn` sets a particular column of this matrix to that
	 * represented by the provided vector.
	 *
	 * @param i
	 *            the column to set.
	 * @param column
	 *            the data to set.
	 * @return this
	 */
	public function setColumn(column:Int, vector:Vector4f):Void {
		Assert.assert(column >= 0 && column <= 3, "Invalid column index.");

		setElement(0, column, vector.x);
		setElement(1, column, vector.y);
		setElement(2, column, vector.z);
		setElement(3, column, vector.w);
	}

	/**
	 * `get` retrieves a value from the matrix at the given
	 * position.
	 *
	 * @param i
	 *            the row index.
	 * @param j
	 *            the colum index.
	 * @return the value at (i, j).
	 */
	public inline function getElement(row:Int, column:Int):Float {
		return untyped this["m" + row + column];
	}

	/**
	 * `set` places a given value into the matrix at the given
	 * position. If the position is invalid a `Angle3DException` is
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
	public inline function setElement(row:Int, column:Int, value:Float):Void {
		untyped this["m" + row + column] = value;
	}

	/**
	 * `transpose` locally transposes this Matrix.
	 *
	 * @return this object for chaining.
	 */
	public function transposeLocal():Matrix4f {
		var tmp:Float;
		tmp = m01; m01 = m10; m10 = tmp;
		tmp = m02; m02 = m20; m20 = tmp;
		tmp = m03; m03 = m30; m30 = tmp;
		tmp = m12; m12 = m21; m21 = tmp;
		tmp = m13; m13 = m31; m31 = tmp;
		tmp = m23; m23 = m32; m32 = tmp;
		return this;
	}

	public function fromFrustum(near:Float, far:Float, left:Float, right:Float, top:Float, bottom:Float, parallel:Bool = false):Void {
		loadIdentity();

		var w:Float = 1 / (right - left);
		var h:Float = 1 / (top - bottom);
		var d:Float = 1 / (far - near);

		if (!parallel) {
			m00 = (2.0 * near) * w;
			m11 = (2.0 * near) * h;
			m32 = -1.0;
			m33 = 0.0;

			// A
			m02 = (right + left) * w;

			// B
			m12 = (top + bottom) * h;

			// C
			m22 = -(far + near) * d;

			// D
			m23 = -2 * (far * near) * d;
		} else
		{
			// scale
			m00 = 2.0 * w;
			//m11 = 2.0f / (bottom - top);
			m11 = 2.0 * h;
			m22 = -2.0 * d;
			m33 = 1;

			// translation
			m03 = -(right + left) * w;
			//m31 = -(bottom + top) / (bottom - top);
			m13 = -(top + bottom) * h;
			m23 = -(far + near) * d;
		}
	}

	/**
	 * `fromAngleAxis` sets this matrix4f to the values specified
	 * by an angle and an axis of rotation.  This method creates an object, so
	 * use fromAngleNormalAxis if your axis is already normalized.
	 *
	 * @param angle
	 *            the angle to rotate (in radians).
	 * @param axis
	 *            the axis of rotation.
	 */
	public function fromAngleAxis(angle:Float, axis:Vector3f):Void {
		var normAxis:Vector3f = axis.clone();
		normAxis.normalizeLocal();
		fromAngleNormalAxis(angle, normAxis);
	}

	/**
	 * `fromAngleNormalAxis` sets this matrix4f to the values
	 * specified by an angle and a normalized axis of rotation.
	 *
	 * @param angle
	 *            the angle to rotate (in radians).
	 * @param axis
	 *            the axis of rotation (already normalized).
	 */
	public function fromAngleNormalAxis(angle:Float, axis:Vector3f):Void {
		loadIdentity();

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
	 * `mult` multiplies this matrix by a scalar.
	 *
	 * @param scalar
	 *            the scalar to multiply this matrix by.
	 */
	public function multFloatLocal(value:Float):Matrix4f {
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
		return this;
	}

	/**
	 * Apply a scale to this matrix.
	 *
	 * @param scale
	 *            the scale to apply
	 */
	public function scaleVecLocal(scale:Vector3f):Void {
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

	public function multFloat(scalar:Float, result:Matrix4f = null):Matrix4f {
		if (result == null)
			result = new Matrix4f();

		result.multFloatLocal(scalar);
		return result;
	}

	/**
	 * `mult` multiplies this matrix with another matrix. The
	 * result matrix will then be returned. This matrix will be on the left hand
	 * side, while the parameter matrix will be on the right.
	 *
	 * @param mat
	 *            the matrix to multiply this matrix by.
	 * @param result
	 *            where to store the result. It is safe for in2 and store to be
	 *            the same object.
	 * @return the resultant matrix
	 */
	public function mult(mat:Matrix4f, result:Matrix4f = null):Matrix4f {
		if (result == null)
			result = new Matrix4f();

		var mm00 = mat.m00; var mm01 = mat.m01; var mm02 = mat.m02; var mm03 = mat.m03;
		var mm10 = mat.m10; var mm11 = mat.m11; var mm12 = mat.m12; var mm13 = mat.m13;
		var mm20 = mat.m20; var mm21 = mat.m21; var mm22 = mat.m22; var mm23 = mat.m23;
		var mm30 = mat.m30; var mm31 = mat.m31; var mm32 = mat.m32; var mm33 = mat.m33;

		result.m00 = m00 * mm00 + m01 * mm10 + m02 * mm20 + m03 * mm30;
		result.m01 = m00 * mm01 + m01 * mm11 + m02 * mm21 + m03 * mm31;
		result.m02 = m00 * mm02 + m01 * mm12 + m02 * mm22 + m03 * mm32;
		result.m03 = m00 * mm03 + m01 * mm13 + m02 * mm23 + m03 * mm33;

		result.m10 = m10 * mm00 + m11 * mm10 + m12 * mm20 + m13 * mm30;
		result.m11 = m10 * mm01 + m11 * mm11 + m12 * mm21 + m13 * mm31;
		result.m12 = m10 * mm02 + m11 * mm12 + m12 * mm22 + m13 * mm32;
		result.m13 = m10 * mm03 + m11 * mm13 + m12 * mm23 + m13 * mm33;

		result.m20 = m20 * mm00 + m21 * mm10 + m22 * mm20 + m23 * mm30;
		result.m21 = m20 * mm01 + m21 * mm11 + m22 * mm21 + m23 * mm31;
		result.m22 = m20 * mm02 + m21 * mm12 + m22 * mm22 + m23 * mm32;
		result.m23 = m20 * mm03 + m21 * mm13 + m22 * mm23 + m23 * mm33;

		result.m30 = m30 * mm00 + m31 * mm10 + m32 * mm20 + m33 * mm30;
		result.m31 = m30 * mm01 + m31 * mm11 + m32 * mm21 + m33 * mm31;
		result.m32 = m30 * mm02 + m31 * mm12 + m32 * mm22 + m33 * mm32;
		result.m33 = m30 * mm03 + m31 * mm13 + m32 * mm23 + m33 * mm33;

		return result;
	}

	/**
	 * `mult` multiplies this matrix with another matrix. The
	 * results are stored internally and a handle to this matrix will
	 * then be returned. This matrix will be on the left hand
	 * side, while the parameter matrix will be on the right.
	 *
	 * @param in2
	 *            the matrix to multiply this matrix by.
	 * @return the resultant matrix
	 */
	public function multLocal(mat:Matrix4f):Void {
		var tm00 = m00; var tm01 = m01; var tm02 = m02; var tm03 = m03;
		var tm10 = m10; var tm11 = m11; var tm12 = m12; var tm13 = m13;
		var tm20 = m20; var tm21 = m21; var tm22 = m22; var tm23 = m23;
		var tm30 = m30; var tm31 = m31; var tm32 = m32; var tm33 = m33;

		var mm00 = mat.m00; var mm01 = mat.m01; var mm02 = mat.m02; var mm03 = mat.m03;
		var mm10 = mat.m10; var mm11 = mat.m11; var mm12 = mat.m12; var mm13 = mat.m13;
		var mm20 = mat.m20; var mm21 = mat.m21; var mm22 = mat.m22; var mm23 = mat.m23;
		var mm30 = mat.m30; var mm31 = mat.m31; var mm32 = mat.m32; var mm33 = mat.m33;

		m00 = tm00 * mm00 + tm01 * mm10 + tm02 * mm20 + tm03 * mm30;
		m01 = tm00 * mm01 + tm01 * mm11 + tm02 * mm21 + tm03 * mm31;
		m02 = tm00 * mm02 + tm01 * mm12 + tm02 * mm22 + tm03 * mm32;
		m03 = tm00 * mm03 + tm01 * mm13 + tm02 * mm23 + tm03 * mm33;

		m10 = tm10 * mm00 + tm11 * mm10 + tm12 * mm20 + tm13 * mm30;
		m11 = tm10 * mm01 + tm11 * mm11 + tm12 * mm21 + tm13 * mm31;
		m12 = tm10 * mm02 + tm11 * mm12 + tm12 * mm22 + tm13 * mm32;
		m13 = tm10 * mm03 + tm11 * mm13 + tm12 * mm23 + tm13 * mm33;

		m20 = tm20 * mm00 + tm21 * mm10 + tm22 * mm20 + tm23 * mm30;
		m21 = tm20 * mm01 + tm21 * mm11 + tm22 * mm21 + tm23 * mm31;
		m22 = tm20 * mm02 + tm21 * mm12 + tm22 * mm22 + tm23 * mm32;
		m23 = tm20 * mm03 + tm21 * mm13 + tm22 * mm23 + tm23 * mm33;

		m30 = tm30 * mm00 + tm31 * mm10 + tm32 * mm20 + tm33 * mm30;
		m31 = tm30 * mm01 + tm31 * mm11 + tm32 * mm21 + tm33 * mm31;
		m32 = tm30 * mm02 + tm31 * mm12 + tm32 * mm22 + tm33 * mm32;
		m33 = tm30 * mm03 + tm31 * mm13 + tm32 * mm23 + tm33 * mm33;
	}

	/**
	 * `mult` multiplies a vector about a rotation matrix and adds
	 * translation. The resulting vector is returned.
	 *
	 * @param vec
	 *            vec to multiply against.
	 * @param result
	 *            a vector to store the result in. Created if null is passed.
	 * @return the rotated vector.
	 */
	public function multVec(vec:Vector3f, result:Vector3f = null):Vector3f {
		if (result == null)
			result = new Vector3f();

		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;
		result.x = m00 * vx + m01 * vy + m02 * vz + m03;
		result.y = m10 * vx + m11 * vy + m12 * vz + m13;
		result.z = m20 * vx + m21 * vy + m22 * vz + m23;

		return result;
	}

	/**
	 * `mult` multiplies a vector about a rotation matrix. The
	 * resulting vector is returned.
	 *
	 * @param vec
	 *            vec to multiply against.
	 * @param store
	 *            a vector to store the result in.  created if null is passed.
	 * @return the rotated vector.
	 */
	public function multVecAcross(vec:Vector3f, result:Vector3f = null):Vector3f {
		if (result == null)
			result = new Vector3f();

		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;
		result.x = m00 * vx + m10 * vy + m20 * vz + m30;
		result.y = m01 * vx + m11 * vy + m21 * vz + m31;
		result.z = m02 * vx + m12 * vy + m22 * vz + m32;
		return result;
	}

	/**
	 * `multNormal` multiplies a vector about a rotation matrix, but
	 * does not add translation. The resulting vector is returned.
	 *
	 * @param vec
	 *            vec to multiply against.
	 * @param store
	 *            a vector to store the result in. Created if null is passed.
	 * @return the rotated vector.
	 */
	public function multNormal(vec:Vector3f, result:Vector3f = null):Vector3f {
		if (result == null)
			result = new Vector3f();

		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;

		result.x = m00 * vx + m01 * vy + m02 * vz;
		result.y = m10 * vx + m11 * vy + m12 * vz;
		result.z = m20 * vx + m21 * vy + m22 * vz;

		return result;
	}

	public function multNormalAcross(vec:Vector3f, result:Vector3f = null):Vector3f {
		if (result == null)
			result = new Vector3f();

		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;
		result.x = m00 * vx + m10 * vy + m20 * vz;
		result.y = m01 * vx + m11 * vy + m21 * vz;
		result.z = m02 * vx + m12 * vy + m22 * vz;

		return result;
	}

	/**
	 * `mult` multiplies a vector about a rotation matrix and adds
	 * translation. The w value is returned as a result of
	 * multiplying the last column of the matrix by 1.0
	 *
	 * @param vec
	 *            vec to multiply against.
	 * @param result
	 *            a vector to store the result in.
	 * @return the W value
	 */
	public function multProj(vec:Vector3f, result:Vector3f):Float {
		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;
		result.x = m00 * vx + m01 * vy + m02 * vz + m03;
		result.y = m10 * vx + m11 * vy + m12 * vz + m13;
		result.z = m20 * vx + m21 * vy + m22 * vz + m23;
		return m30 * vx + m31 * vy + m32 * vz + m33;
	}

	/**
	 * `multVec4` multiplies a `Vector4f` about a rotation
	 * matrix. The resulting vector is returned.
	 *
	 * @param vec
	 *            vec to multiply against.
	 * @param store
	 *            a vector to store the result in. Created if null is passed.
	 * @return the rotated vector.
	 */
	public function multVec4(vec:Vector4f, result:Vector4f = null):Vector4f {
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
	 * `mult` multiplies a vector about a rotation matrix. The
	 * resulting vector is returned.
	 *
	 * @param vec
	 *            vec to multiply against.
	 * @param store
	 *            a vector to store the result in.  created if null is passed.
	 * @return the rotated vector.
	 */
	public function multVec4Across(vec:Vector4f, result:Vector4f = null):Vector4f {
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
	* `mult` multiplies a quaternion about a matrix. The
	* resulting vector is returned.
	*
	* @param vec
	*            vec to multiply against.
	* @param store
	*            a quaternion to store the result in.  created if null is passed.
	* @return store = this * vec
	*/
	public function multQuat(quat:Quaternion, result:Quaternion = null):Quaternion {
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
	public function multQuatLocal(rotation:Quaternion):Void {
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
	public function invert(result:Matrix4f = null):Matrix4f {
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

		if (FastMath.abs(fDet) <= 0) {
			throw ("This matrix cannot be inverted");
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
	public inline function invertLocal():Matrix4f {
		return invert(this);
	}

	/**
	 * Places the adjoint of this matrix in store (creates store if null.)
	 *
	 * @param store
	 *            The matrix to store the result in.  If null, a new matrix is created.
	 * @return store
	 */
	public function adjoint(result:Matrix4f = null):Matrix4f {
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

	public inline function setTransform(position:Vector3f, scale:Vector3f, rotMat:Matrix3f):Void {
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

	public inline function setTransformNoScale(position:Vector3f, rotMat:Matrix3f):Void {
		m00 = rotMat.m00;
		m01 = rotMat.m01;
		m02 = rotMat.m02;
		m03 = position.x;
		m10 = rotMat.m10;
		m11 = rotMat.m11;
		m12 = rotMat.m12;
		m13 = position.y;
		m20 = rotMat.m20;
		m21 = rotMat.m21;
		m22 = rotMat.m22;
		m23 = position.z;

		// No projection term
		m30 = 0;
		m31 = 0;
		m32 = 0;
		m33 = 1;
	}

	/**
	 * `determinant` generates the determinate of this matrix.
	 *
	 * @return the determinate
	 */
	public inline function determinant():Float {
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

	public function add(mat:Matrix4f, result:Matrix4f = null):Matrix4f {
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
	 * `add` adds the values of a parameter matrix to this matrix.
	 *
	 * @param mat
	 *            the matrix to add to this.
	 */
	public function addLocal(mat:Matrix4f):Void {
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

	public function getTranslation(result:Vector3f = null):Vector3f {
		if (result == null)
			result = new Vector3f();

		result.x = m03;
		result.y = m13;
		result.z = m23;
		return result;
	}

	private static var tmpVec:Vector3f = new Vector3f();
	/**
	 * Sets the scale.
	 *
	 * @param x
	 *            the X scale
	 * @param y
	 *            the Y scale
	 * @param z
	 *            the Z scale
	 */
	public function setScale(sx:Float,sy:Float,sz:Float):Void {
		tmpVec.setTo(m00, m10, m20);
		tmpVec.normalizeLocal().scaleLocal(sx);
		m00 = tmpVec.x;
		m10 = tmpVec.y;
		m20 = tmpVec.z;

		tmpVec.setTo(m01, m11, m21);
		tmpVec.normalizeLocal().scaleLocal(sy);
		m01 = tmpVec.x;
		m11 = tmpVec.y;
		m21 = tmpVec.z;

		tmpVec.setTo(m02, m12, m22);
		tmpVec.normalizeLocal().scaleLocal(sz);
		m02 = tmpVec.x;
		m12 = tmpVec.y;
		m22 = tmpVec.z;
	}

	public inline function setTranslation(tx:Float,ty:Float,tz:Float):Void {
		m03 = tx;
		m13 = ty;
		m23 = tz;
	}

	/**
	 * sets this matrix to that of a rotation about
	 * three axes (x, y, z). Where each axis has a specified rotation in
	 * degrees. These rotations are expressed in a single `Vector3f`
	 * object.
	 *
	 * @param rx rotationX
	 * @param ry rotationY
	 * @param rz rotationZ
	 */
	public function setAngles(rx:Float, ry:Float, rz:Float):Void {
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
	 * `setQuaternion` builds a rotation from a
	 * `Quaternion`.
	 *
	 * @param quat
	 *            the quaternion to build the rotation from.
	 * @throws NullPointerException
	 *             if quat is null.
	 */
	public inline function setQuaternion(quat:Quaternion):Void {
		quat.toMatrix4f(this);
	}

	/**
	 *
	 * `translateVect` translates a given Vector3f by the
	 * translation part of this matrix.
	 *
	 * @param data
	 *            the Vector3f to be translated.
	 */
	public inline function translateVect(vec:Vector3f):Void {
		vec.x += m03;
		vec.y += m13;
		vec.z += m23;
	}

	/**
	 *
	 * `inverseRotateVect` rotates a given Vector3f by the rotation
	 * part of this matrix.
	 *
	 * @param vec
	 *            the Vector3f to be rotated.
	 */
	public function inverseRotateVect(vec:Vector3f):Void {
		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;

		vec.x = vx * m00 + vy * m10 + vz * m20;
		vec.y = vx * m01 + vy * m11 + vz * m21;
		vec.z = vx * m02 + vy * m12 + vz * m22;
	}

	public function rotateVect(vec:Vector3f):Void {
		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;

		vec.x = vx * m00 + vy * m01 + vz * m02;
		vec.y = vx * m10 + vy * m11 + vz * m12;
		vec.z = vx * m20 + vy * m21 + vz * m22;
	}

	public function toQuaternion(result:Quaternion = null):Quaternion {
		if (result == null)
			result = new Quaternion();

		result.fromMatrix4f(this);
		return result;
	}

	public function toTranslationVector(result:Vector3f = null):Vector3f {
		if (result == null)
			result = new Vector3f();

		result.setTo(m03, m13, m23);

		return result;
	}

	/**
	 * Retreives the scale vector from the matrix and stores it into a given
	 * vector.
	 *
	 * @param the
	 *            vector where the scale will be stored
	 */
	public function toScaleVector(result:Vector3f = null):Vector3f {
		if (result == null)
			result = new Vector3f();

		result.x = Math.sqrt(m00 * m00 + m10 * m10 + m20 * m20);
		result.y = Math.sqrt(m01 * m01 + m11 * m11 + m21 * m21);
		result.z = Math.sqrt(m02 * m02 + m12 * m12 + m22 * m22);

		return result;
	}

	public inline function toMatrix3f(mat:Matrix3f = null):Matrix3f {
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

	public inline function toBuffer(result:FloatBuffer):Void {
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

	public inline function equals(m1:Matrix4f):Bool {
		return (this.m00 == m1.m00 && this.m01 == m1.m01 && this.m02 == m1.m02 && this.m03 == m1.m03
		&& this.m10 == m1.m10 && this.m11 == m1.m11 && this.m12 == m1.m12 && this.m13 == m1.m13
		&& this.m20 == m1.m20 && this.m21 == m1.m21 && this.m22 == m1.m22 && this.m23 == m1.m23
		&& this.m30 == m1.m30 && this.m31 == m1.m31 && this.m32 == m1.m32 && this.m33 == m1.m33);
	}

	public function toString():String {
		return "Matrix4f\n[" +
		m00 + "\t" + m01 + "\t" + m02 + "\t" + m03 + "\n " +
		m10 + "\t" + m11 + "\t" + m12 + "\t" + m13 + "\n " +
		m20 + "\t" + m21 + "\t" + m22 + "\t" + m23 + "\n " + m30 + "\t" +
		m31 + "\t" + m32 + "\t" + m33 + "]";
	}
}

