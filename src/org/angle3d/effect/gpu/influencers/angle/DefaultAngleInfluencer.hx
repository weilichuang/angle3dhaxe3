package org.angle3d.effect.gpu.influencers.angle;

import org.angle3d.effect.gpu.influencers.AbstractInfluencer;

class DefaultAngleInfluencer extends AbstractInfluencer implements IAngleInfluencer {
	public function new() {
		super();
	}

	public function getDefaultAngle(index:Int):Float {
		return Math.PI * 2 * Math.random();
	}
}

