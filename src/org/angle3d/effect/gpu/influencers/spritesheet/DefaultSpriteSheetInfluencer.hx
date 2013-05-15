package org.angle3d.effect.gpu.influencers.spritesheet;

import org.angle3d.effect.gpu.influencers.AbstractInfluencer;

class DefaultSpriteSheetInfluencer extends AbstractInfluencer implements ISpriteSheetInfluencer
{
	private var _totalFrame:Int;

	public function new(totalFrame:Int = 1)
	{
		super();
		_totalFrame = totalFrame;
	}

	public function getTotalFrame():Int
	{
		return _totalFrame;
	}

	public function getDefaultFrame():Int
	{
		return Std.int(Math.random() * _totalFrame);
	}
}
