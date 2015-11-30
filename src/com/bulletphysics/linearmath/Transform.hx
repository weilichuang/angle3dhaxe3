package com.bulletphysics.linearmath;
import com.bulletphysics.linearmath.MatrixUtil;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Vector3f;

/**
 * Transform represents translation and rotation (rigid transform). Scaling and
 * shearing is not supported.<p>
 * <p/>
 * You can use local shape scaling or {UniformScalingShape} for static rescaling
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
		basis.copyFrom(tr.basis);
		origin.copyFrom(tr.origin);
	}
	
	public inline function fromMatrix3f(mat:Matrix3f):Void
	{
		basis.copyFrom(mat);
		origin.setTo(0, 0, 0);
	}
	
	//public inline function fromMatrix4f(mat:Matrix4f):Void
	//{
		//mat.toMatrix3f(basis);
		//origin.setTo(mat.m03, mat.m13, mat.m23);
	//}
	
	public inline function transform(v:Vector3f):Void
	{
		basis.multVecLocal(v);
		v.addLocal(origin);
	}
	
	public inline function setIdentity():Void
	{
		basis.makeIdentity();
		origin.setTo(0, 0, 0);
	}
	
	public function inverse(tr:Transform = null):Void
	{
		if (tr != null)
		{
			this.fromTransform(tr);
		}
        basis.transposeLocal();
		origin.scaleLocal( -1);
		basis.multVecLocal(origin);
    }

	private static var tmpVec:Vector3f = new Vector3f();
	public inline function mul(tr1:Transform):Void
	{
		tmpVec.copyFrom(tr1.origin);
		transform(tmpVec);
		
		basis.multLocal(tr1.basis);
		origin.copyFrom(tmpVec);
	}
	
	public inline function mul2(tr1:Transform, tr2:Transform ):Void
	{
		tmpVec.copyFrom(tr2.origin);
		tr1.transform(tmpVec);
		
		basis.multBy(tr1.basis, tr2.basis);
		origin.copyFrom(tmpVec);
	}
	
	private static var tmpMatrix3f:Matrix3f = new Matrix3f();
	public inline function invXform(inVec:Vector3f, out:Vector3f):Void
	{
		out.subtractBy(inVec, origin);
		
		tmpMatrix3f.copyFrom(basis);
		tmpMatrix3f.transposeLocal();
		tmpMatrix3f.multVecLocal(out);
	}
	
	public inline function getRotation(out:Quaternion):Quaternion
	{
		MatrixUtil.getRotation(basis, out);
		return out;
	}
	
	public inline function setRotation(q:Quaternion):Void
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
	
	//public function getMatrix(out:Matrix4f):Matrix4f
	//{
		//out.fromMatrix3f(basis);
		//out.m03 = origin.x;
		//out.m13 = origin.y;
		//out.m23 = origin.z;
		//return out;
	//}
	
	public inline function equals(tr:Transform):Bool
	{
		return tr.basis.equals(basis) && tr.origin.equals(origin);
	}
}