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
	
	private static var tmpTranslation:Vector3f = new Vector3f(); 
	private static var tmpTranslation2:Vector3f = new Vector3f(); 
	private static var tmpQuat:Quaternion = new Quaternion(); 
	private static var tmpQuat2:Quaternion = new Quaternion(); 
	private static var tmpScale:Vector3f = new Vector3f(); 
	private static var tmpScale2:Vector3f = new Vector3f(); 
	private var _oldFrame:Int = -1;
	public function setTime(time:Float, weight:Float, 
									control:AnimControl, channel:AnimChannel):Void
	{
		var affectedBones:Vector<Bool> = channel.getAffectedBones();
		if (affectedBones != null && !affectedBones[targetBoneIndex])
		{
			return;
		}
		
		var targetBone:Bone = control.getSkeleton().getBoneAt(targetBoneIndex);
		if (targetBone == null)
			return;
		
		if (lastFrame == 0 || time < 0)
		{
			getRotation(0, tmpQuat);
			getTranslation(0, tmpTranslation);
			if (mUseScale)
			{
				getScale(0, tmpScale);
			}
		}
		else if (time >= times[lastFrame])
		{
			getRotation(lastFrame, tmpQuat);
			getTranslation(lastFrame, tmpTranslation);
			if (mUseScale)
			{
				getScale(lastFrame, tmpScale);
			}
		}
		else
		{
			//var startFrame:Int = 0;
			//use lastFrame so we never overflow the array
			//var i:Int = 0;
			//while(i < lastFrame && times[i] < time)
			//{
				//startFrame = i;
				//i++;
			//}
			
			//二分查找，明显快很多
			//MS3DSkinnedMeshTest例子中，使用二分查找，提高了10帧左右
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
			
			//时间相同，不需要重新计算
			//if (_oldFrame == startFrame)
			//{
				//targetBone.blendAnimTransforms(tmpTranslation, tmpQuat, mUseScale ? tmpScale : null, weight);
				//return;
			//}
			//
			//_oldFrame = startFrame;
			
			if (!needBlend)
			{
				getRotation(startFrame, tmpQuat);
				getTranslation(startFrame, tmpTranslation);
				if (mUseScale)
				{
					getScale(startFrame, tmpScale);
				}
			}
			else
			{
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

				tmpQuat.nlerp(tmpQuat2, blend);
				tmpTranslation.lerp(tmpTranslation, tmpTranslation2, blend);
				if (mUseScale)
				{
					tmpScale.lerp(tmpScale, tmpScale2, blend);
				}
			}
		}

		
		targetBone.blendAnimTransforms(tmpTranslation, tmpQuat, mUseScale ? tmpScale : null, weight);
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

