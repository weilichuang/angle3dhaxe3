package org.angle3d.scene;

import flash.Vector;
import org.angle3d.ds.FastStringMap;
import org.angle3d.bounding.BoundingBox;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.collision.Collidable;
import org.angle3d.collision.CollisionResults;
import org.angle3d.light.Light;
import org.angle3d.light.LightList;
import org.angle3d.material.Material;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Transform;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.scene.RefreshFlag;
import org.angle3d.renderer.FrustumIntersect;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.control.Control;
import org.angle3d.error.Assert;
import org.angle3d.utils.Cloneable;
import org.angle3d.utils.Logger;
import org.angle3d.utils.TempVars;
import org.angle3d.material.MatParamOverride;
using org.angle3d.utils.VectorUtil;

/**
 * `Spatial` defines the base class for scene graph nodes. It
 * maintains a link to a parent, it's local transforms and the world's
 * transforms. All other nodes, such as `Node` and
 * `Geometry` are subclasses of `Spatial`.
 */
class Spatial implements Cloneable implements Collidable
{
	/**
     * Boolean type on Geometries to indicate that physics collision
     * shape generation should ignore them.
     */
    public static inline var USERDATA_PHYSICSIGNORE:String = "UserDataPhysicsIgnore";
    
    /**
     * For geometries using shared mesh, this will specify the shared
     * mesh reference.
     */
    public static inline var USERDATA_SHAREDMESH:String = "UserDataSharedMesh";
	
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var z(get, set):Float;
	
	/**
	 * retrieves the local translation of this node.
	 */
	public var localTranslation(get, set):Vector3f;
	
	/**
	 * retrieves the absolute translation of the spatial.
	 */
	public var worldTranslation(get, never):Vector3f;
	
	public var scaleX(get, set):Float;
	public var scaleY(get, set):Float;
	public var scaleZ(get, set):Float;
	
	/**
	 * The number of controls attached to this Spatial.
	 */
	public var numControls(get, null):Int;
	
	/**
	 * Refresh flags. Indicate what data of the spatial need to be
	 * updated to reflect the correct state.
	 */
	public var refreshFlags:RefreshFlag;
	
	/**
	 * Spatial's parent, or null if it has none.
	 */
	public var parent(get, set):Node;
	
	public var visible(default, set):Bool = true;
	
	/**
	 * 是否真正可见
	 * 自身可能是可见的，但是parent是不可见，所以还是不可见的
	 */
	public var truelyVisible(get, null):Bool;
	
	/**
	 * the cull mode of this spatial, or if set to CullHint.Inherit,
	 * the cullmode of it's parent.
	 */
	public var cullHint(get, null):CullHint;
	
	/**
	 * this spatial's renderqueue bucket. If the mode is set to inherit,
	 * then the spatial gets its renderqueue bucket from its parent.
	 */
	public var queueBucket(get, null):QueueBucket;
	
	/**
	 * The shadow mode of this spatial, if the local shadow
	 * mode is set to inherit, then the parent's shadow mode is returned.
	 *
	 */
	public var shadowMode(get, null):ShadowMode;
	
	/**
	 * the batchHint set on this Spatial, or if set to BatchHint.Inherit, the
     * cull mode of its parent
	 */
	public var batchHint(get, null):BatchHint;
	
	/**
     * localCullHint alters how view frustum culling will treat this
     * spatial.
     *
     * The effect of the default value `CullHint.Inherit` may change if the
     * spatial gets re-parented.
     */
	public var localCullHint(get, set):CullHint;
	
	/**
	 * `localQueueBucket` determines at what phase of the
	 * rendering process this Spatial will rendered. See the
	 * Bucket enum for an explanation of the various
	 * render queue buckets.
	 *
	 */
	public var localQueueBucket(get, set):QueueBucket;
	
	/**
	 * The shadow mode determines how the spatial should be shadowed,
	 * when a shadowing technique is used. See the
	 * documentation for the class ShadowMode for more information.
	 *
	 */
	public var localShadowMode(get, set):ShadowMode;
	
	/**
	 * the batchHint set on this Spatial
	 */
	public var localBatchHint(get, set):BatchHint;
	
	/**
	 * retrieves the world bound at this node level.
	 */
	public var worldBound(get, null):BoundingVolume;
	
	/**
	 * This `FrustumIntersect` is set
	 * when a check is made to determine if the bounds of the object fall inside
	 * a camera's frustum. If a parent is found to fall outside the frustum, the
	 * value for this spatial will not be updated.
	 */
	public var lastFrustumIntersection(get, set):FrustumIntersect;
	
	/**
	 * This spatial's name.
	 */
	public var name:String;

	public var queueDistance:Float = -1e30;
	
	private var mCullHint:CullHint = CullHint.Inherit;
	private var mBatchHint:BatchHint = BatchHint.Inherit;

	/**
	 * Spatial's bounding volume relative to the world.
	 */
	private var mWorldBound:BoundingVolume;

	/**
	 * LightList
	 */
	private var mLocalLights:LightList;
	private var mWorldLights:LightList;
	
	private var localOverrides:Vector<MatParamOverride>;
    private var worldOverrides:Vector<MatParamOverride>;

	private var mFrustrumIntersects:FrustumIntersect = FrustumIntersect.Intersects;
	private var mQueueBucket:QueueBucket = QueueBucket.Inherit;
	private var mShadowMode:ShadowMode = ShadowMode.Inherit;

	private var mLocalTransform:Transform;
	private var mWorldTransform:Transform;

	private var mControls:Vector<Control> = new Vector<Control>();
	private var mNumControl:Int = 0;
	
	private var userData:FastStringMap<Dynamic> = null;
	
	/** 
     * Spatial's parent, or null if it has none.
     */
	private var mParent:Node;

	/**
     * Set to true if a subclass requires `updateLogicalState()` even
     * if it doesn't have any controls.  Defaults to true thus implementing
     * the legacy behavior for any subclasses not specifically turning it
     * off.
     * This flag should be set during construction and never changed
     * as it's supposed to be class-specific and not runtime state.
     */
    private var mRequiresUpdates:Bool = true;
	
	/**
	 * 是否需要使用灯光，确定不使用灯光时可设置为false,可加快速度
	 */
	public var useLight:Bool = true;

	/**
	 * Constructor instantiates a new `Spatial` object setting the
	 * rotation, translation and scale value to defaults.
	 *
	 * @param name
	 *            the name of the scene element. This is required for
	 *            identification and comparision purposes.
	 */
	public function new(name:String)
	{
		this.name = name;
		
		mLocalTransform = new Transform();
		mWorldTransform = new Transform();

		mLocalLights = new LightList(this);
		mWorldLights = new LightList(this);
		
		localOverrides = new Vector<MatParamOverride>();
		worldOverrides = new Vector<MatParamOverride>();

		refreshFlags = RefreshFlag.NONE;
		refreshFlags = refreshFlags.add(RefreshFlag.RF_BOUND);
	}
	
	/**
     * Returns true if this spatial requires `updateLogicalState()` to
     * be called, either because `setRequiresUpdate(true)` has been called
     * or because the spatial has controls.  This is package private to
     * avoid exposing it to the public API since it is only used by Node.
     */
    private inline function requiresUpdates():Bool
	{
        return mRequiresUpdates || mNumControl > 0;
    }
	
	/**
     * Subclasses can call this with true to denote that they require 
     * `updateLogicalState()` to be called even if they contain no controls.
     * Setting this to false reverts to the default behavior of only
     * updating if the spatial has controls.  This is not meant to
     * indicate dynamic state in any way and must be called while 
     * unattached or an IllegalStateException is thrown.  It is designed
     * to be called during object construction and then never changed, ie:
     * it's meant to be subclass specific state and not runtime state.
     * Subclasses of Node or Geometry that do not set this will get the
     * old default behavior as if this was set to true.  Subclasses should
     * call setRequiresUpdate(false) in their constructors to receive
     * optimal behavior if they don't require `updateLogicalState()` to be
     * called even if there are no controls.
     */
	private function setRequiresUpdates(value:Bool):Void
	{
		// Note to explorers, the reason this was done as a protected setter
        // instead of passed on construction is because it frees all subclasses
        // from having to make sure to always pass the value up in case they
        // are subclassed.
        // The reason that requiresUpdates() isn't just a protected method to
        // override (which would be more correct) is because the flag provides
        // some flexibility in how we break subclasses.  A protected method
        // would require that all subclasses that required updates need implement
        // this method or they would silently stop processing updates.  A flag
        // lets us set a default when a subclass is detected that is different
        // than the internal "more efficient" default.
        // Spatial's default is 'true' for this flag requiring subclasses to
        // override it for more optimal behavior.  Node and Geometry will override
        // it to false if the class is Node.class or Geometry.class.
        // This means that all subclasses will default to the old behavior
        // unless they opt in. 
		if ( parent != null )
		{
            throw "setRequiresUpdates() cannot be called once attached."; 
        }
		this.mRequiresUpdates = value;
	}
	
	public function getWorldBound():BoundingVolume
	{
		checkDoBoundUpdate();
		return mWorldBound;
	}

	/**
	 * Indicate that the transform of this spatial has changed and that
	 * a refresh is required.
	 */
	public function setTransformRefresh():Void
	{
		refreshFlags = refreshFlags.add(RefreshFlag.RF_TRANSFORM);
		setBoundRefresh();
	}
	
	public function setLightListRefresh():Void
	{
		refreshFlags = refreshFlags.add(RefreshFlag.RF_LIGHTLIST);
		
		// Make sure next updateGeometricState() visits this branch to update lights.
        var p:Spatial = parent;
        while (p != null) 
		{
            //if (p.refreshFlags != 0) {
                // any refresh flag is sufficient, 
                // as each propagates to the root Node

                // 2015/2/8:
                // This is not true, because using e.g. getWorldBound()
                // or getWorldTransform() activates a "partial refresh"
                // which does not update the lights but does clear
                // the refresh flags on the ancestors!
            
            //    return; 
            //}
            
            if (p.refreshFlags.contains(RefreshFlag.RF_CHILD_LIGHTLIST))
			{
                // The parent already has this flag,
                // so must all ancestors.
                return;
            }
            
            p.refreshFlags = p.refreshFlags.add(RefreshFlag.RF_CHILD_LIGHTLIST);
            p = p.parent;
        }
	}

	public inline function setTransformUpdated():Void
	{
		refreshFlags = refreshFlags.remove(RefreshFlag.RF_TRANSFORM);
	}
	
	/**
	 * Indicate that the bounding of this spatial has changed and that
	 * a refresh is required.
	 */
	public function setBoundRefresh():Void
	{
		refreshFlags = refreshFlags.add(RefreshFlag.RF_BOUND);

		var p:Spatial = mParent;
		while (p != null)
		{
			if (p.needBoundUpdate())
			{
				return;
			}

			p.refreshFlags = p.refreshFlags.add(RefreshFlag.RF_BOUND);
			p = p.mParent;
		}
	}
	
	/**
     * (Internal use only) Forces a refresh of the given types of data.
     * 
     * @param transforms Refresh world transform based on parents'
     * @param bounds Refresh bounding volume data based on child nodes
     * @param lights Refresh light list based on parents'
     */
	@:dox(hide)
	public function forceRefresh(transforms:Bool, bounds:Bool, lights:Bool):Void
	{
		if (transforms)
		{
            setTransformRefresh();
        }
		
        if (bounds) 
		{
            setBoundRefresh();
        }
		
        if (lights) 
		{
            setLightListRefresh();
        }
	}

	/**
	 * 是否需要更新LightList
	 */
	@:dox(hide)
	public inline function needLightListUpdate():Bool
	{
		return refreshFlags.contains(RefreshFlag.RF_LIGHTLIST);
	}

	/**
	 * 是否需要更新坐标
	 */
	@:dox(hide)
	public inline function needTransformUpdate():Bool
	{
		return refreshFlags.contains(RefreshFlag.RF_TRANSFORM);
	}

	/**
	 * 是否需要更新包围体
	 */
	@:dox(hide)
	public inline function needBoundUpdate():Bool
	{
		return refreshFlags.contains(RefreshFlag.RF_BOUND);
	}
	
	@:dox(hide)
	public inline function needMatParamOverrideUpdate():Bool
	{
		return refreshFlags.contains(RefreshFlag.RF_MATPARAM_OVERRIDE);
	}

	public inline function setLightListUpdated():Void
	{
		refreshFlags = refreshFlags.remove(RefreshFlag.RF_LIGHTLIST);
	}

	public inline function setBoundUpdated():Void
	{
		refreshFlags = refreshFlags.remove(RefreshFlag.RF_BOUND);
	}

	/**
	 * `checkCulling` checks the spatial with the camera to see if it
	 * should be culled.
	 * <p>
	 * This method is called by the renderer. Usually it should not be called
	 * directly.
	 *
	 * @param cam The camera to check against.
	 * @return true if inside or intersecting camera frustum (should be rendered), false if outside.
	 */
	public function checkCulling(cam:Camera):Bool
	{
		#if debug
		Assert.assert(refreshFlags == RefreshFlag.NONE, "Scene graph is not properly updated for rendering.\n" + 
					"Make sure scene graph state was not changed after\n" + 
					" rootNode.updateGeometricState() call. \n" +
					"Problem spatial name: " + name);
		#end

		var cm:CullHint = cullHint;

		#if debug
		Assert.assert(cm != CullHint.Inherit, "getCullHint() is not CullHint.Inherit");
		#end

		if (cm == CullHint.Always)
		{
			lastFrustumIntersection = FrustumIntersect.Outside;
			return false;
		}
		else if (cm == CullHint.Never)
		{
			lastFrustumIntersection = FrustumIntersect.Intersects;
			return true;
		}

		// check to see if we can cull this node
		mFrustrumIntersects = (mParent != null) ? mParent.lastFrustumIntersection : FrustumIntersect.Intersects;

		if (mFrustrumIntersects == FrustumIntersect.Intersects)
		{
			if (queueBucket == QueueBucket.Gui)
			{
				return cam.containsGui(worldBound);
			}
			else
			{
				mFrustrumIntersects = cam.contains(worldBound);
			}
		}
		return mFrustrumIntersects != FrustumIntersect.Outside;
	}

	/**
	 * Returns the local LightList, which are the lights
	 * that were directly attached to this `Spatial` through the
	 * `addLight` and `removeLight` methods.
	 *
	 * @return The local light list
	 */
	public inline function getLocalLightList():LightList
	{
		return mLocalLights;
	}

	/**
	 * Returns the world LightList, containing the lights
	 * combined from all this `Spatial's` parents up to and including
	 * this `Spatial`'s lights.
	 *
	 * @return The combined world light list
	 */
	public inline function getWorldLightList():LightList
	{
		return mWorldLights;
	}
	
	/**
     * Get the local material parameter overrides.
     *
     * @return The list of local material parameter overrides.
     */
    public inline function getLocalMatParamOverrides():Vector<MatParamOverride>
	{
        return localOverrides;
    }
	
	/**
     * Get the world material parameter overrides.
     *
     * Note that this list is only updated on a call to `updateGeometricState`. 
	 * After update, the world overrides list
     * will contain the parent's world overrides combined
     * with this spatial's local overrides.
     *
     * @return The list of world material parameter overrides.
     */
    public inline function getWorldMatParamOverrides():Vector<MatParamOverride> 
	{
        return worldOverrides;
    }

	/**
	 * `getWorldRotation` retrieves the absolute rotation of the
	 * Spatial.
	 *
	 * @return the Spatial's world rotation matrix.
	 */
	public function getWorldRotation():Quaternion
	{
		checkDoTransformUpdate();
		return mWorldTransform.rotation;
	}

	/**
	* `getWorldTranslation` retrieves the absolute translation of
	* the spatial.
	*
	* @return the world's tranlsation vector.
	*/
	public function getWorldTranslation():Vector3f
	{
		checkDoTransformUpdate();
		return mWorldTransform.translation;
	}

	/**
	 * `getWorldScale` retrieves the absolute scale factor of the
	 * spatial.
	 *
	 * @return the world's scale factor.
	 */
	public function getWorldScale():Vector3f
	{
		checkDoTransformUpdate();
		return mWorldTransform.scale;
	}

	/**
	* `getWorldTransform` retrieves the world transformation
	* of the spatial.
	*
	* @return the world transform.
	*/
	public function getWorldTransform():Transform
	{
		checkDoTransformUpdate();
		return mWorldTransform;
	}

	/**
	 * `rotateUpTo` is a util function that alters the
	 * localrotation to point the Y axis in the direction given by newUp.
	 *
	 * @param newUp
	 *            the up vector to use - assumed to be a unit vector.
	 */
	public function rotateUpTo(newUp:Vector3f):Void
	{
		var tempVars:TempVars = TempVars.getTempVars();
		var upY:Vector3f = tempVars.vect1;
		var q:Quaternion = tempVars.quat1;
		
		// First figure out the current up vector.
		upY.setTo(0, 1, 0);
		var rot:Quaternion = mLocalTransform.rotation;
		rot.multVecLocal(upY);

		// get_angle between vectors
		var angle:Float = upY.angleBetween(newUp);

		// figure out rotation axis by taking cross product
		var rotAxis:Vector3f = upY.crossLocal(newUp).normalizeLocal();

		// Build a rotation quat and apply current local rotation.
		q.fromAngleAxis(angle, rotAxis);
		q.mult(rot, rot);
		
		tempVars.release();

		setTransformRefresh();
	}

	/**
	 * `lookAt` is a convienence method for auto-setting the local
	 * rotation based on a position and an up vector. It computes the rotation
	 * to transform the z-axis to point onto 'position' and the y-axis to 'up'.
	 * Unlike `org.angle3d.math.Quaternion.lookAt` this method takes a world position to
	 * look at not a relative direction.
	 * 
	 * Note : 28/01/2013 this method has been fixed as it was not taking into account the parent rotation.
     * This was resulting in improper rotation when the spatial had rotated parent nodes.
     * This method is intended to work in world space, so no matter what parent graph the 
     * spatial has, it will look at the given position in world space.
	 *
	 * @param position
	 *            where to look at in terms of world coordinates
	 * @param upVector
	 *            a vector indicating the (local) up direction. (typically {0, 1, 0})
	 */
	public function lookAt(position:Vector3f, upVector:Vector3f):Void
	{
		var worldTranslation:Vector3f = getWorldTranslation();
		
		var tempVars:TempVars = TempVars.getTempVars();
		var compVecA:Vector3f = tempVars.vect4;

		compVecA.copyFrom(position).subtractLocal(worldTranslation);
		getLocalRotation().lookAt(compVecA, upVector);
		
		if (mParent != null)
		{
			var rot:Quaternion = tempVars.quat1;
			
			rot.copyFrom(mParent.getWorldRotation()).inverseLocal().multLocal(getLocalRotation());
			rot.normalizeLocal();
			setLocalRotation(rot);
		}
		
		tempVars.release();

		setTransformRefresh();
	}

	/**
	 * Should be overriden by Node and Geometry.
	 */
	public function updateWorldBound():Void
	{
		// the world bound of a leaf is the same as it's model bound
		// for a node, the world bound is a combination of all it's children
		// bounds
		// -> handled by subclass
		refreshFlags = refreshFlags.remove(RefreshFlag.RF_BOUND);
	}

	private function updateWorldLightList():Void
	{
		if (mParent == null)
		{
			if(useLight)
				mWorldLights.update(mLocalLights, null);
			setLightListUpdated();
		}
		else
		{
			if (!mParent.needLightListUpdate())
			{
				if(useLight)
					mWorldLights.update(mLocalLights, mParent.mWorldLights);
				setLightListUpdated();
			}
			else
			{
				#if debug
				Assert.assert(false, "parent need updateWorldLightList");
				#end
			}
		}
	}
	
	
	private function updateMatParamOverrides():Void
	{
		refreshFlags = refreshFlags.remove(RefreshFlag.RF_MATPARAM_OVERRIDE);

        worldOverrides.length = 0;
        if (parent == null)
		{
			for (i in 0...localOverrides.length)
			{
				if (worldOverrides.indexOf(localOverrides[i]) == -1)
				{
					worldOverrides.push(localOverrides[i]);
				}
			}
        } 
		else 
		{
			#if debug
			Assert.assert(!parent.refreshFlags.contains(RefreshFlag.RF_MATPARAM_OVERRIDE), "aaaaaaaaaaa");
			#end
			
			for (i in 0...parent.worldOverrides.length)
			{
				if (worldOverrides.indexOf(parent.worldOverrides[i]) == -1)
				{
					worldOverrides.push(parent.worldOverrides[i]);
				}
			}
			
			for (i in 0...localOverrides.length)
			{
				if (worldOverrides.indexOf(localOverrides[i]) == -1)
				{
					worldOverrides.push(localOverrides[i]);
				}
			}
        }
    }

    /**
     * Adds a local material parameter override.
     *
     * @param override The override to add.
     * @see `MatParamOverride`
     */
    public function addMatParamOverride(matOverride:MatParamOverride):Void
	{
        if (matOverride == null) {
            throw ("matOverride cannot be null");
        }
		
		if (localOverrides.indexOf(matOverride) == -1)
		{
			localOverrides.push(matOverride);
			setMatParamOverrideRefresh();
		}
    }

    /**
     * Remove a local material parameter override if it exists.
     *
     * @param override The override to remove.
     * @see `MatParamOverride`
     */
    public function removeMatParamOverride(matOverride:MatParamOverride):Void
	{
		var index:Int = localOverrides.indexOf(matOverride);
		if (index != -1)
		{
			localOverrides.splice(index, 1);
			setMatParamOverrideRefresh();
		}
    }

    /**
     * Remove all local material parameter overrides.
     *
     * @see `addMatParamOverride`
     */
    public function clearMatParamOverrides():Void
	{
        if (localOverrides.length != 0) 
		{
            setMatParamOverrideRefresh();
			localOverrides.length = 0;
        }
    }
	
	private function setMatParamOverrideRefresh():Void
	{
		refreshFlags = refreshFlags.add(RefreshFlag.RF_MATPARAM_OVERRIDE);

        var p:Spatial = parent;
        while (p != null)
		{
			if (p.refreshFlags.contains(RefreshFlag.RF_MATPARAM_OVERRIDE))
			{
				return;
			}
			
			p.refreshFlags = p.refreshFlags.add(RefreshFlag.RF_MATPARAM_OVERRIDE);
            p = p.parent;
        }
    }

	/**
	 * Should only be called from `updateGeometricState()`.
	 * In most cases should not be subclassed.
	 */
	private function updateWorldTransforms():Void
	{
		if (mParent == null)
		{
			mWorldTransform.copyFrom(mLocalTransform);
			setTransformUpdated();
		}
		else
		{
			#if debug
			// check if transform for parent is updated
			Assert.assert(!parent.needTransformUpdate(), "parent transform sould already updated");
			#end

			mWorldTransform.copyFrom(mLocalTransform);
			mWorldTransform.combineWithParent(mParent.mWorldTransform);
			setTransformUpdated();
		}
	}

	private static var stackList:Vector<Spatial> = new Vector<Spatial>();
	/**
	 * Computes the world transform of this Spatial in the most
	 * efficient manner possible.
	 */
	public function checkDoTransformUpdate():Void
	{
		if (!needTransformUpdate())
		{
			return;
		}

		if (mParent == null)
		{
			mWorldTransform.copyFrom(mLocalTransform);
			setTransformUpdated();
		}
		else
		{
			var rootNode:Spatial = this;
			var i:Int = 0;
			while (true)
			{
				var hisParent:Spatial = rootNode.parent;
				if (hisParent == null)
				{
					rootNode.mWorldTransform.copyFrom(rootNode.mLocalTransform);
					rootNode.setTransformUpdated();
					i--;
					break;
				}

				stackList[i] = rootNode;

				if (!hisParent.needTransformUpdate())
				{
					break;
				}

				rootNode = hisParent;
				i++;
			}
			
			var j:Int = i;
			while (j >= 0)
			{
				stackList[j].updateWorldTransforms();
				j--;
			}
		}
	}

	/**
	 * Computes this Spatial's world bounding volume in the most efficient
	 * manner possible.
	 */
	public function checkDoBoundUpdate():Void
	{
		if (!needBoundUpdate())
		{
			return;
		}

		checkDoTransformUpdate();

		// Go to children recursively and update their bound
		if (Std.is(this,Node))
		{
			var node:Node = cast this;
			for (i in 0...node.numChildren)
			{
				var child:Spatial = node.getChildAt(i);
				child.checkDoBoundUpdate();
			}
		}

		// All children's bounds have been updated. Update my own now.
		updateWorldBound();
	}

	/**
	 * Called when the Spatial is about to be rendered, to notify
	 * controls attached to this Spatial using the `org.angle3d.scene.control.Control.render()` method.
	 *
	 * @param rm The RenderManager rendering the Spatial.
	 * @param vp The ViewPort to which the Spatial is being rendered to.
	 *
	 */
	public function runControlRender(rm:RenderManager, vp:ViewPort):Void
	{
		if (mNumControl == 0)
			return;
			
		for (i in 0...mNumControl)
		{
			mControls[i].render(rm, vp);
		}
	}

	/**
	 * Add a control to the list of controls.
	 * @param control The control to add.
	 *
	 */
	public function addControl(control:Control):Void
	{
		var before:Bool = requiresUpdates();
		
		if (!mControls.contain(control))
		{
			mControls.push(control);
			mNumControl++;
			control.setSpatial(this);
		}
		
		var after:Bool = requiresUpdates();
		
		// If the requirement to be updated has changed
        // then we need to let the parent node know so it
        // can rebuild its update list.
        if ( parent != null && before != after ) 
		{
            parent.invalidateUpdateList();   
        }
	}

	/**
	 * Removes the given control from this spatial's controls.
	 *
	 * @param control The control to remove
	 * @return True if the control was successfuly removed. False if
	 * the control is not assigned to this spatial.
	 *
	 */
	public function removeControl(control:Control):Bool
	{
		var before:Bool = requiresUpdates();
		
		var result:Bool = mControls.remove(control);
		if (result)
		{
			mNumControl--;
			control.setSpatial(null);
		}
		
		var after:Bool = requiresUpdates();
		
		// If the requirement to be updated has changed
        // then we need to let the parent node know so it
        // can rebuild its update list.
        if ( parent != null && before != after ) 
		{
            parent.invalidateUpdateList();   
        }
		
		return result;
	}
	
	/**
	 * Removes all control that is an instance of the given class.
	 * @param cls
	 */
	public function removeControlByClass(cls:Class<Control>):Void
	{
		var before:Bool = requiresUpdates();
		
		var i:Int = 0;
		while (i < mNumControl)
		{
			if (Std.is(mControls[i], cls))
			{
				var control:Control = mControls[i];
				control.setSpatial(null);
				mControls.splice(i, 1);
				mNumControl--;
				i--;
			}
			i++;
		}
		
		var after:Bool = requiresUpdates();
		
		// If the requirement to be updated has changed
        // then we need to let the parent node know so it
        // can rebuild its update list.
        if ( parent != null && before != after ) 
		{
            parent.invalidateUpdateList();   
        }
	}

	/**
	 * Returns the control at the given index in the list.
	 *
	 * @param index The index of the control in the list to find.
	 * @return The control at the given index.
	 *
	 */
	public inline function getControlAt(index:Int):Control
	{
		return mControls[index];
	}

	public function getControl<T>(cls:Class<T>):T
	{
		for (control in mControls)
		{
			if (Std.is(control,cls))
			{
				return cast control;
			}
		}
		return null;
	}

	public function updateLogicalState(tpf:Float):Void
	{
		if (mNumControl > 0)
		{
			for (i in 0...mNumControl)
			{
				mControls[i].update(tpf);
			}
		}
	}

	/**
	 * `updateGeometricState` updates the lightlist,
	 * computes the world transforms, and computes the world bounds
	 * for this Spatial.
	 * Calling this when the Spatial is attached to a node
	 * will cause undefined results. User code should only call this
	 * method on Spatials having no parent.
	 *
	 */
	public function updateGeometricState():Void
	{
		if (needLightListUpdate())
		{
			updateWorldLightList();
		}

		// NOTE: Update world transforms first because
		// bound transform depends on them.
		if (needTransformUpdate())
		{
			updateWorldTransforms();
		}

		if (needBoundUpdate())
		{
			updateWorldBound();
		}
		
		if (needMatParamOverrideUpdate())
		{
			updateMatParamOverrides();
		}

		Assert.assert(refreshFlags == RefreshFlag.NONE, "Already update all");
	}

	/**
	 * Convert a vector (in) from this spatials' local coordinate space to world
	 * coordinate space.
	 *
	 * @param in
	 *            vector to read from
	 * @param store
	 *            where to write the result (null to create a new vector)
	 * @return the result (store)
	 */
	public function localToWorld(inVec:Vector3f, result:Vector3f = null):Vector3f
	{
		checkDoTransformUpdate();
		return mWorldTransform.transformVector(inVec, result);
	}

	/**
	 * Convert a vector (in) from world coordinate space to this spatials' local
	 * coordinate space.
	 *
	 * @param in
	 *            vector to read from
	 * @param store
	 *            where to write the result
	 * @return the result (store)
	 */
	public function worldToLocal(inVec:Vector3f, result:Vector3f = null):Vector3f
	{
		checkDoTransformUpdate();
		return mWorldTransform.transformInverseVector(inVec, result);
	}

	/**
	 * `removeFromParent` removes this Spatial from it's parent.
	 *
	 * @return true if it has a parent and performed the remove.
	 */
	public function removeFromParent():Bool
	{
		if (mParent != null)
		{
			mParent.detachChild(this);
			return true;
		}
		return false;
	}

	/**
	 * determines if the provided Node is the parent, or parent's parent, etc. of this Spatial.
	 *
	 * @param ancestor the ancestor object to look for.
	 * @return true if the ancestor is found, false otherwise.
	 */
	public function hasAncestor(ancestor:Node):Bool
	{
		if (mParent == null)
		{
			return false;
		}
		else if (mParent == ancestor)
		{
			return true;
		}
		else
		{
			return mParent.hasAncestor(ancestor);
		}
	}

	/**
	 * `getLocalRotation` retrieves the local rotation of this
	 * node.
	 *
	 * @return the local rotation of this node.
	 */
	public inline function getLocalRotation():Quaternion
	{
		return mLocalTransform.rotation;
	}

	/**
	 * `setLocalRotation` sets the local rotation of this node.
	 *
	 * @param rotation
	 *            the new local rotation.
	 */
	public function setLocalRotationByMatrix3f(rotation:Matrix3f):Void
	{
		mLocalTransform.rotation.fromMatrix3f(rotation);
		setTransformRefresh();
	}

	/**
	 * `setLocalRotation` sets the local rotation of this node,
	 * using a quaterion to build the matrix.
	 *
	 * @param quaternion
	 *            the quaternion that defines the matrix.
	 */
	public function setLocalRotation(quat:Quaternion):Void
	{
		mLocalTransform.setRotation(quat);
		setTransformRefresh();
	}
	
	public function setLocalTranslation(vec:Vector3f):Void
	{
		mLocalTransform.setTranslation(vec);
		setTransformRefresh();
	}

	/**
	 * `getLocalScale` retrieves the local scale of this node.
	 *
	 * @return the local scale of this node.
	 */
	public function getLocalScale():Vector3f
	{
		return mLocalTransform.scale;
	}

	/**
	 * `setLocalScale` sets the local scale of this node.
	 *
	 * @param localScale
	 *            the new local scale, applied to x, y and z
	 */
	public function setLocalScale(localScale:Vector3f):Void
	{
		mLocalTransform.setScale(localScale);
		setTransformRefresh();
	}

	public function setLocalScaleXYZ(x:Float, y:Float, z:Float):Void
	{
		mLocalTransform.setScaleXYZ(x, y, z);
		setTransformRefresh();
	}

	public function setTranslationXYZ(x:Float, y:Float, z:Float):Void
	{
		mLocalTransform.setTranslationXYZ(x, y, z);
		setTransformRefresh();
	}

	/**
	 * `setLocalTransform` sets the local transform of this
	 * spatial.
	 */
	public function setTransform(t:Transform):Void
	{
		mLocalTransform.copyFrom(t);
		setTransformRefresh();
	}

	/**
	 * `getLocalTransform` retrieves the local transform of
	 * this spatial.
	 *
	 * @return the local transform of this spatial.
	 */
	public function getTransform():Transform
	{
		return mLocalTransform;
	}

	/**
	 * Applies the given material to the Spatial, this will propagate the
	 * material down to the geometries in the scene graph.
	 *
	 * @param material The material to set.
	 */
	public function setMaterial(material:Material):Void
	{

	}

	/**
	 * addLight adds the given light to the Spatial; causing
	 * all child Spatials to be effected by it.
	 *
	 * @param light The light to add.
	 */
	public function addLight(light:Light):Void
	{
		mLocalLights.addLight(light);
		setLightListRefresh();
	}

	/**
	 * removeLight removes the given light from the Spatial.
	 *
	 * @param light The light to remove.
	 */
	public function removeLight(light:Light):Void
	{
		mLocalLights.removeLight(light);
		setLightListRefresh();
	}

	/**
	 * Translates the spatial by the given translation vector.
	 *
	 * @return The spatial on which this method is called, e.g `this`.
	 */
	public function move(tx:Float,ty:Float,tz:Float):Spatial
	{
		mLocalTransform.translation.x += tx;
		mLocalTransform.translation.y += ty;
		mLocalTransform.translation.z += tz;
		setTransformRefresh();
		return this;
	}

	/**
	 * Scales the spatial by the given value
	 *
	 * @return The spatial on which this method is called, e.g `this`.
	 */
	public function scale(sc:Vector3f):Spatial
	{
		mLocalTransform.scale.multLocal(sc);
		setTransformRefresh();
		return this;
	}

	/**
	 * Rotates the spatial by the given rotation.
	 *
	 * @return The spatial on which this method is called, e.g `this`.
	 */
	public function rotate(rot:Quaternion):Spatial
	{
		mLocalTransform.rotation.multLocal(rot);
		setTransformRefresh();
		return this;
	}

	/**
	 * Rotates the spatial by the xAngle, yAngle and zAngle angles (in radians),
	 * (aka pitch, yaw, roll) in the local coordinate space.
	 *
	 * @return The spatial on which this method is called, e.g `this`.
	 */
	public function rotateAngles(xAngle:Float, yAngle:Float, zAngle:Float):Spatial
	{
		var tempVars:TempVars = TempVars.getTempVars();
		var q:Quaternion = tempVars.quat1;

		q.fromAngles(xAngle, yAngle, zAngle);
		mLocalTransform.rotation.multLocal(q);
		setTransformRefresh();

		tempVars.release();
		
		return this;
	}

	/**
	 * Centers the spatial in the origin of the world bound.
	 * @return The spatial on which this method is called, e.g `this`.
	 */
	public function center():Spatial
	{
		var worldTrans:Vector3f = getWorldTranslation();
		var absTrans:Vector3f = worldTrans.subtract(worldBound.center);
		setLocalTranslation(absTrans);
		
		return this;
	}

	/**
	 * `updateModelBound` recalculates the bounding object for this
	 * Spatial.
	 */
	public function updateModelBound():Void
	{

	}

	/**
	 * setModelBound sets the bounding object for this Spatial.
	 *
	 * @param modelBound the bounding object for this spatial.
	 */
	public function setModelBound(modelBound:BoundingVolume):Void
	{

	}

	/**
	 * A clone of this Spatial, the scene graph in its entirety
	 * is cloned and can be altered independently of the original scene graph.
	 *
	 * Note that meshes of geometries are not cloned explicitly, they
	 * are shared if static, or specially cloned if animated.
	 *
	 * All controls will be cloned using the `Control.cloneForSpatial` method
	 * on the clone.
	 *
	 */
	public function clone(newName:String, cloneMaterial:Bool = true, result:Spatial = null):Spatial
	{
		if (result == null)
		{
			result = new Spatial(newName);
		}

		if (mWorldBound != null)
		{
			result.mWorldBound = mWorldBound.clone();
		}

		result.mWorldLights = mWorldLights.clone();
		result.mLocalLights = mLocalLights.clone();

		// set the new owner of the light lists
		result.mLocalLights.setOwner(result);
		result.mWorldLights.setOwner(result);

		// No need to force cloned to update.
		// This node already has the refresh flags
		// set below so it will have to update anyway.
		result.mWorldTransform.copyFrom(mWorldTransform);
		result.mLocalTransform.copyFrom(mLocalTransform);
		
		result.mQueueBucket = mQueueBucket;
		result.mShadowMode = mShadowMode;
		result.mCullHint = mCullHint;
		result.mBatchHint = mBatchHint;

		result.parent = null;
		result.setBoundRefresh();
		result.setTransformRefresh();
		result.setLightListRefresh();
		result.setMatParamOverrideRefresh();

		for (i in 0...mNumControl)
		{
			var newControl:Control = mControls[i].cloneForSpatial(result);
			result.addControl(newControl);
		}
		
		if (userData != null)
		{
			result.userData = new FastStringMap<Dynamic>();
			
			var keys = userData.keys();
			for (key in keys)
			{
				result.userData.set(key, userData.get(key));
			}
		}
		
		return result;
	}

	public function setBatchHint(batchHint:BatchHint):Void
	{
		mBatchHint = batchHint;
	}
	
	/**
     * `setCullHint` alters how view frustum culling will treat this
     * spatial.
     *
     * @param hint one of: `CullHint.Auto`、`CullHint.Always`、`CullHint.Inherit`、`CullHint.Never`
     * <p>
     * The effect of the default value (CullHint.Inherit) may change if the
     * spatial gets re-parented.
     */
	public function setCullHint(hint:CullHint):Void
	{
		mCullHint = hint;
	}

	/**
	 * Creates a transform matrix that will convert from this spatials'
	 * local coordinate space to the world coordinate space
	 * based on the world transform.
	 *
	 * @param store Matrix where to store the result, if null, a new one
	 * will be created and returned.
	 *
	 * @return store if not null, otherwise, a new matrix containing the result.
	 */
	public function getLocalToWorldMatrix(result:Matrix4f = null):Matrix4f
	{
		if (result == null)
		{
			result = new Matrix4f();
		}
		else
		{
			result.loadIdentity();
		}

		// multiply with scale first, then rotate, finally translate
		result.scaleVecLocal(getWorldScale());
		result.multQuatLocal(getWorldRotation());
		var wTrans:Vector3f = getWorldTranslation();
		result.setTranslation(wTrans.x, wTrans.y, wTrans.z);
		return result;
	}
	
	public function setUserData(key:String, data:Dynamic):Void
	{
		if (userData == null)
			userData = new FastStringMap<Dynamic>();
			
		if (data == null)
		{
			userData.remove(key);
		}
		else
		{
			userData.set(key, data);
		}
	}
	
	public function getUserData(key:String):Dynamic
	{
		if (userData == null)
			return null;
			
		return userData.get(key);
	}
	
	public function hasUserData(key:String):Bool
	{
		if (userData == null)
			return false;
			
		return userData.exists(key);
	}

	/**
	 * Visit each scene graph element ordered by DFS with the default post order mode.
	 * @param visitor
	 */
	public function depthFirstTraversal(visitor:SceneGraphVisitor):Void
	{
		depthFirstTraversalInternal(visitor, DFSMode.POST_ORDER);
	}
	
	/**
     * Visit each scene graph element ordered by DFS.
     * There are two modes: pre order and post order.
     * @param visitor
     * @param mode the traversal mode: pre order or post order
     */
	private function depthFirstTraversalInternal(visitor:SceneGraphVisitor,mode:DFSMode):Void
	{
	
	}

	/**
	 * Visit each scene graph element ordered by BFS
	 * @param visitor
	 */
	public function breadthFirstTraversal(visitor:SceneGraphVisitor):Void
	{
		var queue:Vector<Spatial> = new Vector<Spatial>();
		queue.push(this);

		while (queue.length != 0) 
		{
			var s:Spatial = queue.shift();
			visitor.visit(s);
			s.breadthFirstTraversalInternal(visitor, queue);
		}
	}
	
	private function breadthFirstTraversalInternal(visitor:SceneGraphVisitor,queue:Vector<Spatial>):Void
	{
	
	}

	public function collideWith(other:Collidable, results:CollisionResults):Int
	{
		return -1;
	}
	
	/**
     * @return The sum of all triangles under this Spatial.
     */
	public function getTriangleCount():Int
	{
		return 0;
	}
	
	/**
     * @return The sum of all vertices under this Spatial.
     */
	public function getVertexCount():Int
	{
		return 0;
	}
	
	/**
     * Sets the level of detail to use when rendering this Spatial,
     * this call propagates to all geometries under this Spatial.
     *
     * @param lod The lod level to set.
     */
	public function setLodLevel(lod:Int):Void
	{
		
	}
	
	public function toString():String
	{
		return name;
	}
	
	public function dispose():Void
	{
		for (i in 0...mNumControl)
		{
			mControls[i].dispose();
		}
		mControls = null;
		mNumControl = 0;
	}
	
	private inline function get_parent():Node
	{
		return mParent;
	}
	
	private function set_parent(value:Node):Node
	{
		return this.mParent = value;
	}
	
	private inline function get_x():Float
	{
		return mLocalTransform.translation.x;
	}
	
	private function set_x(value:Float):Float
	{
		mLocalTransform.translation.x = value;
		setTransformRefresh();
		return value;
	}
	
	private inline function get_y():Float
	{
		return mLocalTransform.translation.y;
	}

	private function set_y(value:Float):Float
	{
		mLocalTransform.translation.y = value;
		setTransformRefresh();
		return value;
	}

	private inline function get_z():Float
	{
		return mLocalTransform.translation.z;
	}
	
	private function set_z(value:Float):Float
	{
		mLocalTransform.translation.z = value;
		setTransformRefresh();
		return value;
	}
	
	private inline function get_scaleX():Float
	{
		return mLocalTransform.scale.x;
	}
	
	private function set_scaleX(value:Float):Float
	{
		mLocalTransform.scale.x = value;
		setTransformRefresh();
		return value;
	}
	
	private inline function get_scaleY():Float
	{
		return mLocalTransform.scale.y;
	}

	private function set_scaleY(value:Float):Float
	{
		mLocalTransform.scale.y = value;
		setTransformRefresh();
		return value;
	}
	
	private inline function get_scaleZ():Float
	{
		return mLocalTransform.scale.z;
	}

	private function set_scaleZ(value:Float):Float
	{
		mLocalTransform.scale.z = value;
		setTransformRefresh();
		return value;
	}

	private function get_localTranslation():Vector3f
	{
		return mLocalTransform.translation;
	}
	
	private function set_localTranslation(localTranslation:Vector3f):Vector3f
	{
		mLocalTransform.setTranslation(localTranslation);
		setTransformRefresh();
		return mLocalTransform.translation;
	}
	
	public function getLocalTranslation():Vector3f
	{
		return mLocalTransform.translation;
	}
	
	private function get_worldTranslation():Vector3f
	{
		checkDoTransformUpdate();
		return mWorldTransform.translation;
	}
	
	private function get_lastFrustumIntersection():FrustumIntersect
	{
		return mFrustrumIntersects;
	}

	private function set_lastFrustumIntersection(intersects:FrustumIntersect):FrustumIntersect
	{
		return mFrustrumIntersects = intersects;
	}
	
	private function get_queueBucket():QueueBucket
	{
		if (mQueueBucket != QueueBucket.Inherit)
		{
			return mQueueBucket;
		}
		else if (parent != null)
		{
			return parent.queueBucket;
		}
		else
		{
			return QueueBucket.Opaque;
		}
	}

	
	private function get_shadowMode():ShadowMode
	{
		if (mShadowMode != ShadowMode.Inherit)
		{
			return mShadowMode;
		}
		else if (parent != null)
		{
			return parent.shadowMode;
		}
		else
		{
			return ShadowMode.Off;
		}
	}
	
	private function get_batchHint():BatchHint
	{
		if (mBatchHint != BatchHint.Inherit)
		{
			return mBatchHint;
		}
		else if (mParent != null)
		{
			return mParent.batchHint;
		}
		else 
		{
			return BatchHint.Always;
		}
	}
	
	private function set_visible(value:Bool):Bool
	{
		return this.visible = value;
	}

	private function get_truelyVisible():Bool
	{
		if (this.parent == null)
			return this.visible;

		return visible && this.parent.visible;
	}
	
	private inline function get_worldBound():BoundingVolume
	{
		checkDoBoundUpdate();
		return mWorldBound;
	}

	private function set_localCullHint(hint:CullHint):CullHint
	{
		return mCullHint = hint;
	}
	
	private function get_localCullHint():CullHint
	{
		return mCullHint;
	}

	private function get_cullHint():CullHint
	{
		if (mCullHint != CullHint.Inherit)
		{
			return mCullHint;
		}
		else if (mParent != null)
		{
			return mParent.cullHint;
		}
		else
		{
			return CullHint.Auto;
		}
	}

	private inline function get_localQueueBucket():QueueBucket
	{
		return mQueueBucket;
	}
	
	private inline function set_localQueueBucket(queueBucket:QueueBucket):QueueBucket
	{
		return mQueueBucket = queueBucket;
	}
	
	private function get_localShadowMode():ShadowMode
	{
		return mShadowMode;
	}
	
	private function set_localShadowMode(shadowMode:ShadowMode):ShadowMode
	{
		return mShadowMode = shadowMode;
	}
	
	public function setShadowMode(shadowMode:ShadowMode):Void
	{
		mShadowMode = shadowMode;
	}

	private function get_localBatchHint():BatchHint
	{
		return mBatchHint;
	}
	
	private function set_localBatchHint(batchHint:BatchHint):BatchHint
	{
		return mBatchHint = batchHint;
	}
	
	private inline function get_numControls():Int
	{
		return mNumControl;
	}
}

