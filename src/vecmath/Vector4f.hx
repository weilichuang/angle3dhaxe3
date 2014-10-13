package vecmath;

/**
 * A 3-element vector that is represented by single-precision floating point 
 * x,y,z coordinates.  If this value represents a normal, then it should
 * be normalized.
 *
 */
class Vector4f
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
	
	public var w:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 0)
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
	
	public function absolute():Void
	{
		this.x = Math.abs(this.x);
		this.y = Math.abs(this.y);
		this.z = Math.abs(this.z);
		this.w = Math.abs(this.w);
	}
	
	public inline function fromVector3f(vec:Vector3f):Void
	{
		this.x = vec.x;
		this.y = vec.y;
		this.z = vec.z;
		this.w = 0.0;
	}
	
	public inline function fromVector4f(vec:Vector4f):Void
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
		this.x = a[0];
		this.y = a[1];
		this.z = a[2];
		this.w = a[3];
	}
	
	public function toArray(a:Array<Float>):Void
	{
		a[0] = this.x;
		a[1] = this.y;
		a[2] = this.z;
		a[3] = this.w;
	}
	
	public function add(vec1:Vector4f, vec2:Vector4f = null):Void
	{
		if (vec2 != null)
		{
			this.x = vec1.x + vec2.x;
			this.y = vec1.y + vec2.y;
			this.z = vec1.z + vec2.z;
			this.w = vec1.w + vec2.w;
		}
		else
		{
			this.x += vec1.x;
			this.y += vec1.y;
			this.z += vec1.z;
			this.w += vec1.w;
		}
	}
	
	public function sub(vec1:Vector4f, vec2:Vector4f = null):Void
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
	
	public function negate(vec:Vector4f = null):Void
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
	
	public function scale(s:Float, vec:Vector4f = null):Void
	{
		if (vec != null)
		{
			this.x = s * vec.x;
			this.y = s * vec.y;
			this.z = s * vec.z;
			this.w = s * vec.w;
		}
		else
		{
			this.x *= s;
			this.y *= s;
			this.z *= s;
			this.w *= s;
		}
	}
	
	public function scaleAdd(s:Float, sVec:Vector4f, aVec:Vector4f):Void
	{
		this.x = s * sVec.x + aVec.x;
		this.y = s * sVec.y + aVec.y;
		this.z = s * sVec.z + aVec.z;
		this.w = s * sVec.w + aVec.w;
	}
	
	public function equals(vec:Vector4f):Bool
	{
		return this.x == vec.x && this.y == vec.y && this.z == vec.z && this.w == vec.w;
	}
	
	public function epsilonEquals(vec:Vector4f, epsilon:Float):Bool
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
	
	public inline function lengthSquared():Float
	{
		return x * x + y * y + z * z + w * w;
	}
	
	public inline function length():Float
	{
		return Math.sqrt(x * x + y * y + z * z + w * w);
	}

	public function dot(v1:Vector4f):Float
	{
		return x * v1.x + y * v1.y + z * v1.z + w * v1.w;
	}
	
	public function normalize():Void
	{
        var norm:Float = Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w);
		if (norm != 0)
			norm = 1 / norm;
        this.x *= norm;
        this.y *= norm;
        this.z *= norm;
		this.w *= norm;
	}
	
	public function angle(v1:Vector4f):Float
	{
		var vDot:Float = this.dot(v1) / ( this.length() * v1.length());
        if( vDot < -1.0) vDot = -1.0;
        if( vDot >  1.0) vDot =  1.0;
        return Math.acos(vDot);
	}
	
	public inline function clone():Vector4f
	{
		return new Vector4f(x, y, z, w);
	}
	
	public function toString():String
	{
		return '($x, $y, $z, $w)';
	}
	
}