package org.angle3d.math;

import org.angle3d.error.Assert;
import flash.Vector;
import org.angle3d.math.Vector3f;
import org.angle3d.utils.TempVars;

/**
 * `Quaternion` defines a single example of a more general class of
 * hypercomplex Floats. Quaternions extends a rotation in three dimensions to a
 * rotation in four dimensions. This aVoids "gimbal lock" and allows for smooth
 * continuous rotation.
 *
 * Quaternion is defined by four floating point Floats: {x y z w}.
 *
 */
class Quaternion
{
	/**
	 * Represents the identity quaternion rotation (0, 0, 0, 1).
	 */
	public static var IDENTITY:Quaternion;
	
	public static var ZERO:Quaternion;
	
	public static var DIRECTION_Z:Quaternion;
	
	static function __init__():Void
	{
		IDENTITY = new Quaternion(0, 0, 0, 1);
		ZERO = new Quaternion(0, 0, 0, 0);
		DIRECTION_Z = new Quaternion();
		DIRECTION_Z.fromAxes(Vector3f.UNIT_X, Vector3f.UNIT_Y, Vector3f.UNIT_Z);
	}

	/**
	 * the x value of the vector.
	 */
	public var x:Float;

	/**
	 * the y value of the vector.
	 */
	public var y:Float;

	/**
	 * the z value of the vector.
	 */
	public var z:Float;

	/**
	 * the w value of the vector.
	 */
	public var w:Float;

	/**
     * Constructor instantiates a new `Quaternion` object from the
     * given list of parameters.
     *
     * @param x
     *            the x value of the quaternion.
     * @param y
     *            the y value of the quaternion.
     * @param z
     *            the z value of the quaternion.
     * @param w
     *            the w value of the quaternion.
     */
	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1)
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	/**
	 * sets the data in a Quaternion object from the given list
	 * of parameters.
	 *
	 * @param x
	 *            the x value of the quaternion.
	 * @param y
	 *            the y value of the quaternion.
	 * @param z
	 *            the z value of the quaternion.
	 * @param w
	 *            the w value of the quaternion.
	 * @return this
	 */
	
	public inline function setTo(x:Float, y:Float, z:Float, w:Float):Void
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	
	public inline function copyFrom(q:Quaternion):Quaternion
	{
		x = q.x;
		y = q.y;
		z = q.z;
		w = q.w;
		
		return this;
	}

	
	public inline function clone():Quaternion
	{
		return new Quaternion(x, y, z, w);
	}

	/**
	 * builds a Quaternion from the Euler rotation
	 * angles (x,y,z) aka (pitch, yaw, rall)). Note that we are applying in order: roll, yaw, pitch but
	 * we've ordered them in x, y, and z for convenience.
	 * @param xAngle
	 *            the Euler pitch of rotation (in radians). (aka Attitude, often rot
	 *            around x)
	 * @param yAngle
	 *            the Euler yaw of rotation (in radians). (aka Heading, often
	 *            rot around y)
	 * @param zAngle
	 *            the Euler roll of rotation (in radians). (aka Bank, often
	 *            rot around z)
	 * @see <a href="http://www.euclideanspace.com/maths/geometry/rotations/conversions/eulerToQuaternion/index.htm">http://www.euclideanspace.com/maths/geometry/rotations/conversions/eulerToQuaternion/index.htm</a>
	 *
	 */
	public function fromAngles(xAngle:Float, yAngle:Float, zAngle:Float):Quaternion
	{
		var angle:Float;
		var sinY:Float, sinZ:Float, sinX:Float, cosY:Float, cosZ:Float, cosX:Float;

		angle = zAngle * 0.5;
		sinZ = Math.sin(angle);
		cosZ = Math.cos(angle);
		
		angle = yAngle * 0.5;
		sinY = Math.sin(angle);
		cosY = Math.cos(angle);
		
		angle = xAngle * 0.5;
		sinX = Math.sin(angle);
		cosX = Math.cos(angle);

		var cosYXcosZ:Float = cosY * cosZ;
		var sinYXsinZ:Float = sinY * sinZ;
		var cosYXsinZ:Float = cosY * sinZ;
		var sinYXcosZ:Float = sinY * cosZ;

		x = (cosYXcosZ * sinX + sinYXsinZ * cosX);
		y = (sinYXcosZ * cosX + cosYXsinZ * sinX);
		z = (cosYXsinZ * cosX - sinYXcosZ * sinX);
		w = (cosYXcosZ * cosX - sinYXsinZ * sinX);

		normalizeLocal();
		
		return this;
	}

	
	public inline function makeIdentity():Void
	{
		x = y = z = 0;
		w = 1;
	}

	/**
	 * @return true if this Quaternion is {0,0,0,1}
	 */
	public inline function isIdentity():Bool
	{
		return (x == 0 && y == 0 && z == 0 && w == 1);
	}

	/**
	 * `toAngle` returns this quaternion converted to Euler
	 * rotation angles (yaw,roll,pitch).<br/>
	 * @param result 
	 * @return the Vector3f in which the angles are stored.
	 * @see <a href="http://www.euclideanspace.com/maths/geometry/rotations/conversions/eulerToQuaternion/index.htm">http://www.euclideanspace.com/maths/geometry/rotations/conversions/eulerToQuaternion/index.htm</a>
	 */
	public function toAngle(result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		var sqw:Float = w * w;
		var sqx:Float = x * x;
		var sqy:Float = y * y;
		var sqz:Float = z * z;
		var unit:Float = sqx + sqy + sqz + sqw; // if normalized is one, otherwise
		// is correction factor
		var test:Float = x * y + z * w;
		if (test > 0.499 * unit) // singularity at north pole
		{
			result.y = 2 * Math.atan2(x, w);
			result.z = FastMath.HALF_PI;
			result.x = 0;
		}
		else if (test < -0.499 * unit) // singularity at south pole
		{
			result.y = -2 * Math.atan2(x, w);
			result.z = -FastMath.HALF_PI;
			result.x = 0;
		}
		else
		{
			result.y = Math.atan2(2 * y * w - 2 * x * z, sqx - sqy - sqz + sqw); // roll or heading 
			result.z = Math.asin(2 * test / unit); // pitch or attitude
			result.x = Math.atan2(2 * x * w - 2 * y * z, -sqx + sqy - sqz + sqw); // yaw or bank
		}
		return result;
	}

	/**
	 * `toAngles` returns this quaternion converted to Euler
	 * rotation angles (yaw,roll,pitch).<br/>
	 * @param angles
	 *            the Vector in which the angles should be stored, or null if
	 *            you want a new Vector to be created
	 * @return the Vector in which the angles are stored.
	 * @see <a href="http://www.euclideanspace.com/maths/geometry/rotations/conversions/eulerToQuaternion/index.htm">http://www.euclideanspace.com/maths/geometry/rotations/conversions/eulerToQuaternion/index.htm</a>
	 */
	public function toAngles(result:Vector<Float> = null):Vector<Float>
	{
		if (result == null)
			result = new Vector<Float>(4);

		var sqw:Float = w * w;
		var sqx:Float = x * x;
		var sqy:Float = y * y;
		var sqz:Float = z * z;
		var unit:Float = sqx + sqy + sqz + sqw; // if normalized is one, otherwise
		// is correction factor
		var test:Float = x * y + z * w;
		if (test > 0.499 * unit) // singularity at north pole
		{
			result[1] = 2 * Math.atan2(x, w);
			result[2] = FastMath.HALF_PI;
			result[0] = 0;
		}
		else if (test < -0.499 * unit) // singularity at south pole
		{
			result[1] = -2 * Math.atan2(x, w);
			result[2] = -FastMath.HALF_PI;
			result[0] = 0;
		}
		else
		{
			result[1] = Math.atan2(2 * y * w - 2 * x * z, sqx - sqy - sqz + sqw); // roll or heading 
			result[2] = Math.asin(2 * test / unit); // pitch or attitude
			result[0] = Math.atan2(2 * x * w - 2 * y * z, -sqx + sqy - sqz + sqw); // yaw or bank
		}
		return result;
	}
	
	public function fromMatrix3f2(m00:Float, m01:Float, m02:Float,
									m10:Float, m11:Float, m12:Float,
									m20:Float,m21:Float,m22:Float):Void
	{
		// first normalize the forward (F), up (U) and side (S) vectors of the rotation matrix
        // so that the scale does not affect the rotation
        var lengthSquared:Float = m00 * m00 + m10 * m10 + m20 * m20;
        if (lengthSquared != 1 && lengthSquared != 0)
		{
            lengthSquared = 1.0 / FastMath.sqrt(lengthSquared);
            m00 *= lengthSquared;
            m10 *= lengthSquared;
            m20 *= lengthSquared;
        }
		
        lengthSquared = m01 * m01 + m11 * m11 + m21 * m21;
        if (lengthSquared != 1 && lengthSquared != 0) 
		{
            lengthSquared = 1.0 / FastMath.sqrt(lengthSquared);
            m01 *= lengthSquared;
            m11 *= lengthSquared;
            m21 *= lengthSquared;
        }
		
        lengthSquared = m02 * m02 + m12 * m12 + m22 * m22;
        if (lengthSquared != 1 && lengthSquared != 0) 
		{
            lengthSquared = 1.0 / FastMath.sqrt(lengthSquared);
            m02 *= lengthSquared;
            m12 *= lengthSquared;
            m22 *= lengthSquared;
        }

        // Use the Graphics Gems code, from 
        // ftp://ftp.cis.upenn.edu/pub/graphics/shoemake/quatut.ps.Z
        // *NOT* the "Matrix and Quaternions FAQ", which has errors!

        // the trace is the sum of the diagonal elements; see
        // http://mathworld.wolfram.com/MatrixTrace.html
        var t:Float = m00 + m11 + m22;

        // we protect the division by s by ensuring that s>=1
		
		// |w| >= .5
        if (t >= 0)
		{ 
            var s:Float = FastMath.sqrt(t + 1); // |s|>=1 ...
            w = 0.5 * s;
            s = 0.5 / s;                 // so this division isn't bad
            x = (m21 - m12) * s;
            y = (m02 - m20) * s;
            z = (m10 - m01) * s;
        } 
		else if ((m00 > m11) && (m00 > m22))
		{
            var s:Float = FastMath.sqrt(1.0 + m00 - m11 - m22); // |s|>=1
            x = s * 0.5; // |x| >= .5
            s = 0.5 / s;
            y = (m10 + m01) * s;
            z = (m02 + m20) * s;
            w = (m21 - m12) * s;
        } 
		else if (m11 > m22)
		{
            var s:Float = FastMath.sqrt(1.0 + m11 - m00 - m22); // |s|>=1
            y = s * 0.5; // |y| >= .5
            s = 0.5 / s;
            x = (m10 + m01) * s;
            z = (m21 + m12) * s;
            w = (m02 - m20) * s;
        } 
		else
		{
            var s:Float = FastMath.sqrt(1.0 + m22 - m00 - m11); // |s|>=1
            z = s * 0.5; // |z| >= .5
            s = 0.5 / s;
            x = (m02 + m20) * s;
            y = (m21 + m12) * s;
            w = (m10 - m01) * s;
        }
	}

	/**
	 *
	 * `fromRotationMatrix` generates a quaternion from a supplied
	 * matrix. This matrix is assumed to be a rotational matrix.
	 *
	 * @param matrix
	 *            the matrix that defines the rotation.
	 */
	public function fromMatrix3f(mat:Matrix3f):Quaternion
	{
		var m00:Float = mat.m00; var m01:Float = mat.m01; var m02:Float = mat.m02;
		var m10:Float = mat.m10; var m11:Float = mat.m11; var m12:Float = mat.m12;
		var m20:Float = mat.m20; var m21:Float = mat.m21; var m22:Float = mat.m22;
		
		// first normalize the forward (F), up (U) and side (S) vectors of the rotation matrix
        // so that the scale does not affect the rotation
        var lengthSquared:Float = m00 * m00 + m10 * m10 + m20 * m20;
        if (lengthSquared != 1 && lengthSquared != 0)
		{
            lengthSquared = 1.0 / FastMath.sqrt(lengthSquared);
            m00 *= lengthSquared;
            m10 *= lengthSquared;
            m20 *= lengthSquared;
        }
		
        lengthSquared = m01 * m01 + m11 * m11 + m21 * m21;
        if (lengthSquared != 1 && lengthSquared != 0) 
		{
            lengthSquared = 1.0 / FastMath.sqrt(lengthSquared);
            m01 *= lengthSquared;
            m11 *= lengthSquared;
            m21 *= lengthSquared;
        }
		
        lengthSquared = m02 * m02 + m12 * m12 + m22 * m22;
        if (lengthSquared != 1 && lengthSquared != 0) 
		{
            lengthSquared = 1.0 / FastMath.sqrt(lengthSquared);
            m02 *= lengthSquared;
            m12 *= lengthSquared;
            m22 *= lengthSquared;
        }

        // Use the Graphics Gems code, from 
        // ftp://ftp.cis.upenn.edu/pub/graphics/shoemake/quatut.ps.Z
        // *NOT* the "Matrix and Quaternions FAQ", which has errors!

        // the trace is the sum of the diagonal elements; see
        // http://mathworld.wolfram.com/MatrixTrace.html
        var t:Float = m00 + m11 + m22;

        // we protect the division by s by ensuring that s>=1
		
		// |w| >= .5
        if (t >= 0)
		{ 
            var s:Float = FastMath.sqrt(t + 1); // |s|>=1 ...
            w = 0.5 * s;
            s = 0.5 / s;                 // so this division isn't bad
            x = (m21 - m12) * s;
            y = (m02 - m20) * s;
            z = (m10 - m01) * s;
        } 
		else if ((m00 > m11) && (m00 > m22))
		{
            var s:Float = FastMath.sqrt(1.0 + m00 - m11 - m22); // |s|>=1
            x = s * 0.5; // |x| >= .5
            s = 0.5 / s;
            y = (m10 + m01) * s;
            z = (m02 + m20) * s;
            w = (m21 - m12) * s;
        } 
		else if (m11 > m22)
		{
            var s:Float = FastMath.sqrt(1.0 + m11 - m00 - m22); // |s|>=1
            y = s * 0.5; // |y| >= .5
            s = 0.5 / s;
            x = (m10 + m01) * s;
            z = (m21 + m12) * s;
            w = (m02 - m20) * s;
        } 
		else
		{
            var s:Float = FastMath.sqrt(1.0 + m22 - m00 - m11); // |s|>=1
            z = s * 0.5; // |z| >= .5
            s = 0.5 / s;
            x = (m02 + m20) * s;
            y = (m21 + m12) * s;
            w = (m10 - m01) * s;
        }

        return this;
	}

	public function fromMatrix4f(mat:Matrix4f):Void
	{
		var s:Float;

		 //Use the Graphics Gems code, from 
		 //ftp://ftp.cis.upenn.edu/pub/graphics/shoemake/quatut.ps.Z
		 //*NOT* the "Matrix and Quaternions FAQ", which has errors!

		 //the trace is the sum of the diagonal elements; see
		 //http://mathworld.wolfram.com/MatrixTrace.html
		var t:Float = mat.m00 + mat.m11 + mat.m22;

		 //we protect the division by s by ensuring that s>=1
		if (t >= 0) // |w| >= .5
		{
			s = FastMath.sqrt(t + 1); // |s|>=1 ...
			w = 0.5 * s;
			s = 0.5 / s; // so this division isn't bad
			x = (mat.m21 - mat.m12) * s;
			y = (mat.m02 - mat.m20) * s;
			z = (mat.m10 - mat.m01) * s;
		}
		else if ((mat.m00 > mat.m11) && (mat.m00 > mat.m22))
		{
			s = FastMath.sqrt(1.0 + mat.m00 - mat.m11 - mat.m22); // |s|>=1
			x = s * 0.5; // |x| >= .5
			s = 0.5 / s;
			y = (mat.m10 + mat.m01) * s;
			z = (mat.m02 + mat.m20) * s;
			w = (mat.m21 - mat.m12) * s;
		}
		else if (mat.m11 > mat.m22)
		{
			s = FastMath.sqrt(1.0 + mat.m11 - mat.m00 - mat.m22); // |s|>=1
			y = s * 0.5; // |y| >= .5
			s = 0.5 / s;
			x = (mat.m10 + mat.m01) * s;
			z = (mat.m21 + mat.m12) * s;
			w = (mat.m02 - mat.m20) * s;
		}
		else
		{
			s = FastMath.sqrt(1.0 + mat.m22 - mat.m00 - mat.m11); // |s|>=1
			z = s * 0.5; // |z| >= .5
			s = 0.5 / s;
			x = (mat.m02 + mat.m20) * s;
			y = (mat.m21 + mat.m12) * s;
			w = (mat.m10 - mat.m01) * s;
		}
	}

	/**
	 * converts this quaternion to a rotational
	 * matrix. The result is stored in result.
	 *
	 * @param result
	 *            The Matrix3f to store the result in.
	 * @return the rotation matrix representation of this quaternion.
	 */
	public inline function toMatrix3f(result:Matrix3f = null):Matrix3f
	{
		if (result == null)
			result = new Matrix3f();
			
		var norm:Float = x * x + y * y + z * z + w * w;

		 //we explicitly test norm against one here, saving a division
		 //at the cost of a test and branch.  Is it worth it?
		var s:Float = (norm == 1) ? 2 : ((norm > 0) ? 2 / norm : 0);

		// compute xs/ys/zs first to save 6 multiplications, since xs/ys/zs
		// will be used 2-4 times each.
		var xs:Float = x * s;
		var ys:Float = y * s;
		var zs:Float = z * s;
		var xx:Float = x * xs;
		var xy:Float = x * ys;
		var xz:Float = x * zs;
		var xw:Float = w * xs;
		var yy:Float = y * ys;
		var yz:Float = y * zs;
		var yw:Float = w * ys;
		var zz:Float = z * zs;
		var zw:Float = w * zs;

		// using s=2/norm (instead of 1/norm) saves 9 multiplications by 2 here
		result.m00 = 1 - (yy + zz);
		result.m01 = (xy - zw);
		result.m02 = (xz + yw);
		result.m10 = (xy + zw);
		result.m11 = 1 - (xx + zz);
		result.m12 = (yz - xw);
		result.m20 = (xz - yw);
		result.m21 = (yz + xw);
		result.m22 = 1 - (xx + yy);
		
		return result;
	}

	public function toMatrix4f(result:Matrix4f):Matrix4f
	{
		if (result == null)
			result = new Matrix4f();
			
		var norm:Float = x * x + y * y + z * z + w * w;
		// we explicitly test norm against one here, saving a division
		// at the cost of a test and branch.  Is it worth it?
		var s:Float = (norm == 1) ? 2 : ((norm > 0) ? 2 / norm : 0);

		// compute xs/ys/zs first to save 6 multiplications, since xs/ys/zs
		// will be used 2-4 times each.
		var xs:Float = x * s;
		var ys:Float = y * s;
		var zs:Float = z * s;
		var xx:Float = x * xs;
		var xy:Float = x * ys;
		var xz:Float = x * zs;
		var xw:Float = w * xs;
		var yy:Float = y * ys;
		var yz:Float = y * zs;
		var yw:Float = w * ys;
		var zz:Float = z * zs;
		var zw:Float = w * zs;

		// using s=2/norm (instead of 1/norm) saves 9 multiplications by 2 here
		result.m00 = 1 - (yy + zz);
		result.m01 = (xy - zw);
		result.m02 = (xz + yw);
		result.m03 = 0;
		result.m10 = (xy + zw);
		result.m11 = 1 - (xx + zz);
		result.m12 = (yz - xw);
		result.m13 = 0;
		result.m20 = (xz - yw);
		result.m21 = (yz + xw);
		result.m22 = 1 - (xx + yy);
		result.m23 = 0;
		result.m30 = 0;
		result.m31 = 0;
		result.m32 = 0;
		result.m33 = 1;
		
		return result;
	}
	
	
	public inline function toVector(list:Vector<Float>):Void
	{
		list[0] = x;
		list[1] = y;
		list[2] = z;
		list[3] = w;
	}

	/**
	 * `getRotationColumn` returns one of three columns specified
	 * by the parameter. This column is returned as a `Vector3f`
	 * object.  The value is retrieved as if this quaternion was first normalized.
	 *
	 * @param i
	 *            the column to retrieve. Must be between 0 and 2.
	 * @param store
	 *            the vector object to store the result in. if null, a new one
	 *            is created.
	 * @return the column specified by the index.
	 */
	public function getRotationColumn(i:Int, result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		var norm:Float = x * x + y * y + z * z + w * w;
		if (norm != 1.0)
		{
			norm = 1 / FastMath.sqrt(norm);
		}

		var xx:Float = x * x * norm;
		var xy:Float = x * y * norm;
		var xz:Float = x * z * norm;
		var xw:Float = x * w * norm;
		var yy:Float = y * y * norm;
		var yz:Float = y * z * norm;
		var yw:Float = y * w * norm;
		var zz:Float = z * z * norm;
		var zw:Float = z * w * norm;

		switch (i)
		{
			case 0:
				result.x = 1 - 2 * (yy + zz);
				result.y = 2 * (xy + zw);
				result.z = 2 * (xz - yw);
			case 1:
				result.x = 2 * (xy - zw);
				result.y = 1 - 2 * (xx + zz);
				result.z = 2 * (yz + xw);
			case 2:
				result.x = 2 * (xz + yw);
				result.y = 2 * (yz - xw);
				result.z = 1 - 2 * (xx + yy);
			default:
				Assert.assert(false, "Invalid column index. " + i);
		}

		return result;
	}

	private static var normAxis:Vector3f = new Vector3f();
	/**
	 * sets this quaternion to the values
	 * specified by an angle and a normalized axis of rotation.
	 *
	 * @param angle
	 *            the angle to rotate (in radians).
	 * @param axis
	 *            the axis of rotation (already normalized).
	 */
	public function fromAngleAxis(angle:Float, axis:Vector3f):Quaternion
	{
		axis.normalize(normAxis);
        fromAngleNormalAxis(angle, normAxis);
        return this;
	}
	
	/**
     * `fromAngleNormalAxis` sets this quaternion to the values
     * specified by an angle and a normalized axis of rotation.
     *
     * @param angle
     *            the angle to rotate (in radians).
     * @param axis
     *            the axis of rotation (already normalized).
     */
    public function fromAngleNormalAxis(angle:Float, axis:Vector3f):Quaternion
	{
        if (axis.x == 0 && axis.y == 0 && axis.z == 0)
		{
			makeIdentity();
		}
		else
		{
			var halfAngle:Float = 0.5 * angle;
			var sinAngle:Float = Math.sin(halfAngle);
			x = sinAngle * axis.x;
			y = sinAngle * axis.y;
			z = sinAngle * axis.z;
			w = Math.cos(halfAngle);
		}
		return this;
    }

	/**
	 * `toAngleAxis` sets a given angle and axis to that
	 * represented by the current quaternion. The values are stored as
	 * following: The axis is provided as a parameter and built by the method,
	 * the angle is returned as a float.
	 *
	 * @param axisStore
	 *            the object we'll store the computed axis in.
	 * @return the angle of rotation in radians.
	 */
	public function toAngleAxis(result:Vector3f = null):Float
	{
		var sqrLength:Float = x * x + y * y + z * z;
		var angle:Float;
		if (sqrLength == 0.0)
		{
			angle = 0;
			if (result != null)
			{
				result.x = 1.0;
				result.y = 0.0;
				result.z = 0.0;
			}
		}
		else
		{
			angle = 2.0 * Math.acos(w);
			if (result != null)
			{
				var invLength:Float = 1 / FastMath.sqrt(sqrLength);
				result.x = x * invLength;
				result.y = y * invLength;
				result.z = z * invLength;
			}
		}
		return angle;
	}

	/**
	 * sets this quaternion's value as an interpolation
	 * between two other quaternions.
	 *
	 * @param q1
	 *            the first quaternion.
	 * @param q2
	 *            the second quaternion.
	 * @param t
	 *            the amount to interpolate between the two quaternions.
	 */
	/**
	 * A general equation for 'slerping' unit vectors in N dimensions is:
	 * (sin((1-t)a)v1+sin(ta)v2)/sin(a)
	 * Where v1 and v2 are the vectors you're interpolating, 'a' is the angle between them,
	 * and t is the parametric value.
	 * You'll notice that the equation fails when the angle is 0 or pi. If near 0,
	 * the vectors are presumably close enough that lerp or nlerp will give acceptable results.
	 * If near pi, there isn't a unique solution, and you have a special case to consider.
	 * We can use the same equation for unit-length quaternions if we consider them as points
	 * on the 4d unit hypersphere. An adjustment that is often made is to negate one of the
	 * quaternions if the dot product between them is negative.
	 * This is because q and -q represent the same rotation,
	 * and if q1.q2 < 0, negating one of them will cause slerp to take a shorter path,
	 * which is usually desirable. (Note that this also aVoids the special case of q1 = -q2.)
	 * Here's an implementation:
	 * template <class T> Quaternion<T> Quaternion<T>::Slerp(const Quaternion<T>& q1, const Quaternion<T>& q2, T t, T epsilon)
	 * {
	 *     if (t <= (T)0.0)
	 *         return q1;
	 *     if (t >= (T)1.0)
	 *        return q2;
	 *
	 *     Quaternion<T> q3 = q2;
	 *     T c = q1.Dot(q3);
	 *
	 *     if (c < (T)0.0)
	 *     {
	 *         q3 = -q3;
	 *         c = -c;
	 *     }
	 *
	 *     if (c > (T)1.0 - epsilon)
	 *         return Normalize(Lerp(q1, q3, t)); // Lerp() = q1 + t * (q2 - q1)
	 *
	 *     T a = Math<T>::ACos©; // ACos() clamps input to [-1, 1]
	 *     return (Math<T>::Sin(((T)1.0 - t) * a) * q1 + Math<T>::Sin(t * a) * q3) / Math<T>::Sin(a);
	 * }
	 *
	 */
	public function slerp(q1:Quaternion, q2:Quaternion, interp:Float, epsilon:Float = 0.05):Void
	{
		if (interp <= 0 || q1.equals(q2))
		{
			copyFrom(q1);
			return;
		}
		else if (interp >= 1)
		{
			copyFrom(q2);
			return;
		}
		
		var math = Math;

		var q1x:Float = q1.x, q1y:Float = q1.y, q1z:Float = q1.z, q1w:Float = q1.w;
		var q2x:Float = q2.x, q2y:Float = q2.y, q2z:Float = q2.z, q2w:Float = q2.w;

		//var result : Float = q1.dot(q2);
		var result:Float = q1x * q2x + q1y * q2y + q1z * q2z + q1w * q2w;
		if (result < 0.0)
		{
			// Negate the second quaternion and the result of the dot product
			q2x = -q2x;
			q2y = -q2y;
			q2z = -q2z;
			q2w = -q2w;
			result = -result;
		}

		// set_the first and second scale for the interpolation
		var scale0:Float = 1 - interp;
		var scale1:Float = interp;

		// Check if the angle between the 2 quaternions was big enough to
		// warrant such calculations
		if (result < 1.0 - epsilon) // get_the angle between the 2 quaternions,
		{
			// and then store the sin() of that angle
			var theta:Float = math.acos(result);
			var invSinTheta:Float = 1.0 / math.sin(theta);

			var interpTheta:Float = interp * theta;

			// Calculate the scale for q1 and q2, according to the angle and
			// it's sine value
			scale0 = math.sin(theta - interpTheta) * invSinTheta;
			scale1 = math.sin(interpTheta) * invSinTheta;
		}

		// Calculate the x, y, z and w values for the quaternion by using a special
		// form of linear interpolation for quaternions.
		this.x = (scale0 * q1x) + (scale1 * q2x);
		this.y = (scale0 * q1y) + (scale1 * q2y);
		this.z = (scale0 * q1z) + (scale1 * q2z);
		this.w = (scale0 * q1w) + (scale1 * q2w);
	}

	/**
     * Sets the values of this quaternion to the nlerp from itself to q2 by blend.
     * @param q2
     * @param blend
     */
	public inline function nlerp(q2:Quaternion, blend:Float):Void
	{
		var blendI:Float = 1.0 - blend;
		if (dot(q2) < 0.0)
		{
			blend = -blend;
		}

		x = blendI * x + blend * q2.x;
		y = blendI * y + blend * q2.y;
		z = blendI * z + blend * q2.z;
		w = blendI * w + blend * q2.w;

		normalizeLocal();
	}

	/**
	 * `add` adds the values of this quaternion to those of the
	 * parameter quaternion. The result is returned as a new quaternion.
	 *
	 * @param q
	 *            the quaternion to add to this.
	 * @return the new quaternion.
	 */
	
	public inline function add(q:Quaternion):Quaternion
	{
		return new Quaternion(x + q.x, y + q.y, z + q.z, w + q.w);
	}

	/**
	 * `add` adds the values of this quaternion to those of the
	 * parameter quaternion. The result is stored in this Quaternion.
	 *
	 * @param q
	 *            the quaternion to add to this.
	 * @return This Quaternion after addition.
	 */
	
	public inline function addLocal(q:Quaternion):Void
	{
		this.x += q.x;
		this.y += q.y;
		this.z += q.z;
		this.w += q.w;
	}

	/**
	 * `subtract` subtracts the values of the parameter quaternion
	 * from those of this quaternion. The result is returned as a new
	 * quaternion.
	 *
	 * @param q
	 *            the quaternion to subtract from this.
	 * @return the new quaternion.
	 */
	
	public inline function subtract(q:Quaternion):Quaternion
	{
		return new Quaternion(x - q.x, y - q.y, z - q.z, w - q.w);
	}

	/**
	 * `subtract` subtracts the values of the parameter quaternion
	 * from those of this quaternion. The result is stored in this Quaternion.
	 *
	 * @param q
	 *            the quaternion to subtract from this.
	 * @return This Quaternion after subtraction.
	 */
	
	public inline function subtractLocal(q:Quaternion):Void
	{
		this.x -= q.x;
		this.y -= q.y;
		this.z -= q.z;
		this.w -= q.w;
	}

	/**
	 * 注意：四元数相乘不符合乘法交换律  q * p != p * q
	 * mult multiplies this quaternion by a parameter quaternion.
	 * The result is returned as a new quaternion. It should be noted that
	 * quaternion multiplication is not commutative so q * p != p * q.
	 *
	 * @param q   the quaternion to multiply this quaternion by.
	 * @param res the quaternion to store the result in.
	 * @return the new quaternion.
	 */
	public inline function mult(q:Quaternion, result:Quaternion = null):Quaternion
	{
		if (result == null)
		{
			result = new Quaternion();
		}

		var tw:Float = w, tx:Float = x, ty:Float = y, tz:Float = z;
		var qw:Float = q.w, qx:Float = q.x, qy:Float = q.y, qz:Float = q.z;

		result.x = tx * qw + ty * qz - tz * qy + tw * qx;
		result.y = -tx * qz + ty * qw + tz * qx + tw * qy;
		result.z = tx * qy - ty * qx + tz * qw + tw * qz;
		result.w = -tx * qx - ty * qy - tz * qz + tw * qw;
		return result;
	}
	
	public inline function copyMultLocal(copyQ:Quaternion,q:Quaternion):Quaternion
	{
		var tw:Float = copyQ.w, tx:Float = copyQ.x, ty:Float = copyQ.y, tz:Float = copyQ.z;
		var qw:Float = q.w, qx:Float = q.x, qy:Float = q.y, qz:Float = q.z;

		x =  tx * qw + ty * qz - tz * qy + tw * qx;
		y = -tx * qz + ty * qw + tz * qx + tw * qy;
		z =  tx * qy - ty * qx + tz * qw + tw * qz;
		w = -tx * qx - ty * qy - tz * qz + tw * qw;
		return this;
	}

	public inline function multLocal(q:Quaternion):Quaternion
	{
		var tw:Float = w, tx:Float = x, ty:Float = y, tz:Float = z;
		var qw:Float = q.w, qx:Float = q.x, qy:Float = q.y, qz:Float = q.z;

		x =  tx * qw + ty * qz - tz * qy + tw * qx;
		y = -tx * qz + ty * qw + tz * qx + tw * qy;
		z =  tx * qy - ty * qx + tz * qw + tw * qz;
		w = -tx * qx - ty * qy - tz * qz + tw * qw;
		return this;
	}
	
	public inline function multBy(q1:Quaternion, q2:Quaternion):Void
    {
		var q1x:Float = q1.x; var q1y:Float = q1.y; var q1z:Float = q1.z; var q1w:Float = q1.w;
		var q2x:Float = q2.x; var q2y:Float = q2.y; var q2z:Float = q2.z; var q2w:Float = q2.w;

		this.w = q1w * q2w - q1x * q2x - q1y * q2y - q1z * q2z;
		this.x = q1w * q2x + q2w * q1x + q1y * q2z - q1z * q2y;
		this.y = q1w * q2y + q2w * q1y - q1x * q2z + q1z * q2x;
		this.z = q1w * q2z + q2w * q1z + q1x * q2y - q1y * q2x;
	}

	/**
	 * `apply` multiplies this quaternion by a parameter matrix
	 * internally.
	 *
	 * @param matrix
	 *            the matrix to apply to this quaternion.
	 */
	public function apply(matrix:Matrix3f):Void
	{
		var oldX:Float = x, oldY:Float = y, oldZ:Float = z, oldW:Float = w;
		fromMatrix3f(matrix);
		var tempX:Float = x, tempY:Float = y, tempZ:Float = z, tempW:Float = w;

		x = oldX * tempW + oldY * tempZ - oldZ * tempY + oldW * tempX;
		y = -oldX * tempZ + oldY * tempW + oldZ * tempX + oldW * tempY;
		z = oldX * tempY - oldY * tempX + oldZ * tempW + oldW * tempZ;
		w = -oldX * tempX - oldY * tempY - oldZ * tempZ + oldW * tempW;
	}

	/**
	 *
	 * `fromAxes` creates a Quaternion that
	 * represents the coordinate system defined by three axes. These axes are
	 * assumed to be orthogonal and no error checking is applied. Thus, the user
	 * must insure that the three axes being provided indeed represents a proper
	 * right handed coordinate system.
	 *
	 * @param xAxis vector representing the x-axis of the coordinate system.
	 * @param yAxis vector representing the y-axis of the coordinate system.
	 * @param zAxis vector representing the z-axis of the coordinate system.
	 */
	public function fromAxes(xAxis:Vector3f, yAxis:Vector3f, zAxis:Vector3f):Void
	{
		fromMatrix3f2(xAxis.x, yAxis.x, zAxis.x,
					xAxis.y, yAxis.y, zAxis.y,
					xAxis.z, yAxis.z, zAxis.z );
	}

	/**
	 *
	 * `toAxes` takes in an array of three vectors. Each vector
	 * corresponds to an axis of the coordinate system defined by the quaternion
	 * rotation.
	 *
	 * @param axis
	 *            the array of vectors to be filled.
	 */
	public function toAxes(axis:Array<Vector3f>):Void
	{
		var tempMat:Matrix3f = new Matrix3f();
		toMatrix3f(tempMat);
		axis[0] = tempMat.copyColumnTo(0, axis[0]);
		axis[1] = tempMat.copyColumnTo(1, axis[1]);
		axis[2] = tempMat.copyColumnTo(2, axis[2]);
	}

	/**
	 * `mult` multiplies this quaternion by a parameter vector. The
	 * result is stored in the supplied vector
	 *
	 * @param v
	 *            the vector to multiply this quaternion by.
	 * @return v
	 */
	/**
	 * nVidia SDK implementation
	 * Vector3 uv, uuv;
	 * Vector3 qvec(x, y, z);
	 * uv = qvec.crossProduct(v);
	 * uuv = qvec.crossProduct(uv);
	 * uv *= (2.0f * w);
	 * uuv *= 2.0f;
	 * return v + uv + uuv;
	 */
	public inline function multVector(v:Vector3f, result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		var vx:Float = v.x, vy:Float = v.y, vz:Float = v.z;

		var xx:Float = x * x;
		var yy:Float = y * y;
		var zz:Float = z * z;
		var ww:Float = w * w;

		var x2:Float = x * 2;
		var y2:Float = y * 2;
		var z2:Float = z * 2;
		var w2:Float = w * 2;

		var tempX:Float, tempY:Float;
		tempX = ww * vx + y2 * w * vz - z2 * w * vy + xx * vx + y2 * x * vy + z2 * x * vz - zz * vx - yy * vx;
		tempY = x2 * y * vx + yy * vy + z2 * y * vz + w2 * z * vx - zz * vy + ww * vy - x2 * w * vz - xx * vy;
		result.z = x2 * z * vx + y2 * z * vy + zz * vz - w2 * y * vx - yy * vz + w2 * x * vy - xx * vz + ww * vz;
		result.x = tempX;
		result.y = tempY;

		return result;
	}

	public function multVecLocal(vec:Vector3f):Vector3f
	{
		var vx:Float = vec.x, vy:Float = vec.y, vz:Float = vec.z;

		var xx:Float = x * x;
		var yy:Float = y * y;
		var zz:Float = z * z;
		var ww:Float = w * w;

		var x2:Float = x * 2;
		var y2:Float = y * 2;
		var z2:Float = z * 2;
		var w2:Float = w * 2;

		var tempX:Float, tempY:Float;
		tempX = ww * vx + y2 * w * vz - z2 * w * vy + xx * vx + y2 * x * vy + z2 * x * vz - zz * vx - yy * vx;
		tempY = x2 * y * vx + yy * vy + z2 * y * vz + w2 * z * vx - zz * vy + ww * vy - x2 * w * vz - xx * vy;
		vec.z = x2 * z * vx + y2 * z * vy + zz * vz - w2 * y * vx - yy * vz + w2 * x * vy - xx * vz + ww * vz;
		vec.x = tempX;
		vec.y = tempY;
		
		return vec;
	}

	/**
	 * `mult` multiplies this quaternion by a parameter scalar. The
	 * result is returned as a new quaternion.
	 *
	 * @param scalar
	 *            the quaternion to multiply this quaternion by.
	 * @return the new quaternion.
	 */
	public function scale(value:Float):Quaternion
	{
		return new Quaternion(value * x, value * y, value * z, value * w);
	}

	/**
	 * `mult` multiplies this quaternion by a parameter scalar. The
	 * result is stored locally.
	 *
	 * @param scalar
	 *            the quaternion to multiply this quaternion by.
	 * @return this.
	 */
	
	public inline function scaleLocal(value:Float):Quaternion
	{
		x *= value;
		y *= value;
		z *= value;
		w *= value;
		return this;
	}

	/**
	 * `dot` calculates and returns the dot product of this
	 * quaternion with that of the parameter quaternion.
	 *
	 * @param q
	 *            the quaternion to calculate the dot product of.
	 * @return the dot product of this and the parameter quaternion.
	 */
	
	public inline function dot(q:Quaternion):Float
	{
		return x * q.x + y * q.y + z * q.z + w * q.w;
	}

	/**
	 * `norm` returns the norm of this quaternion. This is the dot
	 * product of this quaternion with itself.
	 *
	 * @return the norm of the quaternion.
	 */
	
	public inline function getNorm():Float
	{
		return x * x + y * y + z * z + w * w;
	}

	/**
	 * `normalize` normalizes the current Quaternion
	 */
	public inline function normalizeLocal():Void
	{
		var norm:Float = getNorm();
		if (norm != 0)
		{
			norm = 1 / FastMath.sqrt(norm);
			x *= norm;
			y *= norm;
			z *= norm;
			w *= norm;
			
		}
		else
		{
			x = y = z = w = 0.0;
		}
	}

	/**
	 * `inverse` returns the inverse of this quaternion as a new
	 * quaternion. If this quaternion does not have an inverse (if its normal is
	 * 0 or less), then null is returned.
	 *
	 * @return the inverse of this quaternion or null if the inverse does not
	 *         exist.
	 */
	public function inverse():Quaternion
	{
		var norm:Float = x * x + y * y + z * z + w * w;
		if (norm > 0.0)
		{
			var invNorm:Float = 1.0 / norm;
			return new Quaternion(-x * invNorm, -y * invNorm, -z * invNorm, w * invNorm);
		}
		// return an invalid result to flag the error
		return null;
	}

	/**
	 * 假设已经归一化
	 */
	
	public inline function unitInverse():Quaternion
	{
		return new Quaternion(-x, -y, -z, w);
	}

	/**
	 * `inverse` calculates the inverse of this quaternion and
	 * returns this quaternion after it is calculated. If this quaternion does
	 * not have an inverse (if it's norma is 0 or less), nothing happens
	 *
	 * @return the inverse of this quaternion
	 */
	public function inverseLocal():Quaternion
	{
		var norm:Float = getNorm();
		if (norm > 0.0)
		{
			norm = 1.0 / norm;
			x *= -norm;
			y *= -norm;
			z *= -norm;
			w *= norm;
		}
		return this;
	}

	/**
	 * 假设已经归一化
	 */
	
	public inline function uintInverseLocal():Void
	{
		x = -x;
		y = -y;
		z = -z;
	}

	/**
	 * `negate` inverts the values of the quaternion.
	 *
	 */
	
	public inline function negate():Void
	{
		x *= -1;
		y *= -1;
		z *= -1;
		w *= -1;
	}

	/**
	 * `lookAt` is a convienence method for auto-setting the
	 * quaternion based on a direction and an up vector. It computes
	 * the rotation to transform the z-axis to point into 'direction'
	 * and the y-axis to 'up'.
	 *
	 * @param direction
	 *            where to look at in terms of local coordinates
	 * @param up
	 *            a vector indicating the local up direction.
	 *            (typically {0, 1, 0} in Angle3D.)
	 */
	public function lookAt(direction:Vector3f, up:Vector3f):Void
	{
		var tVars:TempVars = TempVars.getTempVars();

		tVars.vect3.copyFrom(direction).normalizeLocal();
		tVars.vect1.copyFrom(up).crossLocal(direction).normalizeLocal();
		tVars.vect2.copyFrom(direction).crossLocal(tVars.vect1).normalizeLocal();
		fromAxes(tVars.vect1, tVars.vect2, tVars.vect3);

		tVars.release();
	}

	public inline function equals(other:Quaternion):Bool
	{
		return x == other.x && y == other.y && z == other.z && w == other.w;
	}

	public function toString():String
	{
		return 'Quaternion($x,$y,$z,$w)';
	}
}

