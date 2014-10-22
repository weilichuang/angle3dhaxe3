package vecmath;

/**
 * ...
 * @author weilichuang
 */
class Matrix3f
{
	public static inline var EPS:Float = 1.0e-8;
	
	/** 
    * The first matrix element in the first row.
    */
    public var m00:Float;

  /** 
    * The second matrix element in the first row.
    */
    public var m01:Float;

  /** 
    * The third matrix element in the first row.
    */
    public var m02:Float;

  /** 
    * The first matrix element in the second row.
    */
    public var m10:Float;

  /** 
    * The second matrix element in the second row.
    */
    public var m11:Float;

  /** 
    * The third matrix element in the second row.
    */
    public var m12:Float;

  /** 
    * The first matrix element in the third row.
    */
    public var m20:Float;

  /** 
    * The second matrix element in the third row.
    */
    public var m21:Float;

  /** 
    * The third matrix element in the third row.
    */
    public var m22:Float;

	public function new(m00:Float = 1.0, m01:Float = 0.0, m02:Float = 0.0,
						m10:Float = 0.0, m11:Float = 1.0, m12:Float = 0.0,
						m20:Float = 0.0, m21:Float = 0.0, m22:Float = 1.0) 
	{
		this.m00 = m00;
		this.m01 = m01;
		this.m02 = m02;

		this.m10 = m10;
		this.m11 = m11;
		this.m12 = m12;

		this.m20 = m20;
		this.m21 = m21;
		this.m22 = m22;
	}
	
	public function clone():Matrix3f
	{
		var result:Matrix3f = new Matrix3f();
		result.fromMatrix3f(this);
		return result;
	}
	
	public inline function fromMatrix3f(m1:Matrix3f):Void
	{
		this.m00 = m1.m00;
        this.m01 = m1.m01;
        this.m02 = m1.m02;
 
        this.m10 = m1.m10;
        this.m11 = m1.m11;
        this.m12 = m1.m12;
 
        this.m20 = m1.m20;
        this.m21 = m1.m21;
        this.m22 = m1.m22;
	}
	
	public function fromArray(v:Array<Float>):Void
	{
		this.m00 = v[0];
		this.m01 = v[1];
		this.m02 = v[2];

		this.m10 = v[3];
		this.m11 = v[4];
		this.m12 = v[5];

		this.m20 = v[6];
		this.m21 = v[7];
		this.m22 = v[8];
	}
	
	public function setIdentity():Void
	{
		this.m00 = 1.0;
		this.m01 = 0.0;
		this.m02 = 0.0;

		this.m10 = 0.0;
		this.m11 = 1.0;
		this.m12 = 0.0;

		this.m20 = 0.0;
		this.m21 = 0.0;
		this.m22 = 1.0;
	}
	
	public function setElement(row:Int, column:Int, value:Float):Void
	{
		switch (row) 
		{
			case 0:
				switch(column)
				{
					case 0:
						m00 = value;
					case 1:
						m01 = value;
					case 2:
						m02 = value;
				}
			case 1:
				switch(column) 
				{
					case 0:
						m10 = value;
					case 1:
						m11 = value;
					case 2:
						m12 = value;
				}
			case 2:
				switch(column) 
				{
					case 0:
						m20 = value;
					case 1:
						m21 = value;
					case 2:
						m22 = value;
				}
		}
	}
	
	public function getElement(row:Int, column:Int):Float
	{
		switch (row) 
		{
			case 0:
				switch(column)
				{
					case 0:
						return m00;
					case 1:
						return m01;
					case 2:
						return m02;
				}
			case 1:
				switch(column) 
				{
					case 0:
						return m10;
					case 1:
						return m11;
					case 2:
						return m12;
				}
			case 2:
				switch(column) 
				{
					case 0:
						return m20;
					case 1:
						return m21;
					case 2:
						return m22;
				}
		}
		return 0;
	}
	
	public function setRow(row:Int, x:Float, y:Float, z:Float):Void
    {
		switch (row) 
		{
			case 0:
				this.m00 = x;
				this.m01 = y;
				this.m02 = z;

			case 1:
				this.m10 = x;
				this.m11 = y;
				this.m12 = z;

			case 2:
				this.m20 = x;
				this.m21 = y;
				this.m22 = z;
		}
    }
	
	public inline function getRow(row:Int, v:Vector3f):Void
	{
		if (row == 0)
		{
			v.setTo(m00, m01, m02);
		}
		else if (row == 1)
		{
			v.setTo(m10, m11, m12);
		}
		else if (row == 2)
		{
			v.setTo(m20, m21, m22);
		}
	}
	
	public function getColumn(column:Int, v:Vector3f):Void
	{
		if (column == 0)
		{
			v.setTo(m00, m10, m20);
		}
		else if (column == 1)
		{
			v.setTo(m01, m11, m21);
		}
		else if (column == 2)
		{
			v.setTo(m02, m12, m22);
		}
	}

	public function addFloat(scalar:Float, m1:Matrix3f = null):Void
	{
		if (m1 != null)
		{
			this.m00 = m1.m00 + scalar;
			this.m01 = m1.m01 + scalar;
			this.m02 = m1.m02 + scalar;
			this.m10 = m1.m10 + scalar;
			this.m11 = m1.m11 + scalar;
			this.m12 = m1.m12 + scalar;
			this.m20 = m1.m20 + scalar;
			this.m21 = m1.m21 + scalar;
			this.m22 = m1.m22 + scalar;
		}
		else
		{
			m00 += scalar;
			m01 += scalar;
			m02 += scalar;
			m10 += scalar;
			m11 += scalar;
			m12 += scalar;
			m20 += scalar;
			m21 += scalar;
			m22 += scalar;
		}
	}

	public function addMatrix3f(m1:Matrix3f, m2:Matrix3f = null):Void
	{
		if (m2 != null)
		{
			this.m00 = m1.m00 + m2.m00;
			this.m01 = m1.m01 + m2.m01;
			this.m02 = m1.m02 + m2.m02;

			this.m10 = m1.m10 + m2.m10;
			this.m11 = m1.m11 + m2.m11;
			this.m12 = m1.m12 + m2.m12;

			this.m20 = m1.m20 + m2.m20;
			this.m21 = m1.m21 + m2.m21;
			this.m22 = m1.m22 + m2.m22;
		}
		else
		{
			this.m00 += m1.m00;
			this.m01 += m1.m01;
			this.m02 += m1.m02;
	 
			this.m10 += m1.m10;
			this.m11 += m1.m11;
			this.m12 += m1.m12;
	 
			this.m20 += m1.m20;
			this.m21 += m1.m21;
			this.m22 += m1.m22;
		}
	}
	
	public function subMatrix3f(m1:Matrix3f, m2:Matrix3f = null):Void
	{
		if (m2 != null)
		{
			this.m00 = m1.m00 - m2.m00;
			this.m01 = m1.m01 - m2.m01;
			this.m02 = m1.m02 - m2.m02;

			this.m10 = m1.m10 - m2.m10;
			this.m11 = m1.m11 - m2.m11;
			this.m12 = m1.m12 - m2.m12;

			this.m20 = m1.m20 - m2.m20;
			this.m21 = m1.m21 - m2.m21;
			this.m22 = m1.m22 - m2.m22;
		}
		else
		{
			this.m00 -= m1.m00;
			this.m01 -= m1.m01;
			this.m02 -= m1.m02;
	 
			this.m10 -= m1.m10;
			this.m11 -= m1.m11;
			this.m12 -= m1.m12;
	 
			this.m20 -= m1.m20;
			this.m21 -= m1.m21;
			this.m22 -= m1.m22;
		}
	}

	public function transpose(m1:Matrix3f = null):Void
	{
		if (m1 != null && m1 != this)
		{
			this.m00 = m1.m00;
			this.m01 = m1.m10;
			this.m02 = m1.m20;

			this.m10 = m1.m01;
			this.m11 = m1.m11;
			this.m12 = m1.m21;

			this.m20 = m1.m02;
			this.m21 = m1.m12;
			this.m22 = m1.m22;
		}
		else
		{
			var temp:Float = this.m10;
			this.m10 = this.m01;
			this.m01 = temp;

			temp = this.m20;
			this.m20 = this.m02;
			this.m02 = temp;

			temp = this.m21;
			this.m21 = this.m12;
			this.m12 = temp;
		}
	}
	
	public function setQuat4f(q1:Quat4f):Void
	{
		this.m00 = 1.0 - 2.0 * q1.y * q1.y - 2.0 * q1.z * q1.z;
		this.m10 = 2.0 * (q1.x * q1.y + q1.w * q1.z);
		this.m20 = 2.0 * (q1.x * q1.z - q1.w * q1.y);

		this.m01 = 2.0 * (q1.x * q1.y - q1.w * q1.z);
		this.m11 = 1.0 - 2.0 * q1.x * q1.x - 2.0 * q1.z * q1.z;
		this.m21 = 2.0 * (q1.y * q1.z + q1.w * q1.x);

		this.m02 = 2.0 * (q1.x * q1.z + q1.w * q1.y);
		this.m12 = 2.0 * (q1.y * q1.z - q1.w * q1.x);
		this.m22 = 1.0 - 2.0 * q1.x * q1.x - 2.0 * q1.y * q1.y;
	}
	
	/**
	 * <code>determinant</code> generates the determinate of this matrix.
	 *
	 * @return the determinate
	 */
	public function determinant():Float
	{
		var fCo00:Float = m11 * m22 - m12 * m21;
		var fCo10:Float = m12 * m20 - m10 * m22;
		var fCo20:Float = m10 * m21 - m11 * m20;
		var fDet:Float = m00 * fCo00 + m01 * fCo10 + m02 * fCo20;
		return fDet;
	}
	
	public function invert(m1:Matrix3f = null):Void
	{
		if(m1 != null && m1 != this)
			this.fromMatrix3f(m1);
		
		var det:Float = determinant();
		if (det == 0)
		{
			this.setZero();
			return;
		}

		var fInvDet:Float = 1 / det;

		var f00:Float = (m11 * m22 - m12 * m21) * fInvDet;
		var f01:Float = (m02 * m21 - m01 * m22) * fInvDet;
		var f02:Float = (m01 * m12 - m02 * m11) * fInvDet;
		var f10:Float = (m12 * m20 - m10 * m22) * fInvDet;
		var f11:Float = (m00 * m22 - m02 * m20) * fInvDet;
		var f12:Float = (m02 * m10 - m00 * m12) * fInvDet;
		var f20:Float = (m10 * m21 - m11 * m20) * fInvDet;
		var f21:Float = (m01 * m20 - m00 * m21) * fInvDet;
		var f22:Float = (m00 * m11 - m01 * m10) * fInvDet;

		this.m00 = f00;
		this.m01 = f01;
		this.m02 = f02;
		this.m10 = f10;
		this.m11 = f11;
		this.m12 = f12;
		this.m20 = f20;
		this.m21 = f21;
		this.m22 = f22;
	}

	public function setScale(scale:Float):Void
	{
		this.m00 = scale;
		this.m01 = 0.0;
		this.m02 = 0.0;

		this.m10 = 0.0;
		this.m11 = scale;
		this.m12 = 0.0;

		this.m20 = 0.0;
		this.m21 = 0.0;
		this.m22 = scale;
	}
	
	public function rotX(angle:Float):Void
	{
		var sinAngle:Float, cosAngle:Float;

		sinAngle = Math.sin(angle);
		cosAngle = Math.cos(angle);

		this.m00 = 1.0;
		this.m01 = 0.0;
		this.m02 = 0.0;

		this.m10 = 0.0;
		this.m11 = cosAngle;
		this.m12 = -sinAngle;

		this.m20 = 0.0;
		this.m21 = sinAngle;
		this.m22 = cosAngle;
	}
	
	public function rotY(angle:Float):Void
	{
		var sinAngle:Float, cosAngle:Float;

		sinAngle = Math.sin(angle);
		cosAngle = Math.cos(angle);

		this.m00 = cosAngle;
		this.m01 = 0.0;
		this.m02 = sinAngle;

		this.m10 = 0.0;
		this.m11 = 1.0;
		this.m12 = 0.0;

		this.m20 = -sinAngle;
		this.m21 = 0.0;
		this.m22 = cosAngle;
	}
	
	public function rotZ(angle:Float):Void
	{
		var sinAngle:Float, cosAngle:Float;

		sinAngle = Math.sin(angle);
		cosAngle = Math.cos(angle);

		this.m00 = cosAngle;
		this.m01 = -sinAngle;
		this.m02 = 0.0;

		this.m10 = sinAngle;
		this.m11 = cosAngle;
		this.m12 = 0.0;

		this.m20 = 0.0;
		this.m21 = 0.0;
		this.m22 = 1.0;
	}
	
	public function mulScalar(scalar:Float, m1:Matrix3f = null):Void
	{
		if (m1 != null)
		{
			this.m00 = scalar * m1.m00;
			this.m01 = scalar * m1.m01;
			this.m02 = scalar * m1.m02;
	 
			this.m10 = scalar * m1.m10;
			this.m11 = scalar * m1.m11;
			this.m12 = scalar * m1.m12;
	 
			this.m20 = scalar * m1.m20;
			this.m21 = scalar * m1.m21;
			this.m22 = scalar * m1.m22;
		}
		else
		{
			m00 *= scalar;
			m01 *= scalar;
			m02 *= scalar;

			m10 *= scalar;
			m11 *= scalar;
			m12 *= scalar;

			m20 *= scalar;
			m21 *= scalar;
			m22 *= scalar;
		}
	}

	public function mul(m1:Matrix3f, m2:Matrix3f = null):Void
	{
		if (m2 == null)
		{
			var m00:Float, m01:Float, m02:Float,
			m10:Float, m11:Float, m12:Float,
			m20:Float, m21:Float, m22:Float;

			m00 = this.m00 * m1.m00 + this.m01 * m1.m10 + this.m02 * m1.m20;
			m01 = this.m00 * m1.m01 + this.m01 * m1.m11 + this.m02 * m1.m21;
			m02 = this.m00 * m1.m02 + this.m01 * m1.m12 + this.m02 * m1.m22;

			m10 = this.m10 * m1.m00 + this.m11 * m1.m10 + this.m12 * m1.m20;
			m11 = this.m10 * m1.m01 + this.m11 * m1.m11 + this.m12 * m1.m21;
			m12 = this.m10 * m1.m02 + this.m11 * m1.m12 + this.m12 * m1.m22;

			m20 = this.m20 * m1.m00 + this.m21 * m1.m10 + this.m22 * m1.m20;
			m21 = this.m20 * m1.m01 + this.m21 * m1.m11 + this.m22 * m1.m21;
			m22 = this.m20 * m1.m02 + this.m21 * m1.m12 + this.m22 * m1.m22;

			this.m00 = m00; this.m01 = m01; this.m02 = m02;
			this.m10 = m10; this.m11 = m11; this.m12 = m12;
			this.m20 = m20; this.m21 = m21; this.m22 = m22;
			
			return;
		}
		
		
		if (this != m1 && this != m2) 
		{
            this.m00 = m1.m00 * m2.m00 + m1.m01 * m2.m10 + m1.m02 * m2.m20;
            this.m01 = m1.m00 * m2.m01 + m1.m01 * m2.m11 + m1.m02 * m2.m21;
            this.m02 = m1.m00 * m2.m02 + m1.m01 * m2.m12 + m1.m02 * m2.m22;

            this.m10 = m1.m10 * m2.m00 + m1.m11 * m2.m10 + m1.m12 * m2.m20;
            this.m11 = m1.m10 * m2.m01 + m1.m11 * m2.m11 + m1.m12 * m2.m21;
            this.m12 = m1.m10 * m2.m02 + m1.m11 * m2.m12 + m1.m12 * m2.m22;

            this.m20 = m1.m20 * m2.m00 + m1.m21 * m2.m10 + m1.m22 * m2.m20;
            this.m21 = m1.m20 * m2.m01 + m1.m21 * m2.m11 + m1.m22 * m2.m21;
            this.m22 = m1.m20 * m2.m02 + m1.m21 * m2.m12 + m1.m22 * m2.m22;
		} 
		else 
		{
			var m00:Float, m01:Float, m02:Float,
			  m10:Float, m11:Float, m12:Float,
			  m20:Float, m21:Float, m22:Float;

            m00 = m1.m00 * m2.m00 + m1.m01 * m2.m10 + m1.m02 * m2.m20; 
            m01 = m1.m00 * m2.m01 + m1.m01 * m2.m11 + m1.m02 * m2.m21; 
            m02 = m1.m00 * m2.m02 + m1.m01 * m2.m12 + m1.m02 * m2.m22;
 
            m10 = m1.m10 * m2.m00 + m1.m11 * m2.m10 + m1.m12 * m2.m20; 
            m11 = m1.m10 * m2.m01 + m1.m11 * m2.m11 + m1.m12 * m2.m21;
            m12 = m1.m10 * m2.m02 + m1.m11 * m2.m12 + m1.m12 * m2.m22;
 
            m20 = m1.m20 * m2.m00 + m1.m21 * m2.m10 + m1.m22 * m2.m20; 
            m21 = m1.m20 * m2.m01 + m1.m21 * m2.m11 + m1.m22 * m2.m21; 
            m22 = m1.m20 * m2.m02 + m1.m21 * m2.m12 + m1.m22 * m2.m22;

            this.m00 = m00; this.m01 = m01; this.m02 = m02;
            this.m10 = m10; this.m11 = m11; this.m12 = m12;
            this.m20 = m20; this.m21 = m21; this.m22 = m22;
		}
	}

	public function equals(m1:Matrix3f):Bool
	{
		return(this.m00 == m1.m00 && this.m01 == m1.m01 && this.m02 == m1.m02
             && this.m10 == m1.m10 && this.m11 == m1.m11 && this.m12 == m1.m12
             && this.m20 == m1.m20 && this.m21 == m1.m21 && this.m22 == m1.m22);
	}
	
	public function epsilonEquals(m1:Matrix3f,epsilon:Float):Bool
	{
		if( Math.abs( this.m00 - m1.m00) > epsilon) return false;
        if( Math.abs( this.m01 - m1.m01) > epsilon) return false;
        if( Math.abs( this.m02 - m1.m02) > epsilon) return false;

        if( Math.abs( this.m10 - m1.m10) > epsilon) return false;
        if( Math.abs( this.m11 - m1.m11) > epsilon) return false;
        if( Math.abs( this.m12 - m1.m12) > epsilon) return false;

        if( Math.abs( this.m20 - m1.m20) > epsilon) return false;
        if( Math.abs( this.m21 - m1.m21) > epsilon) return false;
        if( Math.abs( this.m22 - m1.m22) > epsilon) return false;

        return true;
	}
	
	public function setZero():Void
	{
		m00 = 0.0;
        m01 = 0.0;
        m02 = 0.0;
 
        m10 = 0.0;
        m11 = 0.0;
        m12 = 0.0;
 
        m20 = 0.0;
        m21 = 0.0;
        m22 = 0.0;
	}
	
	public function transform(vec:Vector3f, result:Vector3f = null):Void
	{
		var tx:Float = m00 * vec.x + m01 * vec.y + m02 * vec.z; 
		var ty:Float = m10 * vec.x + m11 * vec.y + m12 * vec.z; 
		var tz:Float = m20 * vec.x + m21 * vec.y + m22 * vec.z;
		
		if(result == null)
			vec.setTo(tx, ty, tz);
		else 
			result.setTo(tx, ty, tz);
	}
	
	public function toString():String
	{
		return '$m00, $m01, $m02\n$m10, $m11, $m12\n$m20, $m21, $m22\n';
	}
	
}