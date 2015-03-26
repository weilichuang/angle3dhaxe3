package org.angle3d.bullet.control;
import haxe.ds.IntMap;
import org.angle3d.utils.FastStringMap;
import org.angle3d.animation.AnimControl;
import org.angle3d.animation.Bone;
import org.angle3d.animation.Skeleton;
import org.angle3d.animation.SkeletonControl;
import org.angle3d.bullet.collision.PhysicsCollisionEvent;
import org.angle3d.bullet.collision.PhysicsCollisionListener;
import org.angle3d.bullet.collision.PhysicsCollisionObject;
import org.angle3d.bullet.collision.RagdollCollisionListener;
import org.angle3d.bullet.collision.shapes.BoxCollisionShape;
import org.angle3d.bullet.collision.shapes.HullCollisionShape;
import org.angle3d.bullet.control.ragdoll.HumanoidRagdollPreset;
import org.angle3d.bullet.control.ragdoll.RagdollPreset;
import org.angle3d.bullet.control.ragdoll.RagdollUtils;
import org.angle3d.bullet.joints.SixDofJoint;
import org.angle3d.bullet.objects.PhysicsRigidBody;
import org.angle3d.bullet.PhysicsSpace;
import org.angle3d.math.FastMath;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.control.Control;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Logger;
import org.angle3d.utils.TempVars;

/**
 * <strong>This control is still a WIP, use it at your own risk</strong><br> To
 * use this control you need a model with an AnimControl and a
 * SkeletonControl.<br> This should be the case if you imported an animated
 * model from Ogre or blender.<br> Note enabling/disabling the control
 * add/removes it from the physic space<br> <p> This control creates collision
 * shapes for each bones of the skeleton when you call
 * spatial.addControl(ragdollControl). <ul> <li>The shape is HullCollision shape
 * based on the vertices associated with each bone and based on a tweakable
 * weight threshold (see setWeightThreshold)</li> <li>If you don't want each
 * bone to be a collision shape, you can specify what bone to use by using the
 * addBoneName method<br> By using this method, bone that are not used to create
 * a shape, are "merged" to their parent to create the collision shape. </li>
 * </ul> </p> <p> There are 2 modes for this control : <ul> <li><strong>The
 * kinematic modes :</strong><br> this is the default behavior, this means that
 * the collision shapes of the body are able to interact with physics enabled
 * objects. in this mode physic shapes follow the moovements of the animated
 * skeleton (for example animated by a key framed animation) this mode is
 * enabled by calling setKinematicMode(); </li> <li><strong>The ragdoll modes
 * :</strong><br> To enable this behavior, you need to call setRagdollMode()
 * method. In this mode the charater is entirely controled by physics, so it
 * will fall under the gravity and move if any force is applied to it. </li>
 * </ul> </p>
 *
 * @author Normen Hansen and Rémy Bouquet (Nehon)
 */
class KinematicRagdollControl extends AbstractPhysicsControl implements PhysicsCollisionListener 
{
    private var listeners:Array<RagdollCollisionListener>;
    private var boneList:Array<String> = new Array<String>();
    private var boneLinks:FastStringMap<PhysicsBoneLink> = new FastStringMap<PhysicsBoneLink>();
    private var modelPosition:Vector3f = new Vector3f();
    private var modelRotation:Quaternion = new Quaternion();
    private var baseRigidBody:PhysicsRigidBody;
    private var targetModel:Spatial;
    private var skeleton:Skeleton;
    private var preset:RagdollPreset = new HumanoidRagdollPreset();
    private var initScale:Vector3f;
    private var mode:KinematicRagdollMode = KinematicRagdollMode.Kinematic;
    private var debug:Bool = false;
    private var blendedControl:Bool = false;
    private var weightThreshold:Float = -1.0;
    private var blendStart:Float = 0.0;
    private var blendTime:Float = 1.0;
    private var eventDispatchImpulseThreshold:Float = 10;
    private var rootMass:Float = 15;
    private var totalMass:Float = 0;
    private var ikTargets:FastStringMap<Vector3f> = new FastStringMap<Vector3f>();
    private var ikChainDepth:FastStringMap<Int> = new FastStringMap<Int>();
    private var ikRotSpeed:Float = 7;
    private var limbDampening:Float = 0.6;

    private var IKThreshold:Float = 0.1;

    public function new(preset:RagdollPreset, weightThreshold:Float = -1) 
	{
		super();
        baseRigidBody = new PhysicsRigidBody(new BoxCollisionShape(new Vector3f(0.1,0.1,0.1)), 1);
        baseRigidBody.setKinematic(mode == KinematicRagdollMode.Kinematic);
        this.preset = preset;
        this.weightThreshold = weightThreshold;
    }

    override public function update(tpf:Float):Void
	{
        if (!enabled) 
		{
            return;
        }
        if (mode == KinematicRagdollMode.IK)
		{
            ikUpdate(tpf);
        } 
		else if (mode == KinematicRagdollMode.Ragdoll && targetModel.getLocalTranslation().equals(modelPosition)) 
		{
            //if the ragdoll has the control of the skeleton, we update each bone with its position in physic world space.
            ragDollUpdate(tpf);
        } 
		else
		{
            kinematicUpdate(tpf);
        }
    }

    private function ragDollUpdate(tpf:Float):Void 
	{
        var vars:TempVars = TempVars.getTempVars();
        var tmpRot1:Quaternion = vars.quat1;
        var tmpRot2:Quaternion = vars.quat2;

		var link:PhysicsBoneLink;
		
        for (link in boneLinks) 
		{
            var position:Vector3f = vars.vect1;

            //retrieving bone position in physic world space
            var p:Vector3f = link.rigidBody.getMotionState().getWorldLocation();
            //transforming this position with inverse transforms of the model
            targetModel.getWorldTransform().transformInverseVector(p, position);

            //retrieving bone rotation in physic world space
            var q:Quaternion = link.rigidBody.getMotionState().getWorldRotationQuat();

            //multiplying this rotation by the initialWorld rotation of the bone, 
            //then transforming it with the inverse world rotation of the model
            tmpRot1.copyFrom(q).multLocal(link.initalWorldRotation);
            tmpRot2.copyFrom(targetModel.getWorldRotation()).inverseLocal().mult(tmpRot1, tmpRot1);
            tmpRot1.normalizeLocal();

			var bone:Bone = link.bone;
            //if the bone is the root bone, we apply the physic's transform to the model, so its position and rotation are correctly updated
            if (bone.parent == null) 
			{

                //offsetting the physic's position/rotation by the root bone inverse model space position/rotaion
                modelPosition.copyFrom(p).subtractLocal(bone.getBindPosition());
                targetModel.parent.getWorldTransform().transformInverseVector(modelPosition, modelPosition);
                modelRotation.copyFrom(q).multLocal(tmpRot2.copyFrom(bone.getBindRotation()).inverseLocal());


                //applying transforms to the model
                targetModel.setLocalTranslation(modelPosition);

                targetModel.setLocalRotation(modelRotation);

                //Applying computed transforms to the bone
                bone.setUserTransformsInModelSpace(position, tmpRot1);

            } 
			else
			{
                //if boneList is empty, this means that every bone in the ragdoll has a collision shape,
                //so we just update the bone position
                if (boneList.length == 0)
				{
                    bone.setUserTransformsInModelSpace(position, tmpRot1);
                } 
				else
				{
                    //boneList is not empty, this means some bones of the skeleton might not be associated with a collision shape.
                    //So we update them recusively
                    RagdollUtils.setTransform(bone, position, tmpRot1, false, boneList);
                }
            }
        }
        vars.release();
    }

    private function kinematicUpdate(tpf:Float):Void 
	{
        //the ragdoll does not have the controll, so the keyframed animation updates the physic position of the physic bonces
        var vars:TempVars = TempVars.getTempVars();
        var tmpRot1:Quaternion = vars.quat1;
        var tmpRot2:Quaternion = vars.quat2;
        var position:Vector3f = vars.vect1;
        for (link in boneLinks)
		{
			var bone:Bone = link.bone;
//            if(link.usedbyIK){
//                continue;
//            }
            //if blended control this means, keyframed animation is updating the skeleton, 
            //but to allow smooth transition, we blend this transformation with the saved position of the ragdoll
            if (blendedControl) 
			{
                var position2:Vector3f = vars.vect2;
                //initializing tmp vars with the start position/rotation of the ragdoll
                position.copyFrom(link.startBlendingPos);
                tmpRot1.copyFrom(link.startBlendingRot);

                //interpolating between ragdoll position/rotation and keyframed position/rotation
                tmpRot2.copyFrom(tmpRot1).nlerp(tmpRot2,bone.getModelSpaceRotation(), blendStart / blendTime);
                position2.copyFrom(position).interpolateLocal(bone.getModelSpacePosition(), blendStart / blendTime);
                tmpRot1.copyFrom(tmpRot2);
                position.copyFrom(position2);

                //updating bones transforms
                if (boneList.length == 0) 
				{
                    //we ensure we have the control to update the bone
                    bone.setUserControl(true);
                    bone.setUserTransformsInModelSpace(position, tmpRot1);
                    //we give control back to the key framed animation.
                    bone.setUserControl(false);
                } 
				else
				{
                    RagdollUtils.setTransform(link.bone, position, tmpRot1, true, boneList);
                }

            }
            //setting skeleton transforms to the ragdoll
            matchPhysicObjectToBone(link, position, tmpRot1);
            modelPosition.copyFrom(targetModel.getLocalTranslation());
        }

        //time control for blending
        if (blendedControl) 
		{
            blendStart += tpf;
            if (blendStart > blendTime)
			{
                blendedControl = false;
            }
        }
        vars.release();
    }
	
    private function ikUpdate(tpf:Float):Void
	{
        var vars:TempVars = TempVars.getTempVars();

        var tmpRot1:Quaternion = vars.quat1;
        var tmpRot2:Array<Quaternion> = [vars.quat2, new Quaternion()];
		
		var distance:Float;
        var bone:Bone;
		var keys = ikTargets.keys();
		for(boneName in keys)
		{
            bone = boneLinks.get(boneName).bone;
            if (!bone.hasUserControl())
			{
                Logger.log('${boneName} doesnt have user control');
                continue;
            }
			
            distance = bone.getModelSpacePosition().distance(ikTargets.get(boneName));
            if (distance < IKThreshold) 
			{
                Logger.log("Distance is close enough");
                continue;
            }
			
            var depth:Int = 0;
            var maxDepth:Int = ikChainDepth.get(bone.name);
            updateBone(boneLinks.get(bone.name), tpf * Math.sqrt(distance), vars, tmpRot1, tmpRot2, bone, ikTargets.get(boneName), depth, maxDepth);

            var position:Vector3f = vars.vect1;
            
            for (link in boneLinks) 
			{
                matchPhysicObjectToBone(link, position, tmpRot1);
            }
        }
        vars.release();
    }
    
    public function updateBone(link:PhysicsBoneLink, tpf:Float, vars:TempVars, tmpRot1:Quaternion, tmpRot2:Array<Quaternion>, 
	tipBone:Bone, target:Vector3f, depth:Int, maxDepth:Int):Void 
	{
        if (link == null || link.bone.parent == null) 
		{
            return;
        }
        var preQuat:Quaternion = link.bone.localRot;
        var vectorAxis:Vector3f;
        
        var measureDist:Array<Float> = [Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY];
        for (dirIndex in 0...3)
		{
            if (dirIndex == 0)
			{
                vectorAxis = Vector3f.Z_AXIS;
            } 
			else if (dirIndex == 1)
			{
                vectorAxis = Vector3f.X_AXIS;
            } 
			else {
                vectorAxis = Vector3f.Y_AXIS;
            }

            for (posOrNeg in 0...2)
			{
                var rot:Float = ikRotSpeed * tpf / (link.rigidBody.getMass() * 2);

                rot = FastMath.clamp(rot, link.joint.getRotationalLimitMotor(dirIndex).getLoLimit(), link.joint.getRotationalLimitMotor(dirIndex).getHiLimit());
                tmpRot1.fromAngleAxis(rot, vectorAxis);
//                tmpRot1.fromAngleAxis(rotSpeed * tpf / (link.rigidBody.getMass() * 2), vectorAxis);
                
                
                tmpRot2[posOrNeg] = link.bone.localRot.multLocal(tmpRot1);
                tmpRot2[posOrNeg].normalizeLocal();

                ikRotSpeed = -ikRotSpeed;
               
                link.bone.setLocalRotation(tmpRot2[posOrNeg]);
                link.bone.update();
                measureDist[posOrNeg] = tipBone.getModelSpacePosition().distance(target);
                link.bone.setLocalRotation(preQuat);
            }

            if (measureDist[0] < measureDist[1])
			{
                link.bone.setLocalRotation(tmpRot2[0]);
            } 
			else if (measureDist[0] > measureDist[1])
			{
                link.bone.setLocalRotation(tmpRot2[1]);
            }

        }
        link.bone.localRot.normalizeLocal();

        link.bone.update();
//        link.usedbyIK = true;
        if (link.bone.parent != null && depth < maxDepth)
		{
            updateBone(boneLinks.get(link.bone.parent.name), tpf * limbDampening, vars, tmpRot1, tmpRot2, tipBone, target, depth + 1, maxDepth);
        }
    }

    /**
     * Set the transforms of a rigidBody to match the transforms of a bone. this
     * is used to make the ragdoll follow the skeleton motion while in Kinematic
     * mode
     *
     * @param link the link containing the bone and the rigidBody
     * @param position just a temp vector for position
     * @param tmpRot1 just a temp quaternion for rotation
     */
    private function matchPhysicObjectToBone(link:PhysicsBoneLink, position:Vector3f, tmpRot1:Quaternion):Void
	{
        //computing position from rotation and scale
        targetModel.getWorldTransform().transformVector(link.bone.getModelSpacePosition(), position);

        //computing rotation
        tmpRot1.copyFrom(link.bone.getModelSpaceRotation()).multLocal(link.bone.getWorldBindInverseRotation());
        targetModel.getWorldRotation().mult(tmpRot1, tmpRot1);
        tmpRot1.normalizeLocal();

        //updating physic location/rotation of the physic bone
        link.rigidBody.setPhysicsLocation(position);
        link.rigidBody.setPhysicsRotationWithQuaternion(tmpRot1);

    }

    /**
     * rebuild the ragdoll this is useful if you applied scale on the ragdoll
     * after it's been initialized, same as reattaching.
     */
    public function reBuild():Void 
	{
        if (spatial == null)
		{
            return;
        }
        removeSpatialData(spatial);
        createSpatialData(spatial);
    }
	
	override function createSpatialData(model:Spatial):Void 
	{
        targetModel = model;
        var parent:Node = model.parent;


        var initPosition:Vector3f = model.getLocalTranslation().clone();
        var initRotation:Quaternion = model.getLocalRotation().clone();
        initScale = model.getLocalScale().clone();

        model.removeFromParent();
        model.setLocalTranslation(Vector3f.ZERO);
        model.setLocalRotation(Quaternion.IDENTITY);
        model.setLocalScaleXYZ(1,1,1);
        //HACK ALERT change this
        //I remove the skeletonControl and readd it to the spatial to make sure it's after the ragdollControl in the stack
        //Find a proper way to order the controls.
        var sc:SkeletonControl = cast model.getControl(SkeletonControl);
        if (sc == null)
		{
            throw ("The root node of the model should have a SkeletonControl. Make sure the control is there and that it's not on a sub node.");
        }
        model.removeControl(sc);
        model.addControl(sc);

        // put into bind pose and compute bone transforms in model space
        // maybe dont reset to ragdoll out of animations?
        scanSpatial(model);


        if (parent != null)
		{
            parent.attachChild(model);

        }
        model.setLocalTranslation(initPosition);
        model.setLocalRotation(initRotation);
        model.setLocalScale(initScale);

        if (added)
		{
            addPhysics(space);
        }
        Logger.log('Created physics ragdoll for skeleton ${skeleton}');
    }
	
	override function removeSpatialData(spat:Spatial):Void 
	{
        if (added)
		{
            removePhysics(space);
        }
        boneLinks = new FastStringMap<PhysicsBoneLink>();
    }

    /**
     * Add a bone name to this control Using this method you can specify which
     * bones of the skeleton will be used to build the collision shapes.
     *
     * @param name
     */
    public function addBoneName(name:String):Void 
	{
        boneList.push(name);
    }

    private function scanSpatial(model:Spatial):Void
	{
        var animControl:AnimControl = cast model.getControl(AnimControl);
        var pointsMap:IntMap<Array<Float>> = null;
        if (weightThreshold == -1.0)
		{
            pointsMap = RagdollUtils.buildPointMap(model);
        }

        skeleton = cast(animControl,SkeletonControl).getSkeleton();
        skeleton.resetAndUpdate();
        for (i in 0...skeleton.rootBones.length)
		{
            var childBone:Bone = skeleton.rootBones[i];
            if (childBone.parent == null)
			{
                Logger.log('Found root bone in skeleton ${skeleton}');
                boneRecursion(model, childBone, baseRigidBody, 1, pointsMap);
            }
        }
    }

    private function boneRecursion(model:Spatial, bone:Bone, parent:PhysicsRigidBody, reccount:Int, pointsMap:IntMap<Array<Float>>):Void 
	{
        var parentShape:PhysicsRigidBody = parent;
        if (boneList.length == 0 || boneList.indexOf(bone.name) != -1)
		{

            var link:PhysicsBoneLink = new PhysicsBoneLink();
            link.bone = bone;

            //creating the collision shape 
            var shape:HullCollisionShape = null;
            if (pointsMap != null)
			{
                //build a shape for the bone, using the vertices that are most influenced by this bone
                shape = RagdollUtils.makeShapeFromPointMap(pointsMap, RagdollUtils.getBoneIndices(link.bone, skeleton, boneList), initScale, link.bone.getModelSpacePosition());
            } 
			else
			{
                //build a shape for the bone, using the vertices associated with this bone with a weight above the threshold
                shape = RagdollUtils.makeShapeFromVerticeWeights(model, RagdollUtils.getBoneIndices(link.bone, skeleton, boneList), initScale, link.bone.getModelSpacePosition(), weightThreshold);
            }

            var shapeNode:PhysicsRigidBody = new PhysicsRigidBody(shape, rootMass / reccount);

            shapeNode.setKinematic(mode == KinematicRagdollMode.Kinematic);
            totalMass += rootMass / reccount;

            link.rigidBody = shapeNode;
            link.initalWorldRotation = bone.getModelSpaceRotation().clone();

            if (parent != null)
			{
                //get joint position for parent
                var posToParent:Vector3f = new Vector3f();
                if (bone.parent != null)
				{
                    bone.getModelSpacePosition().subtract(bone.parent.getModelSpacePosition(), posToParent).multLocal(initScale);
                }

                var joint:SixDofJoint = new SixDofJoint(parent, shapeNode, posToParent, new Vector3f(0, 0, 0), true);
                preset.setupJointForBone(bone.name, joint);

                link.joint = joint;
                joint.setCollisionBetweenLinkedBodys(false);
            }
            boneLinks.set(bone.name, link);
            shapeNode.setUserObject(link);
            parentShape = shapeNode;
        }
		
		for (childBone in bone.children)
		{
			boneRecursion(model, childBone, parentShape, reccount + 1, pointsMap);
		}
    }

    /**
     * Set the joint limits for the joint between the given bone and its parent.
     * This method can't work before attaching the control to a spatial
     *
     * @param boneName the name of the bone
     * @param maxX the maximum rotation on the x axis (in radians)
     * @param minX the minimum rotation on the x axis (in radians)
     * @param maxY the maximum rotation on the y axis (in radians)
     * @param minY the minimum rotation on the z axis (in radians)
     * @param maxZ the maximum rotation on the z axis (in radians)
     * @param minZ the minimum rotation on the z axis (in radians)
     */
    public function setJointLimit(boneName:String, maxX:Float, minX:Float, maxY:Float, minY:Float, maxZ:Float, minZ:Float):Void 
	{
        var link:PhysicsBoneLink = boneLinks.get(boneName);
        if (link != null)
		{
            RagdollUtils.setJointLimit(link.joint, maxX, minX, maxY, minY, maxZ, minZ);
        }
		else
		{
            Logger.log('Not joint was found for bone ${boneName}. make sure you call spatial.addControl(ragdoll) before setting joints limit' );
        }
    }

    /**
     * Return the joint between the given bone and its parent. This return null
     * if it's called before attaching the control to a spatial
     *
     * @param boneName the name of the bone
     * @return the joint between the given bone and its parent
     */
    public function getJoint(boneName:String):SixDofJoint
	{
        var link:PhysicsBoneLink = boneLinks.get(boneName);
        if (link != null) 
		{
            return link.joint;
        } 
		else
		{
            Logger.log('Not joint was found for bone ${boneName}. make sure you call spatial.addControl(ragdoll) before setting joints limit' );
            return null;
        }
    }
	
	override function setPhysicsLocation(vec:Vector3f):Void 
	{
		if (baseRigidBody != null)
		{
            baseRigidBody.setPhysicsLocation(vec);
        }
	}

    override function setPhysicsRotation(quat:Quaternion):Void 
	{
		if (baseRigidBody != null) 
		{
            baseRigidBody.setPhysicsRotationWithQuaternion(quat);
        }
	}

    override function addPhysics(space:PhysicsSpace):Void 
	{
		if (baseRigidBody != null)
		{
            space.add(baseRigidBody);
        }
        for (physicsBoneLink in boneLinks) 
		{
            if (physicsBoneLink.rigidBody != null)
			{
                space.add(physicsBoneLink.rigidBody);
                if (physicsBoneLink.joint != null)
				{
                    space.add(physicsBoneLink.joint);
                }
            }
        }
        space.addCollisionListener(this);
	}
	
	override function removePhysics(space:PhysicsSpace):Void 
	{
		if (baseRigidBody != null)
		{
            space.remove(baseRigidBody);
        }
		
        for (physicsBoneLink in boneLinks)
		{
            if (physicsBoneLink.joint != null)
			{
                space.remove(physicsBoneLink.joint);
                if (physicsBoneLink.rigidBody != null) 
				{
                    space.remove(physicsBoneLink.rigidBody);
                }
            }
        }
        space.removeCollisionListener(this);
	}
	
    /**
     * For internal use only callback for collisionevent
     *
     * @param event
     */
    public function collision(event:PhysicsCollisionEvent):Void 
	{
        var objA:PhysicsCollisionObject = event.getObjectA();
        var objB:PhysicsCollisionObject = event.getObjectB();

        //excluding collisions that involve 2 parts of the ragdoll
        if (event.getNodeA() == null && event.getNodeB() == null)
		{
            return;
        }

        //discarding low impulse collision
        if (event.getAppliedImpulse() < eventDispatchImpulseThreshold)
		{
            return;
        }

        var hit:Bool = false;
        var hitBone:Bone = null;
        var hitObject:PhysicsCollisionObject = null;

        //Computing which bone has been hit
        if (Std.is(objA.getUserObject(), PhysicsBoneLink))
		{
            var link:PhysicsBoneLink = cast objA.getUserObject();
            if (link != null)
			{
                hit = true;
                hitBone = link.bone;
                hitObject = objB;
            }
        }

        if (Std.is(objB.getUserObject(), PhysicsBoneLink))
		{
            var link:PhysicsBoneLink = cast objB.getUserObject();
            if (link != null)
			{
                hit = true;
                hitBone = link.bone;
                hitObject = objA;

            }
        }

        //dispatching the event if the ragdoll has been hit
        if (hit && listeners != null)
		{
            for (listener in listeners) 
			{
                listener.collide(hitBone, hitObject, event);
            }
        }

    }

    /**
     * Enable or disable the ragdoll behaviour. if ragdollEnabled is true, the
     * character motion will only be powerd by physics else, the characted will
     * be animated by the keyframe animation, but will be able to physically
     * interact with its physic environnement
     *
     * @param ragdollEnabled
     */
    private function setMode(mode:KinematicRagdollMode):Void 
	{
        this.mode = mode;
		
        var animControl:AnimControl = cast targetModel.getControl(AnimControl);
        animControl.setEnabled(mode == KinematicRagdollMode.Kinematic);

        baseRigidBody.setKinematic(mode == KinematicRagdollMode.Kinematic);
		if (mode != KinematicRagdollMode.IK) 
		{
			var vars:TempVars = TempVars.getTempVars();

			for (link in boneLinks)
			{
				link.rigidBody.setKinematic(mode == KinematicRagdollMode.Kinematic);
				if (mode == KinematicRagdollMode.Ragdoll)
				{
					var tmpRot1:Quaternion = vars.quat1;
					var position:Vector3f = vars.vect1;
					//making sure that the ragdoll is at the correct place.
					matchPhysicObjectToBone(link, position, tmpRot1);
				}

			}
			vars.release();
		}

        if (mode != KinematicRagdollMode.IK)
		{
            for (bone in skeleton.rootBones)
			{
                RagdollUtils.setUserControl(bone, mode == KinematicRagdollMode.Ragdoll);
            }
        }
        
    }

    /**
     * Smoothly blend from Ragdoll mode to Kinematic mode This is useful to
     * blend ragdoll actual position to a keyframe animation for example
     *
     * @param blendTime the blending time between ragdoll to anim.
     */
    public function blendToKinematicMode(blendTime:Float):Void
	{
        if (mode == KinematicRagdollMode.Kinematic) 
		{
            return;
        }
		
        blendedControl = true;
        this.blendTime = blendTime;
        mode = KinematicRagdollMode.Kinematic;
		
        var animControl:AnimControl = cast targetModel.getControl(AnimControl);
        animControl.setEnabled(true);


        var vars:TempVars = TempVars.getTempVars();
        for (link in boneLinks) 
		{

            var p:Vector3f = link.rigidBody.getMotionState().getWorldLocation();
            var position:Vector3f = vars.vect1;

            targetModel.getWorldTransform().transformInverseVector(p, position);

            var q:Quaternion = link.rigidBody.getMotionState().getWorldRotationQuat();
            var q2:Quaternion = vars.quat1;
            var q3:Quaternion = vars.quat2;

            q2.copyFrom(q).multLocal(link.initalWorldRotation).normalizeLocal();
            q3.copyFrom(targetModel.getWorldRotation()).inverseLocal().mult(q2, q2);
            q2.normalizeLocal();
            link.startBlendingPos.copyFrom(position);
            link.startBlendingRot.copyFrom(q2);
            link.rigidBody.setKinematic(true);
        }
        vars.release();

        for (bone in skeleton.rootBones)
		{
            RagdollUtils.setUserControl(bone, false);
        }

        blendStart = 0;
    }

    /**
     * Set the control into Kinematic mode In theis mode, the collision shapes
     * follow the movements of the skeleton, and can interact with physical
     * environement
     */
    public function setKinematicMode():Void 
	{
        if (mode != KinematicRagdollMode.Kinematic) 
		{
            setMode(KinematicRagdollMode.Kinematic);
        }
    }

    /**
     * Sets the control into Ragdoll mode The skeleton is entirely controlled by
     * physics.
     */
    public function setRagdollMode():Void
	{
        if (mode != KinematicRagdollMode.Ragdoll) 
		{
            setMode(KinematicRagdollMode.Ragdoll);
        }
    }

    /**
     * Sets the control into Inverse Kinematics mode. The affected bones are affected by IK.
     * physics.
     */
    public function setIKMode():Void 
	{
        if (mode != KinematicRagdollMode.IK) 
		{
            setMode(KinematicRagdollMode.IK);
        }
    }
    
    /**
     * retruns the mode of this control
     *
     * @return
     */
    public function getMode():KinematicRagdollMode
	{
        return mode;
    }

    /**
     * add a
     *
     * @param listener
     */
    public function addCollisionListener(listener:RagdollCollisionListener):Void 
	{
        if (listeners == null)
		{
            listeners = new Array<RagdollCollisionListener>();
        }
        listeners.push(listener);
    }

    public function setRootMass(rootMass:Float):Void 
	{
        this.rootMass = rootMass;
    }

    public function getTotalMass():Float
	{
        return totalMass;
    }

    public function getWeightThreshold():Float
	{
        return weightThreshold;
    }

    public function setWeightThreshold(weightThreshold:Float):Void 
	{
        this.weightThreshold = weightThreshold;
    }

    public function getEventDispatchImpulseThreshold():Float
	{
        return eventDispatchImpulseThreshold;
    }

    public function setEventDispatchImpulseThreshold(eventDispatchImpulseThreshold:Float):Void
	{
        this.eventDispatchImpulseThreshold = eventDispatchImpulseThreshold;
    }

    /**
     * Set the CcdMotionThreshold of all the bone's rigidBodies of the ragdoll
     *
     * @see PhysicsRigidBody#setCcdMotionThreshold(float)
     * @param value
     */
    public function setCcdMotionThreshold(value:Float):Void 
	{
        for (link in boneLinks)
		{
            link.rigidBody.setCcdMotionThreshold(value);
        }
    }

    /**
     * Set the CcdSweptSphereRadius of all the bone's rigidBodies of the ragdoll
     *
     * @see PhysicsRigidBody#setCcdSweptSphereRadius(float)
     * @param value
     */
    public function setCcdSweptSphereRadius(value:Float):Void 
	{
        for (link in boneLinks)
		{
            link.rigidBody.setCcdSweptSphereRadius(value);
        }
    }

    /**
     * return the rigidBody associated to the given bone
     *
     * @param boneName the name of the bone
     * @return the associated rigidBody.
     */
    public function getBoneRigidBody(boneName:String):PhysicsRigidBody
	{
        var link:PhysicsBoneLink = boneLinks.get(boneName);
        if (link != null)
		{
            return link.rigidBody;
        }
        return null;
    }

    override public function cloneForSpatial(spatial:Spatial):Control
	{
        var control:KinematicRagdollControl = new KinematicRagdollControl(preset, weightThreshold);
        control.setMode(mode);
        control.setRootMass(rootMass);
        control.setWeightThreshold(weightThreshold);
        control.setApplyPhysicsLocal(applyLocal);
        return control;
    }
   
    public function setIKTarget(bone:Bone, worldPos:Vector3f, chainLength:Int):Vector3f
	{
        var target:Vector3f = worldPos.subtract(targetModel.getWorldTranslation());
        ikTargets.set(bone.name, target);
        ikChainDepth.set(bone.name, chainLength);
        var i:Int = 0;
        while (i < chainLength + 2 && bone.parent != null) 
		{
            if (!bone.hasUserControl()) 
			{
                bone.setUserControl(true);
            }
            bone = bone.parent;
            i++;
        }


//        setIKMode();
        return target;
    }

    public function removeIKTarget(bone:Bone):Void
	{
        var depth:Int = ikChainDepth.get(bone.name);
		ikChainDepth.remove(bone.name);
        var i:Int = 0;
        while (i < depth + 2 && bone.parent != null)
		{
            if (bone.hasUserControl()) 
			{
//                matchPhysicObjectToBone(boneLinks.get(bone.getName()), position, tmpRot1);
                bone.setUserControl(false);
            }
            bone = bone.parent;
            i++;
        }
    }
    
    public function removeAllIKTargets():Void
	{
        ikTargets = new FastStringMap<Vector3f>();
        ikChainDepth = new FastStringMap<Int>();
        applyUserControl();
    }
	
    public function applyUserControl():Void 
	{
        for (bone in skeleton.rootBones)
		{
            RagdollUtils.setUserControl(bone, false);
        }

        if (!ikTargets.iterator().hasNext())
		{
            setKinematicMode();
        } 
		else 
		{
            var vars:TempVars = TempVars.getTempVars();
			
			var keys = ikTargets.keys();
			for (key in keys)
			{
				var bone:Bone = boneLinks.get(key).bone;
				
				while (bone.parent != null)
				{
                    var tmpRot1:Quaternion = vars.quat1;
                    var position:Vector3f = vars.vect1;
                    matchPhysicObjectToBone(boneLinks.get(bone.name), position, tmpRot1);
                    bone.setUserControl(true);
                    bone = bone.parent;
                }
			}
			
            vars.release();
        }
    }
	
    public function getIkRotSpeed():Float 
	{
        return ikRotSpeed;
    }

    public function setIkRotSpeed(ikRotSpeed:Float):Void 
	{
        this.ikRotSpeed = ikRotSpeed;
    }

    public function getIKThreshold():Float 
	{
        return IKThreshold;
    }

    public function setIKThreshold(IKThreshold:Float):Void
	{
        this.IKThreshold = IKThreshold;
    }

    
    public function getLimbDampening():Float 
	{
        return limbDampening;
    }

    public function setLimbDampening(limbDampening:Float):Void 
	{
        this.limbDampening = limbDampening;
    }
    
    public function getBone(name:String):Bone
	{
        return skeleton.getBoneByName(name);
    }
}

enum KinematicRagdollMode 
{
	Kinematic;
	Ragdoll;
	IK;
}

class PhysicsBoneLink 
{
	public var rigidBody:PhysicsRigidBody;
	public var bone:Bone;
	public var joint:SixDofJoint;
	public var initalWorldRotation:Quaternion;
	public var startBlendingRot:Quaternion = new Quaternion();
	public var startBlendingPos:Vector3f = new Vector3f();

	public function new()
	{
	}
}
