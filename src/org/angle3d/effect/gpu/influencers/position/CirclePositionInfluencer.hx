package org.angle3d.effect.gpu.influencers.position;

import org.angle3d.effect.gpu.influencers.AbstractInfluencer;
import org.angle3d.math.Vector3f;

/**
 * 粒子随机分配在一个圆环平面内
 * edge为true时，粒子都在圆环上
 * random为true时，随机分配位置,否则均匀分配--->如何均匀分配呢
 */
class CirclePositionInfluencer extends AbstractInfluencer implements IPositionInfluencer {
	private var _center:Vector3f;
	private var _radius:Float;
	private var _startAngle:Float;

	public function new(center:Vector3f, radius:Float, startAngle:Float) {
		super();

		_center = center;
		_radius = radius;
		_startAngle = startAngle;
	}

	public function getPosition(index:Int, store:Vector3f):Vector3f {
		var _perAngle:Float = Math.PI * 2 / _generator.perSecondParticleCount;

		index = index % _generator.perSecondParticleCount;

		store.x = _center.x + Math.sin(index * _perAngle) * _radius;
		store.y = _center.y;
		store.z = _center.z + Math.cos(index * _perAngle) * _radius;

		return store;
	}
}
