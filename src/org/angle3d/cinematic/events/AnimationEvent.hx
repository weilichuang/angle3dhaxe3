package org.angle3d.cinematic.events;

import org.angle3d.animation.AnimChannel;
import org.angle3d.animation.AnimControl;
import org.angle3d.scene.Spatial;

//TODO 继续添加内容
class AnimationEvent extends AbstractCinematicEvent
{
	private var channel:AnimChannel;
	private var animationName:String;
	private var modelName:String;

	public function new(model:Spatial, animationName:String, initialDuration:Float = 10, mode:Int = 0)
	{
		super(initialDuration, mode);

		modelName = model.name;
		this.animationName = animationName;
		initialDuration = cast(model.getControlByClass(AnimControl),AnimControl).getAnimationLength(animationName);
	}
}
