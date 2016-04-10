package com.bulletphysics.collision.shapes;
import org.angle3d.math.Vector3f;

/**
 * Cylinder shape around the X axis.
 
 */
class CylinderShapeX extends CylinderShape
{

	public function new(halfExtents:Vector3f) 
	{
		super(halfExtents);
		upAxis = 0;
		recalcLocalAabb();
	}
	
	override public function localGetSupportingVertexWithoutMargin(vec:Vector3f, out:Vector3f):Vector3f 
	{
		return cylinderLocalSupportX(getHalfExtentsWithoutMargin(new Vector3f()), vec, out);
	}
	
	override public function batchedUnitVectorGetSupportingVertexWithoutMargin(vectors:Array<Vector3f>, supportVerticesOut:Array<Vector3f>, numVectors:Int):Void 
	{
		for (i in 0...numVectors)
		{
			cylinderLocalSupportX(getHalfExtentsWithoutMargin(new Vector3f()), vectors[i], supportVerticesOut[i]);
		}
	}
	
	override public function getRadius():Float 
	{
		return getHalfExtentsWithMargin(new Vector3f()).y;
	}
	
	override public function getName():String 
	{
		return "CylinderX";
	}
	
	
}