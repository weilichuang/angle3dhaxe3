package org.angle3d.animation;

import flash.Vector;
import msignal.Signal.Signal3;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.FastStringMap;
import org.angle3d.scene.control.AbstractControl;
import de.polygonal.ds.error.Assert;
import org.angle3d.utils.TempVars;

using org.angle3d.utils.ArrayUtil;

/**
 * AnimControl is a Spatial control that allows manipulation
 * of skeletal animation.
 *
 * The control currently supports:
 * 1) Animation blending/transitions
 * 2) Multiple animation channels
 * 3) Multiple skins
 * 4) Animation event listeners
 * 5) Animated model cloning
 * 6) Animated model binary import/export
 * 7) Hardware skinning
 * 8) Attachments
 * 9) Add/remove skins
 *
 * Planned:
 * 1) Morph/Pose animation
 *
 */
class AnimControl extends AbstractControl
{
	public var onAnimCycleDone(get,never):Signal3<AnimControl,AnimChannel,String>;
	public var onAnimChange(get, never):Signal3<AnimControl,AnimChannel,String>;
	
	public var numChannels(get, null):Int;
	
	/**
     * Skeleton object must contain corresponding data for the targets' weight buffers.
     */
	private var skeleton:Skeleton;
	
	/**
	 * List of animations
	 */
	private var mAnimationMap:FastStringMap<Animation>;

	/**
	 * Animation channels
	 */
	private var mChannels:Vector<AnimChannel>;

	private var _onAnimCycleDone:Signal3<AnimControl,AnimChannel,String>;
	private var _onAnimChange:Signal3<AnimControl,AnimChannel,String>;

	public function new(skeleton:Skeleton = null)
	{
		super();
		
		mAnimationMap = new FastStringMap<Animation>();
		mChannels = new Vector<AnimChannel>();

		_onAnimCycleDone = new Signal3<AnimControl,AnimChannel,String>();
		_onAnimChange = new Signal3<AnimControl,AnimChannel,String>();
		
		this.skeleton = skeleton;
		reset();
	}
	
	private function get_onAnimChange():Signal3<AnimControl,AnimChannel,String>
	{
		return _onAnimChange;
	}
	
	private function get_onAnimCycleDone():Signal3<AnimControl,AnimChannel,String>
	{
		return _onAnimCycleDone;
	}
	
	public inline function getSkeleton():Skeleton
	{
        return skeleton;
    }
	
	public function setAnimations(animations:FastStringMap<Animation>):Void
	{
		this.mAnimationMap = animations;
	}
	
	public function getAnimation(name:String):Animation
	{
		return mAnimationMap.get(name);
	}

	public function addAnimation(animation:Animation):Void
	{
		mAnimationMap.set(animation.name, animation);
	}

	public function removeAnimation(anim:Animation):Void
	{
		mAnimationMap.remove(anim.name);
	}
	
	public function getAnimationNames():Array<String>
	{
		return mAnimationMap.keys();
	}

	public function getAnimationLength(name:String):Float
	{
		var a:Animation = mAnimationMap.get(name);

		#if debug
		Assert.assert(a != null, "The animation " + name + " does not exist in this AnimControl");
		#end

		return a.length;
	}

	/**
	 * Create a new animation channel, by default assigned to all bones
	 * in the skeleton.
	 *
	 * @return A new animation channel for this `AnimControl`.
	 */
	public function createChannel():AnimChannel
	{
		var channel:AnimChannel = new AnimChannel(this);
		mChannels.push(channel);
		return channel;
	}
	
	public function removeChannel(channel:AnimChannel):Void
	{
		var index:Int = mChannels.indexOf(channel);
		if (index != -1)
			mChannels.splice(index, 1);
	}

	public function getChannel(index:Int):AnimChannel
	{
		return mChannels[index];
	}
	
	private inline function get_numChannels():Int
	{
		return mChannels.length;
	}

	public function clearChannels():Void
	{
		for (channel in mChannels)
		{
			_onAnimCycleDone.dispatch(this, channel, channel.getAnimationName());
		}
		mChannels.length = 0;
	}
	
	/**
	 * Internal use only.
	 */
	override private function controlUpdate(tpf:Float):Void
	{
		if (skeleton != null)
		{
			skeleton.reset();
		}
		
		for (i in 0...numChannels)
		{
			mChannels[i].update(tpf);
		}
		
		if (skeleton != null)
			skeleton.update();
	}
	
	public function notifyAnimChange(channel:AnimChannel, name:String):Void
	{
		_onAnimChange.dispatch(this, channel, name);
	}
	
	public function notifyAnimCycleDone(channel:AnimChannel, name:String):Void
	{
		_onAnimCycleDone.dispatch(this, channel, name);
	}
	
	public function clearListeners():Void
	{
		_onAnimChange.removeAll();
		_onAnimCycleDone.removeAll();
	}
	
	override public function setSpatial(value:Spatial):Void 
	{
		super.setSpatial(value);
	}
	
	public function reset():Void
	{
		if (skeleton != null)
			skeleton.resetAndUpdate();
	}
}

