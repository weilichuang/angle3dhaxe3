package org.angle3d.cinematic;

import flash.Vector;
import haxe.ds.UnsafeStringMap;
import org.angle3d.app.Application;
import org.angle3d.app.state.AppState;
import org.angle3d.app.state.AppStateManager;
import org.angle3d.cinematic.events.AbstractCinematicEvent;
import org.angle3d.cinematic.events.CinematicEvent;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.RenderManager;
import org.angle3d.scene.CameraNode;
import org.angle3d.scene.control.CameraControl;
import org.angle3d.scene.Node;

class Cinematic extends AbstractCinematicEvent implements AppState
{
	private var scene:Node;
	private var timeLine:TimeLine;
	private var lastFetchedKeyFrame:Int;
	private var cinematicEvents:Vector<CinematicEvent>;
	private var cameraMap:UnsafeStringMap<CameraNode>;
	private var currentCam:CameraNode;
	private var initialized:Bool;
	private var scheduledPause:Int;

	public function new(scene:Node, initialDuration:Float = 10, loopMode:Int = 0)
	{
		super(initialDuration, loopMode);

		timeLine = new TimeLine();
		lastFetchedKeyFrame = -1;
		cinematicEvents = new Vector<CinematicEvent>();
		cameraMap = new UnsafeStringMap<CameraNode>();
		initialized = false;
		scheduledPause = -1;

		this.scene = scene;
	}

	override public function onPlay():Void
	{
		if (isInitialized())
		{
			scheduledPause = -1;
			//enableCurrentCam(true);
			if (playState == PlayState.Paused)
			{
				var length:Int = cinematicEvents.length;
				for (i in 0...length)
				{
					var ct:CinematicEvent = cinematicEvents[i];
					if (ct.getPlayState() == PlayState.Paused)
					{
						ct.play();
					}
				}
			}
		}
	}

	override public function onStop():Void
	{
		time = 0;
		lastFetchedKeyFrame = -1;
		var length:Int = cinematicEvents.length;
		for (i in 0...length)
		{
			var ct:CinematicEvent = cinematicEvents[i];
			ct.setTime(0);
			ct.stop();
		}
		enableCurrentCam(false);
	}

	override public function onPause():Void
	{
		var length:Int = cinematicEvents.length;
		for (i in 0...length)
		{
			var ct:CinematicEvent = cinematicEvents[i];
			if (ct.getPlayState() == PlayState.Playing)
			{
				ct.pause();
			}
		}
		//enableCurrentCam(false);
	}

	override public function setSpeed(speed:Float):Void
	{
		super.setSpeed(speed);
		var length:Int = cinematicEvents.length;
		for (i in 0...length)
		{
			var ct:CinematicEvent = cinematicEvents[i];
			ct.setSpeed(speed);
		}
	}

	public function initialize(stateManager:AppStateManager, app:Application):Void
	{
		init(app, this);
		var length:Int = cinematicEvents.length;
		for (i in 0...length)
		{
			var ct:CinematicEvent = cinematicEvents[i];
			ct.init(app, this);
		}

		initialized = true;
	}

	public function setEnabled(value:Bool):Void
	{
		if (value)
		{
			play();
		}
	}

	public function isEnabled():Bool
	{
		return playState == PlayState.Playing;
	}

	public function stateAttached(stateManager:AppStateManager):Void
	{
	}

	public function stateDetached(stateManager:AppStateManager):Void
	{
		stop();
	}

	public function update(tpf:Float):Void
	{
		if (isInitialized())
		{
			internalUpdate(tpf);
		}
	}

	private function step():Void
	{
		if (playState != PlayState.Playing)
		{
			play();
			scheduledPause = 2;
		}
	}

	override public function onUpdate(tpf:Float):Void
	{
		if (scheduledPause >= 0)
		{
			if (scheduledPause == 0)
			{
				pause();
			}
			scheduledPause--;
		}

		var length:Int = cinematicEvents.length;
		for (i in 0...length)
		{
			var ct:CinematicEvent = cinematicEvents[i];
			ct.internalUpdate(tpf);
		}

		var keyFrameIndex:Int = timeLine.getKeyFrameIndexFromTime(time);

		//iterate to make sure every key frame is triggered
		var i:Int = lastFetchedKeyFrame + 1;
		while (i <= keyFrameIndex)
		{
			var keyFrame:KeyFrame = timeLine.getKeyFrameAtIndex(i);
			if (keyFrame != null)
			{
				keyFrame.trigger();
			}

			i++;
		}

		lastFetchedKeyFrame = keyFrameIndex;
	}

	override public function setTime(time:Float):Void
	{
		//stopping all events
		onStop();

		super.setTime(time);

		var keyFrameIndex:Int = timeLine.getKeyFrameIndexFromTime(time);

		//triggering all the event from start to "time" 
		//then computing timeoffsetfor each event
		for (i in 0...(keyFrameIndex + 1))
		{
			var keyFrame:KeyFrame = timeLine.getKeyFrameAtIndex(i);
			if (keyFrame != null)
			{
				var tracks:Vector<CinematicEvent> = keyFrame.getTracks();
				var length:Int = tracks.length;
				for (j in 0...length)
				{
					var track:CinematicEvent = tracks[j];
					var t:Float = time - timeLine.getKeyFrameTime(keyFrame);
					if (t >= 0 && (t <= track.getInitialDuration() || track.getLoopMode() != LoopMode.DontLoop))
					{
						track.play();
					}
					track.setTime(t);
				}
			}
		}

		lastFetchedKeyFrame = keyFrameIndex;
		if (playState != PlayState.Playing)
		{
			pause();
		}
	}

	/**
	 * Adds a cinematic event to this cinematic at the given timestamp. This
	 * operation returns a keyFrame
	 *
	 * @param timeStamp the time when the event will start after the begining of
	 * the cinematic
	 * @param cinematicEvent the cinematic event
	 * @return the keyFrame for that event.
	 */
	public function addTrack(timeStamp:Float, track:CinematicEvent):KeyFrame
	{
		var keyFrame:KeyFrame = timeLine.getKeyFrameAtTime(timeStamp);
		if (keyFrame == null)
		{
			keyFrame = new KeyFrame();
			timeLine.addKeyFrameAtTime(timeStamp, keyFrame);
		}

		keyFrame.addTrack(track);
		cinematicEvents.push(track);
		if (isInitialized())
		{
			track.init(null, this);
		}
		return keyFrame;
	}


	/**
	 * removes the first occurrence found of the given cinematicEvent.
	 *
	 * @param cinematicEvent the cinematicEvent to remove
	 * @return true if the element has been removed
	 */
//		public function removeCinematicEvent( cinematicEvent:CinematicEvent):Bool {
//			var index:Int =cinematicEvents.indexOf(cinematicEvent);
//			if(index == -1)
//				return;
//			
//			cinematicEvents.splice(index,1);
//
//			for (KeyFrame keyFrame : timeLine.values()) {
//				if (keyFrame.cinematicEvents.remove(cinematicEvent)) {
//					return true;
//				}
//			}
//			return false;
//		}
//		
//		/**
//		 * removes the first occurrence found of the given cinematicEvent for the given time stamp.
//		 * @param timeStamp the timestamp when the cinematicEvent has been added
//		 * @param cinematicEvent the cinematicEvent to remove
//		 * @return true if the element has been removed
//		 */
//		public function removeCinematicEvent(timeStamp:Float, cinematicEvent:CinematicEvent):Bool {
//			KeyFrame keyFrame = timeLine.getKeyFrameAtTime(timeStamp);
//			return removeCinematicEvent(keyFrame, cinematicEvent);
//		}
//		
//		/**
//		 * removes the first occurrence found of the given cinematicEvent for the given keyFrame
//		 * @param keyFrame the keyFrame returned by the addCinematicEvent method.
//		 * @param cinematicEvent the cinematicEvent to remove
//		 * @return true if the element has been removed
//		 */
//		public function removeCinematicEvent(keyFrame:KeyFrame, cinematicEvent:CinematicEvent):Bool {
//			Bool ret = keyFrame.cinematicEvents.remove(cinematicEvent);
//			cinematicEvents.remove(cinematicEvent);
//			if (keyFrame.isEmpty()) {
//				timeLine.removeKeyFrame(keyFrame.getIndex());
//			}
//			return ret;
//		}

	public function render(rm:RenderManager):Void
	{
	}

	public function postRender():Void
	{
	}

	public function cleanup():Void
	{

	}

	public function fitDuration():Void
	{
		var kf:KeyFrame = timeLine.getKeyFrameAtTime(timeLine.getLastKeyFrameIndex());
		var d:Float = 0;
		var tracks:Vector<CinematicEvent> = kf.getTracks();
		var length:Int = tracks.length;
		for (i in 0...length)
		{
			var ck:CinematicEvent = tracks[i];
			if (d < (ck.getDuration() * ck.getSpeed()))
			{
				d = (ck.getDuration() * ck.getSpeed());
			}
		}

		initialDuration = d;
	}

	public function bindCamera(cameraName:String, cam:Camera):CameraNode
	{
		var node:CameraNode = new CameraNode(cameraName, cam);
		node.controlDir = CameraControl.SpatialToCamera;
		node.getCameraControl().setEnabled(false);
		cameraMap.set(cameraName, node);
		scene.attachChild(node);
		return node;
	}

	public function getCamera(cameraName:String):CameraNode
	{
		return cameraMap.get(cameraName);
	}

	private function enableCurrentCam(enabled:Bool):Void
	{
		if (currentCam != null)
		{
			currentCam.getControlAt(0).setEnabled(enabled);
		}
	}

	public function setActiveCamera(cameraName:String):Void
	{
		enableCurrentCam(false);
		currentCam = cameraMap.get(cameraName);
		enableCurrentCam(true);
	}

	public function setScene(scene:Node):Void
	{
		this.scene = scene;
	}

	public function getScene():Node
	{
		return this.scene;
	}

	public function isInitialized():Bool
	{
		return this.initialized;
	}
}

