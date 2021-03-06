package org.angle3d.bullet.collision.shapes;
import com.bulletphysics.collision.shapes.ConeShape;
import com.bulletphysics.collision.shapes.ConeShapeX;
import com.bulletphysics.collision.shapes.ConeShapeZ;
import org.angle3d.bullet.util.Converter;

/**
 * ...
 
 */
class ConeCollisionShape extends CollisionShape
{
	private var radius:Float;
	private var height:Float;
	private var axis:Int;

	public function new(radius:Float, height:Float, axis:Int = 1) 
	{
		super();
		this.radius = radius;
		this.height = height;
		this.axis = axis;
	}
	
	public inline function getRadius():Float
	{
		return this.radius;
	}
	
	public inline function getHeight():Float
	{
		return this.height;
	}
	
	public inline function getAxis():Int
	{
		return this.axis;
	}
	
	private function createShape():Void
	{
		switch(this.axis)
		{
			case 0:
				cShape = new ConeShapeX(radius, height);
			case 1:
				cShape = new ConeShape(radius, height);
			case 2:
				cShape = new ConeShapeZ(radius, height);
		}
		
		cShape.setLocalScaling(getScale());
		cShape.setMargin(margin);
	}
}