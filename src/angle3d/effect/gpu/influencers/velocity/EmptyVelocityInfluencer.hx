package angle3d.effect.gpu.influencers.velocity;

import angle3d.effect.gpu.influencers.AbstractInfluencer;
import angle3d.math.Vector3f;

/**
 * 速度为0
 */
class EmptyVelocityInfluencer extends AbstractInfluencer implements IVelocityInfluencer {
	public function new() {
		super();
	}

	public function getVelocity(index:Int, vector3:Vector3f):Vector3f {
		vector3.setTo(0.0, 0.0, 0.0);
		return vector3;
	}
}
