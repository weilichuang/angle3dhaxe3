package com.bulletphysics.collision.shapes;
import vecmath.Vector3f;

/**
 * ConcaveShape class provides an interface for non-moving (static) concave shapes.
 * @author weilichuang
 */
class ConcaveShape extends CollisionShape
{
	private var collisionMargin:Float = 0.0;

	public function new() 
	{
		super();
	}
	
	public function processAllTriangles(callback:TriangleCallback,aabbMin:Vector3f,aabbMax:Vector3f):Void
	{
		
	}
	
	override public function getMargin():Float
	{
		return collisionMargin;
	}
	
	override public function setMargin(margin:Float):Void
	{
		this.collisionMargin = margin;
	}
	
}