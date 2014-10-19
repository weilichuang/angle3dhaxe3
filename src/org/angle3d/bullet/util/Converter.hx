package org.angle3d.bullet.util;
import com.bulletphysics.collision.shapes.IndexedMesh;
import de.polygonal.core.math.Mathematics;
import haxe.ds.Vector;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Transform;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import vecmath.Matrix3f;

/**
 * ...
 * @author weilichuang
 */
class Converter
{

	public function new() 
	{
		
	}
	
	public static function a2vTransform(inT:org.angle3d.math.Transform, out:com.bulletphysics.linearmath.Transform):com.bulletphysics.linearmath.Transform
	{
        a2vVector3f(inT.translation, out.origin);
        aQuaterion2vMatrix3f(inT.rotation, out.basis);
        return out;
    }

    public static function v2aTransform(inT:com.bulletphysics.linearmath.Transform, out:org.angle3d.math.Transform):org.angle3d.math.Transform
	{
        v2aVector3f(inT.origin, out.translation);
        vMatrix3f2Quaterion(inT.basis, out.rotation);
        return out;
    }
	
	public static function a2vVector3f(oldVec:org.angle3d.math.Vector3f,result:vecmath.Vector3f = null):vecmath.Vector3f
	{
		if(result == null)
			result = new vecmath.Vector3f();
		result.x = oldVec.x;
		result.y = oldVec.y;
		result.z = oldVec.z;
        return result;
    }
	
	public static function v2aVector3f(oldVec:vecmath.Vector3f,result:org.angle3d.math.Vector3f = null):org.angle3d.math.Vector3f
	{
		if(result == null)
			result = new org.angle3d.math.Vector3f();
		result.x = oldVec.x;
		result.y = oldVec.y;
		result.z = oldVec.z;
        return result;
    }
	
	public static function v2aQuat(oldQuat:vecmath.Quat4f, newQuat:org.angle3d.math.Quaternion):org.angle3d.math.Quaternion 
	{
        newQuat.setTo(oldQuat.x, oldQuat.y, oldQuat.z, oldQuat.w);
        return newQuat;
    }
	
	public static function a2vMatrix3f(oldMatrix:org.angle3d.math.Matrix3f, newMatrix:vecmath.Matrix3f = null):vecmath.Matrix3f 
	{
		if (newMatrix == null)
			newMatrix = new vecmath.Matrix3f();
        newMatrix.m00 = oldMatrix.m00;
        newMatrix.m01 = oldMatrix.m01;
        newMatrix.m02 = oldMatrix.m02;
        newMatrix.m10 = oldMatrix.m10;
        newMatrix.m11 = oldMatrix.m11;
        newMatrix.m12 = oldMatrix.m12;
        newMatrix.m20 = oldMatrix.m20;
        newMatrix.m21 = oldMatrix.m21;
        newMatrix.m22 = oldMatrix.m22;
        return newMatrix;
    }
	
	public static function v2aMatrix3f(oldMatrix:vecmath.Matrix3f, newMatrix:org.angle3d.math.Matrix3f = null):org.angle3d.math.Matrix3f
	{
		if (newMatrix == null)
			newMatrix = new org.angle3d.math.Matrix3f();
        newMatrix.m00 = oldMatrix.m00;
        newMatrix.m01 = oldMatrix.m01;
        newMatrix.m02 = oldMatrix.m02;
        newMatrix.m10 = oldMatrix.m10;
        newMatrix.m11 = oldMatrix.m11;
        newMatrix.m12 = oldMatrix.m12;
        newMatrix.m20 = oldMatrix.m20;
        newMatrix.m21 = oldMatrix.m21;
        newMatrix.m22 = oldMatrix.m22;
        return newMatrix;
    }
	
	public static function aQuaterion2vMatrix3f(oldQuaternion:org.angle3d.math.Quaternion, 
											newMatrix:vecmath.Matrix3f = null):vecmath.Matrix3f
	{
		if (newMatrix == null)
			newMatrix = new vecmath.Matrix3f();
			
        var norm:Float = oldQuaternion.w * oldQuaternion.w + oldQuaternion.x * oldQuaternion.x + oldQuaternion.y * oldQuaternion.y + oldQuaternion.z * oldQuaternion.z;
        var s:Float = (norm == 1) ? 2 : (norm > 0) ? 2 / norm : 0;

        // compute xs/ys/zs first to save 6 multiplications, since xs/ys/zs
        // will be used 2-4 times each.
        var xs:Float = oldQuaternion.x * s;
        var ys:Float = oldQuaternion.y * s;
        var zs:Float = oldQuaternion.z * s;
        var xx:Float = oldQuaternion.x * xs;
        var xy:Float = oldQuaternion.x * ys;
        var xz:Float = oldQuaternion.x * zs;
        var xw:Float = oldQuaternion.w * xs;
        var yy:Float = oldQuaternion.y * ys;
        var yz:Float = oldQuaternion.y * zs;
        var yw:Float = oldQuaternion.w * ys;
        var zz:Float = oldQuaternion.z * zs;
        var zw:Float = oldQuaternion.w * zs;

        // using s=2/norm (instead of 1/norm) saves 9 multiplications by 2 here
        newMatrix.m00 = 1 - (yy + zz);
        newMatrix.m01 = (xy - zw);
        newMatrix.m02 = (xz + yw);
        newMatrix.m10 = (xy + zw);
        newMatrix.m11 = 1 - (xx + zz);
        newMatrix.m12 = (yz - xw);
        newMatrix.m20 = (xz - yw);
        newMatrix.m21 = (yz + xw);
        newMatrix.m22 = 1 - (xx + yy);

        return newMatrix;
    }
	
	public static function vMatrix3f2Quaterion(oldMatrix:vecmath.Matrix3f, 
											newQuaternion:org.angle3d.math.Quaternion = null):org.angle3d.math.Quaternion
	{
		if (newQuaternion == null)
			newQuaternion = new org.angle3d.math.Quaternion();
        // the trace is the sum of the diagonal elements; see
        // http://mathworld.wolfram.com/MatrixTrace.html
        var t:Float = oldMatrix.m00 + oldMatrix.m11 + oldMatrix.m22;
        var w:Float, x:Float, y:Float, z:Float;
        // we protect the division by s by ensuring that s>=1
        if (t >= 0)
		{ // |w| >= .5
            var s:Float = Mathematics.sqrt(t + 1); // |s|>=1 ...
            w = 0.5 * s;
            s = 0.5 / s;                 // so this division isn't bad
            x = (oldMatrix.m21 - oldMatrix.m12) * s;
            y = (oldMatrix.m02 - oldMatrix.m20) * s;
            z = (oldMatrix.m10 - oldMatrix.m01) * s;
        } 
		else if ((oldMatrix.m00 > oldMatrix.m11) && (oldMatrix.m00 > oldMatrix.m22)) 
		{
            var s:Float = Mathematics.sqrt(1.0 + oldMatrix.m00 - oldMatrix.m11 - oldMatrix.m22); // |s|>=1
            x = s * 0.5; // |x| >= .5
            s = 0.5 / s;
            y = (oldMatrix.m10 + oldMatrix.m01) * s;
            z = (oldMatrix.m02 + oldMatrix.m20) * s;
            w = (oldMatrix.m21 - oldMatrix.m12) * s;
        } 
		else if (oldMatrix.m11 > oldMatrix.m22)
		{
            var s:Float = Mathematics.sqrt(1.0 + oldMatrix.m11 - oldMatrix.m00 - oldMatrix.m22); // |s|>=1
            y = s * 0.5; // |y| >= .5
            s = 0.5 / s;
            x = (oldMatrix.m10 + oldMatrix.m01) * s;
            z = (oldMatrix.m21 + oldMatrix.m12) * s;
            w = (oldMatrix.m02 - oldMatrix.m20) * s;
        } 
		else
		{
            var s:Float = Mathematics.sqrt(1.0 + oldMatrix.m22 - oldMatrix.m00 - oldMatrix.m11); // |s|>=1
            z = s * 0.5; // |z| >= .5
            s = 0.5 / s;
            x = (oldMatrix.m02 + oldMatrix.m20) * s;
            y = (oldMatrix.m21 + oldMatrix.m12) * s;
            w = (oldMatrix.m10 - oldMatrix.m01) * s;
        }
		newQuaternion.setTo(x, y, z, w);
        return newQuaternion;
    }
	
	public static function a2vMesh(mesh:Mesh):IndexedMesh
	{
        var jBulletIndexedMesh:IndexedMesh = new IndexedMesh();
        jBulletIndexedMesh.triangleIndexBase = new Vector(mesh.getTriangleCount() * 3 * 4);
        jBulletIndexedMesh.vertexBase = new Vector(mesh.getVertexCount() * 3 * 4);

        var indices = mesh.getIndices();
        var vertices = mesh.getVertexBuffer(BufferType.POSITION).getData();

        var verticesLength:Int = mesh.getVertexCount() * 3;
        jBulletIndexedMesh.numVertices = mesh.getVertexCount();
        jBulletIndexedMesh.vertexStride = 12; //3 verts * 4 bytes per.
        for (i in 0...verticesLength) 
		{
            var tempFloat:Float = vertices[i];
            jBulletIndexedMesh.vertexBase[i] = tempFloat;
        }

        var indicesLength:Int = mesh.getTriangleCount() * 3;
        jBulletIndexedMesh.numTriangles = mesh.getTriangleCount();
        jBulletIndexedMesh.triangleIndexStride = 12; //3 index entries * 4 bytes each.
        for (i in 0...indicesLength)
		{
            jBulletIndexedMesh.triangleIndexBase[i] = indices[i];
        }

        return jBulletIndexedMesh;
    }
	
}