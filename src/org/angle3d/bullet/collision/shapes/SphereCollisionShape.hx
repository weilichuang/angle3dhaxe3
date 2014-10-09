package org.angle3d.bullet.collision.shapes;
import com.bulletphysics.collision.shapes.SphereShape;
import org.angle3d.bullet.util.Converter;

/**
 * Basic sphere collision shape
 * @author weilichuang
 */
class SphereCollisionShape extends CollisionShape
{
	private var radius:Float;

	public function new(radius:Float) 
	{
		super();
		this.radius = radius;
	}
	
	public function getRadius():Float
	{
		return this.radius;
	}
	
	private function createShape():Void
	{
		cShape = new SphereShape(radius);
		cShape.setLocalScaling(Converter.a2vVector3f(getScale()));
		cShape.setMargin(margin);
	}
}