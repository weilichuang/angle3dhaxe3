package com.bulletphysics.collision.shapes;

/**
 * ...
 
 */
class CapsuleShapeZ extends CapsuleShape
{

	public function new(radius:Float, height:Float) 
	{
		super(radius, height);
		upAxis = 2;
		implicitShapeDimensions.setTo(radius, radius, 0.5 * height);
	}
	
	override public function getName():String 
	{
		return "CapsuleZ";
	}
	
}