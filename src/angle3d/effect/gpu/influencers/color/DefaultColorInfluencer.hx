package angle3d.effect.gpu.influencers.color;

import angle3d.effect.gpu.influencers.AbstractInfluencer;
import angle3d.math.Color;

class DefaultColorInfluencer extends AbstractInfluencer implements IColorInfluencer {
	private var _color:UInt;

	public function new(color:UInt = 0x0) {
		super();
		_color = color;
	}

	public function getColor(index:Int, color:Color):Color {
		color.setRGB(_color);
		return color;
	}
}
