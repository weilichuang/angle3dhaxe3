package org.angle3d.bullet.collision.shapes;
import com.bulletphysics.collision.shapes.CylinderShape;
import com.bulletphysics.collision.shapes.CylinderShapeX;
import com.bulletphysics.collision.shapes.CylinderShapeZ;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Vector3f;
import org.angle3d.utils.Logger;

/**
 * Basic cylinder collision shape
 * @author weilichuang
 */
class CylinderCollisionShape extends CollisionShape
{
	private var halfExtents:Vector3f;
	private var axis:Int;

	public function new(halfExtents:Vector3f, axis:Int = 2)
	{
		super();
		this.halfExtents = halfExtents;
		this.axis = axis;
		createShape();
	}
	
	public function getHalfExtents():Vector3f
	{
		return this.halfExtents;
	}
	
	public function getAxis():Int
	{
		return this.axis;
	}
	
	override public function setScale(scale:Vector3f):Void 
	{
		Logger.warn("CylinderCollisionShape cannot be scaled");
	}
	
	private function createShape():Void
	{
		switch(this.axis)
		{
			case 0:
				cShape = new CylinderShapeX(Converter.a2vVector3f(halfExtents));
			case 1:
				cShape = new CylinderShape(Converter.a2vVector3f(halfExtents));
			case 2:
				cShape = new CylinderShapeZ(Converter.a2vVector3f(halfExtents));
		}
		
		cShape.setLocalScaling(Converter.a2vVector3f(getScale()));
		cShape.setMargin(margin);
	}
	
}