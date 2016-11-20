package org.angle3d.effect.gpu.influencers.spin;

import org.angle3d.effect.gpu.influencers.AbstractInfluencer;
import org.angle3d.math.FastMath;

class DefaultSpinInfluencer extends AbstractInfluencer implements ISpinInfluencer
{
	private var _spin:Float;
	private var _variation:Float;

	public function new(spin:Float = 0, variation:Float = 0.0)
	{
		super();
		_spin = spin;
		_variation = variation;
	}

	public function getSpin(index:Int):Float
	{
		return FastMath.interpolateLinearFloat(_spin, (Math.random() * 2 - 1) * _spin, _variation);
	}
}
