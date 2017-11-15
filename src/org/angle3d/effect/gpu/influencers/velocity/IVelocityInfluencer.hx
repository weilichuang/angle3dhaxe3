package org.angle3d.effect.gpu.influencers.velocity;

import org.angle3d.math.Vector3f;
import org.angle3d.effect.gpu.influencers.IInfluencer;

/**
 * 定义粒子速度
 */
interface IVelocityInfluencer extends IInfluencer {
	function getVelocity(index:Int, store:Vector3f):Vector3f;
}

