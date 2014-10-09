package org.angle3d.bullet.collision.shapes;
import com.bulletphysics.collision.shapes.StaticPlaneShape;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Plane;

/**
 * ...
 * @author weilichuang
 */
class PlaneCollisionShape extends CollisionShape
{
	private var plane:Plane;

	public function new(plane:Plane) 
	{
		super();
		this.plane = plane;
		createShape();
	}
	
	public function getPlane():Plane
	{
		return plane;
	}
	
	private function createShape():Void
	{
		cShape = new StaticPlaneShape(Converter.a2vVector3f(plane.normal),plane.constant);
        cShape.setLocalScaling(Converter.a2vVector3f(getScale()));
        cShape.setMargin(margin);
	}
	
}