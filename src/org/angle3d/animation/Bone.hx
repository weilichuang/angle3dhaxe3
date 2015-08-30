package org.angle3d.animation;

import flash.Vector;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Transform;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Node;
import org.angle3d.utils.TempVars;

/**
 * Bone describes a bone in the bone-weight skeletal animation
 * system. A bone contains a name and an index, as well as relevant
 * transformation data.
 * 
 * A bone has 3 sets of transforms :
 * 1. The bind transforms, that are the transforms of the bone when the skeleton
 * is in its rest pose (also called bind pose or T pose in the literature). 
 * The bind transforms are expressed in Local space meaning relatively to the 
 * parent bone.
 * 
 * 2. The Local transforms, that are the transforms of the bone once animation
 * or user transforms has been applied to the bind pose. The local transforms are
 * expressed in Local space meaning relatively to the parent bone.
 * 
 * 3. The Model transforms, that are the transforms of the bone relatives to the 
 * rootBone of the skeleton. Those transforms are what is needed to apply skinning 
 * to the mesh the skeleton controls.
 * Note that there can be several rootBones in a skeleton. The one considered for 
 * these transforms is the one that is an ancestor of this bone.
 *
 */
class Bone
{
	public var name:String;
	public var parentName:String = null;
	public var parent:Bone;

	public var children:Vector<Bone>;
	
	/**
     * If enabled, user can control bone transform with setUserTransforms.
     * Animation transforms are not applied to this bone when enabled.
     */
    private var userControl:Bool = false;
	
	/**
	 * The attachment node.
	 */
	private var mAttachNode:Node;
	
	/**
	 * Bind transform is the local bind transform of this bone. (local space)
	 */
	private var mBindPos:Vector3f;
	private var mBindRot:Quaternion;
	private var mBindScale:Vector3f;
	
	/**
	 * The inverse bind transforms of this bone expressed in model space    
	 */
	private var mWorldBindInversePos:Vector3f;
	private var mWorldBindInverseRot:Quaternion;
	private var mWorldBindInverseScale:Vector3f;
	
	/**
	 * 本地坐标，相对于父骨骼
	 * The local animated or user transform combined with the local bind transform
	 */
	public var localPos:Vector3f;
	public var localRot:Quaternion;
	public var localScale:Vector3f;

	/**
	 * The model transforms of this bone     
	 */
	private var mModelPos:Vector3f;
	private var mModelRot:Quaternion;
	private var mModelScale:Vector3f;
	
	/**
     * Used to handle blending from one animation to another.
     * See {@link #blendAnimTransforms(org.angle3d.math.Vector3f, org.angle3d.math.Quaternion, org.angle3d.math.Vector3f, float)}
     * on how this variable is used.
     */
    private var currentWeightSum:Float = -1;

	public function new(name:String)
	{
		this.name = name;

		mBindPos = new Vector3f();
		mBindRot = new Quaternion();
		mBindScale = new Vector3f(1.0, 1.0, 1.0);

		localPos = new Vector3f();
		localRot = new Quaternion();
		localScale = new Vector3f(1.0, 1.0, 1.0);

		mModelPos = new Vector3f();
		mModelRot = new Quaternion();
		mModelScale = new Vector3f(1.0, 1.0, 1.0);

		mWorldBindInversePos = new Vector3f();
		mWorldBindInverseRot = new Quaternion();
		mWorldBindInverseScale = new Vector3f(1.0, 1.0, 1.0);
	}
	
	public inline function getLocalPosition():Vector3f
	{
		return localPos;
	}
	
	public inline function getLocalRotation():Quaternion
	{
		return localRot;
	}
	
	public inline function getLocalScale():Vector3f
	{
		return localScale;
	}
	
	/**
	 * 模型空间坐标
	 * Returns the position of the bone in model space.
	 *
	 * @return The position of the bone in model space.
	 */
	public function getModelSpacePosition():Vector3f
	{
		return mModelPos;
	}

	/**
	 * Returns the rotation of the bone in model space.
	 *
	 * @return The rotation of the bone in model space.
	 */
	public function getModelSpaceRotation():Quaternion
	{
		return mModelRot;
	}

	/**
	 * Returns the scale of the bone in model space.
	 *
	 * @return The scale of the bone in model space.
	 */
	public function getModelSpaceScale():Vector3f
	{
		return mModelScale;
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
	
	public function getModelBindInverseTransform(result:Transform = null):Transform
	{
        if (result == null)
			result = new Transform();
        result.setTranslation(mWorldBindInversePos);
        result.setRotation(mWorldBindInverseRot);
        if (mWorldBindInverseScale != null)
		{
            result.setScale(mWorldBindInverseScale);
        }
        return result;
    }
    
    public function getBindInverseTransform(result:Transform = null):Transform
	{
        if (result == null)
			result = new Transform();
        result.setTranslation(mBindPos);
        result.setRotation(mBindRot);
        if (mBindScale != null)
		{
            result.setScale(mBindScale);
        }
        return result.invertLocal();
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
			mAttachNode.setUserData("AttachedBone", this);
		}
		return mAttachNode;
	}

	/**
     * Used internally after model cloning.
     * @param attachNode
     */
	public function setAttachmentsNode(attachNode:Node):Void
	{
		mAttachNode = attachNode;
	}


	/**
	 * Add a new child to this bone. Shouldn't be used by user code.
	 * Can corrupt skeleton.
	 *
	 * @param bone The bone to add
	 */
	public function addChild(bone:Bone):Void
	{
		if (children == null)
		{
			children = new Vector<Bone>();
		}
		children.push(bone);
		bone.parent = this;
	}
	
	 /**
     * Returns the bind position expressed in local space (relative to the parent bone).
     * <p>
     * The bind pose transform of the bone in local space is its "default"
     * transform with no animation applied.
     * 
     * @return the bind position in local space.
     */
    public function getBindPosition():Vector3f
	{
        return mBindPos;
    }

    /**
     * Returns the bind rotation expressed in local space (relative to the parent bone).
     * <p>
     * The bind pose transform of the bone in local space is its "default"
     * transform with no animation applied.
     * 
     * @return the bind rotation in local space.
     */    
    public function getBindRotation():Quaternion
	{
        return mBindRot;
    }  
    
    /**
     * Returns the  bind scale expressed in local space (relative to the parent bone).
     * <p>
     * The bind pose transform of the bone in local space is its "default"
     * transform with no animation applied.
     * 
     * @return the bind scale in local space.
     */
    public function getBindScale():Vector3f
	{
        return mBindScale;
    }

	
	/**
     * If enabled, user can control bone transform with setUserTransforms.
     * Animation transforms are not applied to this bone when enabled.
     */
    public function setUserControl(enable:Bool):Void
	{
        userControl = enable;
    }

	/**
     * Updates the model transforms for this bone, and, possibly the attach node
     * if not null.
     * <p>
     * The model transform of this bone is computed by combining the parent's
     * model transform with this bones' local transform.
     */
	public function update():Void
	{
		updateModelTransforms();

		if (children != null)
		{
			var i:Int = children.length;
			while (--i >= 0)
			{
				children[i].update();
			}
		}
	}
	
	public function updateModelTransforms():Void
	{
		if (currentWeightSum == 1)
		{
            currentWeightSum = -1;
        } 
		else if (currentWeightSum != -1)
		{
            // Apply the weight to the local transform
            if (currentWeightSum == 0) 
			{
                localRot.copyFrom(mBindRot);
                localPos.copyFrom(mBindPos);
                localScale.copyFrom(mBindScale);
            } 
			else
			{
                var invWeightSum:Float = 1 - currentWeightSum;
                localRot.nlerp(mBindRot, invWeightSum);
                localPos.interpolateLocal(mBindPos, invWeightSum);
                localScale.interpolateLocal(mBindScale, invWeightSum);
            }
            
            // Future invocations of transform blend will start over.
            currentWeightSum = -1;
        }
		
		if (parent != null)
		{
			//rotation
			parent.mModelRot.mult(localRot, mModelRot);

			//scale
			parent.mModelScale.mult(localScale, mModelScale);

			//translation
			//scale and rotation of parent affect bone position            
			parent.mModelRot.multVector(localPos, mModelPos);
			mModelPos.multLocal(parent.mModelScale);
			mModelPos.addLocal(parent.mModelPos);
		}
		else
		{
			//root Bone
			mModelRot.copyFrom(localRot);
			mModelPos.copyFrom(localPos);
			mModelScale.copyFrom(localScale);
		}

		if (mAttachNode != null)
		{
			mAttachNode.setLocalTranslation(mModelPos);
			mAttachNode.setLocalRotation(mModelRot);
			mAttachNode.setLocalScale(mModelScale);
		}
	}

	/**
	 * 设置骨骼的初始状态
	 * Saves the current bone state as its binding pose, including its children.
	 */
	public function setBindingPose():Void
	{
		mBindPos.copyFrom(localPos);
		mBindRot.copyFrom(localRot);
		mBindScale.copyFrom(localScale);

		// Save inverse derived position/scale/orientation, used for calculate offsettransform later
		mWorldBindInversePos.setTo( -mModelPos.x, -mModelPos.y, -mModelPos.z);

		mWorldBindInverseRot.copyFrom(mModelRot);
		mWorldBindInverseRot.inverseLocal();

		mWorldBindInverseScale.setTo(1 / mModelScale.x, 1 / mModelScale.y, 1 / mModelScale.z);

		if (children != null)
		{
			var length:Int = children.length;
			for (i in 0...length)
			{
				children[i].setBindingPose();
			}
		}
	}

	/**
	 * Reset the bone and it's children to bind pose.
	 */
	public inline function reset():Void
	{
		if (!userControl)
		{
			localPos.copyFrom(mBindPos);
			localRot.copyFrom(mBindRot);
			localScale.copyFrom(mBindScale);
		}

		if (children != null)
		{
			var length:Int = children.length;
			for (i in 0...length)
			{
				children[i].reset();
			}
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
	private static var tRotate:Quaternion = new Quaternion();
	private static var tTranslate:Vector3f = new Vector3f();
	private static var tScale:Vector3f = new Vector3f();
	private static var tMat3:Matrix3f = new Matrix3f();
	public function getOffsetTransform(outTransform:Matrix4f):Void
	{
		// Computing scale
		mModelScale.mult(mWorldBindInverseScale, tScale);

		// Computing rotation
		mModelRot.mult(mWorldBindInverseRot, tRotate);

		// Computing translation
		// Translation depend on rotation and scale
		tScale.mult(mWorldBindInversePos, tTranslate);
		tRotate.multVector(tTranslate, tTranslate);
		tTranslate.addLocal(mModelPos);
		
		// Populating the matrix
		tRotate.toMatrix3f(tMat3);
		outTransform.setTransform(tTranslate, tScale, tMat3);
	}
	
	/**
     * 
     * Sets the transforms of this bone in local space (relative to the parent bone)
     *
     * @param translation the translation in local space
     * @param rotation the rotation in local space
     * @param scale the scale in local space
     */
    public function setUserTransforms(translation:Vector3f, rotation:Quaternion, scale:Vector3f):Void
	{
        if (!userControl) 
		{
            throw ("You must call setUserControl(true) in order to setUserTransform to work");
        }

        localPos.copyAddLocal(mBindPos,translation);
        localRot.copyMultLocal(mBindRot, rotation);
        localScale.copyMultLocal(mBindScale, scale);
    }
	
	/**
     * Sets the transforms of this bone in model space (relative to the root bone)
     * 
     * Must update all bones in skeleton for this to work.
     * @param translation translation in model space
     * @param rotation rotation in model space
     */
	public function setUserTransformsInModelSpace(translation:Vector3f, rotation:Quaternion, scale:Vector3f = null):Void
	{
		if (!userControl) 
		{
            throw ("You must call setUserControl(true) in order to setUserTransformsInModelSpace to work");
        }

        mModelPos.copyFrom(translation);
        mModelRot.copyFrom(rotation);
		if(scale != null)
			mModelScale.copyFrom(scale);

        //if there is an attached Node we need to set it's local transforms too.
        if (mAttachNode != null)
		{
            mAttachNode.setLocalTranslation(translation);
            mAttachNode.setLocalRotation(rotation);
			if(scale != null)
				mAttachNode.setLocalScale(scale);
        }
	}
	
	/**
     * Returns the local transform of this bone combined with the given position and rotation
     * @param position a position
     * @param rotation a rotation
     */
    public function getCombinedTransform(position:Vector3f, rotation:Quaternion,result:Transform = null):Transform
	{
        if (result == null)
		{
            result = new Transform();
        }
        rotation.multVector(localPos, result.translation).addLocal(position);
		result.setRotation(rotation);
        result.rotation.multLocal(localRot);
        return result;
    }

	/**
	 * Sets the local animation transform of this bone.
	 * Bone is assumed to be in bind pose when this is called.
	 */
	public function setAnimTransforms(translation:Vector3f, rotation:Quaternion, scale:Vector3f):Void
	{
		if (userControl)
			return;
			
		localPos.copyAddLocal(mBindPos, translation);

		localRot.copyMultLocal(mBindRot, rotation);

		if (scale != null)
		{
			localScale.copyMultLocal(mBindScale,scale);
		}
	}

	private static var tmpTranslation:Vector3f = new Vector3f();
	private static var tmpRotation:Quaternion = new Quaternion();
	private static var tmpScale:Vector3f = new Vector3f();
	public function blendAnimTransforms(translation:Vector3f, rotation:Quaternion, scale:Vector3f, weight:Float):Void
	{
		if (userControl)
			return;
			
		if (weight == 0)
		{
			// Do not apply this transform at all.
			return;
		}
		
		if (currentWeightSum == 1)
		{
			return;//More than 2 transforms are being blended
		}
		else if (currentWeightSum == -1 || currentWeightSum == 0)
		{
			// Set the transform fully
            localPos.copyAddLocal(mBindPos, translation);
            localRot.copyMultLocal(mBindRot,rotation);
            if (scale != null)
			{
                localScale.copyMultLocal(mBindScale, scale);
            }
            // Set the weight. It will be applied in updateModelTransforms().
            currentWeightSum = weight;
		}
		else
		{
			// The weight is already set. 
			//Blend in the new transform.
			
			//location
			tmpTranslation.copyAddLocal(mBindPos, translation);
			localPos.interpolateLocal(tmpTranslation, weight);

			//rotation
			tmpRotation.copyMultLocal(mBindRot,rotation);
			localRot.nlerp(tmpRotation, weight);

			//scale
			if (scale != null)
			{
				tmpScale.copyMultLocal(mBindScale, scale);
				localScale.interpolateLocal(tmpScale, weight);
			}
			
			// Ensures no new weights will be blended in the future.
            currentWeightSum = 1;
		}
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
	
	public function hasUserControl():Bool
	{
		return userControl;
	}
	
	public function setLocalRotation(rot:Quaternion):Void
	{
		if (!userControl) 
		{
            throw ("User control must be on bone to allow user transforms");
        }
		
        this.localRot.copyFrom(rot);
	}
}

