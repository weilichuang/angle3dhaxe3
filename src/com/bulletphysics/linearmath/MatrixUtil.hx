package com.bulletphysics.linearmath ;
import com.bulletphysics.BulletGlobals;
import com.bulletphysics.linearmath.VectorUtil;
import de.polygonal.core.math.Mathematics;
import vecmath.FastMath;
import vecmath.Matrix3f;
import vecmath.Quat4f;
import vecmath.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class MatrixUtil
{
	public static inline function scale(dest:Matrix3f, mat:Matrix3f, s:Vector3f):Void
	{
        dest.m00 = mat.m00 * s.x;
        dest.m01 = mat.m01 * s.y;
        dest.m02 = mat.m02 * s.z;
        dest.m10 = mat.m10 * s.x;
        dest.m11 = mat.m11 * s.y;
        dest.m12 = mat.m12 * s.z;
        dest.m20 = mat.m20 * s.x;
        dest.m21 = mat.m21 * s.y;
        dest.m22 = mat.m22 * s.z;
    }

    public static inline function absolute(mat:Matrix3f):Void
	{
        mat.m00 = FastMath.fabs(mat.m00);
        mat.m01 = FastMath.fabs(mat.m01);
        mat.m02 = FastMath.fabs(mat.m02);
        mat.m10 = FastMath.fabs(mat.m10);
        mat.m11 = FastMath.fabs(mat.m11);
        mat.m12 = FastMath.fabs(mat.m12);
        mat.m20 = FastMath.fabs(mat.m20);
        mat.m21 = FastMath.fabs(mat.m21);
        mat.m22 = FastMath.fabs(mat.m22);
    }
	
	public static function setFromOpenGLSubMatrix(mat:Matrix3f, m:Array<Float>):Void
	{
        mat.m00 = m[0];
        mat.m01 = m[4];
        mat.m02 = m[8];
        mat.m10 = m[1];
        mat.m11 = m[5];
        mat.m12 = m[9];
        mat.m20 = m[2];
        mat.m21 = m[6];
        mat.m22 = m[10];
    }

    public static function getOpenGLSubMatrix(mat:Matrix3f, m:Array<Float>):Void
	{
        m[0] = mat.m00;
        m[1] = mat.m10;
        m[2] = mat.m20;
        m[3] = 0;
        m[4] = mat.m01;
        m[5] = mat.m11;
        m[6] = mat.m21;
        m[7] = 0;
        m[8] = mat.m02;
        m[9] = mat.m12;
        m[10] = mat.m22;
        m[11] = 0;
    }
	
	public static function setRotation(dest:Matrix3f, q:Quat4f):Void
	{
        var d:Float = q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w;

        var s:Float = 2 / d;
        var xs:Float = q.x * s, ys = q.y * s, zs = q.z * s;
        var wx:Float = q.w * xs, wy = q.w * ys, wz = q.w * zs;
        var xx:Float = q.x * xs, xy = q.x * ys, xz = q.x * zs;
        var yy:Float = q.y * ys, yz = q.y * zs, zz = q.z * zs;
        dest.m00 = 1 - (yy + zz);
        dest.m01 = xy - wz;
        dest.m02 = xz + wy;
        dest.m10 = xy + wz;
        dest.m11 = 1 - (xx + zz);
        dest.m12 = yz - wx;
        dest.m20 = xz - wy;
        dest.m21 = yz + wx;
        dest.m22 = 1 - (xx + yy);
    }

	private static var temp:Array<Float> = [0,0,0,0];
	public static function getRotation(mat:Matrix3f, dest:Quat4f):Void
	{
        var trace:Float = mat.m00 + mat.m11 + mat.m22;

        if (trace > 0)
		{
            var s:Float = Mathematics.sqrt(trace + 1);
            temp[3] = (s * 0.5);
            s = 0.5 / s;

            temp[0] = ((mat.m21 - mat.m12) * s);
            temp[1] = ((mat.m02 - mat.m20) * s);
            temp[2] = ((mat.m10 - mat.m01) * s);
        } 
		else
		{
            var i:Int = mat.m00 < mat.m11 ? (mat.m11 < mat.m22 ? 2 : 1) : (mat.m00 < mat.m22 ? 2 : 0);
            var j:Int = (i + 1) % 3;
            var k:Int = (i + 2) % 3;

            var s:Float = Mathematics.sqrt(mat.getElement(i, i) - mat.getElement(j, j) - mat.getElement(k, k) + 1);
            temp[i] = s * 0.5;
            s = 0.5 / s;

            temp[3] = (mat.getElement(k, j) - mat.getElement(j, k)) * s;
            temp[j] = (mat.getElement(j, i) + mat.getElement(i, j)) * s;
            temp[k] = (mat.getElement(k, i) + mat.getElement(i, k)) * s;
        }
		
        dest.setTo(temp[0], temp[1], temp[2], temp[3]);
	}
	
	public static inline function transposeTransform(dest:Vector3f, vec:Vector3f, mat:Matrix3f):Void
	{
		var dx:Float = mat.m00 * vec.x + mat.m10 * vec.y + mat.m20 * vec.z;
		var dy:Float = mat.m01 * vec.x + mat.m11 * vec.y + mat.m21 * vec.z;
		var dz:Float = mat.m02 * vec.x + mat.m12 * vec.y + mat.m22 * vec.z;
		dest.setTo(dx, dy, dz);
	}
	
	/**
     * Diagonalizes this matrix by the Jacobi method. rot stores the rotation
     * from the coordinate system in which the matrix is diagonal to the original
     * coordinate system, i.e., old_this = rot * new_this * rot^T. The iteration
     * stops when all off-diagonal elements are less than the threshold multiplied
     * by the sum of the absolute values of the diagonal, or when maxSteps have
     * been executed. Note that this matrix is assumed to be symmetric.
     */
    // JAVA NOTE: diagonalize method from 2.71
    public static function diagonalize(mat:Matrix3f, rot:Matrix3f, threshold:Float, maxSteps:Int):Void
	{
        var row:Vector3f = new Vector3f();

        rot.setIdentity();
		var step:Int = maxSteps;
        while (step > 0) 
		{
            // find off-diagonal element [p][q] with largest magnitude
            var p:Int = 0;
            var q:Int = 1;
            var r:Int = 2;
            var max:Float = FastMath.fabs(mat.m01);
            var v:Float = FastMath.fabs(mat.m02);
            if (v > max) 
			{
                q = 2;
                r = 1;
                max = v;
            }
            v = FastMath.fabs(mat.m12);
            if (v > max)
			{
                p = 1;
                q = 2;
                r = 0;
                max = v;
            }

            var t:Float = threshold * (FastMath.fabs(mat.m00) + FastMath.fabs(mat.m11) + FastMath.fabs(mat.m22));
            if (max <= t)
			{
                if (max <= BulletGlobals.SIMD_EPSILON * t)
				{
                    return;
                }
                step = 1;
            }

            // compute Jacobi rotation J which leads to a zero for element [p][q]
            var mpq:Float = mat.getElement(p, q);
            var theta:Float = (mat.getElement(q, q) - mat.getElement(p, p)) / (2 * mpq);
            var theta2:Float = theta * theta;
            var cos:Float;
            var sin:Float;
            if ((theta2 * theta2) < (10 / BulletGlobals.SIMD_EPSILON))
			{
                t = (theta >= 0) ? 1 / (theta + Mathematics.sqrt(1 + theta2))
                        : 1 / (theta - Mathematics.sqrt(1 + theta2));
                cos = Mathematics.invSqrt(1 + t * t);
                sin = cos * t;
            } 
			else 
			{
                // approximation for large theta-value, i.e., a nearly diagonal matrix
                t = 1 / (theta * (2 + 0.5 / theta2));
                cos = 1 - 0.5 * t * t;
                sin = cos * t;
            }

            // apply rotation to matrix (this = J^T * this * J)
            mat.setElement(p, q, 0);
            mat.setElement(q, p, 0);
            mat.setElement(p, p, mat.getElement(p, p) - t * mpq);
            mat.setElement(q, q, mat.getElement(q, q) + t * mpq);
            var mrp:Float = mat.getElement(r, p);
            var mrq:Float = mat.getElement(r, q);
            mat.setElement(r, p, cos * mrp - sin * mrq);
            mat.setElement(p, r, cos * mrp - sin * mrq);
            mat.setElement(r, q, cos * mrq + sin * mrp);
            mat.setElement(q, r, cos * mrq + sin * mrp);

            // apply rotation to rot (rot = rot * J)
            for (i in 0...3) 
			{
                rot.getRow(i, row);

                mrp = VectorUtil.getCoord(row, p);
                mrq = VectorUtil.getCoord(row, q);
                VectorUtil.setCoord(row, p, cos * mrp - sin * mrq);
                VectorUtil.setCoord(row, q, cos * mrq + sin * mrp);
                rot.setRow(i, row.x, row.y, row.z);
            }
			
			step--;
        }
	}
}