package angle3d.bullet.collision.shapes;
import com.bulletphysics.collision.shapes.SphereShape;
import angle3d.bullet.util.Converter;

/**
 * Basic sphere collision shape

 */
class SphereCollisionShape extends CollisionShape {
	private var radius:Float;

	public function new(radius:Float) {
		super();
		this.radius = radius;
		createShape();
	}

	public inline function getRadius():Float {
		return this.radius;
	}

	private function createShape():Void {
		cShape = new SphereShape(radius);
		cShape.setLocalScaling(getScale());
		cShape.setMargin(margin);
	}
}