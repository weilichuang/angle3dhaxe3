package org.angle3d.effect.gpu.influencers.position;

import org.angle3d.math.Vector3f;
import org.angle3d.effect.gpu.influencers.IInfluencer;

/**
 * 控制粒子的初始出现位置
 *
 * 应该也确定包围盒
 */
interface IPositionInfluencer extends IInfluencer {
	function getPosition(index:Int, store:Vector3f):Vector3f;
}
