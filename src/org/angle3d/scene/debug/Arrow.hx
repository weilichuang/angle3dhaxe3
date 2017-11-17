package org.angle3d.scene.debug;

import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.shape.WireframeLineSet;
import org.angle3d.scene.shape.WireframeShape;

/**
 * ...

 */
class Arrow extends WireframeShape {
	private var _curExtent:Vector3f = new Vector3f(-1e30,-1e30,-1e30);

	private var tempQuat:Quaternion = new Quaternion();
	private var tempVec:Vector3f = new Vector3f();

	private static var positions:Array<Float> = [
				0, 0, 0,
				0, 0, 1, // tip
				0.05, 0, 0.9, // tip right
				-0.05, 0, 0.9, // tip left
				0, 0.05, 0.9, // tip top
				0, -0.05, 0.9, // tip buttom
			];

	private static var indices:Array<Int> = [0, 1,
			1, 2,
			1, 3,
			1, 4,
			1, 5];

	public function new(extent:Vector3f) {
		super();

		setArrowExtent(extent);
	}

	/**
	 * Sets the arrow's extent.
	 * This will modify the buffers on the mesh.
	 *
	 * @param extent the arrow's extent.
	 */

	public function setArrowExtent(extent:Vector3f):Void {
		if (_curExtent.equals(extent))
			return;

		_curExtent.copyFrom(extent);

		var len:Float = _curExtent.length;
		var dir:Vector3f = _curExtent.normalize();

		tempQuat.lookAt(dir, Vector3f.UNIT_Y);
		tempQuat.normalizeLocal();

		var newPositions:Array<Float> = new Array<Float>(positions.length);
		var i:Int = 0;
		while (i < newPositions.length) {
			var vec:Vector3f = tempVec.setTo(positions[i], positions[i + 1], positions[i + 2]);
			vec.scaleLocal(len);
			tempQuat.multVector(vec, vec);

			newPositions[i] = vec.x;
			newPositions[i + 1] = vec.y;
			newPositions[i + 2] = vec.z;

			i += 3;
		}

		if (mSegments.length == 0) {
			var j:Int = 0;
			while (j < indices.length) {
				addSegment(new WireframeLineSet(0, 0, 0,
				0, 0, 0));

				j += 2;
			}
		}

		var index:Int = 0;
		var j:Int = 0;
		while (j < indices.length) {
			var sIndex:Int = indices[j];
			var eIndex:Int = indices[j + 1];
			mSegments[index++].setTo(newPositions[sIndex*3+0], newPositions[sIndex*3+1], newPositions[sIndex*3+2],
									 newPositions[eIndex * 3 + 0], newPositions[eIndex * 3 + 1], newPositions[eIndex * 3 + 2]);

			j += 2;
		}
		build();
	}

}