package org.angle3d.effect.gpu.influencers;

import org.angle3d.effect.gpu.ParticleShapeGenerator;

class AbstractInfluencer implements IInfluencer
{
	private var _generator:ParticleShapeGenerator;

	public function new()
	{
	}

	public var generator(get, set):ParticleShapeGenerator;
	private function get_generator():ParticleShapeGenerator
	{
		return _generator;
	}
	private function set_generator(value:ParticleShapeGenerator):ParticleShapeGenerator
	{
		return _generator = value;
	}
}
