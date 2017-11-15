package org.angle3d.effect.gpu.influencers.position;

import org.angle3d.effect.gpu.influencers.AbstractInfluencer;
import org.angle3d.math.Vector3f;

/**
 * 粒子随机分配在一个球体内
 * edge为true时，粒子都在球体表面上
 * random为true时，随机分配位置,否则均匀分配--->如何均匀分配呢
 */
class SpherePositionInfluencer extends AbstractInfluencer implements IPositionInfluencer {
	private var _center:Vector3f;
	private var _radius:Float;
	private var _radiusSquared:Float;
	private var _edge:Bool;
	private var _random:Bool;

	private var _randomPoint:Vector3f;

	public function new(center:Vector3f, radius:Float, edge:Bool = false, random:Bool = true) {
		super();

		_center = center;
		_radius = radius;
		_radiusSquared = radius * radius;
		_edge = edge;
		_random = random;
		_randomPoint = new Vector3f();
	}

	public function getPosition(index:Int, store:Vector3f):Vector3f {
		if (_edge) {
			_randomPoint.x = (Math.random() * 2 - 1);
			_randomPoint.y = (Math.random() * 2 - 1);
			_randomPoint.z = (Math.random() * 2 - 1);
			_randomPoint.normalizeLocal();

			store.x = _center.x + _randomPoint.x * _radius;
			store.y = _center.y + _randomPoint.y * _radius;
			store.z = _center.z + _randomPoint.z * _radius;
		} else
		{
			do
			{
				store.x = _center.x + (Math.random() * 2 - 1) * _radius;
				store.y = _center.y + (Math.random() * 2 - 1) * _radius;
				store.z = _center.z + (Math.random() * 2 - 1) * _radius;
			} while (store.distanceSquared(_center) > _radiusSquared);
		}

		return store;
	}
}
