package angle3d.bullet.collision.shapes;
import com.bulletphysics.collision.shapes.BoxShape;
import angle3d.bullet.util.Converter;
import angle3d.math.Vector3f;

/**
 * Basic box collision shape

 */
class BoxCollisionShape extends CollisionShape {
	private var halfExtents:Vector3f;

	public function new(halfExtents:Vector3f) {
		super();
		this.halfExtents = halfExtents;
		createShape();
	}

	public inline function getHalfExtents():Vector3f {
		return halfExtents;
	}

	private function createShape():Void {
		cShape = new BoxShape(halfExtents);
		cShape.setLocalScaling(getScale());
		cShape.setMargin(margin);
	}
}