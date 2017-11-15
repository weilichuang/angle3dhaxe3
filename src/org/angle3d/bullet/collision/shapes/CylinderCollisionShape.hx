package org.angle3d.bullet.collision.shapes;
import com.bulletphysics.collision.shapes.CylinderShape;
import com.bulletphysics.collision.shapes.CylinderShapeX;
import com.bulletphysics.collision.shapes.CylinderShapeZ;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Vector3f;
import org.angle3d.utils.Logger;

/**
 * Basic cylinder collision shape

 */
class CylinderCollisionShape extends CollisionShape {
	private var halfExtents:Vector3f;
	private var axis:Int;

	public function new(halfExtents:Vector3f, axis:Int = 2) {
		super();
		this.halfExtents = halfExtents;
		this.axis = axis;
		createShape();
	}

	public inline function getHalfExtents():Vector3f {
		return this.halfExtents;
	}

	public inline function getAxis():Int {
		return this.axis;
	}

	override public function setScale(scale:Vector3f):Void {
		Logger.warn("CylinderCollisionShape cannot be scaled");
	}

	private function createShape():Void {
		switch (this.axis) {
			case 0:
				cShape = new CylinderShapeX(halfExtents);
			case 1:
				cShape = new CylinderShape(halfExtents);
			case 2:
				cShape = new CylinderShapeZ(halfExtents);
		}

		cShape.setLocalScaling(getScale());
		cShape.setMargin(margin);
	}

}