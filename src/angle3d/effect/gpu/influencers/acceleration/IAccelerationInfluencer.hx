package angle3d.effect.gpu.influencers.acceleration;

import angle3d.effect.gpu.influencers.IInfluencer;
import angle3d.math.Vector3f;

/**
 * 定义粒子加速度
 */
interface IAccelerationInfluencer extends IInfluencer {
	function getAcceleration(velocity:Vector3f, store:Vector3f):Vector3f;
}

