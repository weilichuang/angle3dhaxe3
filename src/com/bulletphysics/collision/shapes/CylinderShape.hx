package com.bulletphysics.collision.shapes;

import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import de.polygonal.core.math.Mathematics;
import vecmath.Vector3f;

/**
 * CylinderShape class implements a cylinder shape primitive, centered around
 * the origin. Its central axis aligned with the Y axis. {@link CylinderShapeX}
 * is aligned with the X axis and {@link CylinderShapeZ} around the Z axis.
 * 
 * @author weilichuang
 */
class CylinderShape extends BoxShape
{
	private var upAxis:Int;

	public function new(halfExtents:Vector3f) 
	{
		super(halfExtents);
		upAxis = 1;
		recalcLocalAabb();
	}
	
	override public function getAabb(trans:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		_PolyhedralConvexShape_getAabb(trans, aabbMin, aabbMax);
	}
	
	private function cylinderLocalSupportX(halfExtents:Vector3f, v:Vector3f, out:Vector3f):Vector3f
	{
		return cylinderLocalSupport(halfExtents, v, 0, 1, 0, 2, out);
	}
	
	private function cylinderLocalSupportY(halfExtents:Vector3f, v:Vector3f, out:Vector3f):Vector3f
	{
		return cylinderLocalSupport(halfExtents, v, 1, 0, 1, 2, out);
	}
	
	private function cylinderLocalSupportZ(halfExtents:Vector3f, v:Vector3f, out:Vector3f):Vector3f
	{
		return cylinderLocalSupport(halfExtents, v, 2, 0, 2, 1, out);
	}
	
	private function cylinderLocalSupport(halfExtents:Vector3f, v:Vector3f, cylinderUpAxis:Int, 
										XX:Int, YY:Int, ZZ:Int, out:Vector3f):Vector3f
	{
		//mapping depends on how cylinder local orientation is
        // extents of the cylinder is: X,Y is for radius, and Z for height

        var radius:Float = VectorUtil.getCoord(halfExtents, XX);
        var halfHeight:Float = VectorUtil.getCoord(halfExtents, cylinderUpAxis);

        var d:Float;

        var s:Float = Mathematics.sqrt(VectorUtil.getCoord(v, XX) * VectorUtil.getCoord(v, XX) + VectorUtil.getCoord(v, ZZ) * VectorUtil.getCoord(v, ZZ));
        if (s != 0)
		{
            d = radius / s;
            VectorUtil.setCoord(out, XX, VectorUtil.getCoord(v, XX) * d);
            VectorUtil.setCoord(out, YY, VectorUtil.getCoord(v, YY) < 0 ? -halfHeight : halfHeight);
            VectorUtil.setCoord(out, ZZ, VectorUtil.getCoord(v, ZZ) * d);
            return out;
        }
		else
		{
            VectorUtil.setCoord(out, XX, radius);
            VectorUtil.setCoord(out, YY, VectorUtil.getCoord(v, YY) < 0 ? -halfHeight : halfHeight);
            VectorUtil.setCoord(out, ZZ, 0);
            return out;
        }
	}
	
	override public function localGetSupportingVertexWithoutMargin(vec:Vector3f,out:Vector3f):Vector3f 
	{
		return cylinderLocalSupportY(getHalfExtentsWithoutMargin(new Vector3f()), vec, out);
	}
	
	override public function batchedUnitVectorGetSupportingVertexWithoutMargin(vectors:Array<Vector3f>, supportVerticesOut:Array<Vector3f>, numVectors:Int):Void 
	{
		for (i in 0...numVectors)
		{
            cylinderLocalSupportY(getHalfExtentsWithoutMargin(new Vector3f()), vectors[i], supportVerticesOut[i]);
        }
	}
	
	override public function localGetSupportingVertex(vec0:Vector3f, out:Vector3f):Vector3f 
	{
		var supVertex:Vector3f = out;
        localGetSupportingVertexWithoutMargin(vec0, supVertex);

        if (getMargin() != 0)
		{
            var vecnorm:Vector3f = vec0.clone();
            if (vecnorm.lengthSquared() < (BulletGlobals.SIMD_EPSILON * BulletGlobals.SIMD_EPSILON))
			{
                vecnorm.setTo(-1, -1, -1);
            }
            vecnorm.normalize();
            supVertex.scaleAdd(getMargin(), vecnorm, supVertex);
        }
        return out;
	}
	
	override public function getShapeType():BroadphaseNativeType 
	{
		return BroadphaseNativeType.CYLINDER_SHAPE_PROXYTYPE;
	}
	
	public function getUpAxis():Int
	{
		return upAxis;
	}
	
	public function getRadius():Float
	{
		return getHalfExtentsWithMargin(new Vector3f()).x;
	}
	
	override public function getName():String 
	{
		return "CylinderY";
	}
}