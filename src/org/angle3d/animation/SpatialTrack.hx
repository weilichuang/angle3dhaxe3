package org.angle3d.animation;

import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Spatial;
import de.polygonal.ds.error.Assert;
import org.angle3d.utils.TempVars;
import flash.Vector;
/**
 * This class represents the track for spatial animation.
 *
 * @author Marcin Roguski (Kaelthas)
 */
class SpatialTrack implements Track
{
	/**
	 * Translations of the track.
	 */
	private var translations:Vector<Float>;
	/**
	 * Rotations of the track.
	 */
	private var rotations:Vector<Float>;
	/**
	 * Scales of the track.
	 */
	private var scales:Vector<Float>;
	/**
	 * The times of the animations frames.
	 */
	private var times:Vector<Float>;

	public function new(times:Vector<Float>, translations:Vector<Float> = null, rotations:Vector<Float> = null, scales:Vector<Float> = null)
	{
		setKeyframes(times, translations, rotations, scales);
	}

	/**
	 *
	 * Modify the spatial which this track modifies.
	 *
	 * @param time
	 *            the current time of the animation
	 * @param spatial
	 *            the spatial that should be animated with this track
	 */
	public function setCurrentTime(time:Float, weight:Float, control:AnimControl, channel:AnimChannel):Void
	{
		var vars:TempVars = TempVars.getTempVars();
		var tempV:Vector3f = vars.vect1;
		var tempS:Vector3f = vars.vect2;
		var tempQ:Quaternion = vars.quat1;
		var tempV2:Vector3f = vars.vect3;
		var tempS2:Vector3f = vars.vect4;
		var tempQ2:Quaternion = vars.quat2;

		var lastFrame:Int = times.length - 1;
		if (lastFrame == 0 || time < 0 || time >= times[lastFrame])
		{
			var frame:Int = 0;
			if (time >= times[lastFrame])
			{
				frame = lastFrame;
			}

			if (rotations != null)
			{
				getRotation(frame, tempQ);
			}
			if (translations != null)
			{
				getTranslation(frame, tempV);
			}
			if (scales != null)
			{
				getScale(frame, tempS);
			}
		}
		else
		{
			var startFrame:Int = 0;
			var endFrame:Int = 1;
			// use lastFrame so we never overflow the array
			var i:Int = 0;
			while(i < lastFrame && times[i] < time)
			{
				startFrame = i;
				endFrame = i + 1;
				i++;
			}

			var blend:Float = (time - times[startFrame]) / (times[endFrame] - times[startFrame]);

			if (rotations != null)
			{
				getRotation(startFrame, tempQ);
				getRotation(endFrame, tempQ2);
			}
			if (translations != null)
			{
				getTranslation(startFrame, tempV);
				getTranslation(endFrame, tempV2);
			}
			if (scales != null)
			{
				getScale(startFrame, tempS);
				getScale(endFrame, tempS2);
			}

			tempQ.slerp(tempQ, tempQ2, blend);
			tempV.lerp(tempV, tempV2, blend);
			tempS.lerp(tempS, tempS2, blend);
		}

		var spatial:Spatial = control.getSpatial();

		if (translations != null)
		{
			spatial.translation = tempV;
		}

		if (rotations != null)
		{
			spatial.setLocalRotation(tempQ);
		}

		if (scales != null)
		{
			spatial.setLocalScale(tempS);
		}
		
		vars.release();
	}

	/**
	 * set_the translations and rotations for this bone track
	 * @param times a float array with the time of each frame
	 * @param translations the translation of the bone for each frame
	 * @param rotations the rotation of the bone for each frame
	 */
	public function setKeyframes(times:Vector<Float>, translations:Vector<Float>, rotations:Vector<Float>, scales:Vector<Float> = null):Void
	{
		Assert.assert(times.length > 0, "SpatialTrack with no keyframes!");

		this.times = times;
		this.translations = translations;
		this.rotations = rotations;
		this.scales = scales;
	}


	/**
	 * @return the length of the track
	 */
	public function getTotalTime():Float
	{
		return times == null ? 0 : times[times.length - 1] - times[0];
	}

	public function clone():Track
	{
		//need implements
		return null;
	}

	private inline function getTranslation(index:Int, vec3:Vector3f):Void
	{
		var i3:Int = index * 3;
		vec3.x = translations[i3];
		vec3.y = translations[i3 + 1];
		vec3.z = translations[i3 + 2];
	}

	private function getScale(index:Int, vec3:Vector3f):Void
	{
		var i3:Int = index * 3;
		vec3.x = scales[i3];
		vec3.y = scales[i3 + 1];
		vec3.z = scales[i3 + 2];
	}

	private inline function getRotation(index:Int, quat:Quaternion):Void
	{
		var i4:Int = index * 4;
		quat.x = rotations[i4];
		quat.y = rotations[i4 + 1];
		quat.z = rotations[i4 + 2];
		quat.w = rotations[i4 + 3];
	}

}

