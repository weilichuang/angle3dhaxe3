package com.bulletphysics.collision.shapes;
import org.angle3d.math.Vector3f;

/**
 * Cylinder shape around the Z axis.
 * @author weilichuang
 */
class CylinderShapeZ extends CylinderShape
{

	public function new(halfExtents:Vector3f) 
	{
		super(halfExtents);
		upAxis = 2;
		recalcLocalAabb();
	}
	
	override public function localGetSupportingVertexWithoutMargin(vec:Vector3f, out:Vector3f):Vector3f 
	{
		return cylinderLocalSupportZ(getHalfExtentsWithoutMargin(new Vector3f()), vec, out);
	}
	
	override public function batchedUnitVectorGetSupportingVertexWithoutMargin(vectors:Array<Vector3f>, supportVerticesOut:Array<Vector3f>, numVectors:Int):Void 
	{
		for (i in 0...numVectors)
		{
			cylinderLocalSupportZ(getHalfExtentsWithoutMargin(new Vector3f()), vectors[i], supportVerticesOut[i]);
		}
	}
	
	override public function getRadius():Float 
	{
		return getHalfExtentsWithMargin(new Vector3f()).x;
	}
	
	override public function getName():String 
	{
		return "CylinderZ";
	}
	
	
}