package org.angle3d.animation;

import org.angle3d.cinematic.LoopMode;
import org.angle3d.math.FastMath;
import org.angle3d.error.Assert;
import org.angle3d.utils.Logger;
import org.angle3d.utils.TempVars;

/**
 * `AnimChannel` provides controls, such as play, pause, fast forward, etc, for an animation.
 * The animation channel may influence the entire model or specific bones of the model's
 * skeleton. A single model may have multiple animation channels influencing
 * various parts of its body. For example, a character model may have an
 * animation channel for its feet, and another for its torso, and
 * the animations for each channel are controlled independently.
 *
 */
class AnimChannel {
	private static inline var DEFAULT_BLEND_TIME:Float = 0.15;

	public var control:AnimControl;

	private var affectedBones:Array<Bool>;

	private var animation:Animation;
	private var blendFrom:Animation;
	private var time:Float;
	private var speed:Float;
	private var timeBlendFrom:Float;
	private var blendTime:Float;
	private var speedBlendFrom:Float;
	private var notified:Bool = false;

	private var loopMode:LoopMode;
	private var loopModeBlendFrom:LoopMode;

	private var blendAmount:Float = 1;
	private var blendRate:Float = 0;

	public function new(control:AnimControl) {
		this.control = control;
	}

	public function getControl():AnimControl {
		return this.control;
	}

	/**
	 * @return The name of the currently playing animation, or null if
	 * none is assigned.
	 *
	 * @see `AnimChannel.setAnim`
	 */
	public function getAnimationName():String {
		return animation != null ? animation.name : "";
	}

	/**
	 * @return The loop mode currently set_for the animation. The loop mode
	 * determines what will happen to the animation once it finishes
	 * playing.
	 *
	 * For more information, see the LoopMode enum class.
	 * @see `LoopMode`
	 * @see `AnimChannel.setLoopMode`
	 */
	public function getLoopMode():LoopMode {
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
	public function setLoopMode(mode:LoopMode):Void {
		this.loopMode = mode;
	}

	/**
	 * @return The speed that is assigned to the animation channel. The speed
	 * is a scale value starting from 0.0, at 1.0 the animation will play
	 * at its default speed.
	 *
	 * @see `AnimChannel.setSpeed`
	 */
	public function getSpeed():Float {
		return speed;
	}

	/**
	 * @param speed set the speed of the animation channel. The speed
	 * is a scale value starting from 0.0, at 1.0 the animation will play
	 * at its default speed.
	 */
	public function setSpeed(speed:Float):Void {
		this.speed = speed;
		if (blendTime > 0) {
			this.speedBlendFrom = speed;
			blendTime = Math.min(blendTime, animation.length / speed);
			if (blendTime != 0)
				blendRate = 1 / blendTime;
			else
				blendRate = 0;
		}
	}

	/**
	 * @return The time of the currently playing animation. The time
	 * starts at 0 and continues on until getAnimMaxTime().
	 *
	 * @see `AnimChannel.setTime`
	 */
	public function getTime():Float {
		return time;
	}

	/**
	 * @param speed set_the speed of the animation channel. The speed
	 * is a scale value starting from 0.0, at 1.0 the animation will play
	 * at its default speed.
	 */
	public function setTime(time:Float):Void {
		this.time = FastMath.clamp(time, 0, getAnimMaxTime());
	}

	/**
	 * @return The length of the currently playing animation, or zero
	 * if no animation is playing.
	 *
	 * @see `AnimChannel.getTime`
	 */
	public function getAnimMaxTime():Float {
		return animation != null ? animation.length : 0;
	}

	/**
	 * set the current animation that is played by this AnimChannel.
	 * <p>
	 * This resets the time to zero, and optionally blends the animation
	 * over `blendTime` seconds with the currently playing animation.
	 * Notice that this method will reset the control's speed to 1.0.
	 *
	 * @param name The name of the animation to play
	 * @param blendTime The blend time over which to blend the new animation
	 * with the old one. If zero, then no blending will occur and the new
	 * animation will be applied instantly.
	 */
	public function setAnim(name:String, blendTime:Float = 0):Void {
		#if debug
		Assert.assert(name != null, "name cannot be null");
		Assert.assert(blendTime >= 0.0, "blendTime cannot be less than zero");
		#end

		var anim:Animation = control.getAnimation(name);

		#if debug
		Assert.assert(anim != null, "Cannot find animation named: '" + name + "'");
		#end

		control.notifyAnimChange(this, name);

		if (animation != null && blendTime > 0) {
			this.blendTime = blendTime;
			// activate blending
			blendFrom = animation;
			blendTime = Math.min(blendTime, anim.length / speed);
			timeBlendFrom = time;
			speedBlendFrom = speed;
			loopModeBlendFrom = loopMode;
			blendAmount = 0;
			blendRate = 1 / blendTime;
		} else
		{
			blendFrom = null;
		}

		animation = anim;
		time = 0;
		this.speed = 1;
		this.loopMode = LoopMode.Loop;
		notified = false;
	}

	/**
	 * Add all the bones of the model's skeleton to be
	 * influenced by this animation channel.
	 */
	public function addAllBones():Void {
		affectedBones = null;
	}

	public function addBone(bone:Bone):Void {
		var boneIndex:Int = control.getSkeleton().getBoneIndex(bone);
		if (affectedBones == null) {
			affectedBones = new Array<Bool>(control.getSkeleton().numBones);
		}
		affectedBones[boneIndex] = true;
	}

	public function addBoneByName(name:String):Void {
		addBone(control.getSkeleton().getBoneByName(name));
	}

	public function addToRootBone(bone:Bone):Void {
		addBone(bone);
		while (bone.parent != null) {
			bone = bone.parent;
			addToRootBone(bone);
		}
	}

	public function addToRootBoneByName(name:String):Void {
		addToRootBone(control.getSkeleton().getBoneByName(name));
	}

	public function addFromRootBone(bone:Bone):Void {
		addBone(bone);

		var children:Array<Bone> = bone.children;
		if (children == null)
			return;

		for (i in 0...children.length) {
			addBone(children[i]);
		}
	}

	public function addFromRootBoneByName(name:String):Void {
		addFromRootBone(control.getSkeleton().getBoneByName(name));
	}

	public inline function getAffectedBones():Array<Bool> {
		return affectedBones;
	}

	public function stopAnimation():Void {
		animation = null;
	}

	public function reset(rewind:Bool):Void {
		if (rewind) {
			setTime(0);
			if (control.getSkeleton() != null) {
				control.getSkeleton().resetAndUpdate();
			} else {
				update(0);
			}
		}
		animation = null;
		notified = false;
	}

	public function update(tpf:Float):Void {
		if (animation == null)
			return;

		if (blendFrom != null && blendAmount != 1.0) {
			// The blendFrom anim is set, the actual animation
			// playing will be set
			blendFrom.setTime(timeBlendFrom, 1 - blendAmount, control, this);

			timeBlendFrom += tpf * speedBlendFrom;
			timeBlendFrom = AnimationUtils.clampWrapTime(timeBlendFrom, blendFrom.length, loopModeBlendFrom);
			if (timeBlendFrom < 0) {
				timeBlendFrom = -timeBlendFrom;
				speedBlendFrom = -speedBlendFrom;
			}

			blendAmount += tpf * blendRate;
			if (blendAmount > 1) {
				blendAmount = 1;
				blendFrom = null;
			}
		}

		animation.setTime(time, blendAmount, control, this);
		time += tpf * speed;

		if (animation.length > 0) {
			if (!notified && (time >= animation.length || time < 0)) {
				if (loopMode == LoopMode.DontLoop) {
					// Note that this flag has to be set before calling the notify
					// since the notify may start a new animation and then unset
					// the flag.
					notified = true;
				}
				control.notifyAnimCycleDone(this, animation.name);
			}
		}

		time = AnimationUtils.clampWrapTime(time, animation.length, loopMode);
		if (time < 0) {
			// Negative time indicates that speed should be inverted
			// (for cycle loop mode only)
			time = -time;
			speed = -speed;
		}
	}
}

