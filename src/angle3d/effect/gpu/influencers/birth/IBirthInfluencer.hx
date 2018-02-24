package angle3d.effect.gpu.influencers.birth;

import angle3d.effect.gpu.influencers.IInfluencer;

/**
 * 定义粒子出生时间
 */
interface IBirthInfluencer extends IInfluencer {
	function getBirth(index:Int):Float;
}

