package angle3d.effect.gpu.influencers.spin;

import angle3d.effect.gpu.influencers.IInfluencer;

/**
 * 定义粒子初始自转角度
 */
interface ISpinInfluencer extends IInfluencer {
	function getSpin(index:Int):Float;
}

