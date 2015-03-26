package org.angle3d.animation;

import flash.Vector;
import org.angle3d.utils.FastStringMap;
import org.angle3d.math.Matrix4f;
import org.angle3d.utils.TempVars;

/**
 * Skeleton is a convenience class for managing a bone hierarchy.
 * Skeleton updates the world transforms to reflect the current local
 * animated matrixes.
 * A Skeleton can only one rootBone
 *
 * @author weilichuang
 */
class Skeleton
{
	public var rootBones:Vector<Bone>;
	
	public var numBones(get, null):Int;
	public var boneList(get,null):Vector<Bone>;

	private var mBoneList:Vector<Bone>;
	private var mBoneMap:FastStringMap<Bone>;

	/**
	 * Contains the skinning matrices, multiplying it by a vertex effected by a bone
	 * will cause it to go to the animated position.
	 */
	private var mSkinningMatrixes:Vector<Matrix4f>;

	/**
	 * Creates a skeleton from a bone list.
	 * The root bones are found automatically.
	 * <p>
	 * Note that using this constructor will cause the bones in the list
	 * to have their bind pose recomputed based on their local transforms.
	 *
	 * @param boneList The list of bones to manage by this Skeleton
	 */
	public function new(boneList:Vector<Bone>)
	{
		this.mBoneList = boneList;
		createSkinningMatrices();
		buildBoneTree();
	}

	
	private inline function get_numBones():Int
	{
		return mBoneList.length;
	}

	private inline function get_boneList():Vector<Bone>
	{
		return mBoneList;
	}

	/**
	 * 建立骨骼树结构，查找每个骨骼的父类
	 */
	private function buildBoneTree():Void
	{
		mBoneMap = new FastStringMap<Bone>();
		var count:Int = mBoneList.length;
		for (i in 0...count)
		{
			mBoneMap.set(mBoneList[i].name,mBoneList[i]);
		}

		rootBones = new Vector<Bone>();
		for (bone in mBoneList)
		{
			if (bone.parentName == null || bone.parentName == "")
			{
				rootBones.push(bone);
			}
			else
			{
				var parentBone:Bone = mBoneMap.get(bone.parentName);
				parentBone.addChild(bone);
			}
		}

		count = rootBones.length;
		for (i in 0...count)
		{
			rootBones[i].update();
			rootBones[i].setBindingPose();
		}
	}

	public function copy(source:Skeleton):Void
	{
//			var sourceList:Vector<Bone> = source.boneList;
//
//			this.mBoneList = new Vector<Bone>();
//			var count:Int = sourceList.length;
//			for (var i:Int = 0; i < count; i++)
//			{
//				mBoneList[i] = sourceList[i].clone();
//			}
//
//			createSkinningMatrices();
//			buildBoneTree();
	}

	private function createSkinningMatrices():Void
	{
		var count:Int = mBoneList.length;
		mSkinningMatrixes = new Vector<Matrix4f>(count, true);
		for (i in 0...count)
		{
			mSkinningMatrixes[i] = new Matrix4f();
		}
	}

	/**
	 * Updates world transforms for all bones in this skeleton.
	 * Typically called after setting local animation transforms.
	 */
	public function update():Void
	{
		var count:Int = rootBones.length;
		for (i in 0...count)
		{
			rootBones[i].update();
		}
	}

	/**
	 * Saves the current skeleton state as it's binding pose.
	 */
	public function setBindingPose():Void
	{
		var count:Int = rootBones.length;
		for (i in 0...count)
		{
			rootBones[i].setBindingPose();
		}
	}

	/**
	 * Reset_the skeleton to bind pose.
	 */
	public function reset():Void
	{
		var count:Int = rootBones.length;
		for (i in 0...count)
		{
			rootBones[i].reset();
		}
	}

	/**
	 * Reset_the skeleton to bind pose and updates the bones
	 */
	public function resetAndUpdate():Void
	{
		var count:Int = rootBones.length;
		for (i in 0...count)
		{
			rootBones[i].reset();
			rootBones[i].update();
		}
	}

	/**
	 * return a bone for the given index
	 * @param index
	 * @return
	 */
	public inline function getBoneAt(index:Int):Bone
	{
		return mBoneList[index];
	}

	/**
	 * returns the bone with the given name
	 * @param name
	 * @return
	 */
	public inline function getBoneByName(name:String):Bone
	{
		return mBoneMap.get(name);
	}

	/**
	 * returns the bone index of the given bone
	 * @param bone
	 * @return
	 */
	public inline function getBoneIndex(bone:Bone):Int
	{
		return mBoneList.indexOf(bone);
	}

	/**
	 * returns the bone index of the bone that has the given name
	 * @param name
	 * @return
	 */
	public function getBoneIndexByName(name:String):Int
	{
		var bone:Bone = mBoneMap.get(name);
		return mBoneList.indexOf(bone);
	}

	/**
	 * Compute the skining matrices for each bone of the skeleton that
	 * would be used to transform vertices of associated meshes
	 */
	//耗时有点久，看看是否可以缓存数据
	public function computeSkinningMatrices():Vector<Matrix4f>
	{
		var tempVar:TempVars = TempVars.getTempVars();

		var count:Int = mBoneList.length;
		for (i in 0...count)
		{
			mBoneList[i].getOffsetTransform(mSkinningMatrixes[i], tempVar.quat1, tempVar.vect1, tempVar.vect2, tempVar.tempMat3);
		}

		tempVar.release();

		return mSkinningMatrixes;
	}
}

