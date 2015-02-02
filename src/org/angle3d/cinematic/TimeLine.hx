package org.angle3d.cinematic;

import haxe.ds.IntMap;

//TODO 换一种实现
class TimeLine
{
	private var map:IntMap<KeyFrame>;
	private var keyFramesPerSeconds:Float;
	private var lastKeyFrameIndex:Int;

	public function new()
	{
		map = new IntMap<KeyFrame>();
		keyFramesPerSeconds = 30;
		lastKeyFrameIndex = 0;
	}

	public function getKeyFrameAtTime(time:Float):KeyFrame
	{
		return map.get(getKeyFrameIndexFromTime(time));
	}

	public function getKeyFrameAtIndex(keyFrameIndex:Int):KeyFrame
	{
		return map.get(keyFrameIndex);
	}

	public function addKeyFrameAtTime(time:Float, keyFrame:KeyFrame):Void
	{
		addKeyFrameAtIndex(getKeyFrameIndexFromTime(time), keyFrame);
	}

	public function addKeyFrameAtIndex(keyFrameIndex:Int, keyFrame:KeyFrame):Void
	{
		map.set(keyFrameIndex, keyFrame);
		keyFrame.setIndex(keyFrameIndex);
		if (lastKeyFrameIndex < keyFrameIndex)
		{
			lastKeyFrameIndex = keyFrameIndex;
		}
	}

	public function removeKeyFrame(keyFrameIndex:Int):Void
	{
		map.remove(keyFrameIndex);
		if (lastKeyFrameIndex == keyFrameIndex)
		{
			var kf:KeyFrame = null;
			var i:Int = keyFrameIndex;
			while (kf == null && i >= 0)
			{
				kf = getKeyFrameAtIndex(i);
				lastKeyFrameIndex = i;

				i--;
			}
		}
	}

	public function removeKeyFrameByTime(time:Float):Void
	{
		removeKeyFrame(getKeyFrameIndexFromTime(time));
	}

	public function getKeyFrameIndexFromTime(time:Float):Int
	{
		return Math.round(time * keyFramesPerSeconds);
	}

	public function getKeyFrameTime(keyFrame:KeyFrame):Float
	{
		return keyFrame.getIndex() / keyFramesPerSeconds;
	}

	//public function getAllKeyFrames():Vector<KeyFrame>
	//{
		//return map.toVector();
	//}

	public function getLastKeyFrameIndex():Int
	{
		return lastKeyFrameIndex;
	}
}

