package org.angle3d.effect.gpu.influencers.velocity;

import org.angle3d.effect.gpu.influencers.AbstractInfluencer;
import org.angle3d.math.Vector3f;

class ConeVelocityInfluencer extends AbstractInfluencer implements IVelocityInfluencer {
	private var _speed:Float;

	private var _temp:Vector3f;
	private var _variation:Float;

	public function new(speed:Float) {
		super();

		_speed = speed;

		_temp = new Vector3f();
	}

	public function getVelocity(index:Int, store:Vector3f):Vector3f {
		var degree1:Float = Math.random() * Math.PI * 2;
		var degree2:Float = Math.PI * 80 / 180 + Math.random() * Math.PI * 5 / 180;

		store.x = _speed * Math.sin(degree1) * Math.cos(degree2);
		store.y = _speed * Math.sin(degree2);
		store.z = _speed * Math.cos(degree1) * Math.cos(degree2);

		return store;
	}
}
