package org.angle3d.animation;

import org.angle3d.utils.TempVars;

/**
 * SkeletonAnimControl is a Spatial control that allows manipulation
 * of skeletal animation.
 *
 */
class SkeletonAnimControl extends AnimControl
{
	/**
	 * Skeleton object must contain corresponding data for the targets' weight buffers.
	 */
	//public var skeleton:Skeleton;

	public function new(skeleton:Skeleton)
	{
		super(skeleton);

		//this.skeleton = skeleton;
		this.skeleton.resetAndUpdate();

	}

	override private function controlUpdate(tpf:Float):Void
	{
		if (numChannels > 0)
		{
			skeleton.reset();

			for (i in 0...numChannels)
			{
				mChannels[i].update(tpf);
			}
			
			skeleton.update();
		}
	}
}
