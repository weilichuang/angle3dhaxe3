package com.bulletphysics.linearmath;
import vecmath.Matrix3f;
import com.bulletphysics.linearmath.MatrixUtil;
import vecmath.Vector3f;

/**
 * Utility functions for axis aligned bounding boxes (AABB).
 * @author weilichuang
 */
class AabbUtil2
{

	public static function aabbExpand(aabbMin:Vector3f, aabbMax:Vector3f, expansionMin:Vector3f, expansionMax:Vector3f):Void
	{
        aabbMin.add(expansionMin);
        aabbMax.add(expansionMax);
    }

    public static function outcode(p:Vector3f, halfExtent:Vector3f):Int 
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
        var aabbHalfExtent:Vector3f = new Vector3f();
        var aabbCenter:Vector3f = new Vector3f();
        var source:Vector3f = new Vector3f();
        var target:Vector3f = new Vector3f();
        var r:Vector3f = new Vector3f();
        var hitNormal:Vector3f = new Vector3f();

        aabbHalfExtent.sub2(aabbMax, aabbMin);
        aabbHalfExtent.scale(0.5);

        aabbCenter.add(aabbMax, aabbMin);
        aabbCenter.scale(0.5);

        source.sub2(rayFrom, aabbCenter);
        target.sub2(rayTo, aabbCenter);

        var sourceOutcode:Int = outcode(source, aabbHalfExtent);
        var targetOutcode:Int = outcode(target, aabbHalfExtent);
        if ((sourceOutcode & targetOutcode) == 0x0) 
		{
            var lambda_enter:Float = 0;
            var lambda_exit:Float = param[0];
            r.sub2(target, source);

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
                        var lambda:Float = (-VectorUtil.getCoord(source, i) - VectorUtil.getCoord(aabbHalfExtent, i) * normSign) / VectorUtil.getCoord(r, i);
                        if (lambda_enter <= lambda)
						{
                            lambda_enter = lambda;
                            hitNormal.setTo(0, 0, 0);
                            VectorUtil.setCoord(hitNormal, i, normSign);
                        }
                    } 
					else if ((targetOutcode & bit) != 0) 
					{
                        var lambda:Float = (-VectorUtil.getCoord(source, i) - VectorUtil.getCoord(aabbHalfExtent, i) * normSign) / VectorUtil.getCoord(r, i);
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
                normal.fromVector3f(hitNormal);
                return true;
            }
        }
        return false;
    }

    /**
     * Conservative test for overlap between two AABBs.
     */
    public static function testAabbAgainstAabb2(aabbMin1:Vector3f, aabbMax1:Vector3f, aabbMin2:Vector3f, aabbMax2:Vector3f):Bool
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

        if (Math.min(Math.min(p1.x, p2.x), p3.x) > aabbMax.x) return false;
        if (Math.max(Math.max(p1.x, p2.x), p3.x) < aabbMin.x) return false;

        if (Math.min(Math.min(p1.z, p2.z), p3.z) > aabbMax.z) return false;
        if (Math.max(Math.max(p1.z, p2.z), p3.z) < aabbMin.z) return false;

        if (Math.min(Math.min(p1.y, p2.y), p3.y) > aabbMax.y) return false;
        if (Math.max(Math.max(p1.y, p2.y), p3.y) < aabbMin.y) return false;

        return true;
    }

    public static function transformAabb(halfExtents:Vector3f, margin:Float, t:Transform, aabbMinOut:Vector3f, aabbMaxOut:Vector3f):Void
	{
        var halfExtentsWithMargin:Vector3f = new Vector3f();
        halfExtentsWithMargin.x = halfExtents.x + margin;
        halfExtentsWithMargin.y = halfExtents.y + margin;
        halfExtentsWithMargin.z = halfExtents.z + margin;

        var abs_b:Matrix3f = t.basis.clone();
        MatrixUtil.absolute(abs_b);

        var tmp:Vector3f = new Vector3f();

        var center:Vector3f = t.origin.clone();
        var extent:Vector3f = new Vector3f();
        abs_b.getRow(0, tmp);
        extent.x = tmp.dot(halfExtentsWithMargin);
        abs_b.getRow(1, tmp);
        extent.y = tmp.dot(halfExtentsWithMargin);
        abs_b.getRow(2, tmp);
        extent.z = tmp.dot(halfExtentsWithMargin);

        aabbMinOut.sub2(center, extent);
        aabbMaxOut.add(center, extent);
    }

    public static function transformAabb2(localAabbMin:Vector3f, localAabbMax:Vector3f, 
										margin:Float, trans:Transform, 
										aabbMinOut:Vector3f,  aabbMaxOut:Vector3f):Void
	{
        //assert (localAabbMin.x <= localAabbMax.x);
        //assert (localAabbMin.y <= localAabbMax.y);
        //assert (localAabbMin.z <= localAabbMax.z);

        var localHalfExtents:Vector3f = new Vector3f();
        localHalfExtents.sub2(localAabbMax, localAabbMin);
        localHalfExtents.scale(0.5);

        localHalfExtents.x += margin;
        localHalfExtents.y += margin;
        localHalfExtents.z += margin;

        var localCenter:Vector3f = new Vector3f();
        localCenter.add(localAabbMax, localAabbMin);
        localCenter.scale(0.5);

        var abs_b:Matrix3f = trans.basis.clone();
        MatrixUtil.absolute(abs_b);

        var center:Vector3f = localCenter.clone();
        trans.transform(center);

        var extent:Vector3f = new Vector3f();
        var tmp:Vector3f = new Vector3f();

        abs_b.getRow(0, tmp);
        extent.x = tmp.dot(localHalfExtents);
        abs_b.getRow(1, tmp);
        extent.y = tmp.dot(localHalfExtents);
        abs_b.getRow(2, tmp);
        extent.z = tmp.dot(localHalfExtents);

        aabbMinOut.sub2(center, extent);
        aabbMaxOut.add(center, extent);
    }
	
}