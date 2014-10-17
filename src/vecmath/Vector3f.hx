package vecmath;

/**
 * A 3-element vector that is represented by single-precision floating point 
 * x,y,z coordinates.  If this value represents a normal, then it should
 * be normalized.
 *
 */
class Vector3f
{
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

	public function new(x:Float = 0, y:Float = 0, z:Float = 0)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	public function absolute(vec:Vector3f = null):Void
	{
		if (vec != null)
		{
			this.x = FastMath.fabs(vec.x);
			this.y = FastMath.fabs(vec.y);
			this.z = FastMath.fabs(vec.z);
		}
		else
		{
			this.x = FastMath.fabs(this.x);
			this.y = FastMath.fabs(this.y);
			this.z = FastMath.fabs(this.z);
		}
	}
	
	public inline function fromVector3f(vec:Vector3f):Void
	{
		this.x = vec.x;
		this.y = vec.y;
		this.z = vec.z;
	}
	
	public inline function fromArray(a:Array<Float>):Void
	{
		this.x = a[0];
		this.y = a[1];
		this.z = a[2];
	}
	
	public function toArray(a:Array<Float>):Void
	{
		a[0] = this.x;
		a[1] = this.y;
		a[2] = this.z;
	}
	
	public inline function setTo(x:Float, y:Float, z:Float):Void
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	public function add(vec1:Vector3f,vec2:Vector3f = null):Void
	{
		if (vec2 != null)
		{
			this.x = vec1.x + vec2.x;
			this.y = vec1.y + vec2.y;
			this.z = vec1.z + vec2.z;
		}
		else
		{
			this.x += vec1.x;
			this.y += vec1.y;
			this.z += vec1.z;
		}
	}

	public function sub(vec1:Vector3f, vec2:Vector3f = null):Void
	{
		if (vec2 != null)
		{
			this.x = vec1.x - vec2.x;
			this.y = vec1.y - vec2.y;
			this.z = vec1.z - vec2.z;
		}
		else
		{
			this.x -= vec1.x;
			this.y -= vec1.y;
			this.z -= vec1.z;
		}
	}
	
	public function negate(vec:Vector3f = null):Void
	{
		if (vec != null)
		{
			this.x = -vec.x;
			this.y = -vec.y;
			this.z = -vec.z;
		}
		else
		{
			this.x = -this.x;
			this.y = -this.y;
			this.z = -this.z;
		}
	}

	public function scale(s:Float, vec:Vector3f = null):Void
	{
		if (vec != null)
		{
			this.x = s * vec.x;
			this.y = s * vec.y;
			this.z = s * vec.z;
		}
		else
		{
			this.x *= s;
			this.y *= s;
			this.z *= s;
		}	
	}

	public inline function scaleAdd(s:Float, sVec:Vector3f, aVec:Vector3f):Void
	{
		this.x = s * sVec.x + aVec.x;
		this.y = s * sVec.y + aVec.y;
		this.z = s * sVec.z + aVec.z;
	}
	
	public function equals(vec:Vector3f):Bool
	{
		return this.x == vec.x && this.y == vec.y && this.z == vec.z;
	}
	
	public function epsilonEquals(vec:Vector3f, epsilon:Float):Bool
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
		
		return true;
	}
	
	public inline function lengthSquared():Float
	{
		return x * x + y * y + z * z;
	}
	
	public inline function length():Float
	{
		return Math.sqrt(x * x + y * y + z * z);
	}
	
	public inline function cross(v1:Vector3f, v2:Vector3f):Void
	{
		var tx:Float = v1.y * v2.z - v1.z * v2.y;
		var ty:Float = v2.x * v1.z - v2.z * v1.x;
		this.z = v1.x * v2.y - v1.y * v2.x;
		this.x = tx;
		this.y = ty;
	}
	
	public inline function dot(v1:Vector3f):Float
	{
		return x * v1.x + y * v1.y + z * v1.z;
	}
	
	public function normalize(vec:Vector3f = null):Void
	{
		if (vec != null)
			this.fromVector3f(vec);
			
        var norm:Float = Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
		if (norm != 0)
			norm = 1 / norm;
        this.x *= norm;
        this.y *= norm;
        this.z *= norm;
	}
	
	public function angle(v1:Vector3f):Float
	{
		var vDot:Float = this.dot(v1) / ( this.length() * v1.length());
        if( vDot < -1.0) vDot = -1.0;
        if( vDot >  1.0) vDot =  1.0;
        return Math.acos(vDot);
	}
	
	/**   
    *  Linearly interpolates between this tuple and tuple t1 and 
    *  places the result into this tuple:  this = (1-alpha)*this + alpha*t1. 
    *  @param t1  the first tuple 
    *  @param alpha  the alpha interpolation parameter   
    */    
	public function interpolate(t1:Vector3f,t2:Vector3f,alpha:Float):Void
	{  
		this.x = (1 - alpha) * t1.x + alpha * t2.x;
	    this.y = (1 - alpha) * t1.y + alpha * t2.y;
	    this.z = (1 - alpha) * t1.z + alpha * t2.z;
	} 
	
	public inline function clone():Vector3f
	{
		return new Vector3f(x, y, z);
	}
	
	public function toString():String
	{
		return '($x, $y, $z )';
	}
	
}