package angle3d.effect.gpu.influencers.alpha;

import angle3d.effect.gpu.influencers.IInfluencer;

interface IAlphaInfluencer extends IInfluencer {
	function getAlpha(index:Int):Float;
}

