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
 * <code>Bone</code> describes a bone in the bone-weight skeletal animation
 * system. A bone contains a name and an index, as well as relevant
 * transformation data.
 */
class Bone
{
	public var name:String;
	public var parentName:String = null;
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
	
	/**
     * If enabled, user can control bone transform with setUserTransforms.
     * Animation transforms are not applied to this bone when enabled.
     */
    private var userControl:Bool = false;
	
	/**
     * Used to handle blending from one animation to another.
     * See {@link #blendAnimTransforms(org.angle3d.math.Vector3f, org.angle3d.math.Quaternion, org.angle3d.math.Vector3f, float)}
     * on how this variable is used.
     */
    private var currentWeightSum:Float = -1;

	public function new(name:String)
	{
		this.name = name;

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
	
	public function getModelBindInverseTransform():Transform
	{
        var t:Transform = new Transform();
        t.setTranslation(mWorldBindInversePos);
        t.setRotation(mWorldBindInverseRot);
        if (mWorldBindInverseScale != null)
		{
            t.setScale(mWorldBindInverseScale);
        }
        return t;
    }
    
    public function getBindInverseTransform():Transform
	{
        var t:Transform = new Transform();
        t.setTranslation(mBindPos);
        t.setRotation(mBindRot);
        if (mBindScale != null)
		{
            t.setScale(mBindScale);
        }
        return t.invert();
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

		var i:Int = children.length;
		while (--i >= 0)
		{
			children[i].update();
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
                localRot.nlerp(localRot,mBindRot, invWeightSum);
                localPos.interpolateLocal(mBindPos, invWeightSum);
                localScale.interpolateLocal(mBindScale, invWeightSum);
            }
            
            // Future invocations of transform blend will start over.
            currentWeightSum = -1;
        }
		
		if (parent != null)
		{
			//rotation
			parent.mWorldRot.mult(localRot, mWorldRot);

			//scale
			parent.mWorldScale.mult(localScale, mWorldScale);

			//translation
			//scale and rotation of parent affect bone position            
			parent.mWorldRot.multVector(localPos, mWorldPos);
			mWorldPos.multLocal(parent.mWorldScale);
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
			mAttachNode.setLocalTranslation(mWorldPos);
			mAttachNode.setLocalRotation(mWorldRot);
			mAttachNode.setLocalScale(mWorldScale);
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
	public inline function reset():Void
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
	private static var tRotate:Quaternion = new Quaternion();
	private static var tTranslate:Vector3f = new Vector3f();
	private static var tScale:Vector3f = new Vector3f();
	private static var tMat3:Matrix3f = new Matrix3f();
	public function getOffsetTransform(outTransform:Matrix4f):Void
	{
		// Computing scale
		mWorldScale.mult(mWorldBindInverseScale, tScale);

		// Computing rotation
		mWorldRot.mult(mWorldBindInverseRot, tRotate);

		// Computing translation
		// Translation depend on rotation and scale
		tScale.mult(mWorldBindInversePos, tTranslate);
		tRotate.multVector(tTranslate, tTranslate);
		tTranslate.addLocal(mWorldPos);
		tRotate.toMatrix3f(tMat3);

		// Populating the matrix
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

        localPos.copyFrom(mBindPos);
        localRot.copyFrom(mBindRot);
        localScale.copyFrom(mBindScale);

        localPos.addLocal(translation);
        localRot.multLocal(rotation);
        localScale.multLocal(scale);
    }
	
	/**
     * Returns the local transform of this bone combined with the given position and rotation
     * @param position a position
     * @param rotation a rotation
     */
	private var tmpTransform:Transform;
    public function getCombinedTransform(position:Vector3f, rotation:Quaternion):Transform
	{
        if (tmpTransform == null)
		{
            tmpTransform = new Transform();
        }
        rotation.multVector(localPos, tmpTransform.translation).addLocal(position);
		tmpTransform.rotation = rotation;
        tmpTransform.rotation.multLocal(localRot);
        return tmpTransform;
    }
	
	/**
     * Sets the transforms of this bone in model space (relative to the root bone)
     * 
     * Must update all bones in skeleton for this to work.
     * @param translation translation in model space
     * @param rotation rotation in model space
     */
    public function setUserTransformsInModelSpace(translation:Vector3f, rotation:Quaternion):Void
	{
        if (!userControl) 
		{
            throw ("You must call setUserControl(true) in order to setUserTransformsInModelSpace to work");
        }

        // TODO: add scale here ???
        mWorldPos.copyFrom(translation);
        mWorldRot.copyFrom(rotation);
        
        //if there is an attached Node we need to set it's local transforms too.
        if (mAttachNode != null)
		{
            mAttachNode.setLocalTranslation(translation);
            mAttachNode.setLocalRotation(rotation);
        }
    }

	/**
	 * Sets the local animation transform of this bone.
	 * Bone is assumed to be in bind pose when this is called.
	 */
	public function setAnimTransforms(translation:Vector3f, rotation:Quaternion, scale:Vector3f):Void
	{
		if (userControl)
			return;
			
		localPos.copyAdd(mBindPos, translation);

		//localRot.copyFrom(mBindRot);
		//localRot.multLocal(rotation);
		
		var tw:Float = mBindRot.w, tx:Float = mBindRot.x, ty:Float = mBindRot.y, tz:Float = mBindRot.z;
		var qw:Float = rotation.w, qx:Float = rotation.x, qy:Float = rotation.y, qz:Float = rotation.z;
		localRot.x =  tx * qw + ty * qz - tz * qy + tw * qx;
		localRot.y = -tx * qz + ty * qw + tz * qx + tw * qy;
		localRot.z =  tx * qy - ty * qx + tz * qw + tw * qz;
		localRot.w = -tx * qx - ty * qy - tz * qz + tw * qw;

		if (scale != null)
		{
			localScale.copyFrom(mBindScale);
			localScale.multLocal(scale);
		}
	}

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
            localPos.copyFrom(mBindPos).addLocal(translation);
            localRot.copyFrom(mBindRot).multLocal(rotation);
            if (scale != null)
			{
                localScale.copyFrom(mBindScale).multLocal(scale);
            }
            // Set the weight. It will be applied in updateModelTransforms().
            currentWeightSum = weight;
		}
		else
		{
			// The weight is already set. 
            // Blend in the new transform.
			
			var tempVar:TempVars = TempVars.getTempVars();

			var tmpTranslation:Vector3f = tempVar.vect1;
			var tmpRotation:Quaternion = tempVar.quat1;

			//location
			tmpTranslation.copyAdd(mBindPos, translation);
			localPos.interpolateLocal(tmpTranslation, weight);
			//localPos.lerp(localPos, tmpTranslation, weight);

			//rotation
			tmpRotation.copyFrom(mBindRot);
			tmpRotation.multLocal(rotation);
			localRot.nlerp(localRot, tmpRotation, weight);

			//scale
			if (scale != null)
			{
				var tmpScale:Vector3f = tempVar.vect2;
				tmpScale.copyFrom(mBindScale);
				localScale.multLocal(scale);
				//localScale.lerp(localScale, tmpScale, weight);
				localScale.interpolateLocal(tmpScale, weight);
			}
			
			// Ensures no new weights will be blended in the future.
            currentWeightSum = 1;

			tempVar.release();
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

