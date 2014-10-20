package com.bulletphysics.linearmath;
import vecmath.Matrix3f;
import vecmath.Matrix4f;
import com.bulletphysics.linearmath.MatrixUtil;
import vecmath.Quat4f;
import vecmath.Vector3f;

/**
 * Transform represents translation and rotation (rigid transform). Scaling and
 * shearing is not supported.<p>
 * <p/>
 * You can use local shape scaling or {@link UniformScalingShape} for static rescaling
 * of collision objects.
 * @author weilichuang
 */
class Transform
{
	/**
     * Rotation matrix of this Transform.
     */
	public var basis:Matrix3f = new Matrix3f();
	
	/**
     * Translation vector of this Transform.
     */
	public var origin:Vector3f = new Vector3f();
	

	public function new() 
	{
		
	}
	
	public function clone():Transform
	{
		var result:Transform = new Transform();
		result.fromTransform(this);
		return result;
	}
	
	public function fromTransform(tr:Transform):Void
	{
		basis.fromMatrix3f(tr.basis);
		origin.fromVector3f(tr.origin);
	}
	
	public function fromMatrix3f(mat:Matrix3f):Void
	{
		basis.fromMatrix3f(mat);
		origin.setTo(0, 0, 0);
	}
	
	public function fromMatrix4f(mat:Matrix4f):Void
	{
		mat.toMatrix3f(basis);
		origin.setTo(mat.m03, mat.m13, mat.m23);
	}
	
	public function transform(v:Vector3f):Void
	{
		basis.transform(v);
		v.add(origin);
	}
	
	public function setIdentity():Void
	{
		basis.setIdentity();
		origin.setTo(0, 0, 0);
	}
	
	public function inverse(tr:Transform = null):Void
	{
		if (tr != null)
		{
			this.fromTransform(tr);
		}
        basis.transpose();
		origin.scale( -1);
		basis.transform(origin);
    }

	public function mul(tr1:Transform, tr2:Transform = null):Void
	{
		if (tr2 != null)
		{
			var vec:Vector3f = tr2.origin;
			tr1.transform(vec);
			
			basis.mul(tr1.basis, tr2.basis);
			origin.fromVector3f(vec);
			return;
		}
		
		var vec:Vector3f = tr1.origin.clone();
		transform(vec);
		
		basis.mul(tr1.basis);
		origin.fromVector3f(vec);
	}
	
	private static var tmpMatrix3f:Matrix3f = new Matrix3f();
	public function invXform(inVec:Vector3f, out:Vector3f):Void
	{
		out.sub2(inVec, origin);
		
		tmpMatrix3f.fromMatrix3f(basis);
		tmpMatrix3f.transpose();
		tmpMatrix3f.transform(out);
	}
	
	public inline function getRotation(out:Quat4f):Quat4f
	{
		MatrixUtil.getRotation(basis, out);
		return out;
	}
	
	public inline function setRotation(q:Quat4f):Void
	{
		MatrixUtil.setRotation(basis, q);
	}
	
	public function setFromOpenGLMatrix(m:Array<Float>):Void
	{
		MatrixUtil.setFromOpenGLSubMatrix(basis, m);
		origin.setTo(m[12], m[13], m[14]);
	}
	
	public function getOpenGLMatrix(m:Array<Float>):Void
	{
		MatrixUtil.getOpenGLSubMatrix(basis, m);
		m[12] = origin.x;
		m[13] = origin.y;
		m[14] = origin.z;
		m[15] = 1.0;
	}
	
	public function getMatrix(out:Matrix4f):Matrix4f
	{
		out.fromMatrix3f(basis);
		out.m03 = origin.x;
		out.m13 = origin.y;
		out.m23 = origin.z;
		return out;
	}
	
	public function equals(tr:Transform):Bool
	{
		return tr.basis.equals(basis) && tr.origin.equals(origin);
	}
}