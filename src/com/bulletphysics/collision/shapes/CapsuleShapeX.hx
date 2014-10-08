package com.bulletphysics.collision.shapes;

/**
 * ...
 * @author weilichuang
 */
class CapsuleShapeX extends CapsuleShape
{

	public function new(radius:Float, height:Float) 
	{
		super(radius, height);
		upAxis = 0;
		implicitShapeDimensions.setTo(0.5 * height, radius, radius);
	}
	
	override public function getName():String 
	{
		return "CapsuleX";
	}
	
}