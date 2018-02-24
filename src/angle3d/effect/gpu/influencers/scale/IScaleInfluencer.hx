package angle3d.effect.gpu.influencers.scale;

import angle3d.effect.gpu.influencers.IInfluencer;

/**
 * 定义粒子初始缩放
 */
interface IScaleInfluencer extends IInfluencer {
	/**
	 * 缩放
	 */
	function getDefaultScale(index:Int):Float;
}

