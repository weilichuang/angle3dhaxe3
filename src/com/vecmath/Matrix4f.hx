package com.vecmath;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;

/**
 * ...
 * @author weilichuang
 */
class Matrix4f
{
	/**
     *  The first element of the first row.
     */
    public var m00:Float;

    /**
     *  The second element of the first row.
     */
    public var m01:Float;

    /**
     *  The third element of the first row.
     */
    public var m02:Float;

    /**
     *  The fourth element of the first row.
     */
    public var m03:Float;

    /**
     *  The first element of the second row.
     */
    public var m10:Float;

    /**
     *  The second element of the second row.
     */
    public var m11:Float;

    /**
     *  The third element of the second row.
     */
    public var m12:Float;

    /**
     *  The fourth element of the second row.
     */
    public var m13:Float;

    /**
     *  The first element of the third row.
     */
    public var m20:Float;

    /**
     *  The second element of the third row.
     */
    public var m21:Float;

    /**
     * The third element of the third row.
     */
    public var m22:Float;

    /**
     * The fourth element of the third row.
     */
    public var m23:Float;

    /**
     * The first element of the fourth row.
     */
    public var m30:Float;

    /**
     * The second element of the fourth row.
     */
    public var m31:Float;

    /**
     * The third element of the fourth row.
     */
    public var m32:Float;

    /**
     * The fourth element of the fourth row.
     */
    public var m33:Float;

	public function new(m00:Float = 1.0, m01:Float = 0.0, m02:Float = 0.0, m03:Float = 0.0,
						m10:Float = 0.0, m11:Float = 1.0, m12:Float = 0.0, m13:Float = 0.0,
						m20:Float = 0.0, m21:Float = 0.0, m22:Float = 1.0, m23:Float = 0.0,
						m30:Float = 0.0, m31:Float = 0.0, m32:Float = 0.0, m33:Float = 1.0) 
	{
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
	
	public function fromMatrix4f(m1:Matrix4f):Void
	{
		this.m00 = m1.m00;
        this.m01 = m1.m01;
        this.m02 = m1.m02;
        this.m03 = m1.m03;

        this.m10 = m1.m10;
        this.m11 = m1.m11;
        this.m12 = m1.m12;
        this.m13 = m1.m13;

        this.m20 = m1.m20;
        this.m21 = m1.m21;
        this.m22 = m1.m22;
        this.m23 = m1.m23;

        this.m30 = m1.m30;
        this.m31 = m1.m31;
        this.m32 = m1.m32;
        this.m33 = m1.m33;
	}
	
	public function fromArray(v:Array<Float>):Void
	{
		this.m00 = v[ 0];
		this.m01 = v[ 1];
		this.m02 = v[ 2];
		this.m03 = v[ 3];

		this.m10 = v[ 4];
		this.m11 = v[ 5];
		this.m12 = v[ 6];
		this.m13 = v[ 7];

		this.m20 = v[ 8];
		this.m21 = v[ 9];
		this.m22 = v[10];
		this.m23 = v[11];

		this.m30 = v[12];
		this.m31 = v[13];
		this.m32 = v[14];
		this.m33 = v[15];
	}
	
	public function getTranslation(vec:Vector3f):Void
	{
		vec.x = m03;
		vec.y = m13;
		vec.z = m23;
	}
	
	public function setIdentity():Void
	{
		this.m00 = 1.0;
		this.m01 = 0.0;
		this.m02 = 0.0;
		this.m03 = 0.0;

		this.m10 = 0.0;
		this.m11 = 1.0;
		this.m12 = 0.0;
		this.m13 = 0.0;

		this.m20 = 0.0;
		this.m21 = 0.0;
		this.m22 = 1.0;
		this.m23 = 0.0;

		this.m30 = 0.0;
		this.m31 = 0.0;
		this.m32 = 0.0;
		this.m33 = 1.0;
	}
	
	public function setElement(row:Int, column:Int, value:Float):Void
	{
		#if debug
		if (row > 3 || column > 3)
		{
			throw 'OutOfBound row: $row, column: $column';
		}
		#end
		
		Reflect.setField(this, "m" + row + column, value);
	}
	
	public function getElement(row:Int, column:Int):Float
	{
		#if debug
		if (row > 3 || column > 3)
		{
			throw 'OutOfBound row: $row, column: $column';
		}
		#end
		return Reflect.field(this, "m" + row + column);
	}
	
	public function setRow(row:Int, x:Float, y:Float, z:Float, w:Float):Void
    {
		switch (row) 
		{
			case 0:
				this.m00 = x;
				this.m01 = y;
				this.m02 = z;
				this.m03 = w;

			case 1:
				this.m10 = x;
				this.m11 = y;
				this.m12 = z;
				this.m13 = w;

			case 2:
				this.m20 = x;
				this.m21 = y;
				this.m22 = z;
				this.m23 = w;

			case 3:
				this.m30 = x;
				this.m31 = y;
				this.m32 = z;
				this.m33 = w;
		}
    }
	
	public function getRow(row:Int, v:Vector4f):Void
	{
		if (row == 0)
		{
			v.setTo(m00, m01, m02, m03);
		}
		else if (row == 1)
		{
			v.setTo(m10, m11, m12, m13);
		}
		else if (row == 2)
		{
			v.setTo(m20, m21, m22, m23);
		}
		else if (row == 3)
		{
			v.setTo(m30, m31, m32, m33);
		}
	}
	
	public function getColumn(column:Int, v:Vector4f):Void
	{
		if (column == 0)
		{
			v.setTo(m00, m10, m20, m30);
		}
		else if (column == 1)
		{
			v.setTo(m01, m11, m21, m31);
		}
		else if (column == 2)
		{
			v.setTo(m02, m12, m22, m32);
		}
		else if (column == 3)
		{
			v.setTo(m03, m13, m23, m33);
		}
	}
	
	public function toMatrix3f(m1:Matrix3f):Void
	{
		m1.m00 = m00; m1.m01 = m01; m1.m02 = m02; 
		m1.m10 = m10; m1.m11 = m11; m1.m12 = m12; 
		m1.m20 = m20; m1.m21 = m21; m1.m22 = m22;
	}
	
	/**  
    * Gets the upper 3x3 values of this matrix and places them into  
    * the matrix m1.  
    * @param m1  the matrix that will hold the values 
    */
	public function getRotationScale(m1:Matrix3f):Void
	{
		m1.m00 = m00; m1.m01 = m01; m1.m02 = m02; 
		m1.m10 = m10; m1.m11 = m11; m1.m12 = m12; 
		m1.m20 = m20; m1.m21 = m21; m1.m22 = m22;
	}
	
	public function fromMatrix3f(m1:Matrix3f):Void
	{
		m00 = m1.m00; m01 = m1.m01; m02 = m1.m02;
        m10 = m1.m10; m11 = m1.m11; m12 = m1.m12;
        m20 = m1.m20; m21 = m1.m21; m22 = m1.m22;
		m30 = 0.0; m31 = 0.0; m32 = 0.0; m33 = 1.0;
	}
	
	/**
     * Sets the value of this matrix from the rotation expressed by 
     * the rotation matrix m1, the translation t1, and the scale factor.
     * The translation is not modified by the scale.
     * @param m1  the rotation component
     * @param t1  the translation component
     * @param scale  the scale component
     */
    public function fromMatrix3fAndTranslation(m1:Matrix3f, t1:Vector3f, scale:Float):Void
    {
        this.m00 = m1.m00*scale;
        this.m01 = m1.m01*scale;
        this.m02 = m1.m02*scale;
        this.m03 = t1.x;

        this.m10 = m1.m10*scale;
        this.m11 = m1.m11*scale;
        this.m12 = m1.m12*scale;
        this.m13 = t1.y;

        this.m20 = m1.m20*scale;
        this.m21 = m1.m21*scale;
        this.m22 = m1.m22*scale;
        this.m23 = t1.z;

        this.m30 = 0.0;
        this.m31 = 0.0;
        this.m32 = 0.0;
        this.m33 = 1.0;
    }
	
	public function fromScale(scale:Float):Void
	{
		this.m00 = scale;
		this.m01 = 0.0;
		this.m02 = 0.0;
		this.m03 = 0.0;

		this.m10 = 0.0;
		this.m11 = scale;
		this.m12 = 0.0;
		this.m13 = 0.0;

		this.m20 = 0.0;
		this.m21 = 0.0;
		this.m22 = scale;
		this.m23 = 0.0;

		this.m30 = 0.0;
		this.m31 = 0.0;
		this.m32 = 0.0;
		this.m33 = 1.0;
	}
	
	public function addFloat(scalar:Float,m1:Matrix4f=null):Void
	{
		if (m1 != null && m1 != this)
		{
			this.m00 = m1.m00 +  scalar;
			this.m01 = m1.m01 +  scalar;
			this.m02 = m1.m02 +  scalar;
			this.m03 = m1.m03 +  scalar;
			this.m10 = m1.m10 +  scalar;
			this.m11 = m1.m11 +  scalar;
			this.m12 = m1.m12 +  scalar;
			this.m13 = m1.m13 +  scalar;
			this.m20 = m1.m20 +  scalar;
			this.m21 = m1.m21 +  scalar;
			this.m22 = m1.m22 +  scalar;
			this.m23 = m1.m23 +  scalar;
			this.m30 = m1.m30 +  scalar;
			this.m31 = m1.m31 +  scalar;
			this.m32 = m1.m32 +  scalar;
			this.m33 = m1.m33 +  scalar;
		}
		else
		{
			m00 += scalar;
			m01 += scalar;
			m02 += scalar;
			m03 += scalar;
			m10 += scalar;
			m11 += scalar;
			m12 += scalar;
			m13 += scalar;
			m20 += scalar;
			m21 += scalar;
			m22 += scalar;
			m23 += scalar;
			m30 += scalar;
			m31 += scalar;
			m32 += scalar;
			m33 += scalar;
		}
	}
	
	public function addMatrix4f(m1:Matrix4f, m2:Matrix4f = null):Void
	{
		if (m2 == null)
		{
			this.m00 += m1.m00;
			this.m01 += m1.m01;
			this.m02 += m1.m02;
			this.m03 += m1.m03;
	 
			this.m10 += m1.m10;
			this.m11 += m1.m11;
			this.m12 += m1.m12;
			this.m13 += m1.m13;
	 
			this.m20 += m1.m20;
			this.m21 += m1.m21;
			this.m22 += m1.m22;
			this.m23 += m1.m23;
	 
			this.m30 += m1.m30;
			this.m31 += m1.m31;
			this.m32 += m1.m32;
			this.m33 += m1.m33;
			return;
		}
		
		this.m00 = m1.m00 + m2.m00;
		this.m01 = m1.m01 + m2.m01;
		this.m02 = m1.m02 + m2.m02;
		this.m03 = m1.m03 + m2.m03;

		this.m10 = m1.m10 + m2.m10;
		this.m11 = m1.m11 + m2.m11;
		this.m12 = m1.m12 + m2.m12;
		this.m13 = m1.m13 + m2.m13;

		this.m20 = m1.m20 + m2.m20;
		this.m21 = m1.m21 + m2.m21;
		this.m22 = m1.m22 + m2.m22;
		this.m23 = m1.m23 + m2.m23;

		this.m30 = m1.m30 + m2.m30;
		this.m31 = m1.m31 + m2.m31;
		this.m32 = m1.m32 + m2.m32;
		this.m33 = m1.m33 + m2.m33;
	}
	
	public function subMatrix4f(m1:Matrix4f, m2:Matrix4f = null):Void
	{
		if (m2 == null)
		{
			this.m00 -= m1.m00;
			this.m01 -= m1.m01;
			this.m02 -= m1.m02;
			this.m03 -= m1.m03;
	 
			this.m10 -= m1.m10;
			this.m11 -= m1.m11;
			this.m12 -= m1.m12;
			this.m13 -= m1.m13;
	 
			this.m20 -= m1.m20;
			this.m21 -= m1.m21;
			this.m22 -= m1.m22;
			this.m23 -= m1.m23;
	 
			this.m30 -= m1.m30;
			this.m31 -= m1.m31;
			this.m32 -= m1.m32;
			this.m33 -= m1.m33;
			return;
		}
		
		this.m00 = m1.m00 - m2.m00;
		this.m01 = m1.m01 - m2.m01;
		this.m02 = m1.m02 - m2.m02;
		this.m03 = m1.m03 - m2.m03;

		this.m10 = m1.m10 - m2.m10;
		this.m11 = m1.m11 - m2.m11;
		this.m12 = m1.m12 - m2.m12;
		this.m13 = m1.m13 - m2.m13;

		this.m20 = m1.m20 - m2.m20;
		this.m21 = m1.m21 - m2.m21;
		this.m22 = m1.m22 - m2.m22;
		this.m23 = m1.m23 - m2.m23;

		this.m30 = m1.m30 - m2.m30;
		this.m31 = m1.m31 - m2.m31;
		this.m32 = m1.m32 - m2.m32;
		this.m33 = m1.m33 - m2.m33;
	}

	public function transpose():Void
	{
		var temp:Float;

		temp = this.m10;
		this.m10 = this.m01;
		this.m01 = temp;

		temp = this.m20;
		this.m20 = this.m02;
		this.m02 = temp;

		temp = this.m30;
		this.m30 = this.m03;
		this.m03 = temp;

		temp = this.m21;
		this.m21 = this.m12;
		this.m12 = temp;

		temp = this.m31;
		this.m31 = this.m13;
		this.m13 = temp;

		temp = this.m32;
		this.m32 = this.m23;
		this.m23 = temp;
	}
	
	public function invert():Void
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

		if (fDet == 0)
		{
			this.setIdentity();
			return;
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

		this.m00 = f00;
		this.m01 = f01;
		this.m02 = f02;
		this.m03 = f03;
		this.m10 = f10;
		this.m11 = f11;
		this.m12 = f12;
		this.m13 = f13;
		this.m20 = f20;
		this.m21 = f21;
		this.m22 = f22;
		this.m23 = f23;
		this.m30 = f30;
		this.m31 = f31;
		this.m32 = f32;
		this.m33 = f33;
	}
	
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
	
	public function fromQuat4f(q1:Quat4f):Void
	{
		this.m00 = (1.0 - 2.0 * q1.y * q1.y - 2.0 * q1.z * q1.z);
        this.m10 = (2.0 * (q1.x * q1.y + q1.w * q1.z));
        this.m20 = (2.0 * (q1.x * q1.z - q1.w * q1.y));

        this.m01 = (2.0 * (q1.x * q1.y - q1.w * q1.z));
        this.m11 = (1.0 - 2.0 * q1.x * q1.x - 2.0 * q1.z * q1.z);
        this.m21 = (2.0 * (q1.y * q1.z + q1.w * q1.x));

        this.m02 = (2.0 * (q1.x * q1.z + q1.w * q1.y));
        this.m12 = (2.0 * (q1.y * q1.z - q1.w * q1.x));
        this.m22 = (1.0 - 2.0 * q1.x * q1.x - 2.0 * q1.y * q1.y);

        this.m03 = 0.0;
        this.m13 = 0.0;
        this.m23 = 0.0;

        this.m30 = 0.0;
        this.m31 = 0.0;
        this.m32 = 0.0;
        this.m33 = 1.0;
	}
	
	public function fromQTS(q1:Quat4f, t1:Vector3f, s:Float):Void
	{
		this.m00 = (s * (1.0 - 2.0 * q1.y * q1.y -2.0 * q1.z * q1.z));
		this.m10 = (s * (2.0 * (q1.x * q1.y + q1.w * q1.z)));
		this.m20 = (s * (2.0 * (q1.x * q1.z - q1.w * q1.y)));

		this.m01 = (s * (2.0 * (q1.x * q1.y - q1.w * q1.z)));
		this.m11 = (s * (1.0 - 2.0 * q1.x * q1.x -2.0 * q1.z * q1.z));
		this.m21 = (s * (2.0 * (q1.y * q1.z + q1.w * q1.x)));

		this.m02 = (s * (2.0 * (q1.x * q1.z + q1.w * q1.y)));
		this.m12 = (s * (2.0 * (q1.y * q1.z - q1.w * q1.x)));
		this.m22 = (s * (1.0 - 2.0 * q1.x * q1.x -2.0 * q1.y * q1.y));

		this.m03 = t1.x;
		this.m13 = t1.y;
		this.m23 = t1.z;

		this.m30 = 0.0;
		this.m31 = 0.0;
		this.m32 = 0.0;
		this.m33 = 1.0;
	}
	
	public function rotX(angle:Float):Void
	{
		var sinAngle:Float, cosAngle:Float;

		sinAngle = Math.sin(angle);
		cosAngle = Math.cos(angle);

		this.m00 = 1.0;
		this.m01 = 0.0;
		this.m02 = 0.0;
		this.m03 = 0.0;

		this.m10 = 0.0;
		this.m11 = cosAngle;
		this.m12 = -sinAngle;
		this.m13 = 0.0;

		this.m20 = 0.0;
		this.m21 = sinAngle;
		this.m22 = cosAngle;
		this.m23 = 0.0;

		this.m30 = 0.0;
		this.m31 = 0.0;
		this.m32 = 0.0;
		this.m33 = 1.0;
	}
	
	public function rotY(angle:Float):Void
	{
		var sinAngle:Float, cosAngle:Float;

		sinAngle = Math.sin(angle);
		cosAngle = Math.cos(angle);

		this.m00 = cosAngle;
		this.m01 = 0.0;
		this.m02 = sinAngle;
		this.m03 = 0.0;

		this.m10 = 0.0;
		this.m11 = 1.0;
		this.m12 = 0.0;
		this.m13 = 0.0;

		this.m20 = -sinAngle;
		this.m21 = 0.0;
		this.m22 = cosAngle;
		this.m23 = 0.0;

		this.m30 = 0.0;
		this.m31 = 0.0;
		this.m32 = 0.0;
		this.m33 = 1.0;
	}
	
	public function rotZ(angle:Float):Void
	{
		var sinAngle:Float, cosAngle:Float;

		sinAngle = Math.sin(angle);
		cosAngle = Math.cos(angle);

		this.m00 = cosAngle;
		this.m01 = -sinAngle;
		this.m02 = 0.0;
		this.m03 = 0.0;

		this.m10 = sinAngle;
		this.m11 = cosAngle;
		this.m12 = 0.0;
		this.m13 = 0.0;

		this.m20 = 0.0;
		this.m21 = 0.0;
		this.m22 = 1.0;
		this.m23 = 0.0;

		this.m30 = 0.0;
		this.m31 = 0.0;
		this.m32 = 0.0;
		this.m33 = 1.0;
	}
	
	public function mulScalar(scalar:Float, m1:Matrix4f = null):Void
	{
		if (m1 != null)
		{
			this.m00 = m1.m00 * scalar;
			this.m01 = m1.m01 * scalar;
			this.m02 = m1.m02 * scalar;
			this.m03 = m1.m03 * scalar;
			this.m10 = m1.m10 * scalar;
			this.m11 = m1.m11 * scalar;
			this.m12 = m1.m12 * scalar;
			this.m13 = m1.m13 * scalar;
			this.m20 = m1.m20 * scalar;
			this.m21 = m1.m21 * scalar;
			this.m22 = m1.m22 * scalar;
			this.m23 = m1.m23 * scalar;
			this.m30 = m1.m30 * scalar;
			this.m31 = m1.m31 * scalar;
			this.m32 = m1.m32 * scalar;
			this.m33 = m1.m33 * scalar;
			return;
		}
		
		m00 *= scalar;
		m01 *= scalar;
		m02 *= scalar;
		m03 *= scalar;
		m10 *= scalar;
		m11 *= scalar;
		m12 *= scalar;
		m13 *= scalar;
		m20 *= scalar;
		m21 *= scalar;
		m22 *= scalar;
		m23 *= scalar;
		m30 *= scalar;
		m31 *= scalar;
		m32 *= scalar;
		m33 *= scalar;
	}
	
	public function mul(m1:Matrix4f, m2:Matrix4f = null):Void
	{
		if (m2 == null)
		{
			var m00:Float, m01:Float, m02:Float, m03:Float,
			m10:Float, m11:Float, m12:Float, m13:Float,
			m20:Float, m21:Float, m22:Float, m23:Float,
			m30:Float, m31:Float, m32:Float, m33:Float; 

			m00 = this.m00*m1.m00 + this.m01*m1.m10 + 
				  this.m02*m1.m20 + this.m03*m1.m30;
			m01 = this.m00*m1.m01 + this.m01*m1.m11 + 
				  this.m02*m1.m21 + this.m03*m1.m31;
			m02 = this.m00*m1.m02 + this.m01*m1.m12 + 
				  this.m02*m1.m22 + this.m03*m1.m32;
			m03 = this.m00*m1.m03 + this.m01*m1.m13 + 
				  this.m02*m1.m23 + this.m03*m1.m33;

			m10 = this.m10*m1.m00 + this.m11*m1.m10 + 
				  this.m12*m1.m20 + this.m13*m1.m30; 
			m11 = this.m10*m1.m01 + this.m11*m1.m11 + 
				  this.m12*m1.m21 + this.m13*m1.m31;
			m12 = this.m10*m1.m02 + this.m11*m1.m12 + 
				  this.m12*m1.m22 + this.m13*m1.m32;
			m13 = this.m10*m1.m03 + this.m11*m1.m13 + 
				  this.m12*m1.m23 + this.m13*m1.m33;

			m20 = this.m20*m1.m00 + this.m21*m1.m10 + 
				  this.m22*m1.m20 + this.m23*m1.m30; 
			m21 = this.m20*m1.m01 + this.m21*m1.m11 + 
				  this.m22*m1.m21 + this.m23*m1.m31;
			m22 = this.m20*m1.m02 + this.m21*m1.m12 + 
				  this.m22*m1.m22 + this.m23*m1.m32;
			m23 = this.m20*m1.m03 + this.m21*m1.m13 + 
				  this.m22*m1.m23 + this.m23*m1.m33;

			m30 = this.m30*m1.m00 + this.m31*m1.m10 + 
				  this.m32*m1.m20 + this.m33*m1.m30; 
			m31 = this.m30*m1.m01 + this.m31*m1.m11 + 
				  this.m32*m1.m21 + this.m33*m1.m31;
			m32 = this.m30*m1.m02 + this.m31*m1.m12 + 
				  this.m32*m1.m22 + this.m33*m1.m32;
			m33 = this.m30*m1.m03 + this.m31*m1.m13 + 
				  this.m32*m1.m23 + this.m33*m1.m33;
	 
			this.m00 = m00; this.m01 = m01; this.m02 = m02; this.m03 = m03;
			this.m10 = m10; this.m11 = m11; this.m12 = m12; this.m13 = m13;
			this.m20 = m20; this.m21 = m21; this.m22 = m22; this.m23 = m23;
			this.m30 = m30; this.m31 = m31; this.m32 = m32; this.m33 = m33;
			return;
		}
		
		if (this != m1 && this != m2)
		{

            this.m00 = m1.m00 * m2.m00 + m1.m01 * m2.m10 + m1.m02 * m2.m20 + m1.m03 * m2.m30;
            this.m01 = m1.m00 * m2.m01 + m1.m01 * m2.m11 + m1.m02 * m2.m21 + m1.m03 * m2.m31;
            this.m02 = m1.m00 * m2.m02 + m1.m01 * m2.m12 + m1.m02 * m2.m22 + m1.m03 * m2.m32;
            this.m03 = m1.m00 * m2.m03 + m1.m01 * m2.m13 + m1.m02 * m2.m23 + m1.m03 * m2.m33;

            this.m10 = m1.m10 * m2.m00 + m1.m11 * m2.m10 + m1.m12 * m2.m20 + m1.m13 * m2.m30;
            this.m11 = m1.m10 * m2.m01 + m1.m11 * m2.m11 + m1.m12 * m2.m21 + m1.m13 * m2.m31;
            this.m12 = m1.m10 * m2.m02 + m1.m11 * m2.m12 + m1.m12 * m2.m22 + m1.m13 * m2.m32;
            this.m13 = m1.m10 * m2.m03 + m1.m11 * m2.m13 + m1.m12 * m2.m23 + m1.m13 * m2.m33;

            this.m20 = m1.m20 * m2.m00 + m1.m21 * m2.m10 +  m1.m22 * m2.m20 + m1.m23 * m2.m30;
            this.m21 = m1.m20 * m2.m01 + m1.m21 * m2.m11 + m1.m22 * m2.m21 + m1.m23 * m2.m31;
            this.m22 = m1.m20 * m2.m02 + m1.m21 * m2.m12 + m1.m22 * m2.m22 + m1.m23 * m2.m32;
            this.m23 = m1.m20 * m2.m03 + m1.m21 * m2.m13 + m1.m22 * m2.m23 + m1.m23 * m2.m33;

            this.m30 = m1.m30 * m2.m00 + m1.m31 * m2.m10 + m1.m32 * m2.m20 + m1.m33 * m2.m30;
            this.m31 = m1.m30 * m2.m01 + m1.m31 * m2.m11 + m1.m32 * m2.m21 + m1.m33 * m2.m31;
            this.m32 = m1.m30 * m2.m02 + m1.m31 * m2.m12 + m1.m32 * m2.m22 + m1.m33 * m2.m32;
            this.m33 = m1.m30 * m2.m03 + m1.m31 * m2.m13 +  m1.m32 * m2.m23 + m1.m33 * m2.m33;
		} 
		else 
		{
			
			var m00:Float, m01:Float, m02:Float, m03:Float,
			m10:Float, m11:Float, m12:Float, m13:Float,
			m20:Float, m21:Float, m22:Float, m23:Float,
			m30:Float, m31:Float, m32:Float, m33:Float; 
			
            m00 = m1.m00 * m2.m00 + m1.m01 * m2.m10 + m1.m02 * m2.m20 + m1.m03 * m2.m30;
            m01 = m1.m00 * m2.m01 + m1.m01 * m2.m11 + m1.m02 * m2.m21 + m1.m03 * m2.m31;
            m02 = m1.m00 * m2.m02 + m1.m01 * m2.m12 + m1.m02 * m2.m22 + m1.m03 * m2.m32;
            m03 = m1.m00 * m2.m03 + m1.m01 * m2.m13 + m1.m02 * m2.m23 + m1.m03 * m2.m33;
 
            m10 = m1.m10 * m2.m00 + m1.m11 * m2.m10 + m1.m12 * m2.m20 + m1.m13 * m2.m30;
            m11 = m1.m10 * m2.m01 + m1.m11 * m2.m11 + m1.m12 * m2.m21 + m1.m13 * m2.m31;
            m12 = m1.m10 * m2.m02 + m1.m11 * m2.m12 + m1.m12 * m2.m22 + m1.m13 * m2.m32;
            m13 = m1.m10 * m2.m03 + m1.m11 * m2.m13 + m1.m12 * m2.m23 + m1.m13 * m2.m33;
 
            m20 = m1.m20 * m2.m00 + m1.m21 * m2.m10 + m1.m22 * m2.m20 + m1.m23 * m2.m30;
            m21 = m1.m20 * m2.m01 + m1.m21 * m2.m11 + m1.m22 * m2.m21 + m1.m23 * m2.m31;
            m22 = m1.m20 * m2.m02 + m1.m21 * m2.m12 + m1.m22 * m2.m22 + m1.m23 * m2.m32;
            m23 = m1.m20 * m2.m03 + m1.m21 * m2.m13 + m1.m22 * m2.m23 + m1.m23 * m2.m33;
 
            m30 = m1.m30 * m2.m00 + m1.m31 * m2.m10 + m1.m32 * m2.m20 + m1.m33 * m2.m30;
            m31 = m1.m30 * m2.m01 + m1.m31 * m2.m11 + m1.m32 * m2.m21 + m1.m33 * m2.m31;
            m32 = m1.m30 * m2.m02 + m1.m31 * m2.m12 + m1.m32 * m2.m22 + m1.m33 * m2.m32;
            m33 = m1.m30 * m2.m03 + m1.m31 * m2.m13 + m1.m32 * m2.m23 + m1.m33 * m2.m33;

            this.m00 = m00; this.m01 = m01; this.m02 = m02; this.m03 = m03;
            this.m10 = m10; this.m11 = m11; this.m12 = m12; this.m13 = m13;
            this.m20 = m20; this.m21 = m21; this.m22 = m22; this.m23 = m23;
            this.m30 = m30; this.m31 = m31; this.m32 = m32; this.m33 = m33;
		}
	}
	
	public function equals(m1:Matrix4f):Bool
	{
		return(this.m00 == m1.m00 && this.m01 == m1.m01 && this.m02 == m1.m02
            && this.m03 == m1.m03 && this.m10 == m1.m10 && this.m11 == m1.m11 
            && this.m12 == m1.m12 && this.m13 == m1.m13 && this.m20 == m1.m20 
            && this.m21 == m1.m21 && this.m22 == m1.m22 && this.m23 == m1.m23
            && this.m30 == m1.m30 && this.m31 == m1.m31 && this.m32 == m1.m32
            && this.m33 == m1.m33);
	}
	
	public function epsilonEquals(m1:Matrix4f,epsilon:Float):Bool
	{
		if( Math.abs( this.m00 - m1.m00) > epsilon) return false;
        if( Math.abs( this.m01 - m1.m01) > epsilon) return false;
        if( Math.abs( this.m02 - m1.m02) > epsilon) return false;
        if( Math.abs( this.m03 - m1.m03) > epsilon) return false;

        if( Math.abs( this.m10 - m1.m10) > epsilon) return false;
        if( Math.abs( this.m11 - m1.m11) > epsilon) return false;
        if( Math.abs( this.m12 - m1.m12) > epsilon) return false;
        if( Math.abs( this.m13 - m1.m13) > epsilon) return false;

        if( Math.abs( this.m20 - m1.m20) > epsilon) return false;
        if( Math.abs( this.m21 - m1.m21) > epsilon) return false;
        if( Math.abs( this.m22 - m1.m22) > epsilon) return false;
        if( Math.abs( this.m23 - m1.m23) > epsilon) return false;

        if( Math.abs( this.m30 - m1.m30) > epsilon) return false;
        if( Math.abs( this.m31 - m1.m31) > epsilon) return false;
        if( Math.abs( this.m32 - m1.m32) > epsilon) return false;
        if( Math.abs( this.m33 - m1.m33) > epsilon) return false;

        return true;
	}
	
	public function transformVector4f(vec:Vector4f, result:Vector4f = null):Void
	{
		var x:Float = m00 * vec.x + m01 * vec.y + m02 * vec.z + m03 * vec.w;
		var y:Float = m10 * vec.x + m11 * vec.y + m12 * vec.z + m13 * vec.w;
		var z:Float = m20 * vec.x + m21 * vec.y + m22 * vec.z + m23 * vec.w;
		var w:Float = m30 * vec.x + m31 * vec.y + m32 * vec.z + m33 * vec.w;
		if (result == null)
			vec.setTo(x, y, z, w);
		else
			result.setTo(x, y, z, w);
	}
	
	public function transformVector3f(vec:Vector3f, result:Vector3f = null):Void
	{
		var x:Float = m00 * vec.x + m01 * vec.y + m02 * vec.z + m03;
		var y:Float = m10 * vec.x + m11 * vec.y + m12 * vec.z + m13;
		var z:Float = m20 * vec.x + m21 * vec.y + m22 * vec.z + m23;
		if (result == null)
			vec.setTo(x, y, z);
		else
			result.setTo(x, y, z);
	}
	
	public function setZero():Void
	{
		m00 = 0.0;
        m01 = 0.0;
        m02 = 0.0;
        m03 = 0.0;
        m10 = 0.0;
        m11 = 0.0;
        m12 = 0.0;
        m13 = 0.0;
        m20 = 0.0;
        m21 = 0.0;
        m22 = 0.0;
        m23 = 0.0;
        m30 = 0.0;
        m31 = 0.0;
        m32 = 0.0;
        m33 = 0.0;
	}
	
	public function toString():String
	{
		return '$m00, $m01, $m02, $m03\n$m10, $m11, $m12, $m13\n$m20, $m21, $m22, $m23\n$m30, $m31, $m32, $m33\n';
	}
}