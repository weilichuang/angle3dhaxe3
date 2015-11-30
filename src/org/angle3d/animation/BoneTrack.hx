package org.angle3d.animation;

import de.polygonal.ds.error.Assert;
import flash.Vector;
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
	private var lastFrameTime:Float;
	
	private var divideCount:Int;

	private var mUseScale:Bool = false;
	
	private var needBlend:Bool = true;

	/**
	 * Creates a bone track for the given bone index
	 * @param targetBoneIndex the bone index
	
	 * @param times a float array with the time of each frame
	 * @param translations the translation of the bone for each frame
	 * @param rotations the rotation of the bone for each frame
	 * @param scales the scale of the bone for each frame
	 * @param divideCount 每帧之间均分为几部分，设置此值后将不会再执行插值计算，而是预先计算好
	 */
	public function new(boneIndex:Int,
						times:Vector<Float>, 
						translations:Vector<Float>, 
						rotations:Vector<Float>, 
						scales:Vector<Float> = null,
						divideCount:Int = 1)
	{
		this.targetBoneIndex = boneIndex;
		this.divideCount = divideCount;
		this.needBlend = divideCount == 1;
		this.setKeyframes(times, translations, rotations, scales);
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
			var high:Int = lastFrame - 1;
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
			
			if (!needBlend)
			{
				//此时不需要blend,weight设置为1
				var i3:Int = startFrame * 3;
				var i4:Int = startFrame * 4;
				if (!mUseScale)
				{
					targetBone.blendAnimTransforms(translations[i3], translations[i3 + 1], translations[i3 + 2],
												rotations[i4], rotations[i4 + 1], rotations[i4 + 2], rotations[i4 + 3],
												1);
				}
				else
				{
					targetBone.blendAnimTransformsWithScale(translations[i3], translations[i3 + 1], translations[i3 + 2],
												rotations[i4], rotations[i4 + 1], rotations[i4 + 2], rotations[i4 + 3],
												scales[i3], scales[i3 + 1], scales[i3 + 2],
												1);
				}
			}
			else
			{
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
	public function setKeyframes(times:Vector<Float>, translations:Vector<Float>, rotations:Vector<Float>, scales:Vector<Float> = null):Void
	{
		#if debug
		Assert.assert(times.length > 0, "BoneTrack with no keyframes!");
		#end
		
		if (this.divideCount == 1)
		{
			this.times = times;
			totalFrame = this.times.length;
			this.lastFrame = totalFrame - 1;
			if (this.lastFrame < 0)
				this.lastFrame = 0;
			this.lastFrameTime = times[lastFrame];

			this.translations = translations;
			this.rotations = rotations;
			this.scales = scales;
			
		}
		else
		{
			this.times = new Vector<Float>();
			this.translations = new Vector<Float>();
			this.rotations = new Vector<Float>();
			if (scales != null)
			{
				this.scales = new Vector<Float>();
			}
			this.mUseScale = scales != null;
			
			var startPos:Vector3f = new Vector3f();
			var startRotation:Quaternion = new Quaternion();
			var startScale:Vector3f = new Vector3f();
			
			var endPos:Vector3f = new Vector3f();
			var endRotation:Quaternion = new Quaternion();
			var endScale:Vector3f = new Vector3f();
			
			var curPos:Vector3f = new Vector3f();
			var curRotation:Quaternion = new Quaternion();
			var curScale:Vector3f = new Vector3f();
			
			var index:Int = 0;
			while (index < times.length - 1)
			{
				var startTime:Float = times[index];
				var endTime:Float = times[index + 1];
				
				var interCount:Int = Std.int((endTime-startTime) * this.divideCount);
				var interValue:Float = 1 / interCount;
				
				startPos.x = translations[index * 3];
				startPos.y = translations[index * 3 + 1];
				startPos.z = translations[index * 3 + 2];
				
				startRotation.x = rotations[index * 4];
				startRotation.y = rotations[index * 4 + 1];
				startRotation.z = rotations[index * 4 + 2];
				startRotation.w = rotations[index * 4 + 3];
				
				this.times.push(startTime);
				this.translations.push(startPos.x);
				this.translations.push(startPos.y);
				this.translations.push(startPos.z);
				
				this.rotations.push(startRotation.x);
				this.rotations.push(startRotation.y);
				this.rotations.push(startRotation.z);
				this.rotations.push(startRotation.w);
				
				if (mUseScale)
				{
					startScale.x = scales[index * 3];
					startScale.y = scales[index * 3 + 1];
					startScale.z = scales[index * 3 + 2];
				
					this.scales.push(startScale.x);
					this.scales.push(startScale.y);
					this.scales.push(startScale.z);
				}
				
				if (interCount > 1)
				{
					var index1:Int = index + 1;
					
					endPos.x = translations[index1 * 3];
					endPos.y = translations[index1 * 3 + 1];
					endPos.z = translations[index1 * 3 + 2];
					
					endRotation.x = rotations[index1 * 4];
					endRotation.y = rotations[index1 * 4 + 1];
					endRotation.z = rotations[index1 * 4 + 2];
					endRotation.w = rotations[index1 * 4 + 3];

					if (mUseScale)
					{
						endScale.x = scales[index1 * 3];
						endScale.y = scales[index1 * 3 + 1];
						endScale.z = scales[index1 * 3 + 2];
					}
				
					for (i in 0...(interCount - 1))
					{
						var curInterValue:Float = ((i + 1) * interValue);
						this.times.push(startTime + curInterValue);
						
						curPos.lerp(startPos, endPos, curInterValue);
						this.translations.push(curPos.x);
						this.translations.push(curPos.y);
						this.translations.push(curPos.z);
						
						curRotation.copyFrom(startRotation);
						curRotation.nlerp(endRotation, curInterValue);
						this.rotations.push(curRotation.x);
						this.rotations.push(curRotation.y);
						this.rotations.push(curRotation.z);
						this.rotations.push(curRotation.w);
						
						if (mUseScale)
						{
							curScale.lerp(startScale, endScale, curInterValue);
							this.scales.push(curScale.x);
							this.scales.push(curScale.y);
							this.scales.push(curScale.z);
						}
					}
				}
				
				index += 1;
			}
			
			var last:Int = times.length - 1;
			this.times.push(times[last]);
			this.translations.push(translations[last * 3]);
			this.translations.push(translations[last * 3 + 1]);
			this.translations.push(translations[last * 3 + 2]);
			
			this.rotations.push(rotations[last * 4]);
			this.rotations.push(rotations[last * 4 + 1]);
			this.rotations.push(rotations[last * 4 + 2]);
			this.rotations.push(rotations[last * 4 + 3]);
			
			if (mUseScale)
			{
				this.scales.push(scales[last * 3]);
				this.scales.push(scales[last * 3 + 1]);
				this.scales.push(scales[last * 3 + 2]);
			}
			
			totalFrame = this.times.length;
			this.lastFrame = totalFrame - 1;
			if (this.lastFrame < 0)
				this.lastFrame = 0;
			this.lastFrameTime = this.times[lastFrame];
		}
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
		return new BoneTrack(this.targetBoneIndex, this.times, this.translations, this.rotations, this.scales);
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

