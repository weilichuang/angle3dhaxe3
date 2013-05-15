package org.angle3d.effect.gpu.influencers.birth;

import org.angle3d.effect.gpu.influencers.AbstractInfluencer;

/**
 * 根据每秒发射数量分开发射
 */
class PerSecondBirthInfluencer extends AbstractInfluencer implements IBirthInfluencer
{
	private var _scale:Float;

	public function new(scale:Float = 1.0)
	{
		super();
		_scale = scale;
	}

	public function getBirth(index:Int):Float
	{
		return Std.int(index / _generator.perSecondParticleCount) * _scale;
	}
}
