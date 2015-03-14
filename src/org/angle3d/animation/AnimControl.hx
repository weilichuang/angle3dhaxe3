package org.angle3d.animation;

import haxe.ds.UnsafeStringMap;
import org.angle3d.scene.control.AbstractControl;
import de.polygonal.ds.error.Assert;
import org.angle3d.utils.TempVars;

using org.angle3d.utils.ArrayUtil;
/**
 * AnimControl is a Spatial control that allows manipulation
 * of animation.
 *
 */
class AnimControl extends AbstractControl
{
	public var numChannels(get, null):Int;
	
	/**
	 * List of animations
	 */
	private var mAnimationMap:UnsafeStringMap<Animation>;

	/**
	 * Animation channels
	 */
	private var mChannels:Array<AnimChannel>;

	private var mNumChannels:Int;

	public function new()
	{
		super();

		mAnimationMap = new UnsafeStringMap<Animation>();

		mChannels = new Array<AnimChannel>();
		mNumChannels = 0;
	}
	
	private inline function get_numChannels():Int
	{
		return mNumChannels;
	}

	public function addAnimation(name:String, animation:Animation):Void
	{
		mAnimationMap.set(name, animation);
	}

	public function getAnimation(name:String):Animation
	{
		return mAnimationMap.get(name);
	}

	public function getAnimationLength(name:String):Float
	{
		var a:Animation = mAnimationMap.get(name);

		#if debug
		Assert.assert(a != null, "The animation " + name + " does not exist in this AnimControl");
		#end

		return a.time;
	}

	public function removeChannel(channel:AnimChannel):Void
	{
		if (mChannels.remove(channel))
		{
			mNumChannels--;
		}
	}

	/**
	 * Create a new animation channel, by default assigned to all bones
	 * in the skeleton.
	 *
	 * @return A new animation channel for this <code>AnimControl</code>.
	 */
	public function createChannel():AnimChannel
	{
		var channel:AnimChannel = new AnimChannel(this);
		mChannels.push(channel);
		mNumChannels++;
		return channel;
	}

	/**
	 * Internal use only.
	 */
	override private function controlUpdate(tpf:Float):Void
	{
		if (mNumChannels > 0)
		{
			for (i in 0...mNumChannels)
			{
				mChannels[i].update(tpf);
			}
		}
	}
}

