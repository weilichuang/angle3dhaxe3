package org.angle3d.effect.gpu.influencers.scale;

import org.angle3d.effect.gpu.influencers.AbstractInfluencer;
import org.angle3d.math.FastMath;

/**
 * 粒子缩放
 */
class DefaultScaleInfluencer extends AbstractInfluencer implements IScaleInfluencer
{
	private var _scale:Float;
	private var _variation:Float;

	public function new(scale:Float = 1.0, variation:Float = 0.0)
	{
		super();
		_scale = scale;
		_variation = variation;
	}

	public function getDefaultScale(index:Int):Float
	{
		return FastMath.lerp(_scale, Math.random() * 2 - 1, _variation);
	}
}
