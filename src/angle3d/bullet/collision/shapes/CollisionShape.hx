package angle3d.bullet.collision.shapes;
import angle3d.bullet.util.Converter;
import angle3d.math.Vector3f;

/**
 * This Object holds information about a jbullet CollisionShape to be able to reuse
 * CollisionShapes (as suggested in bullet manuals)
 * TODO: add static methods to create shapes from nodes (like jbullet-Angle3D constructor)
 */
class CollisionShape {
	private var cShape:com.bulletphysics.collision.shapes.CollisionShape;
	private var scale:Vector3f = new Vector3f(1, 1, 1);
	private var margin:Float = 0.0;

	public function new() {
	}

	/**
	 * used internally, not safe
	 */
	public function calculateLocalInertia(mass:Float, vector:angle3d.math.Vector3f):Void {
		if (cShape == null) {
			return;
		}

		if (Std.is(this, MeshCollisionShape)) {
			vector.setTo(0, 0, 0);
		} else
		{
			cShape.calculateLocalInertia(mass, vector);
		}
	}

	/**
	 * used internally
	 */
	public function getCShape():com.bulletphysics.collision.shapes.CollisionShape {
		return cShape;
	}

	/**
	 * used internally
	 */
	public function setCShape(cShape:com.bulletphysics.collision.shapes.CollisionShape):Void {
		this.cShape = cShape;
	}

	public function setScale(scale:Vector3f):Void {
		this.scale.copyFrom(scale);
		cShape.setLocalScaling(scale);
	}

	public function getMargin():Float {
		return cShape.getMargin();
	}

	public function setMargin(margin:Float):Void {
		cShape.setMargin(margin);
		this.margin = margin;
	}

	public function getScale():Vector3f {
		return scale;
	}

}