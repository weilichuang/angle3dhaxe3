package org.angle3d.math;

import org.angle3d.math.Vector3f;

/**
 * Represents a translation, rotation and scale in one object.
 *
 */
class Transform {
	public var rotation:Quaternion;
	public var translation:Vector3f;
	public var scale:Vector3f;

	public function new(trans:Vector3f = null, rotation:Quaternion = null, scale:Vector3f = null) {
		this.rotation = new Quaternion();
		this.translation = new Vector3f();
		this.scale = new Vector3f(1, 1, 1);

		if (trans != null) {
			this.translation.copyFrom(trans);
		}

		if (rotation != null) {
			this.rotation.copyFrom(rotation);
		}

		if (scale != null) {
			this.scale.copyFrom(scale);
		}
	}

	/**
	 * Sets this rotation to the given Quaternion value.
	 * @param rot The new rotation for this matrix.
	 */
	public inline function setRotation(rot:Quaternion):Void {
		this.rotation.copyFrom(rot);
	}

	public inline function setRotationXYZW(x:Float, y:Float, z:Float, w:Float):Void {
		this.rotation.setTo(x, y, z, w);
	}

	/**
	 * Sets this translation to the given value.
	 * @param trans The new translation for this matrix.
	 */
	public inline function setTranslation(trans:Vector3f):Void {
		this.translation.copyFrom(trans);
	}

	public inline function setTranslationXYZ(x:Float, y:Float, z:Float):Void {
		this.translation.setTo(x, y, z);
	}

	/**
	 * Sets this scale to the given value.
	 * @param scale The new scale for this matrix.
	 */
	public inline function setScale(scale:Vector3f):Void {
		this.scale.copyFrom(scale);
	}

	public inline function setScaleXYZ(x:Float, y:Float, z:Float):Void {
		this.scale.setTo(x, y, z);
	}

	/**
	 * Sets this matrix to the interpolation between the first matrix and the second by delta amount.
	 * @param t1 The begining transform.
	 * @param t2 The ending transform.
	 * @param delta An amount between 0 and 1 representing how far to interpolate from t1 to t2.
	 */
	public function interpolateTransforms(t1:Transform, t2:Transform, delta:Float):Void {
		this.rotation.slerp(t1.rotation, t2.rotation, delta);
		translation.lerp(t1.translation, t2.translation, delta);
		scale.lerp(t1.scale, t2.scale, delta);
	}

	/**
	 * Changes the values of this matrix acording to it's parent.
	 * Very similar to the concept of Node/Spatial transforms.
	 * @param parent The parent matrix.
	 * @return This matrix, after combining.
	 */
	public function combineWithParent(parent:Transform):Void {
		scale.multLocal(parent.scale);

		parent.rotation.mult(rotation, rotation);

		translation.multLocal(parent.scale);

		parent.rotation.multVecLocal(translation);

		translation.addLocal(parent.translation);
	}

	public function transformVector(inVec:Vector3f, result:Vector3f = null):Vector3f {
		if (result == null)
			result = new Vector3f();

		if (result != inVec)
			result.copyFrom(inVec);

		// multiply with scale first, then rotate, finally translate
		result.multLocal(scale);
		this.rotation.multVecLocal(result);
		result.addLocal(translation);
		return result;
	}

	public function transformInverseVector(inVec:Vector3f, result:Vector3f = null):Vector3f {
		if (result == null)
			result = new Vector3f();

		// The author of this code should look above and take the inverse of that
		// But for some reason, they didnt ..
		// in.subtract(translation, store).divideLocal(scale);
		// rot.inverse().mult(store, store);

		result.x = inVec.x - translation.x;
		result.y = inVec.y - translation.y;
		result.z = inVec.z - translation.z;

		var inverseRot:Quaternion = this.rotation.inverse();
		inverseRot.multVecLocal(result);

		result.x /= scale.x;
		result.y /= scale.y;
		result.z /= scale.z;

		return result;
	}

	/**
	 * Loads the identity.  Equal to translation=1,1,1 scale=0,0,0 rot=0,0,0,1.
	 */
	public function loadIdentity():Void {
		translation.setTo(0, 0, 0);
		scale.setTo(1, 1, 1);
		this.rotation.setTo(0, 0, 0, 1);
	}

	public function toTransformMatrix(result:Matrix4f = null):Matrix4f {
		if (result == null)
			result = new Matrix4f();
		result.setTranslation(translation.x,translation.y,translation.z);
		result.setQuaternion(this.rotation);
		result.setScale(scale.x,scale.y,scale.z);
		return result;
	}

	public function fromTransformMatrix(mat:Matrix4f):Void {
		translation.setTo(mat.tx, mat.ty, mat.tz);
		mat.toQuaternion(this.rotation);
		mat.toScaleVector(scale);
	}

	public function invertLocal():Transform {
		fromTransformMatrix(toTransformMatrix().invertLocal());
		return this;
	}

	public function invert(result:Transform = null):Transform {
		if (result == null)
			result = new Transform();

		result.fromTransformMatrix(toTransformMatrix().invertLocal());
		return result;
	}

	public function copyFrom(trans:Transform):Void {
		translation.copyFrom(trans.translation);
		rotation.copyFrom(trans.rotation);
		scale.copyFrom(trans.scale);
	}

	public function clone():Transform {
		var result:Transform = new Transform();
		result.copyFrom(this);
		return result;
	}
}

