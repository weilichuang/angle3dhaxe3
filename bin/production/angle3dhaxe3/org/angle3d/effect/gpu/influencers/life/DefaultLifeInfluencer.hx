package org.angle3d.effect.gpu.influencers.life;

import org.angle3d.effect.gpu.influencers.AbstractInfluencer;

class DefaultLifeInfluencer extends AbstractInfluencer implements ILifeInfluencer
{
	private var _lowLife:Float;
	private var _highLife:Float;

	public function new(lowLife:Float, highLife:Float)
	{
		super();
		_lowLife = lowLife;
		_highLife = highLife;
	}

	public function getLife(index:Int):Float
	{
		return _lowLife + (_highLife - _lowLife) * Math.random();
	}
}

