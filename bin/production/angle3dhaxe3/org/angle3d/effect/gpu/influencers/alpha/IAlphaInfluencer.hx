package org.angle3d.effect.gpu.influencers.alpha;

import org.angle3d.effect.gpu.influencers.IInfluencer;

interface IAlphaInfluencer extends IInfluencer
{
	function getAlpha(index:Int):Float;
}

