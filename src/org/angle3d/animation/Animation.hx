package org.angle3d.animation;

import org.angle3d.utils.TempVars;

/**
 * The animation class updates the animation target with the tracks of a given type.
 *
 */
class Animation
{
	/**
	 * The name of the animation.
	 */
	public var name:String;

	/**
	 * The length of the animation.
	 */
	public var length:Float;

	/**
	 * The tracks of the animation.
	 */
	public var tracks:Array<Track>;

	public function new(name:String, time:Float)
	{
		this.name = name;
		this.length = time;

		tracks = new Array<Track>();
	}

	public function setTracks(tracks:Array<Track>):Void
	{
		this.tracks = tracks;
	}

	public inline function addTrack(track:Track):Void
	{
		tracks[tracks.length] = track;
	}

	/**
	 * This method sets the current time of the animation.
	 * This method behaves differently for every known track type.
	 * Override this method if you have your own type of track.
	 *
	 * @param time the time of the animation
	 * @param blendWeight the blend weight factor
	 * @param control the animation control
	 * @param channel the animation channel
	 */
	public function setTime(time:Float, blendWeight:Float, control:AnimControl, channel:AnimChannel):Void
	{
		if (tracks == null)
			return;

		var length:Int = tracks.length;
		for (i in 0...length)
		{
			tracks[i].setTime(time, blendWeight, control, channel);
		}
	}

	/**
	 * This method creates a clone of the current object.
	 * @return a clone of the current object
	 */
	public function clone(newName:String):Animation
	{
		var result:Animation = new Animation(newName, this.length);
		
		var length:Int = tracks.length;
		result.tracks = new Array<Track>();
		for (i in 0...length)
		{
			result.tracks[i] = tracks[i].clone();
		}
		return result;
	}
}

