package org.angle3d.effect.gpu.influencers.alpha;

import org.angle3d.effect.gpu.influencers.AbstractInfluencer;

class RandomAlphaInfluencer extends AbstractInfluencer implements IAlphaInfluencer
{
	public function new()
	{
		super();
	}

	public function getAlpha(index:Int):Float
	{
		return Math.random();
	}
}

