package org.angle3d.bullet.collision.shapes;
import com.bulletphysics.collision.shapes.BU_Simplex1to4;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Vector3f;

/**
 * ...
 
 */
class SimplexCollisionShape extends CollisionShape
{
	private var vector1:Vector3f;
	private var vector2:Vector3f;
	private var vector3:Vector3f;
	private var vector4:Vector3f;

	public function new(point1:Vector3f, point2:Vector3f = null, point3:Vector3f = null, point4:Vector3f = null)
	{
		super();
		this.vector1 = point1;
		this.vector2 = point2;
		this.vector3 = point3;
		this.vector4 = point4;
		createShape();
	}
	
	private function createShape():Void
	{
		var simplexShape:BU_Simplex1to4 = new BU_Simplex1to4();
		if (this.vector1 != null)
		{
			simplexShape.addVertex(this.vector1);
		}
		if (this.vector2 != null)
		{
			simplexShape.addVertex(this.vector2);
		}
		if (this.vector3 != null)
		{
			simplexShape.addVertex(this.vector3);
		}
		if (this.vector4 != null)
		{
			simplexShape.addVertex(this.vector4);
		}
		cShape = simplexShape;
		cShape.setLocalScaling(getScale());
		cShape.setMargin(margin);
	}
}