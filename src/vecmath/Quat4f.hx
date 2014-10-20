package vecmath;
import de.polygonal.core.math.Mathematics;

/**
 * A 3-element vector that is represented by single-precision floating point 
 * x,y,z coordinates.  If this value represents a normal, then it should
 * be normalized.
 *
 */
class Quat4f
{
	public static inline var EPS:Float = 0.000001;
	public static inline var EPS2:Float = 1.0e-30;
	public static inline var PIO2:Float = 1.57079632679;
	/**
     * The x coordinate.
     */
	public var x:Float;
	
	/**
     * The y coordinate.
     */
	public var y:Float;
	
	/**
     * The z coordinate.
     */
	public var z:Float;
	
	public var w:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1)
	{
		var mag:Float = Mathematics.invSqrt(x * x + y * y + z * z + w * w);
		this.x = x * mag;
		this.y = y * mag;
		this.z = z * mag;
		this.w = w * mag;
	}
	
	public inline function fromQuat4f(vec:Quat4f):Void
	{
		this.x = vec.x;
		this.y = vec.y;
		this.z = vec.z;
		this.w = vec.w;
	}
	
	public inline function setTo(x:Float, y:Float, z:Float, w:Float):Void
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
	
	public inline function fromArray(a:Array<Float>):Void
	{
		var mag:Float = Mathematics.invSqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2] + a[3] * a[3]);
		this.x = a[0] * mag;
		this.y = a[1] * mag;
		this.z = a[2] * mag;
		this.w = a[3] * mag;
	}
	
	public function toArray(a:Array<Float>):Void
	{
		a[0] = this.x;
		a[1] = this.y;
		a[2] = this.z;
		a[3] = this.w;
	}
	
	public inline function add(vec1:Quat4f):Void
	{
		this.x += vec1.x;
		this.y += vec1.y;
		this.z += vec1.z;
		this.w += vec1.w;
	}
	
	public inline function add2(vec1:Quat4f,vec2:Quat4f):Void
	{
		this.x = vec1.x + vec2.x;
		this.y = vec1.y + vec2.y;
		this.z = vec1.z + vec2.z;
		this.w = vec1.w + vec2.w;
	}
	
	public function sub(vec1:Quat4f,vec2:Quat4f = null):Void
	{
		if (vec2 != null)
		{
			this.x = vec1.x - vec2.x;
			this.y = vec1.y - vec2.y;
			this.z = vec1.z - vec2.z;
			this.w = vec1.w - vec2.w;
		}
		else
		{
			this.x -= vec1.x;
			this.y -= vec1.y;
			this.z -= vec1.z;
			this.w -= vec1.w;			
		}
	}
	
	public function negate(vec:Quat4f = null):Void
	{
		if (vec != null)
		{
			this.x = -vec.x;
			this.y = -vec.y;
			this.z = -vec.z;
			this.w = -vec.w;
		}
		else
		{
			this.x = -this.x;
			this.y = -this.y;
			this.z = -this.z;
			this.w = -this.w;
		}
	}
	
	public inline function scale(s:Float):Void
	{
		this.x *= s;
		this.y *= s;
		this.z *= s;
		this.w *= s;
	}
	
	public inline function scale2(s:Float, vec:Quat4f):Void
	{
		this.x = s * vec.x;
		this.y = s * vec.y;
		this.z = s * vec.z;
		this.w = s * vec.w;
	}
	
	public function scaleAdd(s:Float, sVec:Quat4f, aVec:Quat4f):Void
	{
		this.x = s * sVec.x + aVec.x;
		this.y = s * sVec.y + aVec.y;
		this.z = s * sVec.z + aVec.z;
		this.w = s * sVec.w + aVec.w;
	}
	
	public function equals(vec:Quat4f):Bool
	{
		return this.x == vec.x && this.y == vec.y && this.z == vec.z && this.w == vec.w;
	}
	
	public function epsilonEquals(vec:Quat4f, epsilon:Float):Bool
	{
		var diff:Float = this.x - vec.x;
		if ((diff < 0 ? -diff : diff) > epsilon)
			return false;
			
		diff = this.y - vec.y;
		if ((diff < 0 ? -diff : diff) > epsilon)
			return false;
		
		diff = this.z - vec.z;
		if ((diff < 0 ? -diff : diff) > epsilon)
			return false;
			
		diff = this.w - vec.w;
		if ((diff < 0 ? -diff : diff) > epsilon)
			return false;
		
		return true;
	}
	
	public function conjugateBy(t1:Quat4f):Void
	{
		this.x = -t1.x;
		this.y = -t1.y;
		this.z = -t1.z;
		this.w = t1.w;
	}
	
	public function conjugate():Void
	{
		this.x = -this.x;
		this.y = -this.y;
		this.z = -this.z;
	}
	
	/**
    * Sets the value of this quaternion to the quaternion product of
    * quaternions q1 and q2 (this = q1 * q2).  
    * Note that this is safe for aliasing (e.g. this can be q1 or q2).
    * @param q1 the first quaternion
    * @param q2 the second quaternion
    */
	public function mul(q1:Quat4f, q2:Quat4f = null):Void
    {
		if (q2 == null)
		{
			var tx:Float, ty:Float, tw:Float; 

			tw = this.w * q1.w - this.x * q1.x - this.y * q1.y - this.z * q1.z;
			tx = this.w * q1.x + q1.w * this.x + this.y * q1.z - this.z * q1.y;
			ty = this.w * q1.y + q1.w * this.y - this.x * q1.z + this.z * q1.x;
			this.z = this.w * q1.z + q1.w * this.z + this.x * q1.y - this.y * q1.x;
			this.w = tw;
			this.x = tx;
			this.y = ty;
			return;
		}
		
		if (this != q1 && this != q2) 
		{
		    this.w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z;
		    this.x = q1.w * q2.x + q2.w * q1.x + q1.y * q2.z - q1.z * q2.y;
		    this.y = q1.w * q2.y + q2.w * q1.y - q1.x * q2.z + q1.z * q2.x;
		    this.z = q1.w * q2.z + q2.w * q1.z + q1.x * q2.y - q1.y * q2.x;
		} 
		else 
		{
			var tx:Float, ty:Float, tw:Float;

			tw = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z;
			tx = q1.w * q2.x + q2.w * q1.x + q1.y * q2.z - q1.z * q2.y;
			ty = q1.w * q2.y + q2.w * q1.y - q1.x * q2.z + q1.z * q2.x;
			this.z = q1.w * q2.z + q2.w * q1.z + q1.x * q2.y - q1.y * q2.x;
			this.w = tw;
			this.x = tx;
			this.y = ty;
		}
	}
	
	/** 
   * Multiplies quaternion q1 by the inverse of quaternion q2 and places
   * the value into this quaternion.  The value of both argument quaternions 
   * is preservered (this = q1 * q2^-1).
   * @param q1 the first quaternion
   * @param q2 the second quaternion
   */ 
	public function mulInverse(q1:Quat4f, q2:Quat4f = null):Void
	{
		if (q2 == null)
		{
			var tempQuat:Quat4f = q1.clone();
			tempQuat.inverse();
			
			this.mul(tempQuat);
			return;
		}
		
		var tempQuat:Quat4f = q2.clone();
		tempQuat.inverse();
		
		this.mul(q1, q2);
	}
	
	/**
	* Sets the value of this quaternion to quaternion inverse of quaternion q1.
	* @param q1 the quaternion to be inverted
	*/
	public function inverse(q1:Quat4f = null):Void
	{
		if (q1 == null)
		{
			var norm:Float = (this.w * this.w + this.x * this.x + this.y * this.y + this.z * this.z);
			if (norm != 0)
				norm = 1 / norm;
			this.w *=  norm;
			this.x *= -norm;
			this.y *= -norm;
			this.z *= -norm;
			return;
		}
		
		var norm:Float = (q1.w * q1.w + q1.x * q1.x + q1.y * q1.y + q1.z * q1.z);
		if (norm != 0)
			norm = 1 / norm;
		this.w =  norm * q1.w;
		this.x = -norm * q1.x;
		this.y = -norm * q1.y;
		this.z = -norm * q1.z;
	}

	public function normalize():Void
	{
        var norm:Float = Mathematics.sqrt(this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w);
		if (norm > 0)
		{
			norm = 1 / norm;
			this.x *= norm;
			this.y *= norm;
			this.z *= norm;
			this.w *= norm;
		}
		else
		{
			this.x = 0;
			this.y = 0;
			this.z = 0;
			this.w = 0;
		}
        
	}
	
	public function setMatrix4f(m1:Matrix4f):Void
	{
		var ww:Float = 0.25 * (m1.m00 + m1.m11 + m1.m22 + m1.m33);

        if (ww >= 0)
	    {
		   if (ww >= EPS2)
		   {
			   this.w = Mathematics.sqrt(ww);
			   ww =  0.25 / this.w;
			   this.x = (m1.m21 - m1.m12) * ww;
			   this.y = (m1.m02 - m1.m20) * ww;
			   this.z = (m1.m10 - m1.m01) * ww;
			   return;
		   } 
        } 
	    else
	    {
		   this.w = 0;
		   this.x = 0;
		   this.y = 0;
		   this.z = 1;
		   return;
        }

        this.w = 0;
        ww = -0.5 * (m1.m11 + m1.m22);
       
        if (ww >= 0)
	    { 
		    if (ww >= EPS2)
		    {
			   this.x = Mathematics.sqrt(ww);
			   ww = 0.5 * this.x;
			   this.y = m1.m10 * ww;
			   this.z = m1.m20 * ww;
			   return;
		    }
        } 
		else
		{
		   this.x = 0;
		   this.y = 0;
		   this.z = 1;
		   return;
        }
     
        this.x = 0;
        ww = 0.5 * (1.0 - m1.m22);

        if (ww >= EPS2) 
		{
		   this.y = Mathematics.sqrt(ww);
		   this.z = m1.m21 / (2.0 * this.y);
		   return;
        }
     
        this.y = 0;
        this.z = 1;
	}

	public function setMatrix3f(m1:Matrix3f):Void
	{
		var ww:Float = 0.25 * (m1.m00 + m1.m11 + m1.m22 + 1.0);

        if (ww >= 0)
	    {
		   if (ww >= EPS2)
		   {
			   this.w = Mathematics.sqrt(ww);
			   ww =  0.25 / this.w;
			   this.x = (m1.m21 - m1.m12) * ww;
			   this.y = (m1.m02 - m1.m20) * ww;
			   this.z = (m1.m10 - m1.m01) * ww;
			   return;
		   } 
        } 
	    else
	    {
		   this.w = 0;
		   this.x = 0;
		   this.y = 0;
		   this.z = 1;
		   return;
        }

        this.w = 0;
        ww = -0.5 * (m1.m11 + m1.m22);
       
        if (ww >= 0)
	    { 
		    if (ww >= EPS2)
		    {
			   this.x = Mathematics.sqrt(ww);
			   ww = 0.5  * this.x;
			   this.y = m1.m10 * ww;
			   this.z = m1.m20 * ww;
			   return;
		    }
        } 
		else
		{
		   this.x = 0;
		   this.y = 0;
		   this.z = 1;
		   return;
        }
     
        this.x = 0;
        ww = 0.5 * (1.0 - m1.m22);

        if (ww >= EPS2) 
		{
		   this.y = Mathematics.sqrt(ww);
		   this.z = m1.m21 / (2.0 * this.y);
		   return;
        }
     
        this.y = 0;
        this.z = 1;
	}
	
	public function interpolate(alpha:Float, q1:Quat4f, q2:Quat4f = null):Void
	{
		// From "Advanced Animation and Rendering Techniques"
		// by Watt and Watt pg. 364, function as implemented appeared to be 
		// incorrect.  Fails to choose the same quaternion for the double
		// covering. Resulting in change of direction for rotations.
		// Fixed function to negate the first quaternion in the case that the
		// dot product of q1 and this is negative. Second case was not needed. 
		
		var dot:Float, s1:Float, s2:Float, om:Float, sinom:Float;
		
		if (q2 != null)
		{
			dot = q2.x * q1.x + q2.y * q1.y + q2.z * q1.z + q2.w * q1.w;

			if ( dot < 0 )
			{
				// negate quaternion
				q1.x = -q1.x;  q1.y = -q1.y;  q1.z = -q1.z;  q1.w = -q1.w;
				dot = -dot;
			}

			if ( (1.0 - dot) > EPS )
			{
				om = Math.acos(dot);
				sinom = Math.sin(om);
				s1 = Math.sin((1.0 - alpha) * om) / sinom;
				s2 = Math.sin( alpha * om) / sinom;
			} 
			else
			{
				s1 = 1.0 - alpha;
				s2 = alpha;
			}
			w = (s1 * q1.w + s2 * q2.w);
			x = (s1 * q1.x + s2 * q2.x);
			y = (s1 * q1.y + s2 * q2.y);
			z = (s1 * q1.z + s2 * q2.z);
			return;
		}

		dot = x * q1.x + y * q1.y + z * q1.z + w * q1.w;

		if ( dot < 0 ) 
		{
			// negate quaternion
		    q1.x = -q1.x;  q1.y = -q1.y;  q1.z = -q1.z;  q1.w = -q1.w;
		    dot = -dot;
		}

		if ( (1.0 - dot) > EPS ) 
		{
			om = Math.acos(dot);
			sinom = Math.sin(om);
			s1 = Math.sin((1.0 - alpha) * om) / sinom;
			s2 = Math.sin( alpha * om) / sinom;
		} 
		else
		{
			s1 = 1.0 - alpha;
			s2 = alpha;
		}

		w = (s1 * w + s2 * q1.w);
		x = (s1 * x + s2 * q1.x);
		y = (s1 * y + s2 * q1.y);
		z = (s1 * z + s2 * q1.z);
	}
	
	public inline function clone():Quat4f
	{
		return new Quat4f(x, y, z, w);
	}
	
	public function toString():String
	{
		return '($x, $y, $z, $w)';
	}
	
}