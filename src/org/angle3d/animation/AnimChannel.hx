package org.angle3d.animation;

import org.angle3d.cinematic.LoopMode;
import org.angle3d.math.FastMath;
import de.polygonal.ds.error.Assert;
import org.angle3d.utils.TempVars;

/**
 * AnimChannel provides controls, such as play, pause,
 * fast forward, etc, for an animation. The animation
 * channel may influence the entire model or specific bones of the model's
 * skeleton. A single model may have multiple animation channels influencing
 * various parts of its body. For example, a character model may have an
 * animation channel for its feet, and another for its torso, and
 * the animations for each channel are controlled independently.
 *
 */
class AnimChannel
{
	private static var DEFAULT_BLEND_TIME:Float = 0.15;

	private static function clampWrapTime(t:Float, max:Float, loopMode:Int):Float
	{
		if (max == Math.POSITIVE_INFINITY)
			return t;

		if (t < 0)
		{
			switch (loopMode)
			{
				case LoopMode.DontLoop:
					return 0;
				case LoopMode.Cycle:
					return t;
				case LoopMode.Loop:
					return max - t;
			}
		}
		else if (t > max)
		{
			switch (loopMode)
			{
				case LoopMode.DontLoop:
					return max;
				case LoopMode.Cycle:
					return t - 2 * max;
				case LoopMode.Loop:
					return t - max;
			}
		}

		return t;
	}

	public var control:AnimControl;

	private var animation:Animation;
	private var blendFromAnimation:Animation;
	private var time:Float;
	private var speed:Float;
	private var timeBlendFrom:Float;
	private var speedBlendFrom:Float;

	private var loopMode:Int;
	private var loopModeBlendFrom:Int;

	private var blendAmount:Float;
	private var blendRate:Float;

	public function new(control:AnimControl)
	{
		blendAmount = 1.0;
		blendRate = 0.0;

		this.control = control;
	}

	/**
	 * @return The name of the currently playing animation, or null if
	 * none is assigned.
	 *
	 * @see AnimChannel#setAnim(java.lang.String)
	 */
	public function getAnimationName():String
	{
		return animation != null ? animation.name : "";
	}

	/**
	 * @return The loop mode currently set_for the animation. The loop mode
	 * determines what will happen to the animation once it finishes
	 * playing.
	 *
	 * For more information, see the LoopMode enum class.
	 * @see LoopMode
	 * @see AnimChannel#setLoopMode(com.jme3.animation.LoopMode)
	 */
	public function getLoopMode():Int
	{
		return loopMode;
	}

	/**
	 * @param loopMode set_the loop mode for the channel. The loop mode
	 * determines what will happen to the animation once it finishes
	 * playing.
	 *
	 * For more information, see the LoopMode enum class.
	 * @see LoopMode
	 */
	public function setLoopMode(mode:Int):Void
	{
		this.loopMode = mode;
	}

	/**
	 * @return The speed that is assigned to the animation channel. The speed
	 * is a scale value starting from 0.0, at 1.0 the animation will play
	 * at its default speed.
	 *
	 * @see AnimChannel#setSpeed(float)
	 */
	public function getSpeed():Float
	{
		return speed;
	}

	/**
	 * @param speed set_the speed of the animation channel. The speed
	 * is a scale value starting from 0.0, at 1.0 the animation will play
	 * at its default speed.
	 */
	public function setSpeed(speed:Float):Void
	{
		this.speed = speed;
	}

	/**
	 * @return The time of the currently playing animation. The time
	 * starts at 0 and continues on until getAnimMaxTime().
	 *
	 * @see AnimChannel#setTime(float)
	 */
	public function getTime():Float
	{
		return time;
	}

	/**
	 * @param speed set_the speed of the animation channel. The speed
	 * is a scale value starting from 0.0, at 1.0 the animation will play
	 * at its default speed.
	 */
	public function setTime(time:Float):Void
	{
		this.time = FastMath.clamp(time, 0, getAnimMaxTime());
	}

	/**
	 * @return The length of the currently playing animation, or zero
	 * if no animation is playing.
	 *
	 * @see AnimChannel#getTime()
	 */
	public function getAnimMaxTime():Float
	{
		return animation != null ? animation.time : 0;
	}

	/**
	 * set_the current animation that is played by this AnimChannel.
	 * <p>
	 * This resets the time to zero, and optionally blends the animation
	 * over <code>blendTime</code> seconds with the currently playing animation.
	 * Notice that this method will reset_the control's speed to 1.0.
	 *
	 * @param name The name of the animation to play
	 * @param blendTime The blend time over which to blend the new animation
	 * with the old one. If zero, then no blending will occur and the new
	 * animation will be applied instantly.
	 */
	public function playAnimation(name:String, loopMode:Int, speed:Float = 1.0, blendTime:Float = 0.0):Void
	{
		var newAnimation:Animation = control.getAnimation(name);

		#if debug
		Assert.assert(blendTime >= 0.0, "blendTime cannot be less than zero");
		Assert.assert(newAnimation != null, "Cannot find animation named: '" + name + "'");
		#end

		if (animation != null && blendTime > 0)
		{
			// activate blending
			blendFromAnimation = animation;
			timeBlendFrom = time;
			speedBlendFrom = speed;
			loopModeBlendFrom = loopMode;
			blendAmount = 0;
			blendRate = 1 / blendTime;
		}

		animation = newAnimation;
		time = 0;
		this.speed = speed;
		this.loopMode = loopMode;
	}

	public function stopAnimation():Void
	{
		animation = null;
	}

	public function update(tpf:Float, vars:TempVars):Void
	{
		if (animation == null)
			return;

		if (blendFromAnimation != null)
		{
			blendFromAnimation.setTime(timeBlendFrom, 1 - blendAmount, control, this, vars);

			timeBlendFrom += tpf * speedBlendFrom;
			timeBlendFrom = clampWrapTime(timeBlendFrom, blendFromAnimation.time, loopModeBlendFrom);
			if (timeBlendFrom < 0)
			{
				timeBlendFrom = -timeBlendFrom;
				speedBlendFrom = -speedBlendFrom;
			}

			blendAmount += tpf * blendRate;
			if (blendAmount > 1)
			{
				blendAmount = 1;
				blendFromAnimation = null;
			}
		}

		animation.setTime(time, blendAmount, control, this, vars);

		time += tpf * speed;

		time = clampWrapTime(time, animation.time, loopMode);
		if (time < 0)
		{
			time = -time;
			speed = -speed;
		}
	}
}

