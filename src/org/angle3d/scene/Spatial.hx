package org.angle3d.scene;

import flash.Vector;
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
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.control.Control;
import org.angle3d.utils.Assert;
import org.angle3d.utils.Cloneable;
import org.angle3d.utils.TempVars;
using org.angle3d.math.VectorUtil;

//TODO API 优化
//TODO 还需要添加更多常用属性
//例如：是否可拾取，是否显示鼠标
/**
 * Spatial defines the base class for scene graph nodes. It
 * maintains a link to a parent, it's local transforms and the world's
 * transforms. All other nodes, such as Node and
 * Geometry are subclasses of Spatial.
 * @author andy
 */
class Spatial implements Cloneable implements Collidable
{
	/**
	 * Refresh flag types
	 */
	public static inline var RF_TRANSFORM:Int = 0x01;
	public static inline var RF_BOUND:Int = 0x02;
	public static inline var RF_LIGHTLIST:Int = 0x04;

	public var x(get, set):Float;
	public var y(get, set):Float;
	public var z(get, set):Float;
	
	public var translation(get, set):Vector3f;
	
	public var scaleX(get, set):Float;
	public var scaleY(get, set):Float;
	public var scaleZ(get, set):Float;
	
	//TODO 添加修改旋转的属性
	
	/**
	 * @return The number of controls attached to this Spatial.
	 */
	public var numControls(get, null):Int;
	
	/**
	 * Refresh flags. Indicate what data of the spatial need to be
	 * updated to reflect the correct state.
	 */
	public var refreshFlags(get, null):Int;
	
	/**
	 * Spatial's parent, or null if it has none.
	 */
	public var parent(default, set):Node;
	
	public var visible(default, set):Bool;
	public var truelyVisible(get, null):Bool;
	
	
	public var queueBucket(get, null):QueueBucket;
	public var shadowMode(get, null):ShadowMode;
	public var worldBound(get, null):BoundingVolume;
	
	public var localCullHint(get, set):CullHint;
	public var localQueueBucket(get, set):QueueBucket;
	public var localShadowMode(get, set):ShadowMode;
	public var cullHint(get, null):CullHint;
	
	public var lastFrustumIntersection(get, set):FrustumIntersect;
	
	/**
	 * This spatial's name.
	 */
	public var name:String;

	public var queueDistance:Float;

	/**
	 * Spatial's bounding volume relative to the world.
	 */
	private var mWorldBound:BoundingVolume;

	/**
	 * LightList
	 */
	private var mLocalLights:LightList;
	private var mWorldLights:LightList;

	private var mCullHint:CullHint;

	private var mFrustrumIntersects:FrustumIntersect;
	private var mQueueBucket:QueueBucket;
	private var mShadowMode:ShadowMode;


	private var mLocalTransform:Transform;
	private var mWorldTransform:Transform;

	private var mControls:Vector<Control>;

	private var mRefreshFlags:Int;

	/**
	 * Constructor instantiates a new <code>Spatial</code> object setting the
	 * rotation, translation and scale value to defaults.
	 *
	 * @param name
	 *            the name of the scene element. This is required for
	 *            identification and comparision purposes.
	 */
	public function new(name:String = "")
	{
		this.name = name;
		initialize();
	}
	
	private function set_visible(value:Bool):Bool
	{
		return this.visible = value;
	}

	/**
	 * 是否真正可见
	 * 自身可能是可见的，但是parent是不可见，所以还是不可见的
	 */
	private function get_truelyVisible():Bool
	{
		if (this.parent == null)
			return this.visible;

		return visible && this.parent.visible;
	}

	private function initialize():Void
	{
		mLocalTransform = new Transform();
		mWorldTransform = new Transform();

		mLocalLights = new LightList(this);
		mWorldLights = new LightList(this);

		mWorldBound = new BoundingBox();

		mRefreshFlags = 0;
		mRefreshFlags |= RF_BOUND;

		mCullHint = CullHint.Inherit;
		mFrustrumIntersects = FrustumIntersect.Intersects;
		mQueueBucket = QueueBucket.Inherit;
		mShadowMode = ShadowMode.Inherit;

		visible = true;

		queueDistance = Math.NEGATIVE_INFINITY;

		mControls = new Vector<Control>();
	}

	/**
	 * 是否需要更新LightList
	 * @return
	 */
	public inline function needLightListUpdate():Bool
	{
		return (mRefreshFlags & RF_LIGHTLIST) != 0;
	}

	/**
	 * 是否需要更新坐标
	 * @return
	 */
	public inline function needTransformUpdate():Bool
	{
		return (mRefreshFlags & RF_TRANSFORM) != 0;
	}

	/**
	 * 是否需要更新包围体
	 * @return
	 */
	public inline function needBoundUpdate():Bool
	{
		return (mRefreshFlags & RF_BOUND) != 0;
	}

	/**
	 * Indicate that the transform of this spatial has changed and that
	 * a refresh is required.
	 */
	public function setTransformRefresh():Void
	{
		mRefreshFlags |= RF_TRANSFORM;
		setBoundRefresh();
	}

	public inline function setTransformUpdated():Void
	{
		mRefreshFlags &= ~RF_TRANSFORM;
	}

	public function setLightListRefresh():Void
	{
		mRefreshFlags |= RF_LIGHTLIST;
	}

	public inline function setLightListUpdated():Void
	{
		mRefreshFlags &= ~RF_LIGHTLIST;
	}

	/**
	 * Indicate that the bounding of this spatial has changed and that
	 * a refresh is required.
	 */
	public function setBoundRefresh():Void
	{
		mRefreshFlags |= RF_BOUND;

		var p:Spatial = parent;
		while (p != null)
		{
			if (p.needBoundUpdate())
			{
				return;
			}

			p.mRefreshFlags |= RF_BOUND;
			p = p.parent;
		}
	}

	public inline function setBoundUpdated():Void
	{
		mRefreshFlags &= ~RF_BOUND;
	}

	/**
	 * (Internal use only) Forces a refresh of the given types of data.
	 *
	 * @param transforms Refresh world transform based on parents'
	 * @param bounds Refresh bounding volume data based on child nodes
	 * @param lights Refresh light list based on parents'
	 */
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
	 * <code>checkCulling</code> checks the spatial with the camera to see if it
	 * should be culled.
	 * <p>
	 * This method is called by the renderer. Usually it should not be called
	 * directly.
	 *
	 * @param cam The camera to check against.
	 * @return true if inside or intersecting camera frustum
	 * (should be rendered), false if outside.
	 */
	public function checkCulling(cam:Camera):Bool
	{
		Assert.assert(mRefreshFlags == 0, "Scene graph is not properly updated for rendering.\n" + 
					"Make sure scene graph state was not changed after\n" + 
					" rootNode.updateGeometricState() call. \n" +
					"Problem spatial name: " + name);

		var cm:CullHint = cullHint;

		Assert.assert(cm != CullHint.Inherit, "getCullHint() is not CullHint.Inherit");

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
		mFrustrumIntersects = (parent != null) ? parent.lastFrustumIntersection : FrustumIntersect.Intersects;

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
	 * Returns the local {@link LightList}, which are the lights
	 * that were directly attached to this <code>Spatial</code> through the
	 * {@link #addLight(org.angle3d.light.Light) } and
	 * {@link #removeLight(org.angle3d.light.Light) } methods.
	 *
	 * @return The local light list
	 */
	public function getLocalLightList():LightList
	{
		return mLocalLights;
	}

	/**
	 * Returns the world {@link LightList}, containing the lights
	 * combined from all this <code>Spatial's</code> parents up to and including
	 * this <code>Spatial</code>'s lights.
	 *
	 * @return The combined world light list
	 */
	public function getWorldLightList():LightList
	{
		return mWorldLights;
	}

	/**
	 * <code>getWorldRotation</code> retrieves the absolute rotation of the
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
	* <code>getWorldTranslation</code> retrieves the absolute translation of
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
	 * <code>getWorldScale</code> retrieves the absolute scale factor of the
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
	* <code>getWorldTransform</code> retrieves the world transformation
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
	 * <code>rotateUpTo</code> is a util function that alters the
	 * localrotation to point the Y axis in the direction given by newUp.
	 *
	 * @param newUp
	 *            the up vector to use - assumed to be a unit vector.
	 */
	public function rotateUpTo(newUp:Vector3f):Void
	{
		// First figure out the current up vector.
		var upY:Vector3f = new Vector3f(0, 1, 0);
		var rot:Quaternion = mLocalTransform.rotation;
		rot.multVecLocal(upY);

		// get_angle between vectors
		var angle:Float = upY.angleBetween(newUp);

		// figure out rotation axis by taking cross product
		upY.crossLocal(newUp);
		var rotAxis:Vector3f = upY;
		rotAxis.normalizeLocal();

		// Build a rotation quat and apply current local rotation.
		var q:Quaternion = new Quaternion();
		q.fromAngleAxis(angle, rotAxis);
		q.multiply(rot, rot);

		setTransformRefresh();
	}

	/**
	 * <code>lookAt</code> is a convienence method for auto-setting the local
	 * rotation based on a position and an up vector. It computes the rotation
	 * to transform the z-axis to point onto 'position' and the y-axis to 'up'.
	 * Unlike {@link Quaternion#lookAt} this method takes a world position to
	 * look at not a relative direction.
	 *
	 * @param position
	 *            where to look at in terms of world coordinates
	 * @param upVector
	 *            a vector indicating the (local) up direction. (typically {0,
	 *            1, 0} in jME.)
	 */
	public function lookAt(position:Vector3f, upVector:Vector3f):Void
	{
		var worldTranslation:Vector3f = getWorldTranslation();

		var dir:Vector3f = position.subtract(worldTranslation);
		getRotation().lookAt(dir, upVector);

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
		mRefreshFlags &= ~RF_BOUND;
	}

	private function updateWorldLightList():Void
	{
		if (parent == null)
		{
			mWorldLights.update(mLocalLights, null);
			setLightListUpdated();
		}
		else
		{
			if (!parent.needLightListUpdate())
			{
				mWorldLights.update(mLocalLights, parent.getWorldLightList());
				setLightListUpdated();
			}
			else
			{
				Assert.assert(false, "updateWorldLightList");
			}
		}
	}

	/**
	 * Should only be called from updateGeometricState().
	 * In most cases should not be subclassed.
	 */
	private function updateWorldTransforms():Void
	{
		if (parent == null)
		{
			mWorldTransform.copyFrom(mLocalTransform);
			setTransformUpdated();
		}
		else
		{
			// check if transform for parent is updated
			Assert.assert(!parent.needTransformUpdate(), "parent transform sould already updated");

			mWorldTransform.copyFrom(mLocalTransform);
			mWorldTransform.combineWithParent(parent.getWorldTransform());
			setTransformUpdated();
		}
	}

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

		if (parent == null)
		{
			mWorldTransform.copyFrom(mLocalTransform);
			setTransformUpdated();
		}
		else
		{
			//TODO 此处未完全理解
			var stack:Array<Spatial> = [];
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

				stack[i] = rootNode;

				if (!hisParent.needTransformUpdate())
				{
					break;
				}

				rootNode = hisParent;
				i++;
			}

			while (i >= 0)
			{
				rootNode = stack[i];
				//rootNode.worldTransform.set(rootNode.localTransform);
				//rootNode.worldTransform.combineWithParent(rootNode.parent.worldTransform);
				//rootNode.setTransformUpdated();
				rootNode.updateWorldTransforms();
				i--;
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
			var node:Node = Std.instance(this, Node);
			var length:Int = node.numChildren;
			for (i in 0...length)
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
	 * controls attached to this Spatial using the Control.render() method.
	 *
	 * @param rm The RenderManager rendering the Spatial.
	 * @param vp The ViewPort to which the Spatial is being rendered to.
	 *
	 * @see Spatial#addControl(org.angle3d.scene.control.Control)
	 * @see Spatial#getControl(java.lang.Class)
	 */
	public function runControlRender(rm:RenderManager, vp:ViewPort):Void
	{
		for (control in mControls)
		{
			control.render(rm, vp);
		}
	}

	/**
	 * Add a control to the list of controls.
	 * @param control The control to add.
	 *
	 * @see Spatial#removeControl()
	 */
	public function addControl(control:Control):Void
	{
		if (!mControls.contain(control))
		{
			control.spatial = this;
			mControls.push(control);
		}
	}

	/**
	 * Removes the given control from this spatial's controls.
	 *
	 * @param control The control to remove
	 * @return True if the control was successfuly removed. False if
	 * the control is not assigned to this spatial.
	 *
	 * @see Spatial#addControl(org.angle3d.scene.control.Control)
	 */
	public function removeControl(control:Control):Bool
	{
		if (mControls.remove(control))
		{
			control.spatial = null;
			return true;
		}
		return false;
	}

	/**
	 * Returns the control at the given index in the list.
	 *
	 * @param index The index of the control in the list to find.
	 * @return The control at the given index.
	 *
	 * @see Spatial#addControl(org.angle3d.scene.control.Control)
	 */
	public function getControl(index:Int):Control
	{
		return mControls[index];
	}

	public function getControlByClass(cls:Class<Control>):Control
	{
		for (control in mControls)
		{
			if (Std.is(control,cls))
			{
				return control;
			}
		}
		return null;
	}

	private function get_numControls():Int
	{
		return mControls.length;
	}

	private function get_refreshFlags():Int
	{
		return mRefreshFlags;
	}

	public function update(tpf:Float):Void
	{
		updateControls(tpf);
		updateGeometricState();
	}

	/**
	 * calls the <code>update()</code> method
	 * for all controls attached to this Spatial.
	 *
	 * @param tpf 每帧运行时间，以秒为单位
	 *
	 * @see Spatial#addControl(org.angle3d.scene.control.Control)
	 */
	public function updateControls(tpf:Float):Void
	{
		for (control in mControls)
		{
			control.update(tpf);
		}
	}

	/**
	 * <code>updateGeometricState</code> updates the lightlist,
	 * computes the world transforms, and computes the world bounds
	 * for this Spatial.
	 * Calling this when the Spatial is attached to a node
	 * will cause undefined results. User code should only call this
	 * method on Spatials having no parent.
	 *
	 * @see Spatial#getWorldLightList()
	 * @see Spatial#getWorldTransform()
	 * @see Spatial#getWorldBound()
	 */
	public function updateGeometricState():Void
	{
		// assume that this Spatial is a leaf, a proper implementation
		// for this method should be provided by Node.

		// NOTE: Update world transforms first because
		// bound transform depends on them.
		if (needLightListUpdate())
		{
			updateWorldLightList();
		}

		if (needTransformUpdate())
		{
			updateWorldTransforms();
		}

		if (needBoundUpdate())
		{
			updateWorldBound();
		}

		Assert.assert(mRefreshFlags == 0, "Already update all");
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
	 * Called by {@link Node#attachChild(Spatial)} and
	 * {@link Node#detachChild(Spatial)} - don't call directly.
	 * <code>setParent</code> sets the parent of this node.
	 *
	 * @param parent
	 *            the parent of this node.
	 */
	private inline function set_parent(parent:Node):Node
	{
		return this.parent = parent;
	}

	/**
	 * <code>removeFromParent</code> removes this Spatial from it's parent.
	 *
	 * @return true if it has a parent and performed the remove.
	 */
	public function removeFromParent():Bool
	{
		if (parent != null)
		{
			parent.detachChild(this);
			return true;
		}
		return false;
	}

	/**
	 * determines if the provided Node is the parent, or parent's parent, etc. of this Spatial.
	 *
	 * @param ancestor
	 *            the ancestor object to look for.
	 * @return true if the ancestor is found, false otherwise.
	 */
	public function hasAncestor(ancestor:Node):Bool
	{
		if (parent == null)
		{
			return false;
		}
		else if (parent == ancestor)
		{
			return true;
		}
		else
		{
			return parent.hasAncestor(ancestor);
		}
	}

	/**
	 * <code>getLocalRotation</code> retrieves the local rotation of this
	 * node.
	 *
	 * @return the local rotation of this node.
	 */
	public function getRotation():Quaternion
	{
		return mLocalTransform.rotation;
	}

	/**
	 * <code>setLocalRotation</code> sets the local rotation of this node.
	 *
	 * @param rotation
	 *            the new local rotation.
	 */
	public function setRotationByMatrix3f(rotation:Matrix3f):Void
	{
		mLocalTransform.rotation.fromMatrix3f(rotation);
		setTransformRefresh();
	}

	
	public function setTranslation(vec:Vector3f):Void
	{
		mLocalTransform.setTranslation(vec);
		setTransformRefresh();
	}

	/**
	 * <code>setLocalRotation</code> sets the local rotation of this node,
	 * using a quaterion to build the matrix.
	 *
	 * @param quaternion
	 *            the quaternion that defines the matrix.
	 */
	public function setRotation(quat:Quaternion):Void
	{
		mLocalTransform.setRotation(quat);
		setTransformRefresh();
	}

	/**
	 * <code>getLocalScale</code> retrieves the local scale of this node.
	 *
	 * @return the local scale of this node.
	 */
	public function getScale():Vector3f
	{
		return mLocalTransform.scale;
	}

	/**
	 * <code>setLocalScale</code> sets the local scale of this node.
	 *
	 * @param localScale
	 *            the new local scale, applied to x, y and z
	 */
	public function setScale(localScale:Vector3f):Void
	{
		mLocalTransform.setScale(localScale);
		setTransformRefresh();
	}

	public function setScaleXYZ(x:Float, y:Float, z:Float):Void
	{
		mLocalTransform.setScaleXYZ(x, y, z);
		setTransformRefresh();
	}

	
	private function get_scaleX():Float
	{
		return mLocalTransform.scale.x;
	}
	
	private function set_scaleX(value:Float):Float
	{
		mLocalTransform.scale.x = value;
		setTransformRefresh();
		return value;
	}
	
	private function get_scaleY():Float
	{
		return mLocalTransform.scale.y;
	}

	private function set_scaleY(value:Float):Float
	{
		mLocalTransform.scale.y = value;
		setTransformRefresh();
		return value;
	}
	
	private function get_scaleZ():Float
	{
		return mLocalTransform.scale.z;
	}

	private function set_scaleZ(value:Float):Float
	{
		mLocalTransform.scale.z = value;
		setTransformRefresh();
		return value;
	}

	/**
	 * the local translation of this node.
	 */
	
	private function get_translation():Vector3f
	{
		return mLocalTransform.translation;
	}
	
	private function set_translation(localTranslation:Vector3f):Vector3f
	{
		mLocalTransform.setTranslation(localTranslation);
		setTransformRefresh();
		return mLocalTransform.translation;
	}
	

	public function setTranslationXYZ(x:Float, y:Float, z:Float):Void
	{
		mLocalTransform.setTranslationXYZ(x, y, z);
		setTransformRefresh();
	}
	
	private function get_x():Float
	{
		return mLocalTransform.translation.x;
	}
	
	private function set_x(value:Float):Float
	{
		mLocalTransform.translation.x = value;
		setTransformRefresh();
		return value;
	}
	
	private function get_y():Float
	{
		return mLocalTransform.translation.y;
	}

	private function set_y(value:Float):Float
	{
		mLocalTransform.translation.y = value;
		setTransformRefresh();
		return value;
	}

	private function get_z():Float
	{
		return mLocalTransform.translation.z;
	}
	
	private function set_z(value:Float):Float
	{
		mLocalTransform.translation.z = value;
		setTransformRefresh();
		return value;
	}

	/**
	 * <code>setLocalTransform</code> sets the local transform of this
	 * spatial.
	 */
	public function setTransform(t:Transform):Void
	{
		mLocalTransform.copyFrom(t);
		setTransformRefresh();
	}

	/**
	 * <code>getLocalTransform</code> retrieves the local transform of
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
	 * <code>addLight</code> adds the given light to the Spatial; causing
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
	 * <code>removeLight</code> removes the given light from the Spatial.
	 *
	 * @param light The light to remove.
	 * @see Spatial#addLight(org.angle3d.light.Light)
	 */
	public function removeLight(light:Light):Void
	{
		mLocalLights.removeLight(light);
		setLightListRefresh();
	}

	/**
	 * Translates the spatial by the given translation vector.
	 *
	 * @return The spatial on which this method is called, e.g <code>this</code>.
	 */
	public function move(offset:Vector3f):Void
	{
		mLocalTransform.translation.addLocal(offset);
		setTransformRefresh();
	}

	/**
	 * Scales the spatial by the given value
	 *
	 * @return The spatial on which this method is called, e.g <code>this</code>.
	 */
	public function scale(sc:Vector3f):Void
	{
		mLocalTransform.scale.multiplyLocal(sc);
		setTransformRefresh();
	}

	/**
	 * Rotates the spatial by the given rotation.
	 *
	 * @return The spatial on which this method is called, e.g <code>this</code>.
	 */
	public function rotate(rot:Quaternion):Void
	{
		mLocalTransform.rotation.multiplyLocal(rot);
		setTransformRefresh();
	}

	/**
	 * Rotates the spatial by the xAngle, yAngle and zAngle angles (in radians),
	 * (aka pitch, yaw, roll) in the local coordinate space.
	 *
	 * @return The spatial on which this method is called, e.g <code>this</code>.
	 */
	public function rotateAngles(xAngle:Float, yAngle:Float, zAngle:Float):Void
	{
		var tempVars:TempVars = TempVars.getTempVars();
		var q:Quaternion = tempVars.quat1;

		q.fromAngles(xAngle, yAngle, zAngle);
		mLocalTransform.rotation.multiplyLocal(q);
		setTransformRefresh();

		tempVars.release();
	}

	/**
	 * Centers the spatial in the origin of the world bound.
	 * @return The spatial on which this method is called, e.g <code>this</code>.
	 */
	public function center():Spatial
	{
		var worldTrans:Vector3f = getWorldTranslation();
		var absTrans:Vector3f = worldTrans.subtract(worldBound.center);
		translation = absTrans;
		return this;
	}

	/**
	 * Returns this spatial's renderqueue bucket. If the mode is set_to inherit,
	 * then the spatial gets its renderqueue bucket from its parent.
	 *
	 * @return The spatial's current renderqueue mode.
	 */
	
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

	/**
	 * @return The shadow mode of this spatial, if the local shadow
	 * mode is set_to inherit, then the parent's shadow mode is returned.
	 *
	 * @see Spatial#setShadowMode(org.angle3d.renderer.queue.RenderQueue.ShadowMode)
	 * @see ShadowMode
	 */
	
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

	/**
	 * <code>updateModelBound</code> recalculates the bounding object for this
	 * Spatial.
	 */
	public function updateModelBound():Void
	{

	}

	/**
	 * <code>setModelBound</code> sets the bounding object for this Spatial.
	 *
	 * @param modelBound
	 *            the bounding object for this spatial.
	 */
	public function setBound(modelBound:BoundingVolume):Void
	{

	}

	/**
	 * @return A clone of this Spatial, the scene graph in its entirety
	 * is cloned and can be altered independently of the original scene graph.
	 *
	 * Note that meshes of geometries are not cloned explicitly, they
	 * are shared if static, or specially cloned if animated.
	 *
	 * All controls will be cloned using the Control.cloneForSpatial method
	 * on the clone.
	 *
	 * @see Mesh#cloneForAnim()
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

		// set_the new owner of the light lists
		result.mLocalLights.setOwner(result);
		result.mWorldLights.setOwner(result);

		// No need to force cloned to update.
		// This node already has the refresh flags
		// set_below so it will have to update anyway.
		result.mWorldTransform.copyFrom(mWorldTransform);
		result.mLocalTransform.copyFrom(mLocalTransform);

		result.parent = null;
		result.setBoundRefresh();
		result.setTransformRefresh();
		result.setLightListRefresh();

		var length:Int = mControls.length;
		for (i in 0...length)
		{
			result.mControls.push(mControls[i].cloneForSpatial(result));
		}
		return result;
	}

	
	private function get_worldBound():BoundingVolume
	{
		checkDoBoundUpdate();
		return mWorldBound;
	}

	/**
     * localCullHint alters how view frustum culling will treat this
     * spatial.
     *
     * @param hint one of: CullHint.Auto,CullHint.Always, CullHint.Inherit, or CullHint.Never
     * <p>
     * The effect of the default value (CullHint.Inherit) may change if the
     * spatial gets re-parented.
     */
	private function set_localCullHint(hint:CullHint):CullHint
	{
		return mCullHint = hint;
	}

	/**
	 * @return the cullmode set_on this Spatial
	 */
	private function get_localCullHint():CullHint
	{
		return mCullHint;
	}

	/**
	 * @see #setCullHint(CullHint)
	 * @return the cull mode of this spatial, or if set_to CullHint.Inherit,
	 * the cullmode of it's parent.
	 */
	
	private function get_cullHint():CullHint
	{
		if (mCullHint != CullHint.Inherit)
		{
			return mCullHint;
		}
		else if (parent != null)
		{
			return parent.cullHint;
		}
		else
		{
			return CullHint.Auto;
		}
	}

	/**
	 * [localQueueBucket] determines at what phase of the
	 * rendering process this Spatial will rendered. See the
	 * Bucket enum for an explanation of the various
	 * render queue buckets.
	 *
	 */
	
	/**
	 * @return The locally set_queue bucket mode
	 *
	 * @see Spatial#setQueueBucket(org.angle3d.renderer.queue.RenderQueue.Bucket)
	 */
	private function get_localQueueBucket():QueueBucket
	{
		return mQueueBucket;
	}
	
	private function set_localQueueBucket(queueBucket:QueueBucket):QueueBucket
	{
		return mQueueBucket = queueBucket;
	}

	

	/**
	 * Sets the shadow mode of the spatial
	 * The shadow mode determines how the spatial should be shadowed,
	 * when a shadowing technique is used. See the
	 * documentation for the class ShadowMode for more information.
	 *
	 */
	
	/**
	 * @return The locally set_shadow mode
	 *
	 * @see Spatial#setShadowMode(org.angle3d.renderer.queue.RenderQueue.ShadowMode)
	 */
	private function get_localShadowMode():ShadowMode
	{
		return mShadowMode;
	}
	
	private function set_localShadowMode(shadowMode:ShadowMode):ShadowMode
	{
		return mShadowMode = shadowMode;
	}

	

	/**
	 * Returns this spatial's last frustum intersection result. This int is set
	 * when a check is made to determine if the bounds of the object fall inside
	 * a camera's frustum. If a parent is found to fall outside the frustum, the
	 * value for this spatial will not be updated.
	 *
	 * @return The spatial's last frustum intersection result.
	 */
	
	private function get_lastFrustumIntersection():FrustumIntersect
	{
		return mFrustrumIntersects;
	}

	/**
	 * Overrides the last intersection result. This is useful for operations
	 * that want to start rendering at the middle of a scene tree and don't want
	 * the parent of that node to influence culling. (See texture renderer code
	 * for example.)
	 *
	 * @param intersects
	 *            the new value
	 */
	private function set_lastFrustumIntersection(intersects:FrustumIntersect):FrustumIntersect
	{
		return mFrustrumIntersects = intersects;
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
	 *
	 * @see Spatial#getWorldTransform()
	 */
	public function getLocalToWorldMatrix(result:Matrix4f = null):Matrix4f
	{
		if (result == null)
		{
			result = new Matrix4f();
		}
		else
		{
			result.makeIdentity();
		}

		// multiply with scale first, then rotate, finally translate
		result.scaleVecLocal(getWorldScale());
		result.multQuatLocal(getWorldRotation());
		result.setTranslation(getWorldTranslation());
		return result;
	}

	/**
	 * Visit each scene graph element ordered by DFS
	 * @param visitor
	 */
	public function depthFirstTraversal(visitor:SceneGraphVisitor):Void
	{

	}

	/**
	 * Visit each scene graph element ordered by BFS
	 * @param visitor
	 */
	//public function breadthFirstTraversal(visitor:SceneGraphVisitor):Void
	//{
	//var queue:LinkedQueue<Spatial> = new LinkedQueue<Spatial>();
	//queue.enqueue(this);
//
	//while (!queue.isEmpty()) 
	//{
	//var s:Spatial = queue.dequeue();
	//visitor.visit(s);
	//s.breadthFirstTraversalQueue(visitor, queue);
	//}
	//}
	//
	//private function breadthFirstTraversalQueue(visitor:SceneGraphVisitor,queue:Queue<Spatial>):Void
	//{
	//
	//}

	public function collideWith(other:Collidable, results:CollisionResults):Int
	{
		return -1;
	}
	
	public function toString():String
	{
		return name;
	}
}

