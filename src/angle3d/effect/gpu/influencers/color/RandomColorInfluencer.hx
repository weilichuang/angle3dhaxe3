package angle3d.effect.gpu.influencers.color;

import angle3d.effect.gpu.influencers.AbstractInfluencer;
import angle3d.math.Color;

class RandomColorInfluencer extends AbstractInfluencer implements IColorInfluencer {
	public function new() {
		super();
	}

	public function getColor(index:Int, color:Color):Color {
		color.r = Math.random();
		color.g = Math.random();
		color.b = Math.random();
		return color;
	}
}

