package org.angle3d.effect.gpu.influencers.spritesheet;

import org.angle3d.effect.gpu.influencers.IInfluencer;

/**
 * 定义粒子当前帧和总帧数
 */
interface ISpriteSheetInfluencer extends IInfluencer {
	/**
	 * 总帧数
	 */
	function getTotalFrame():Int;
	function getDefaultFrame():Int;
}

