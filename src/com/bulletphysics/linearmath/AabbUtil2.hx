package com.bulletphysics.linearmath;
import com.bulletphysics.linearmath.MatrixUtil;
import org.angle3d.error.Assert.assert;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Vector3f;

/**
 * Utility functions for axis aligned bounding boxes (AABB).
 
 */
class AabbUtil2
{
	private static var tmpHalfExtents:Vector3f = new Vector3f();
	private static var tmpCenter:Vector3f = new Vector3f();
	private static var tmpLocalCenter:Vector3f = new Vector3f();
	private static var abs_basis:Matrix3f = new Matrix3f();
	private static var extent:Vector3f = new Vector3f();
	private static var tmpVec:Vector3f = new Vector3f();
    private static var source:Vector3f = new Vector3f();
    private static var target:Vector3f = new Vector3f();
    private static var r:Vector3f = new Vector3f();
    private static var hitNormal:Vector3f = new Vector3f();

	public static inline function aabbExpand(aabbMin:Vector3f, aabbMax:Vector3f, expansionMin:Vector3f, expansionMax:Vector3f):Void
	{
        aabbMin.addLocal(expansionMin);
        aabbMax.addLocal(expansionMax);
    }

    public static inline function outcode(p:Vector3f, halfExtent:Vector3f):Int 
	{
        return (p.x < -halfExtent.x ? 0x01 : 0x0) |
                (p.x > halfExtent.x ? 0x08 : 0x0) |
                (p.y < -halfExtent.y ? 0x02 : 0x0) |
                (p.y > halfExtent.y ? 0x10 : 0x0) |
                (p.z < -halfExtent.z ? 0x4 : 0x0) |
                (p.z > halfExtent.z ? 0x20 : 0x0);
    }

    public static function rayAabb(rayFrom:Vector3f, rayTo:Vector3f, aabbMin:Vector3f, aabbMax:Vector3f, param:Array<Float>, normal:Vector3f):Bool
	{
        tmpHalfExtents.subtractBy(aabbMax, aabbMin);
        tmpHalfExtents.scaleLocal(0.5);

        tmpCenter.addBy(aabbMax, aabbMin);
        tmpCenter.scaleLocal(0.5);

        source.subtractBy(rayFrom, tmpCenter);
        target.subtractBy(rayTo, tmpCenter);

        var sourceOutcode:Int = outcode(source, tmpHalfExtents);
        var targetOutcode:Int = outcode(target, tmpHalfExtents);
        if ((sourceOutcode & targetOutcode) == 0x0) 
		{
            var lambda_enter:Float = 0;
            var lambda_exit:Float = param[0];
            r.subtractBy(target, source);

            var normSign:Float = 1;
            hitNormal.setTo(0, 0, 0);
            var bit:Int = 1;

            for (j in 0...2)
			{
				var i:Int = 0;
                while (i != 3)
				{
                    if ((sourceOutcode & bit) != 0) 
					{
                        var lambda:Float = (-LinearMathUtil.getCoord(source, i) - LinearMathUtil.getCoord(tmpHalfExtents, i) * normSign) / LinearMathUtil.getCoord(r, i);
                        if (lambda_enter <= lambda)
						{
                            lambda_enter = lambda;
                            hitNormal.setTo(0, 0, 0);
                            LinearMathUtil.setCoord(hitNormal, i, normSign);
                        }
                    } 
					else if ((targetOutcode & bit) != 0) 
					{
                        var lambda:Float = (-LinearMathUtil.getCoord(source, i) - LinearMathUtil.getCoord(tmpHalfExtents, i) * normSign) / LinearMathUtil.getCoord(r, i);
                        //btSetMin(lambda_exit, lambda);
                        lambda_exit = Math.min(lambda_exit, lambda);
                    }
                    bit <<= 1;
					
					++i;
                }
                normSign = -1;
            }
            if (lambda_enter <= lambda_exit) 
			{
                param[0] = lambda_enter;
                normal.copyFrom(hitNormal);
                return true;
            }
        }
        return false;
    }

    /**
     * Conservative test for overlap between two AABBs.
     */
    public static inline function testAabbAgainstAabb2(aabbMin1:Vector3f, aabbMax1:Vector3f, aabbMin2:Vector3f, aabbMax2:Vector3f):Bool
	{
        var overlap:Bool = true;
        overlap = (aabbMin1.x > aabbMax2.x || aabbMax1.x < aabbMin2.x) ? false : overlap;
        overlap = (aabbMin1.z > aabbMax2.z || aabbMax1.z < aabbMin2.z) ? false : overlap;
        overlap = (aabbMin1.y > aabbMax2.y || aabbMax1.y < aabbMin2.y) ? false : overlap;
        return overlap;
    }

    /**
     * Conservative test for overlap between triangle and AABB.
     */
    public static function testTriangleAgainstAabb2(vertices:Array<Vector3f>, aabbMin:Vector3f, aabbMax:Vector3f):Bool
	{
        var p1:Vector3f = vertices[0];
        var p2:Vector3f = vertices[1];
        var p3:Vector3f = vertices[2];

        if (FastMath.min(FastMath.min(p1.x, p2.x), p3.x) > aabbMax.x) return false;
        if (FastMath.max(FastMath.max(p1.x, p2.x), p3.x) < aabbMin.x) return false;

        if (FastMath.min(FastMath.min(p1.z, p2.z), p3.z) > aabbMax.z) return false;
        if (FastMath.max(FastMath.max(p1.z, p2.z), p3.z) < aabbMin.z) return false;

        if (FastMath.min(FastMath.min(p1.y, p2.y), p3.y) > aabbMax.y) return false;
        if (FastMath.max(FastMath.max(p1.y, p2.y), p3.y) < aabbMin.y) return false;

        return true;
    }

    public static inline function transformAabb(halfExtents:Vector3f, margin:Float, t:Transform, aabbMinOut:Vector3f, aabbMaxOut:Vector3f):Void
	{
        var halfExtentsWithMargin:Vector3f = tmpHalfExtents;
        halfExtentsWithMargin.x = halfExtents.x + margin;
        halfExtentsWithMargin.y = halfExtents.y + margin;
        halfExtentsWithMargin.z = halfExtents.z + margin;

        abs_basis.copyFrom(t.basis);
        MatrixUtil.absolute(abs_basis);

        tmpCenter.copyFrom(t.origin);

        //abs_b.getRow(0, tmp);
		tmpVec.setTo(abs_basis.m00, abs_basis.m01, abs_basis.m02);
        extent.x = tmpVec.dot(halfExtentsWithMargin);
		
        //abs_b.getRow(1, tmp);
		tmpVec.setTo(abs_basis.m10, abs_basis.m11, abs_basis.m12);
        extent.y = tmpVec.dot(halfExtentsWithMargin);
		
        //abs_b.getRow(2, tmp);
		tmpVec.setTo(abs_basis.m20, abs_basis.m21, abs_basis.m22);
        extent.z = tmpVec.dot(halfExtentsWithMargin);

        aabbMinOut.subtractBy(tmpCenter, extent);
        aabbMaxOut.addBy(tmpCenter, extent);
    }

    public static inline function transformAabb2(localAabbMin:Vector3f, localAabbMax:Vector3f, 
										margin:Float, trans:Transform, 
										aabbMinOut:Vector3f,  aabbMaxOut:Vector3f):Void
	{
		#if debug
        assert (localAabbMin.x <= localAabbMax.x);
        assert (localAabbMin.y <= localAabbMax.y);
        assert (localAabbMin.z <= localAabbMax.z);
		#end

        
        tmpHalfExtents.subtractBy(localAabbMax, localAabbMin);
        tmpHalfExtents.scaleLocal(0.5);

        tmpHalfExtents.x += margin;
        tmpHalfExtents.y += margin;
        tmpHalfExtents.z += margin;

        
        tmpLocalCenter.addBy(localAabbMax, localAabbMin);
        tmpLocalCenter.scaleLocal(0.5);

        abs_basis.copyFrom(trans.basis);
        MatrixUtil.absolute(abs_basis);

		tmpCenter.copyFrom(tmpLocalCenter);
        trans.transform(tmpCenter);

        //abs_b.getRow(0, tmp);
		tmpVec.setTo(abs_basis.m00, abs_basis.m01, abs_basis.m02);
        extent.x = tmpVec.dot(tmpHalfExtents);
		
        //abs_b.getRow(1, tmp);
		tmpVec.setTo(abs_basis.m10, abs_basis.m11, abs_basis.m12);
        extent.y = tmpVec.dot(tmpHalfExtents);
		
        //abs_b.getRow(2, tmp);
		tmpVec.setTo(abs_basis.m20, abs_basis.m21, abs_basis.m22);
        extent.z = tmpVec.dot(tmpHalfExtents);

        aabbMinOut.subtractBy(tmpCenter, extent);
        aabbMaxOut.addBy(tmpCenter, extent);
    }
	
}