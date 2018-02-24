package angle3d.effect.gpu.influencers;

import angle3d.effect.gpu.ParticleShapeGenerator;

interface IInfluencer {
	var generator(get,set):ParticleShapeGenerator;
}

