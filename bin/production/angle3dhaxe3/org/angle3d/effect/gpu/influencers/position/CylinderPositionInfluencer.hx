package org.angle3d.effect.gpu.influencers.position;

import org.angle3d.effect.gpu.influencers.AbstractInfluencer;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;

/**
 * 圆柱形
 */
class CylinderPositionInfluencer extends AbstractInfluencer implements IPositionInfluencer
{
	private var _center:Vector3f;
	private var _height:Float;
	private var _radius:Float;
	private var _radiusSquared:Float;
	private var _edge:Bool;
	private var _random:Bool;


	private var _randomPoint:Vector2f;

	/**
	 *
	 * @param height 高度
	 * @param center 底部中心点位置
	 * @param radius 圆柱半径
	 * @param edge 是否放置边缘
	 * @param random 是否随机位置
	 *
	 */
	public function new(height:Float, center:Vector3f, radius:Float, edge:Bool = false, random:Bool = true)
	{
		super();
		
		_height = height;
		_center = center;
		_radius = radius;
		_radiusSquared = radius * radius;
		_edge = edge;
		_random = random;

		_randomPoint = new Vector2f();
	}

	public function getPosition(index:Int, store:Vector3f):Vector3f
	{
		if (_edge)
		{
			_randomPoint.x = (Math.random() * 2 - 1);
			_randomPoint.y = (Math.random() * 2 - 1);
			_randomPoint.normalizeLocal();

			store.x = _center.x + _randomPoint.x * _radius;
			store.z = _center.z + _randomPoint.y * _radius;
		}
		else
		{
			var scx:Float;
			var scz:Float;
			do
			{
				store.x = _center.x + (Math.random() * 2 - 1) * _radius;
				store.z = _center.z + (Math.random() * 2 - 1) * _radius;

				scx = store.x - _center.x;
				scz = store.z - _center.z;
			} while (scx * scx + scz * scz > _radiusSquared);
		}
		store.y = _center.y + Math.random() * _height;
		return store;
	}
}
