package org.angle3d.animation;

import flash.Vector;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Node;
import org.angle3d.utils.TempVars;

/**
 * <code>Bone</code> describes a bone in the bone-weight skeletal animation
 * system. A bone contains a name and an index, as well as relevant
 * transformation data.
 */
class Bone
{
	public var name:String;
	public var parentName:String;
	public var parent:Bone;

	public var children:Vector<Bone>;
	
	/**
	 * 本地坐标，相对于父骨骼
	 * The local animated transform combined with the local bind transform and parent world transform
	 */
	//the local position of the bone, relative to the parent bone.
	public var localPos:Vector3f;
	//the local rotation of the bone, relative to the parent bone.
	public var localRot:Quaternion;
	//the local scale of the bone, relative to the parent bone.
	public var localScale:Vector3f;

	/**
	 * The attachment node follow this bone's motions
	 */
	private var mAttachNode:Node;

	/**
	 * Initial transform is the local bind transform of this bone.
	 * PARENT SPACE -> BONE SPACE
	 */
	private var mBindPos:Vector3f;
	private var mBindRot:Quaternion;
	private var mBindScale:Vector3f;

	/**
	 * The inverse world bind transform.
	 * BONE SPACE -> MODEL SPACE
	 */
	private var mWorldBindInversePos:Vector3f;
	private var mWorldBindInverseRot:Quaternion;
	private var mWorldBindInverseScale:Vector3f;

	

	/**
	 * 模型坐标
	 * MODEL SPACE -> BONE SPACE (in animated state)
	 */
	//the position of the bone in model space.
	private var mWorldPos:Vector3f;
	//the rotation of the bone in model space.
	private var mWorldRot:Quaternion;
	//the scale of the bone in model space.
	private var mWorldScale:Vector3f;

	public function new(name:String)
	{
		this.name = name;

		parentName = "";

		children = new Vector<Bone>();

		mBindPos = new Vector3f();
		mBindRot = new Quaternion();
		mBindScale = new Vector3f(1.0, 1.0, 1.0);

		localPos = new Vector3f();
		localRot = new Quaternion();
		localScale = new Vector3f(1.0, 1.0, 1.0);

		mWorldPos = new Vector3f();
		mWorldRot = new Quaternion();
		mWorldScale = new Vector3f(1.0, 1.0, 1.0);

		mWorldBindInversePos = new Vector3f();
		mWorldBindInverseRot = new Quaternion();
		mWorldBindInverseScale = new Vector3f(1.0, 1.0, 1.0);
	}

	/**
	 * 只克隆基础信息
	 * @return
	 *
	 */
	public function clone():Bone
	{
		var result:Bone = new Bone(this.name);
		result.parentName = this.parentName;
		result.localPos.copyFrom(this.localPos);
		result.localRot.copyFrom(this.localRot);
		result.localScale.copyFrom(this.localScale);
		return result;
	}

	public function getAttachmentsNode():Node
	{
		if (mAttachNode == null)
		{
			mAttachNode = new Node(this.name + "_attachnode");
		}
		return mAttachNode;
	}

	//TODO 修改为内部使用
	public function setAttachmentsNode(value:Node):Void
	{
		mAttachNode = value;
	}

	/**
	 * 模型空间坐标
	 * Returns the position of the bone in model space.
	 *
	 * @return The position of the bone in model space.
	 */
	public function getModelSpacePosition():Vector3f
	{
		return mWorldPos;
	}

	/**
	 * Returns the rotation of the bone in model space.
	 *
	 * @return The rotation of the bone in model space.
	 */
	public function getModelSpaceRotation():Quaternion
	{
		return mWorldRot;
	}

	/**
	 * Returns the scale of the bone in model space.
	 *
	 * @return The scale of the bone in model space.
	 */
	public function getModelSpaceScale():Vector3f
	{
		return mWorldScale;
	}

	/**
	 * Returns the inverse world bind pose position.
	 * <p>
	 * The bind pose transform of the bone is its "default"
	 * transform with no animation applied.
	 *
	 * @return the inverse world bind pose position.
	 */
	public function getWorldBindInversePosition():Vector3f
	{
		return mWorldBindInversePos;
	}

	/**
	 * Returns the inverse world bind pose rotation.
	 * <p>
	 * The bind pose transform of the bone is its "default"
	 * transform with no animation applied.
	 *
	 * @return the inverse world bind pose rotation.
	 */
	public function getWorldBindInverseRotation():Quaternion
	{
		return mWorldBindInverseRot;
	}

	/**
	 * Returns the inverse world bind pose scale.
	 * <p>
	 * The bind pose transform of the bone is its "default"
	 * transform with no animation applied.
	 *
	 * @return the inverse world bind pose scale.
	 */
	public function getWorldBindInverseScale():Vector3f
	{
		return mWorldBindInverseScale;
	}

	/**
	 * Returns the world bind pose position.
	 * <p>
	 * The bind pose transform of the bone is its "default"
	 * transform with no animation applied.
	 *
	 * @return the world bind pose position.
	 */
	public function getWorldBindPosition():Vector3f
	{
		return mBindPos;
	}

	/**
	 * Returns the world bind pose rotation.
	 * <p>
	 * The bind pose transform of the bone is its "default"
	 * transform with no animation applied.
	 *
	 * @return the world bind pose rotation.
	 */
	public function getWorldBindRotation():Quaternion
	{
		return mBindRot;
	}

	/**
	 * Returns the world bind pose scale.
	 * <p>
	 * The bind pose transform of the bone is its "default"
	 * transform with no animation applied.
	 *
	 * @return the world bind pose scale.
	 */
	public function getWorldBindScale():Vector3f
	{
		return mBindScale;
	}

	/**
	 * Add a new child to this bone. Shouldn't be used by user code.
	 * Can corrupt skeleton.
	 *
	 * @param bone The bone to add
	 */
	public function addChild(bone:Bone):Void
	{
		children.push(bone);
		bone.parent = this;
	}

	/**
	 * Updates world transforms for this bone and it's children,and possibly the attach node if not null.
	 * The world transform of this bone is computed by combining the parent's
	 * world transform with this bones' local transform.
	 */
	public function update():Void
	{
		if (parent != null)
		{
			//rotation
			parent.mWorldRot.multiply(localRot, mWorldRot);

			//scale
			parent.mWorldScale.multiply(localScale, mWorldScale);

			//translation
			//scale and rotation of parent affect bone position            
			parent.mWorldRot.multiplyVector(localPos, mWorldPos);
			mWorldPos.multiplyLocal(parent.mWorldScale);
			mWorldPos.addLocal(parent.mWorldPos);
		}
		else
		{
			//root Bone
			mWorldRot.copyFrom(localRot);
			mWorldPos.copyFrom(localPos);
			mWorldScale.copyFrom(localScale);
		}

		if (mAttachNode != null)
		{
			//TODO attacNode首先要根据parent方向旋转
			mAttachNode.setTranslation(mWorldPos);
			mAttachNode.setRotation(mWorldRot);
			mAttachNode.setScale(mWorldScale);
		}

		var i:Int = children.length;
		while (--i >= 0)
		{
			children[i].update();
		}
	}

	/**
	 * 设置骨骼的初始状态
	 */
	public function setBindingPose():Void
	{
		mBindPos.copyFrom(localPos);
		mBindRot.copyFrom(localRot);
		mBindScale.copyFrom(localScale);

		// Save inverse derived position/scale/orientation, used for calculate offsettransform later
		mWorldBindInversePos.copyFrom(mWorldPos);
		mWorldBindInversePos.scaleLocal(-1);

		mWorldBindInverseRot.copyFrom(mWorldRot);
		mWorldBindInverseRot.inverseLocal();

		mWorldBindInverseScale.setTo(1, 1, 1);
		mWorldBindInverseScale.divideLocal(mWorldScale);

		var length:Int = children.length;
		for (i in 0...length)
		{
			children[i].setBindingPose();
		}
	}

	/**
	 * Reset the bone and it's children to bind pose.
	 */
	public function reset():Void
	{
		localPos.copyFrom(mBindPos);
		localRot.copyFrom(mBindRot);
		localScale.copyFrom(mBindScale);

		var length:Int = children.length;
		for (i in 0...length)
		{
			children[i].reset();
		}
	}

	/**
	* Stores the skinning transform in the specified Matrix4f.
	* The skinning transform applies the animation of the bone to a vertex.
	*
	* This assumes that the world transforms for the entire bone hierarchy
	* have already been computed, otherwise this method will return undefined
	* results.
	*
	* @param outTransform
	*/
	public function getOffsetTransform(outTransform:Matrix4f, 
										tRotate:Quaternion, 
										tTranslate:Vector3f, 
										tScale:Vector3f, 
										tMat3:Matrix3f):Void
	{
		// Computing scale
		mWorldScale.multiply(mWorldBindInverseScale, tScale);

		// Computing rotation
		mWorldRot.multiply(mWorldBindInverseRot, tRotate);

		// Computing translation
		// Translation depend on rotation and scale
		tScale.multiply(mWorldBindInversePos, tTranslate);
		tRotate.multiplyVector(tTranslate, tTranslate);
		tTranslate.addLocal(mWorldPos);

		tRotate.toMatrix3f(tMat3);

		// Populating the matrix
		outTransform.setTransform(tTranslate, tScale, tMat3);
	}

	/**
	 * Sets the local animation transform of this bone.
	 * Bone is assumed to be in bind pose when this is called.
	 */
	public function setAnimTransforms(translation:Vector3f, rotation:Quaternion, scale:Vector3f):Void
	{
		localPos.copyAdd(mBindPos, translation);

		localRot.copyFrom(mBindRot);
		localRot.multiplyLocal(rotation);

		if (scale != null)
		{
			localScale.copyFrom(mBindScale);
			localScale.multiplyLocal(scale);
		}
	}

	public function blendAnimTransforms(translation:Vector3f, rotation:Quaternion, scale:Vector3f, weight:Float):Void
	{
		var tempVar:TempVars = TempVars.getTempVars();

		var tmpTranslation:Vector3f = tempVar.vect1;
		var tmpRotation:Quaternion = tempVar.quat1;

		//location
		tmpTranslation.copyAdd(mBindPos, translation);
		localPos.lerp(localPos, tmpTranslation, weight);

		//rotation
		tmpRotation.copyFrom(mBindRot);
		tmpRotation.multiplyLocal(rotation);
		localRot.nlerp(localRot, tmpRotation, weight);

		//scale
		if (scale != null)
		{
			var tmpScale:Vector3f = tempVar.vect2;
			tmpScale.copyFrom(mBindScale);
			localScale.multiplyLocal(scale);
			localScale.lerp(localScale, tmpScale, weight);
		}

		tempVar.release();
	}

	/**
	 * Sets local bind transform for bone.
	 * Call setBindingPose() after all of the skeleton bones' bind transforms are set_to save them.
	 */
	public function setBindTransforms(translation:Vector3f, rotation:Quaternion, scale:Vector3f = null):Void
	{
		mBindPos.copyFrom(translation);
		mBindRot.copyFrom(rotation);
		if (scale != null)
		{
			mBindScale.copyFrom(scale);
		}

		localPos.copyFrom(translation);
		localRot.copyFrom(rotation);
		if (scale != null)
		{
			localScale.copyFrom(scale);
		}
	}
}

