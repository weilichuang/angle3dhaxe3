package angle3d.bullet.collision.shapes.infos;

import angle3d.math.Vector3f;
import angle3d.math.Matrix3f;

class ChildCollisionShape {
	public var location:Vector3f;
	public var rotation:Matrix3f;
	public var shape:CollisionShape;

	public function new(location:Vector3f, rotation:Matrix3f, shape:CollisionShape) {
		this.location = location;
		this.rotation = rotation;
		this.shape = shape;
	}

}