package org.angle3d.bullet.collision.shapes;
import com.bulletphysics.collision.shapes.BoxShape;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Vector3f;

/**
 * Basic box collision shape
 * @author weilichuang
 */
class BoxCollisionShape extends CollisionShape
{
	private var halfExtents:Vector3f;

	public function new(halfExtents:Vector3f) 
	{
		super();
		this.halfExtents = halfExtents;
		createShape();
	}
	
	public function getHalfExtents():Vector3f
	{
		return halfExtents;
	}
	
	private function createShape():Void
	{
        cShape = new BoxShape(Converter.a2vVector3f(halfExtents));
        cShape.setLocalScaling(Converter.a2vVector3f(getScale()));
        cShape.setMargin(margin);
    }
}