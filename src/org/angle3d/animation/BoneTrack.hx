package org.angle3d.animation;

import org.angle3d.error.Assert;

import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;

/**
 * Contains a list of transforms and times for each keyframe.
 *
 */
//TODO 把每个时间段之间最多均分为几段，初始时计算好这些数据，读取时根据其所在时间段读取，不再每次重新计算差值，加快速度
class BoneTrack implements Track
{
	/**
	* Bone index in the skeleton which this track effects.
	*/
	public var targetBoneIndex:Int;
	
	/**
	 * Transforms and times for track.
	 */
	public var translations:Vector<Float>;
	public var rotations:Vector<Float>;
	public var scales:Vector<Float>;
	public var times:Vector<Float>;
	public var totalFrame:Int;
	
	private var lastFrame:Int;
	private var lastFrame1:Int;
	private var lastFrameTime:Float;
	
	private var mUseScale:Bool = false;
	
	/**
	 * Creates a bone track for the given bone index
	 * @param targetBoneIndex the bone index
	 */
	public function new(boneIndex:Int)
	{
		this.targetBoneIndex = boneIndex;
	}
	
	private static var tmpQuat:Quaternion = new Quaternion(); 
	private static var tmpQuat2:Quaternion = new Quaternion(); 
	public function setTime(time:Float, weight:Float, 
									control:AnimControl, channel:AnimChannel):Void
	{
		if (lastFrame == 0)
			return;
			
		var affectedBones:Vector<Bool> = channel.getAffectedBones();
		if (affectedBones != null && !affectedBones[targetBoneIndex])
		{
			return;
		}
		
		var targetBone:Bone = control.getSkeleton().getBoneAt(targetBoneIndex);
		if (targetBone == null)
			return;
			
		if (time > 0 && time <= lastFrameTime)
		{
			//此处有点耗时，找个好的办法优化
			//可以考虑，每次都记录time对应的下标，下次查找时优先从已记录数据里找
			var high:Int = lastFrame1;
			var low:Int = -1;
			while (high - low > 1) 
			{
				var probe:Int = (low + high) >> 1;
				if (times[probe] > time)
					high = probe;
				else
					low = probe;
			}
			
			var startFrame:Int = low;
			var endFrame:Int = startFrame + 1;
			

			var blend:Float = (time - times[startFrame]) / (times[endFrame] - times[startFrame]);

			getRotation(startFrame, tmpQuat);
			getRotation(endFrame, tmpQuat2);
			tmpQuat.nlerp(tmpQuat2, blend);
			
			var blend1:Float = 1 - blend;
			
			var sI3:Int = startFrame * 3;
			var eI3:Int = endFrame * 3;
			
			var tx:Float = translations[sI3] * blend1 + translations[eI3] * blend;
			var ty:Float = translations[sI3 + 1] * blend1 + translations[eI3 + 1] * blend;
			var tz:Float = translations[sI3 + 2] * blend1 + translations[eI3 + 2] * blend;
			
			if (!mUseScale)
			{
				targetBone.blendAnimTransforms(tx, ty, tz,
											tmpQuat.x,tmpQuat.y,tmpQuat.z,tmpQuat.w,
											weight);
			}
			else
			{
				var sx:Float = scales[sI3] * blend1 + scales[eI3] * blend;
				var sy:Float = scales[sI3 + 1] * blend1 + scales[eI3 + 1] * blend;
				var sz:Float = scales[sI3 + 2] * blend1 + scales[eI3 + 2] * blend;
			
				targetBone.blendAnimTransformsWithScale(tx, ty, tz,
											tmpQuat.x,tmpQuat.y,tmpQuat.z,tmpQuat.w,
											sx,sy,sz,
											weight);
			}
		}
		else
		{
			var i3:Int = time <= 0 ? 0 : lastFrame * 3;
			var i4:Int = time <= 0 ? 0 : lastFrame * 4;
			if (!mUseScale)
			{
				targetBone.blendAnimTransforms(translations[i3], translations[i3 + 1], translations[i3 + 2],
											rotations[i4], rotations[i4 + 1], rotations[i4 + 2], rotations[i4 + 3],
											weight);
			}
			else
			{
				targetBone.blendAnimTransformsWithScale(translations[i3], translations[i3 + 1], translations[i3 + 2],
											rotations[i4], rotations[i4 + 1], rotations[i4 + 2], rotations[i4 + 3],
											scales[i3], scales[i3 + 1], scales[i3 + 2],
											weight);
			}
		}
	}

	/**
	 * set the translations and rotations for this bone track
	 * @param times a float array with the time of each frame
	 * @param translations the translation of the bone for each frame
	 * @param rotations the rotation of the bone for each frame
	 * @param scales the scale of the bone for each frame
	 */
	public function setKeyframes(times:Vector<Float>, translations:Vector<Float>, rotations:Vector<Float>, 
								scales:Vector<Float> = null):Void
	{
		#if debug
		Assert.assert(times.length > 0, "BoneTrack with no keyframes!");
		#end

		this.times = times;
		totalFrame = this.times.length;
		this.lastFrame = totalFrame - 1;
		if (this.lastFrame < 0)
			this.lastFrame = 0;
		this.lastFrame1 = this.lastFrame - 1;
		this.lastFrameTime = times[lastFrame];

		this.translations = translations;
		this.rotations = rotations;
		this.scales = scales;
	}
	
	public inline function getTargetBoneIndex():Int
	{
		return targetBoneIndex;
	}

	/**
	 * @return the time of the track
	 */
	public function getLength():Float
	{
		return times == null ? 0 : times[totalFrame - 1] - times[0];
	}

	public function clone():Track
	{
		var track:BoneTrack = new BoneTrack(this.targetBoneIndex);
		track.setKeyframes(this.times, this.translations, this.rotations, this.scales);
		return track;
	}
	
	public function getKeyFrameTimes():Vector<Float>
	{
		return times;
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

