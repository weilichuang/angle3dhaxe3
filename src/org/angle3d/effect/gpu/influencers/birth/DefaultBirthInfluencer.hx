package org.angle3d.effect.gpu.influencers.birth;

import org.angle3d.effect.gpu.influencers.AbstractInfluencer;

class DefaultBirthInfluencer extends AbstractInfluencer implements IBirthInfluencer {
	public function new() {
		super();
	}

	public function getBirth(index:Int):Float {
		var perCount:Int = _generator.perSecondParticleCount;

		var count:Int = Std.int(index / perCount);

		return count + (index - count * perCount) / perCount;
	}
}

