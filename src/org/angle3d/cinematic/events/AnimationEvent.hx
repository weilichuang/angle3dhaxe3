package org.angle3d.cinematic.events;

import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import org.angle3d.animation.AnimChannel;
import org.angle3d.animation.AnimControl;
import org.angle3d.app.LegacyApplication;
import org.angle3d.cinematic.Cinematic;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.scene.Spatial;

/**
 * An event based on an animation of a model. The model has to hold an
 * AnimControl with valid animation (bone or spatial animations).
 *
 * It helps to schedule the playback of an animation on a model in a Cinematic.
 */
class AnimationEvent extends AbstractCinematicEvent {
	public static inline var MODEL_CHANNELS:String = "modelChannels";
	private var channel:AnimChannel;
	private var animationName:String;
	private var model:Spatial;
	private var blendTime:Float = 0;
	private var channelIndex:Int = 0;
	// parent cinematic
	private var cinematic:Cinematic;

	public function new(model:Spatial, animationName:String, initialDuration:Float = 10, mode:LoopMode = LoopMode.Loop,channelIndex:Int=0, blendTime:Float = 0) {
		super(initialDuration, mode);

		initialDuration = Std.instance(model.getControl(AnimControl),AnimControl).getAnimationLength(animationName);
		this.model = model;
		this.animationName = animationName;
		this.channelIndex = channelIndex;
		this.blendTime = blendTime;
	}

	override public function initEvent(app:LegacyApplication, cinematic:Cinematic):Void {
		super.initEvent(app, cinematic);
		this.cinematic = cinematic;
		if (channel == null) {
			var map:IntMap<AnimChannel> = cast cinematic.getEventData(MODEL_CHANNELS, model);
			if (map == null) {
				map = new IntMap<AnimChannel>();

				var numChannels:Int = model.getControl(AnimControl).numChannels;
				for (i in 0...numChannels) {
					map.set(i, model.getControl(AnimControl).getChannel(i));
				}
				cinematic.putEventData(MODEL_CHANNELS, model, map);
			}

			this.channel = map.get(channelIndex);
			if (this.channel == null) {
				if (model != null) {
					channel = model.getControl(AnimControl).createChannel();
					map.set(channelIndex, channel);
				} else {
					throw "modle should not be null";
				}
			}

		}
	}

	override public function setTime(time:Float):Void {
		super.setTime(time);
		if (animationName != channel.getAnimationName()) {
			channel.setAnim(animationName, blendTime);
		}

		var t:Float = time;
		if (loopMode == LoopMode.Loop) {
			t = t % channel.getAnimMaxTime();
		}

		if (loopMode == LoopMode.Cycle) {
			var parity:Float = Math.ceil(time / channel.getAnimMaxTime());

			if (parity > 0 && parity % 2 == 0) {
				t = channel.getAnimMaxTime() - t % channel.getAnimMaxTime();
			} else {
				t = t % channel.getAnimMaxTime();
			}

			if (t < 0) {
				channel.setTime(0);
				channel.reset(true);
			}
			if (t > channel.getAnimMaxTime()) {
				channel.setTime(t);
				channel.getControl().update(0);
				stop();
			} else {
				channel.setTime(t);
				channel.getControl().update(0);
			}
		}
	}

	override public function onPlay():Void {
		channel.getControl().setEnabled(true);
		if (playState == PlayState.Stopped) {
			channel.setAnim(animationName, blendTime);
			channel.setSpeed(speed);
			channel.setLoopMode(loopMode);
			channel.setTime(0);
		}
	}

	override public function setSpeed(speed:Float):Void {
		super.setSpeed(speed);
		if (channel != null) {
			channel.setSpeed(speed);
		}
	}

	override public function onUpdate(tpf:Float):Void {
		super.onUpdate(tpf);
	}

	override public function onStop():Void {
		super.onStop();
	}

	override public function forceStop():Void {
		if (channel != null) {
			channel.setTime(time);
			channel.reset(false);
		}
		super.forceStop();
	}

	override public function onPause():Void {
		if (channel != null) {
			channel.getControl().setEnabled(false);
		}
	}

	override public function setLoopMode(loopMode:LoopMode):Void {
		super.setLoopMode(loopMode);
		if (channel != null) {
			channel.setLoopMode(loopMode);
		}
	}

	override public function dispose():Void {
		super.dispose();
		if (cinematic != null) {
			var map:IntMap<AnimChannel> = cast cinematic.getEventData(MODEL_CHANNELS, model);
			if (map != null) {
				cinematic.removeEventData(MODEL_CHANNELS, model);
			}

			cinematic = null;
			channel = null;
		}
	}
}
