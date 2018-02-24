package angle3d.effect.gpu.influencers.alpha;

import angle3d.effect.gpu.influencers.AbstractInfluencer;

class DefaultAlphaInfluencer extends AbstractInfluencer implements IAlphaInfluencer {
	private var _alpha:Float;

	public function new(alpha:Float = 1.0) {
		super();
		_alpha = alpha;
	}

	public function getAlpha(index:Int):Float {
		return _alpha;
	}
}
