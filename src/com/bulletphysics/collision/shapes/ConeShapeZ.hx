package com.bulletphysics.collision.shapes;

/**
 * ...
 * @author weilichuang
 */
class ConeShapeZ extends ConeShape
{

	public function new(radius:Float, height:Float) 
	{
		super(radius, height);
		setConeUpIndex(2);
	}
	
}