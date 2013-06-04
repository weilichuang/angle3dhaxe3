package org.angle3d.effect.gpu.influencers.angle;

import org.angle3d.effect.gpu.influencers.AbstractInfluencer;

class EmptyAngleInfluencer extends AbstractInfluencer implements IAngleInfluencer
{
	public function new()
	{
		super();
	}

	public function getDefaultAngle(index:Int):Float
	{
		return 0;
	}
}

