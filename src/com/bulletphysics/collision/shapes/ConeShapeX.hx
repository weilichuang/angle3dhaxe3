package com.bulletphysics.collision.shapes;

/**
 * ...
 * @author weilichuang
 */
class ConeShapeX extends ConeShape
{

	public function new(radius:Float,height:Float) 
	{
		super(radius, height);
		setConeUpIndex(0);
	}
	
}