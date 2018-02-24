package angle3d.collision;

import angle3d.bounding.BoundingVolume;
import angle3d.math.Matrix4f;
import angle3d.utils.Cloneable;

/**
 * `CollisionData` is an interface that can be used to
 * do triangle-accurate collision between bounding volumes and rays.
 */
interface CollisionData extends Cloneable {
	function collideWith(other:Collidable, worldMatrix:Matrix4f, worldBound:BoundingVolume, results:CollisionResults):Int;
}

