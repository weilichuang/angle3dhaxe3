package com.bulletphysics.collision.shapes;

import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.LinearMathUtil;
import de.polygonal.core.math.Mathematics;
import flash.Vector;
import org.angle3d.math.Vector3f;

/**
 * CylinderShape class implements a cylinder shape primitive, centered around
 * the origin. Its central axis aligned with the Y axis. {CylinderShapeX}
 * is aligned with the X axis and {CylinderShapeZ} around the Z axis.
 * 
 * @author weilichuang
 */
class CylinderShape extends BoxShape
{
	private var upAxis:Int;

	public function new(halfExtents:Vector3f) 
	{
		super(halfExtents);
		_shapeType = BroadphaseNativeType.CYLINDER_SHAPE_PROXYTYPE;
		upAxis = 1;
		recalcLocalAabb();
	}
	
	override public function getAabb(trans:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		_PolyhedralConvexShape_getAabb(trans, aabbMin, aabbMax);
	}
	
	private inline function cylinderLocalSupportX(halfExtents:Vector3f, v:Vector3f, out:Vector3f):Vector3f
	{
		return cylinderLocalSupport(halfExtents, v, 0, 1, 0, 2, out);
	}
	
	private inline function cylinderLocalSupportY(halfExtents:Vector3f, v:Vector3f, out:Vector3f):Vector3f
	{
		return cylinderLocalSupport(halfExtents, v, 1, 0, 1, 2, out);
	}
	
	private inline function cylinderLocalSupportZ(halfExtents:Vector3f, v:Vector3f, out:Vector3f):Vector3f
	{
		return cylinderLocalSupport(halfExtents, v, 2, 0, 2, 1, out);
	}
	
	private inline function cylinderLocalSupport(halfExtents:Vector3f, v:Vector3f, cylinderUpAxis:Int, 
										XX:Int, YY:Int, ZZ:Int, out:Vector3f):Vector3f
	{
		//mapping depends on how cylinder local orientation is
        // extents of the cylinder is: X,Y is for radius, and Z for height

        var radius:Float = LinearMathUtil.getCoord(halfExtents, XX);
        var halfHeight:Float = LinearMathUtil.getCoord(halfExtents, cylinderUpAxis);

		var vx:Float = LinearMathUtil.getCoord(v, XX);
		var vy:Float = LinearMathUtil.getCoord(v, YY);
		var vz:Float = LinearMathUtil.getCoord(v, ZZ);
		
        var s:Float = Math.sqrt(vx * vx+ vz * vz);
        if (s != 0)
		{
            var d:Float = radius / s;
            LinearMathUtil.setCoord(out, XX, vx * d);
            LinearMathUtil.setCoord(out, YY, vy < 0 ? -halfHeight : halfHeight);
            LinearMathUtil.setCoord(out, ZZ, vz * d);
        }
		else
		{
            LinearMathUtil.setCoord(out, XX, radius);
            LinearMathUtil.setCoord(out, YY, vy < 0 ? -halfHeight : halfHeight);
            LinearMathUtil.setCoord(out, ZZ, 0);
            
        }
		
		return out;
	}
	
	private static var helpVec:Vector3f = new Vector3f();
	override public function localGetSupportingVertexWithoutMargin(vec:Vector3f,out:Vector3f):Vector3f 
	{
		return cylinderLocalSupportY(getHalfExtentsWithoutMargin(helpVec), vec, out);
	}
	
	override public function batchedUnitVectorGetSupportingVertexWithoutMargin(vectors:Array<Vector3f>, 
																			supportVerticesOut:Array<Vector3f>, numVectors:Int):Void 
	{
		for (i in 0...numVectors)
		{
            cylinderLocalSupportY(getHalfExtentsWithoutMargin(helpVec), vectors[i], supportVerticesOut[i]);
        }
	}
	
	override public function localGetSupportingVertex(vec0:Vector3f, out:Vector3f):Vector3f 
	{
		var supVertex:Vector3f = out;
        localGetSupportingVertexWithoutMargin(vec0, supVertex);

        if (getMargin() != 0)
		{
            var vecnorm:Vector3f = vec0.clone();
            if (vecnorm.lengthSquared < (BulletGlobals.FLT_EPSILON * BulletGlobals.FLT_EPSILON))
			{
                vecnorm.setTo(-1, -1, -1);
            }
            vecnorm.normalizeLocal();
            supVertex.scaleAddBy(getMargin(), vecnorm, supVertex);
        }
        return out;
	}
	
	public function getUpAxis():Int
	{
		return upAxis;
	}
	
	public function getRadius():Float
	{
		return getHalfExtentsWithMargin(helpVec).x;
	}
	
	override public function getName():String 
	{
		return "CylinderY";
	}
}