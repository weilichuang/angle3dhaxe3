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
	
	public inline function clone():Transform
	{
		var result:Transform = new Transform();
		result.fromTransform(this);
		return result;
	}
	
	public inline function fromTransform(tr:Transform):Void
	{
		basis.fromMatrix3f(tr.basis);
		origin.fromVector3f(tr.origin);
	}
	
	public inline function fromMatrix3f(mat:Matrix3f):Void
	{
		basis.fromMatrix3f(mat);
		origin.setTo(0, 0, 0);
	}
	
	public inline function fromMatrix4f(mat:Matrix4f):Void
	{
		mat.toMatrix3f(basis);
		origin.setTo(mat.m03, mat.m13, mat.m23);
	}
	
	public inline function transform(v:Vector3f):Void
	{
		basis.transform(v);
		v.add(origin);
	}
	
	public inline function setIdentity():Void
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

	private static var tmpVec:Vector3f = new Vector3f();
	public inline function mul(tr1:Transform):Void
	{
		tmpVec.fromVector3f(tr1.origin);
		transform(tmpVec);
		
		basis.mul(tr1.basis);
		origin.fromVector3f(tmpVec);
	}
	
	public inline function mul2(tr1:Transform, tr2:Transform ):Void
	{
		tmpVec.fromVector3f(tr2.origin);
		tr1.transform(tmpVec);
		
		basis.mul2(tr1.basis, tr2.basis);
		origin.fromVector3f(tmpVec);
	}
	
	private static var tmpMatrix3f:Matrix3f = new Matrix3f();
	public inline function invXform(inVec:Vector3f, out:Vector3f):Void
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
	
	public inline function equals(tr:Transform):Bool
	{
		return tr.basis.equals(basis) && tr.origin.equals(origin);
	}
}