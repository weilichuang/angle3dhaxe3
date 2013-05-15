package org.angle3d.animation;

import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.utils.Assert;
import org.angle3d.utils.TempVars;
import flash.Vector;
/**
 * Contains a list of transforms and times for each keyframe.
 *
 */
class BoneTrack implements Track
{
	/**
	* Bone index in the skeleton which this track effects.
	*/
	public var boneIndex:Int;

	/**
	 * Transforms and times for track.
	 */
	public var translations:Vector<Float>;
	public var rotations:Vector<Float>;
	public var scales:Vector<Float>;
	public var times:Vector<Float>;
	public var totalFrame:Int;

	private var mUseScale:Bool = false;

	/**
	 * Creates a bone track for the given bone index
	 * @param targetBoneIndex the bone index
	 * @param times a float array with the time of each frame
	 * @param translations the translation of the bone for each frame
	 * @param rotations the rotation of the bone for each frame
	 * @param scales the scale of the bone for each frame
	 */
	public function new(boneIndex:Int, times:Vector<Float>, translations:Vector<Float>, rotations:Vector<Float>, scales:Vector<Float> = null)
	{
		this.boneIndex = boneIndex;
		this.setKeyframes(times, translations, rotations, scales);
	}

	public function setCurrentTime(time:Float, weight:Float, control:AnimControl, channel:AnimChannel, tempVars:TempVars):Void
	{
		var tmpTranslation:Vector3f = tempVars.vect1;
		var tmpQuat:Quaternion = tempVars.quat1;

		var tmpTranslation2:Vector3f = tempVars.vect2;
		var tmpQuat2:Quaternion = tempVars.quat2;

		var tmpScale:Vector3f = null;
		var tmpScale2:Vector3f = null;
		if (mUseScale)
		{
			tmpScale = tempVars.vect3;
			tmpScale2 = tempVars.vect4;
		}

		var lastFrame:Int = totalFrame - 1;
		if (lastFrame == 0 || time < 0 || time >= times[lastFrame])
		{
			var frame:Int = 0;
			if (time >= times[lastFrame])
			{
				frame = lastFrame;
			}

			getRotation(frame, tmpQuat);
			getTranslation(frame, tmpTranslation);
			if (mUseScale)
			{
				getScale(frame, tmpScale);
			}
		}
		else
		{
			var startFrame:Int = 0;
			var endFrame:Int = 1;

			//use lastFrame so we never overflow the array
			var i:Int = 0;
			while(i < lastFrame && times[i] < time)
			{
				startFrame = i;
				endFrame = i + 1;
				i++;
			}

			var blend:Float = (time - times[startFrame]) / (times[endFrame] - times[startFrame]);

			getRotation(startFrame, tmpQuat);
			getTranslation(startFrame, tmpTranslation);
			if (mUseScale)
			{
				getScale(startFrame, tmpScale);
			}

			getRotation(endFrame, tmpQuat2);
			getTranslation(endFrame, tmpTranslation2);
			if (mUseScale)
			{
				getScale(endFrame, tmpScale2);
			}

			tmpQuat.slerp(tmpQuat, tmpQuat2, blend);
			tmpTranslation.lerp(tmpTranslation, tmpTranslation2, blend);

			if (mUseScale)
			{
				tmpScale.lerp(tmpScale, tmpScale2, blend);
			}
		}

		var target:Bone = cast(control,SkeletonAnimControl).skeleton.getBoneAt(boneIndex);
		if (weight < 1.0)
		{
			target.blendAnimTransforms(tmpTranslation, tmpQuat, mUseScale ? tmpScale : null, weight);
		}
		else
		{
			target.setAnimTransforms(tmpTranslation, tmpQuat, mUseScale ? tmpScale : null);
		}
	}

	/**
	 * set_the translations and rotations for this bone track
	 * @param times a float array with the time of each frame
	 * @param translations the translation of the bone for each frame
	 * @param rotations the rotation of the bone for each frame
	 * @param scales the scale of the bone for each frame
	 */
	public function setKeyframes(times:Vector<Float>, translations:Vector<Float>, rotations:Vector<Float>, scales:Vector<Float> = null):Void
	{
		#if debug
		Assert.assert(times.length > 0, "BoneTrack with no keyframes!");
		#end

		this.times = times;
		totalFrame = this.times.length;

		this.translations = translations;
		this.rotations = rotations;
		this.scales = scales;
		this.mUseScale = this.scales != null;
	}

	/**
	 * @return the time of the track
	 */
	public function getTotalTime():Float
	{
		return times == null ? 0 : times[totalFrame - 1] - times[0];
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

	
	private inline function getScale(index:Int, vec3:Vector3f):Void
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

