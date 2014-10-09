package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.linearmath.Transform;
import com.vecmath.Vector3f;

/**
 * SphereShape implements an implicit sphere, centered around a local origin with radius.
 * @author weilichuang
 */
class SphereShape extends ConvexInternalShape
{

	public function new(radius:Float) 
	{
		super();
		implicitShapeDimensions.x = radius;
		collisionMargin = radius;
	}
	
	override public function localGetSupportingVertexWithoutMargin(vec:Vector3f, out:Vector3f):Vector3f 
	{
		out.setTo(0, 0, 0);
		return out;
	}
	
	override public function batchedUnitVectorGetSupportingVertexWithoutMargin(vectors:Array<Vector3f>, supportVerticesOut:Array<Vector3f>, numVectors:Int):Void 
	{
		for (i in 0...numVectors)
		{
			supportVerticesOut[i].setTo(0, 0, 0);
		}
	}
	
	override public function getAabb(t:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		var center:Vector3f = t.origin;
        var extent:Vector3f = new Vector3f();
        extent.setTo(getMargin(), getMargin(), getMargin());
        aabbMin.sub(center, extent);
        aabbMax.add(center, extent);
	}
	
	override public function getShapeType():BroadphaseNativeType 
	{
		return BroadphaseNativeType.SPHERE_SHAPE_PROXYTYPE;
	}
	
	override public function calculateLocalInertia(mass:Float, inertia:Vector3f):Void 
	{
		var elem:Float = 0.4 * mass * getMargin() * getMargin();
        inertia.setTo(elem, elem, elem);
	}
	
	override public function getName():String 
	{
		return "SPHERE";
	}
	
	public function getRadius():Float
	{
		return implicitShapeDimensions.x * localScaling.x;
	}
	
	override public function setMargin(margin:Float):Void 
	{
		super.setMargin(margin);
	}
	
	override public function getMargin():Float 
	{
		// to improve gjk behaviour, use radius+margin as the full margin, so never get into the penetration case
        // this means, non-uniform scaling is not supported anymore
        return getRadius();
	}
	
	
}