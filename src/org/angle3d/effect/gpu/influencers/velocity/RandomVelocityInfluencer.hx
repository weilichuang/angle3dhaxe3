package org.angle3d.effect.gpu.influencers.velocity;

import org.angle3d.effect.gpu.influencers.AbstractInfluencer;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;

/***
 * 四面八方随机
 */
class RandomVelocityInfluencer extends AbstractInfluencer implements IVelocityInfluencer {
	private var _speed:Float;

	private var _variation:Float;

	private var _temp:Vector3f;

	public function new(speed:Float, variation:Float = 0) {
		super();

		_speed = speed;

		_variation = FastMath.clamp(variation, 0.0, 1.0);

		_temp = new Vector3f();
	}

	public function getVelocity(index:Int, store:Vector3f):Vector3f {
		_temp.x = (Math.random() * 2 - 1);
		_temp.y = (Math.random() * 2 - 1);
		_temp.z = (Math.random() * 2 - 1);
		_temp.normalizeLocal();

		store.x = _temp.x * _speed;
		store.y = _temp.y * _speed;
		store.z = _temp.z * _speed;

		return store;
	}
}
