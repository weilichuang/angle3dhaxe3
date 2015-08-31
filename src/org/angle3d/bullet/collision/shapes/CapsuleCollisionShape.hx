package org.angle3d.bullet.collision.shapes;
import com.bulletphysics.collision.shapes.CapsuleShape;
import com.bulletphysics.collision.shapes.CapsuleShapeX;
import com.bulletphysics.collision.shapes.CapsuleShapeZ;
import org.angle3d.bullet.util.Converter;

/**
 * Basic capsule collision shape
 * @author weilichuang
 */
class CapsuleCollisionShape extends CollisionShape
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
		createShape();
	}
	
	public function getRadius():Float
	{
		return this.radius;
	}
	
	public function getHeight():Float
	{
		return this.height;
	}
	
	public function getAxis():Int
	{
		return this.axis;
	}
	
	private function createShape():Void
	{
		switch(this.axis)
		{
			case 0:
				cShape = new CapsuleShapeX(radius, height);
			case 1:
				cShape = new CapsuleShape(radius, height);
			case 2:
				cShape = new CapsuleShapeZ(radius, height);
		}
		
		cShape.setLocalScaling(getScale());
		cShape.setMargin(margin);
	}
	
}