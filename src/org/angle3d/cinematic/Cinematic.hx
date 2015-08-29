package org.angle3d.cinematic;

import de.polygonal.ds.error.Assert;
import flash.Vector;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import org.angle3d.utils.FastStringMap;
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
import org.angle3d.utils.Logger;

/**
 * An appstate for composing and playing cut scenes in a game. The cineamtic
 * schedules CinematicEvents over a timeline. Once the Cinematic created it has
 * to be attched to the stateManager.
 *
 * You can add various CinematicEvents to a Cinematic, see package
 * com.jme3.cinematic.events
 *
 * Two main methods can be used to add an event :
 *
 * @see Cinematic#addCinematicEvent(float,
 * com.jme3.cinematic.events.CinematicEvent) , that adds an event at the given
 * time form the cinematic start.
 *
 * @see
 * Cinematic#enqueueCinematicEvent(com.jme3.cinematic.events.CinematicEvent)
 * that enqueue events one after the other according to their initialDuration
 *
 * a cinematic has convenient mathods to handle the playback :
 * @see Cinematic#play()
 * @see Cinematic#pause()
 * @see Cinematic#stop()
 *
 * A cinematic is itself a CinematicEvent, meaning you can embed several
 * Cinematics Embed cinematics must not be added to the stateManager though.
 *
 * Cinematic has a way to handle several point of view by creating CameraNode
 * over a cam and activating them on schedule.
 * @see Cinematic#bindCamera(java.lang.String, com.jme3.renderer.Camera)
 * @see Cinematic#activateCamera(float, java.lang.String)
 * @see Cinematic#setActiveCamera(java.lang.String)
 *
 */
class Cinematic extends AbstractCinematicEvent implements AppState
{
	private var scene:Node;
	private var timeLine:TimeLine;
	private var lastFetchedKeyFrame:Int = -1;
	private var cinematicEvents:Vector<CinematicEvent>;
	private var cameraMap:FastStringMap<CameraNode>;
	private var currentCam:CameraNode;
	private var initialized:Bool = false;
	private var eventsData:FastStringMap<Dynamic>;
	private var nextEnqueue:Float = 0;

	public function new(scene:Node, initialDuration:Float = 10, loopMode:Int = 0)
	{
		super(initialDuration, loopMode);

		timeLine = new TimeLine();
		cinematicEvents = new Vector<CinematicEvent>();
		cameraMap = new FastStringMap<CameraNode>();

		this.scene = scene;
	}

	override public function onPlay():Void
	{
		if (isInitialized())
		{
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
			ct.forceStop();
		}
		setEnableCurrentCam(false);
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
	}

	/**
     * sets the speed of the cinematic. Note that it will set the speed of all
     * events in the cinematic. 1 is normal speed. use 0.5f to make the
     * cinematic twice slower, use 2 to make it twice faster
     *
     * @param speed the speed
     */
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
		initEvent(app, this);

		for (i in 0...cinematicEvents.length)
		{
			var ct:CinematicEvent = cinematicEvents[i];
			ct.initEvent(app, this);
		}

		initialized = true;
	}

	public function setEnabled(enabled:Bool):Void
	{
		if (enabled)
		{
			play();
		}
	}

	/**
     * return true if the cinematic appstate is enabled (the cinematic is
     * playing)
     *
     * @return true if enabled
     */
	public function isEnabled():Bool
	{
		return playState == PlayState.Playing;
	}

	/**
     * called internally
     *
     * @param stateManager the state manager
     */
	public function stateAttached(stateManager:AppStateManager):Void
	{
	}

	/**
     * called internally
     *
     * @param stateManager the state manager
     */
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

	override public function onUpdate(tpf:Float):Void
	{
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
		
		var length:Int = cinematicEvents.length;
		for (i in 0...length)
		{
			var ct:CinematicEvent = cinematicEvents[i];
			ct.internalUpdate(tpf);
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
				var tracks:Vector<CinematicEvent> = keyFrame.getCinematicEvents();
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
	public function addCinematicEvent(timeStamp:Float, cinematicEvent:CinematicEvent):KeyFrame
	{
		var keyFrame:KeyFrame = timeLine.getKeyFrameAtTime(timeStamp);
		if (keyFrame == null)
		{
			keyFrame = new KeyFrame();
			timeLine.addKeyFrameAtTime(timeStamp, keyFrame);
		}

		keyFrame.addCinematicEvent(cinematicEvent);
		cinematicEvents.push(cinematicEvent);
		if (isInitialized())
		{
			cinematicEvent.initEvent(null, this);
		}
		return keyFrame;
	}

	/**
     * enqueue a cinematic event to a cinematic. This is a handy method when you
     * want to chain event of a given duration without knowing their initial
     * duration
     *
     * @param cinematicEvent the cinematic event to enqueue
     * @return the timestamp the evnt was scheduled.
     */
	public function enqueueCinematicEvent(cinematicEvent:CinematicEvent):Float
	{
		var scheduleTime:Float = nextEnqueue;
		addCinematicEvent(scheduleTime, cinematicEvent);
		nextEnqueue += cinematicEvent.getInitialDuration();
		return scheduleTime;
	}
	
	public function removeCinematicEvent(cinematicEvent:CinematicEvent):Bool
	{
		cinematicEvent.dispose();
		var index:Int = cinematicEvents.indexOf(cinematicEvent);
		if(index != -1)
			cinematicEvents.splice(index, 1);
		
		var map:IntMap<KeyFrame> = timeLine.getMap();
		var keys = map.keys();
		for (key in keys)
		{
			var keyFrame:KeyFrame = map.get(key);
			var index:Int = keyFrame.cinematicEvents.indexOf(cinematicEvent);
			if (index != -1)
			{
				keyFrame.cinematicEvents.splice(index, 1);
				return true;
			}
		}
		return false;
	}
	
	/**
     * removes the first occurrence found of the given cinematicEvent for the
     * given keyFrame
     *
     * @param keyFrame the keyFrame returned by the addCinematicEvent method.
     * @param cinematicEvent the cinematicEvent to remove
     * @return true if the element has been removed
     */
	public function removeCinematicEventByKeyFrame(keyFrame:KeyFrame,cinematicEvent:CinematicEvent):Bool
	{
		cinematicEvent.dispose();
		var index:Int = keyFrame.cinematicEvents.indexOf(cinematicEvent);
		if (index != -1)
		{
			keyFrame.cinematicEvents.splice(index, 1);
		}
		var ret:Bool = index != -1;
		
		index = cinematicEvents.indexOf(cinematicEvent);
		if (index != -1)
		{
			cinematicEvents.splice(index, 1);
		}
		
		if (keyFrame.isEmpty())
		{
			timeLine.removeKeyFrame(keyFrame.getIndex());
		}
		
		return ret;
	}
	
	public function removeCinematicEventByTimeStamp(timeStamp:Float,cinematicEvent:CinematicEvent):Bool
	{
		cinematicEvent.dispose();
		var keyFrame:KeyFrame = timeLine.getKeyFrameAtTime(timeStamp);
		return removeCinematicEventByKeyFrame(keyFrame, cinematicEvent);
	}

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
		var cinematicEvents:Vector<CinematicEvent> = kf.getCinematicEvents();
		var length:Int = cinematicEvents.length;
		for (i in 0...length)
		{
			var ce:CinematicEvent = cinematicEvents[i];
			var dur:Float = timeLine.getKeyFrameTime(kf) + ce.getDuration() * ce.getSpeed();
			if (d < dur)
			{
				d = dur;
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

	private function setEnableCurrentCam(enabled:Bool):Void
	{
		if (currentCam != null)
		{
			currentCam.getControl(CameraControl).setEnabled(enabled);
		}
	}

	public function setActiveCamera(cameraName:String):Void
	{
		setEnableCurrentCam(false);
		currentCam = cameraMap.get(cameraName);
		
		#if debug
		Logger.log('$cameraName is not a camera bond to the cinematic, cannot activate');
		#end
		
		setEnableCurrentCam(true);
	}
	
	public function activateCameraByTimeStamp(timeStamp:Float, cameraName:String):Void
	{
		addCinematicEvent(timeStamp, new InternalCinamaticEvent(this, cameraName));
	}
	
	private function getEventsData():FastStringMap<Dynamic>
	{
		if (eventsData == null)
		{
			eventsData = new FastStringMap<Dynamic>();
		}
		return eventsData;
	}
	
	public function putEventData(type:String, key:Dynamic, object:Dynamic):Void
	{
		var data:FastStringMap<Dynamic> = getEventsData();
		var row:ObjectMap<Dynamic,Dynamic> = data.get(type);
		if (row == null)
		{
			row = new ObjectMap<Dynamic,Dynamic>();
		}
		row.set(key, object);
		data.set(type, row);
	}
	
	public function getEventData(type:String, key:Dynamic):Dynamic
	{
		if (eventsData != null)
		{
			var row:ObjectMap<Dynamic,Dynamic> = eventsData.get(type);
			if (row != null)
				return row.get(key);
		}
		return null;
	}
	
	public function removeEventData(type:String, key:Dynamic):Void
	{
		if (eventsData != null)
		{
			var row:ObjectMap<Dynamic,Dynamic> = eventsData.get(type);
			if (row != null)
				row.remove(key);
		}
	}
	
	
	/**
     * clear the cinematic of its events.
     */
    public function clear():Void
	{
        dispose();
        cinematicEvents.length = 0;
        timeLine.clear();
        if (eventsData != null)
		{
            eventsData.clear();
        }
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

class InternalCinamaticEvent extends AbstractCinematicEvent
{
	private var cinematic:Cinematic;
	private var cameraName:String;
	public function new(cinematic:Cinematic,cameraName:String)
	{
		super();
		this.cinematic = cinematic;
		this.cameraName = cameraName;
	}
	
	override public function play():Void
	{
		super.play();
		stop();
	}
	
	override public function onPlay():Void 
	{
		cinematic.setActiveCamera(this.cameraName);
		
	}
	
	override public function onUpdate(tpf:Float):Void 
	{
		
	}
	
	override public function onStop():Void 
	{
		
	}
	
	override public function onPause():Void 
	{
		
	}
	
	override public function forceStop():Void 
	{
		
	}
	
	override public function setTime(time:Float):Void 
	{
		play();
	}
}

