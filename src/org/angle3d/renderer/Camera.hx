package org.angle3d.renderer;

import flash.Vector;
import org.angle3d.bounding.BoundingBox;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Plane;
import org.angle3d.math.PlaneSide;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;
import org.angle3d.renderer.FrustumIntersect;
import org.angle3d.utils.TempVars;

/**
 * Camera is a standalone, purely mathematical class for doing
 * camera-related computations.
 *
 * <p>
 * Given input data such as location, orientation (direction, left, up),
 * and viewport settings, it can compute data neccessary to render objects
 * with the graphics library. Two matrices are generated, the view matrix
 * transforms objects from world space into eye space, while the projection
 * matrix transforms objects from eye space into clip space.
 * </p>
 * <p>Another purpose of the camera class is to do frustum culling operations,
 * defined by six planes which define a 3D frustum shape, it is possible to
 * test if an object bounded by a mathematically defined volume is inside
 * the camera frustum, and thus to aVoid rendering objects that are outside
 * the frustum
 * </p>
 *
 */
class Camera
{
	/**
	 * LEFT_PLANE represents the left plane of the camera frustum.
	 */
	public static inline var LEFT_PLANE:Int = 0;
	/**
	 * RIGHT_PLANE represents the right plane of the camera frustum.
	 */
	public static inline var RIGHT_PLANE:Int = 1;
	/**
	 * BOTTOM_PLANE represents the bottom plane of the camera frustum.
	 */
	public static inline var BOTTOM_PLANE:Int = 2;
	/**
	 * TOP_PLANE represents the top plane of the camera frustum.
	 */
	public static inline var TOP_PLANE:Int = 3;
	/**
	 * FAR_PLANE represents the far plane of the camera frustum.
	 */
	public static inline var FAR_PLANE:Int = 4;
	/**
	 * NEAR_PLANE represents the near plane of the camera frustum.
	 */
	public static inline var NEAR_PLANE:Int = 5;
	/**
	 * FRUSTUM_PLANES represents the number of planes of the camera frustum.
	 */
	public static inline var FRUSTUM_PLANES:Int = 6;
	
	public var viewPortBottom(get, set):Float;
	public var viewPortLeft(get, set):Float;
	public var viewPortRight(get, set):Float;
	public var viewPortTop(get, set):Float;
	
	public var frustumBottom(get, set):Float;
	public var frustumFar(get, set):Float;
	public var frustumLeft(get, set):Float;
	public var frustumNear(get, set):Float;
	public var frustumRight(get, set):Float;
	public var frustumTop(get, set):Float;
	
	public var planeState(get,set):Int;
	
	/** The camera's name. */
	public var name:String;

	public var width:Int;
	public var height:Int;
	
	/**
	 * Camera's location
	 */
	public var location:Vector3f;
	/**
	 * The orientation of the camera.
	 */
	public var rotation:Quaternion;

	/**
	 * Distance from camera to near frustum plane.
	 */
	private var mFrustumNear:Float;
	/**
	 * Distance from camera to far frustum plane.
	 */
	private var mFrustumFar:Float;

	private var mFrustumLeft:Float;
	
	private var mFrustumRight:Float;
	
	private var mFrustumTop:Float;
	
	private var mFrustumBottom:Float;
	
	//Temporary values computed in onFrustumChange that are needed if a
	//call is made to onFrameChange.
	private var mCoeffLeft:Vector<Float>;
	private var mCoeffRight:Vector<Float>;
	private var mCoeffBottom:Vector<Float>;
	private var mCoeffTop:Vector<Float>;

	/**
	 * Array holding the planes that this camera will check for culling.
	 */
	private var mWorldPlanes:Vector<Plane>;

	private var mParallelProjection:Bool;
	private var mProjectionMatrix:Matrix4f;
	
	//view port coordinates
    /**
     * Percent value on display where horizontal viewing starts for this camera.
     * Default is 0.
     */
    private var mViewPortLeft:Float;
    /**
     * Percent value on display where horizontal viewing ends for this camera.
     * Default is 1.
     */
    private var mViewPortRight:Float;
    /**
     * Percent value on display where vertical viewing ends for this camera.
     * Default is 1.
     */
    private var mViewPortTop:Float;
    /**
     * Percent value on display where vertical viewing begins for this camera.
     * Default is 0.
     */
    private var mViewPortBottom:Float;
	
	private var mViewPortWidth:Float;
	
	private var mViewPortHeight:Float;
	

	private var mViewPortChanged:Bool;

	private var mViewMatrix:Matrix4f;
	private var mViewProjectionMatrix:Matrix4f;
	private var mProjectionMatrixOverride:Matrix4f;

	private var mGuiBounding:BoundingBox;

	/**
	 * A mask value set_during contains() that allows fast culling of a Node's
	 * children.
	 */
	private var mPlaneState:Int;

	public function new(width:Int, height:Int)
	{
		this.width = width;
		this.height = height;
		
		mWorldPlanes = new Vector<Plane>(FRUSTUM_PLANES, true);
		for (i in 0...FRUSTUM_PLANES)
		{
			mWorldPlanes[i] = new Plane();
		}

		mProjectionMatrix = new Matrix4f();

		mFrustumNear = 1.0;
		mFrustumFar = 2.0;
		mFrustumLeft = -0.5;
		mFrustumRight = 0.5;
		mFrustumBottom = -0.5;
		mFrustumTop = 0.5;

		mCoeffLeft = new Vector<Float>(2, true);
		mCoeffRight = new Vector<Float>(2, true);
		mCoeffBottom = new Vector<Float>(2, true);
		mCoeffTop = new Vector<Float>(2, true);
		
		mViewPortLeft = 0.0;
        mViewPortRight = 1.0;
        mViewPortTop = 1.0;
        mViewPortBottom = 0.0;
		mViewPortWidth = 1;
		mViewPortHeight = 1;
		
		mViewPortChanged = true;

		mViewMatrix = new Matrix4f();
		mViewProjectionMatrix = new Matrix4f();

		mGuiBounding = new BoundingBox();

		location = new Vector3f();
		rotation = new Quaternion();

		onFrustumChange();
		onViewPortChange();
		onFrameChange();
	}

	public inline function getWidth():Int
	{
		return width;
	}
	
	public inline function getHeight():Int
	{
		return height;
	}

	public function copyFrom(cam:Camera):Void
	{
		location.copyFrom(cam.location);
		rotation.copyFrom(cam.rotation);

		mFrustumNear = cam.mFrustumNear;
		mFrustumFar = cam.mFrustumFar;
		mFrustumLeft = cam.mFrustumLeft;
		mFrustumRight = cam.mFrustumRight;
		mFrustumBottom = cam.mFrustumBottom;
		mFrustumTop = cam.mFrustumTop;

		mCoeffLeft[0] = cam.mCoeffLeft[0];
		mCoeffLeft[1] = cam.mCoeffLeft[1];
		mCoeffRight[0] = cam.mCoeffRight[0];
		mCoeffRight[1] = cam.mCoeffRight[1];
		mCoeffBottom[0] = cam.mCoeffBottom[0];
		mCoeffBottom[1] = cam.mCoeffBottom[1];
		mCoeffTop[0] = cam.mCoeffTop[0];
		mCoeffTop[1] = cam.mCoeffTop[1];

		mViewPortLeft = cam.mViewPortLeft;
		mViewPortRight = cam.mViewPortRight;
		mViewPortTop = cam.mViewPortTop;
		mViewPortBottom = cam.mViewPortBottom;

		this.width = cam.width;
		this.height = cam.height;

		this.mPlaneState = cam.mPlaneState;
		this.mViewPortChanged = cam.mViewPortChanged;
		for (i in 0...FRUSTUM_PLANES)
		{
			mWorldPlanes[i].normal.copyFrom(cam.mWorldPlanes[i].normal);
			mWorldPlanes[i].constant = cam.mWorldPlanes[i].constant;
		}

		this.mParallelProjection = cam.mParallelProjection;
		if (cam.mProjectionMatrixOverride != null)
		{
			if (mProjectionMatrixOverride == null)
			{
				mProjectionMatrixOverride = cam.mProjectionMatrixOverride.clone();
			}
			else
			{
				mProjectionMatrixOverride.copyFrom(cam.mProjectionMatrixOverride);
			}
		}
		else
		{
			this.mProjectionMatrixOverride = null;
		}
		this.mViewMatrix.copyFrom(cam.mViewMatrix);
		this.mProjectionMatrix.copyFrom(cam.mProjectionMatrix);
		this.mViewProjectionMatrix.copyFrom(cam.mViewProjectionMatrix);

		this.mGuiBounding.copyFrom(cam.mGuiBounding);
	}

	public function clone(newName:String):Camera
	{
		var cam:Camera = new Camera(width, height);
		cam.name = newName;
		cam.mViewPortChanged = true;
		cam.mPlaneState = PlaneSide.None;

		for (i in 0...FRUSTUM_PLANES)
		{
			cam.mWorldPlanes[i].copyFrom(mWorldPlanes[i]);
		}

		cam.location.copyFrom(location);
		cam.rotation.copyFrom(rotation);

		if (mProjectionMatrixOverride != null)
		{
			cam.mProjectionMatrixOverride = mProjectionMatrixOverride.clone();
		}

		cam.mViewMatrix.copyFrom(mViewMatrix);
		cam.mProjectionMatrix.copyFrom(mProjectionMatrix);
		cam.mViewProjectionMatrix.copyFrom(mViewProjectionMatrix);
		cam.mGuiBounding = cast(mGuiBounding.clone(), BoundingBox);

		cam.update();

		return cam;
	}

	/**
	 * Sets a clipPlane for this camera.
	 * The cliPlane is used to recompute the projectionMatrix using the plane as the near plane
	 * This technique is known as the oblique near-plane clipping method introduced by Eric Lengyel
	 * more info here
	 * http://www.terathon.com/code/oblique.html
	 * http://aras-p.info/texts/obliqueortho.html
	 * http://hacksoflife.blogspot.com/2008/12/every-now-and-then-i-come-across.html
	 *
	 * Note that this will work properly only if it's called on each update, and be aware that it won't work properly with the sky bucket.
	 * if you want to handle the sky bucket, look at how it's done in SimpleWaterProcessor.java
	 * @param clipPlane the plane
	 * @param side the side the camera stands from the plane
	 */
	public function setClipPlane(clipPlane:Plane, side:Int = -1):Void
	{
		if (side <= -1)
		{
			side = clipPlane.whichSide(location);
		}

		var sideFactor:Float = 1.0;
		if (side == PlaneSide.Negative)
		{
			sideFactor = -1.0;
		}

		//we are on the other side of the plane no need to clip anymore.
		if (clipPlane.whichSide(location) == side)
		{
			return;
		}

		var newProjectionMatrix:Matrix4f = mProjectionMatrix.clone();
		var ivm:Matrix4f = mViewMatrix.clone();

		var point:Vector3f = clipPlane.normal.clone();
		point.scaleLocal(clipPlane.constant);

		var pp:Vector3f = ivm.multVec(point);
		var pn:Vector3f = ivm.multNormal(clipPlane.normal);

		var clipPlaneV:Vector4f = new Vector4f();
		clipPlaneV.x = pn.x * sideFactor;
		clipPlaneV.y = pn.y * sideFactor;
		clipPlaneV.z = pn.z * sideFactor;
		clipPlaneV.w = -pp.dot(pn) * sideFactor;

		var v:Vector4f = new Vector4f();
		v.x = (FastMath.signum(clipPlaneV.x) + newProjectionMatrix.m02) / newProjectionMatrix.m00;
		v.y = (FastMath.signum(clipPlaneV.y) + newProjectionMatrix.m12) / newProjectionMatrix.m11;
		v.z = -1.0;
		v.w = (1.0 + newProjectionMatrix.m22) / newProjectionMatrix.m23;

		var dot:Float = clipPlaneV.dot(v);
		var c:Vector4f = clipPlaneV.scale(2.0 / dot);

		newProjectionMatrix.m20 = c.x - newProjectionMatrix.m30;
		newProjectionMatrix.m21 = c.y - newProjectionMatrix.m31;
		newProjectionMatrix.m22 = c.z - newProjectionMatrix.m32;
		newProjectionMatrix.m23 = c.w - newProjectionMatrix.m33;
		setProjectionMatrix(newProjectionMatrix);
	}

	/**
	 * Resizes this camera's view with the given width and height. This is
	 * similar to constructing a new camera, but reusing the same Object. This
	 * method is called by RenderManager to notify the camera of
	 * changes in the display dimensions.
	 *
	 * @param width the view width
	 * @param height the view height
	 * @param fixAspect If true, the camera's aspect ratio will be recomputed.
	 * Recomputing the aspect ratio requires changing the frustum values.
	 */
	public function resize(width:Int, height:Int, fixAspect:Bool = true):Void
	{
		this.width = width;
		this.height = height;
		onViewPortChange();

		if (fixAspect)
		{
			mFrustumRight = mFrustumTop * width / height;
			mFrustumLeft = -mFrustumRight;
			onFrustumChange();
		}
	}
	
	public function getLocation():Vector3f
	{
		return location;
	}

	public function setLocation(value:Vector3f):Void
	{
		this.location.copyFrom(value);
		onFrameChange();
	}
	
	public function getRotation():Quaternion
	{
		return rotation;
	}

	public function setRotation(value:Quaternion):Void
	{
		this.rotation.copyFrom(value);
		onFrameChange();
	}

	/**
	 * <code>getDirection</code> retrieves the direction vector the camera is
	 * facing.
	 *
	 * @return the direction the camera is facing.
	 * @see Camera#getDirection()
	 */
	public inline function getDirection(result:Vector3f = null):Vector3f
	{
		return rotation.getRotationColumn(2, result);
	}

	/**
	 * <code>getLeft</code> retrieves the left axis of the camera.
	 *
	 * @return the left axis of the camera.
	 * @see Camera#getLeft()
	 */
	public function getLeft(result:Vector3f = null):Vector3f
	{
		return rotation.getRotationColumn(0, result);
	}

	/**
	 * <code>getUp</code> retrieves the up axis of the camera.
	 *
	 * @return the up axis of the camera.
	 * @see Camera#getUp()
	 */
	public function getUp(result:Vector3f = null):Vector3f
	{
		return rotation.getRotationColumn(1, result);
	}

	/**
	 * <code>lookAtDirection</code> sets the direction the camera is facing
	 * given a direction and an up vector.
	 *
	 * @param direction the direction this camera is facing.
	 */
	public function lookAtDirection(direction:Vector3f, upVector:Vector3f):Void
	{
		rotation.lookAt(direction, upVector);
		onFrameChange();
	}

	/**
	 * <code>setAxes</code> sets the axes (left, up and direction) for this
	 * camera.
	 *
	 * @param left      the left axis of the camera.
	 * @param up        the up axis of the camera.
	 * @param direction the direction the camera is facing.
	 * @see Camera#setAxes(com.jme.math.Vector3f,com.jme.math.Vector3f,com.jme.math.Vector3f)
	 */
	public function setAxes(left:Vector3f, up:Vector3f, direction:Vector3f):Void
	{
		rotation.fromAxes(left, up, direction);
		onFrameChange();
	}

	/**
	 * <code>setAxes</code> uses a rotational matrix to set_the axes of the
	 * camera.
	 *
	 * @param axes the matrix that defines the orientation of the camera.
	 */
	public function setAxesFromQuat(axes:Quaternion):Void
	{
		rotation.copyFrom(axes);
		onFrameChange();
	}

	/**
	 * normalizes the camera vectors.
	 */
	public function normalize():Void
	{
		rotation.normalizeLocal();
		onFrameChange();
	}

	/**
	 * <code>setFrame</code> sets the orientation and location of the camera.
	 *
	 * @param location  the point position of the camera.
	 * @param left      the left axis of the camera.
	 * @param up        the up axis of the camera.
	 * @param direction the facing of the camera.
	 */
	public function setFrame(location:Vector3f, left:Vector3f, up:Vector3f, direction:Vector3f):Void
	{
		this.location.copyFrom(location);
		this.rotation.fromAxes(left, up, direction);
		onFrameChange();
	}

	/**
	* <code>setFrame</code> sets the orientation and location of the camera.
	*
	* @param location
	*            the point position of the camera.
	* @param axes
	*            the orientation of the camera.
	*/
	public function setFrameFromQuat(location:Vector3f, axes:Quaternion):Void
	{
		this.location.copyFrom(location);
		this.rotation.copyFrom(axes);
		onFrameChange();
	}

	/**
	 * <code>lookAt</code> is a convienence method for auto-setting the frame
	 * based on a world position the user desires the camera to look at. It
	 * repoints the camera towards the given position using the difference
	 * between the position and the current camera location as a direction
	 * vector and the worldUpVector to compute up and left camera vectors.
	 *
	 * @param pos      where to look at in terms of world coordinates
	 * @param upVector a normalized vector indicating the up direction of the world.
	 */
	//TODO 优化
	public function lookAt(pos:Vector3f, upVector:Vector3f):Void
	{
		var newDirection:Vector3f = pos.subtract(location);
		newDirection.normalizeLocal();

		var newUp:Vector3f = upVector.clone();
		newUp.normalizeLocal();
		if (newUp.isZero())
		{
			newUp.setTo(0, 1, 0);
		}

		var newLeft:Vector3f = newUp.cross(newDirection);
		newLeft.normalizeLocal();
		if (newLeft.isZero())
		{
			if (newDirection.x != 0)
			{
				newLeft.setTo(newDirection.y, -newDirection.x, 0);
			}
			else
			{
				newLeft.setTo(0, newDirection.z, -newDirection.y);
			}
		}

		newUp.copyFrom(newDirection);
		newUp = newUp.cross(newLeft);
		newUp.normalizeLocal();

		rotation.fromAxes(newLeft, newUp, newDirection);
		rotation.normalizeLocal();
		onFrameChange();
	}

	/**
	 * <code>update</code> updates the camera parameters by calling
	 * <code>onFrustumChange</code>,<code>onViewPortChange</code> and
	 * <code>onFrameChange</code>.
	 *
	 * @see Camera#update()
	 */
	public function update():Void
	{
		onFrustumChange();
		onViewPortChange();
		//onFrameChange();
	}

	/**
	 * <code>setViewPort</code> sets the boundaries of the viewport
	 *
	 * @param left   the left boundary of the viewport (default: 0)
	 * @param right  the right boundary of the viewport (default: 1)
	 * @param bottom the bottom boundary of the viewport (default: 0)
	 * @param top    the top boundary of the viewport (default: 1)
	 */
	public function setViewPortRect(left:Float, right:Float, bottom:Float, top:Float):Void
	{
		mViewPortLeft = left;
		mViewPortRight = right;
		mViewPortBottom = bottom;
		mViewPortTop = top;
		onViewPortChange();
	}

	/**
	 * Returns the pseudo distance from the given position to the near
	 * plane of the camera. This is used for render queue sorting.
	 * @param pos The position to compute a distance to.
	 * @return Distance from the far plane to the point.
	 */
	public function distanceToNearPlane(pos:Vector3f):Float
	{
		return mWorldPlanes[NEAR_PLANE].pseudoDistance(pos);
	}

	/**
	 * <code>contains</code> tests a bounding volume against the planes of the
	 * camera's frustum. The frustums planes are set_such that the normals all
	 * face in towards the viewable scene. Therefore, if the bounding volume is
	 * on the negative side of the plane is can be culled out.
	 *
	 * NOTE: This method is used internally for culling, for public usage,
	 * the plane state of the bounding volume must be saved and restored, e.g:
	 * <code>BoundingVolume bv;<br/>
	 * Camera c;<br/>
	 * int planeState = bv.getPlaneState();<br/>
	 * bv.setPlaneState(0);<br/>
	 * c.contains(bv);<br/>
	 * bv.setPlaneState(plateState);<br/>
	 * </code>
	 *
	 * @param bound the bound to check for culling
	 * @return See enums in <code>FrustumIntersect</code>
	 */
	//此函数很费时，需要进行优化
	public function contains(bound:BoundingVolume):Int
	{
		if (bound == null)
		{
			return FrustumIntersect.Inside;
		}

		var mask:Int;
		var rVal:Int = FrustumIntersect.Inside;

		var planeCounter:Int = FRUSTUM_PLANES;
		while (planeCounter >= 0)
		{
			if (planeCounter == bound.getCheckPlane())
			{
				planeCounter--;
				continue; // we have already checked this plane at first iteration
			}

			var planeId:Int = (planeCounter == FRUSTUM_PLANES) ? bound.getCheckPlane() : planeCounter;

			mask = 1 << planeId;
			if ((mPlaneState & mask) == 0)
			{
				var side:Int = bound.whichSide(mWorldPlanes[planeId]);

				if (side == PlaneSide.Negative)
				{
					//object is outside of frustum
					bound.setCheckPlane(planeId);
					return FrustumIntersect.Outside;
				}
				else if (side == PlaneSide.Positive)
				{
					//object is visible on *this* plane, so mark this plane
					//so that we don't check it for sub nodes.
					mPlaneState |= mask;
				}
				else
				{
					rVal = FrustumIntersect.Intersects;
				}
			}
			
			planeCounter--;
		}

		return rVal;
	}

	/**
	 * <code>containsGui</code> tests a bounding volume against the ortho
	 * bounding box of the camera. A bounding box spanning from
	 * 0, 0 to Width, Height. Constrained by the viewport settings on the
	 * camera.
	 *
	 * @param bound the bound to check for culling
	 * @return True if the camera contains the gui element bounding volume.
	 */
	public inline function containsGui(bound:BoundingVolume):Bool
	{
		if (bound == null)
			return true;
		else
			return mGuiBounding.intersects(bound);
	}

	/**
	 * @return the view matrix of the camera.
	 * The view matrix transforms world space into eye space.
	 * This matrix is usually defined by the position and
	 * orientation of the camera.
	 */
	public function getViewMatrix():Matrix4f
	{
		return mViewMatrix;
	}

	/**
	 * Overrides the projection matrix used by the camera. Will
	 * use the matrix for computing the view projection matrix as well.
	 * Use null argument to return to normal functionality.
	 *
	 * @param projMatrix
	 */
	public function setProjectionMatrix(mat:Matrix4f):Void
	{
		mProjectionMatrixOverride = mat;
		updateViewProjection();
	}

	/**
	 * @return the projection matrix of the camera.
	 * The view projection matrix  transforms eye space into clip space.
	 * This matrix is usually defined by the viewport and perspective settings
	 * of the camera.
	 */
	public function getProjectionMatrix():Matrix4f
	{
		if (mProjectionMatrixOverride != null)
		{
			return mProjectionMatrixOverride;
		}

		return mProjectionMatrix;
	}

	/**
	 * Updates the view projection matrix.
	 */
	public function updateViewProjection():Void
	{
		if (mProjectionMatrixOverride != null)
		{
			mProjectionMatrixOverride.mult(mViewMatrix, mViewProjectionMatrix);
//				mViewProjectionMatrix.copyFrom(mProjectionMatrixOverride);
//				mViewProjectionMatrix.multLocal(mViewMatrix);
		}
		else
		{
			mProjectionMatrix.mult(mViewMatrix, mViewProjectionMatrix);
//				mViewProjectionMatrix.copyFrom(mProjectionMatrix);
//				mViewProjectionMatrix.multLocal(mViewMatrix);
		}
	}

	/**
	 * @return The result of multiplying the projection matrix by the view
	 * matrix. This matrix is required for rendering an object. It is
	 * precomputed so as to not compute it every time an object is rendered.
	 */
	public function getViewProjectionMatrix():Matrix4f
	{
		return mViewProjectionMatrix;
	}

	/**
	 * @return True if the viewport (width, height, left, right, bottom, up)
	 * has been changed. This is needed in the renderer so that the proper
	 * viewport can be set-up.
	 */
	public function isViewportChanged():Bool
	{
		return mViewPortChanged;
	}

	/**
	 * Clears the viewport changed flag once it has been updated inside
	 * the renderer.
	 */
	public function clearViewportChanged():Void
	{
		mViewPortChanged = false;
	}

	/**
	 * Called when the viewport has been changed.
	 */
	public function onViewPortChange():Void
	{
		mViewPortChanged = true;
		mViewPortWidth = mViewPortRight - mViewPortLeft;
		mViewPortHeight = mViewPortTop - mViewPortBottom;
		updateGuiBounding();
	}

	private function updateGuiBounding():Void
	{
		var sx:Float = width * mViewPortLeft;
		var ex:Float = width * mViewPortRight;
		var sy:Float = height * mViewPortBottom;
		var ey:Float = height * mViewPortTop;
		var xExtent:Float = Math.max(0, (ex - sx) * 0.5);
		var yExtent:Float = Math.max(0, (ey - sy) * 0.5);

		mGuiBounding.setCenter(new Vector3f(sx + xExtent, sy + yExtent, 0));
		mGuiBounding.xExtent = xExtent;
		mGuiBounding.yExtent = yExtent;
		mGuiBounding.zExtent = FastMath.POSITIVE_INFINITY;
	}

	/**
	 * <code>onFrameChange</code> updates the view frame of the camera.
	 */
	private static var helperLeft:Vector3f = new Vector3f();
	private static var helperDirection:Vector3f = new Vector3f();
	private static var helperUp:Vector3f = new Vector3f();
	public function onFrameChange():Void
	{
		if (location == null || rotation == null)
			return;
			
		var left:Vector3f = getLeft(helperLeft);
		var direction:Vector3f = getDirection(helperDirection);
		var up:Vector3f = getUp(helperUp);

		var dirDotLocation:Float = direction.dot(location);
		
		var dx:Float = direction.x, dy:Float = direction.y, dz:Float = direction.z;

		// left plane
		var plane:Plane = mWorldPlanes[LEFT_PLANE];
		var normal:Vector3f = plane.normal;
		normal.x = left.x * mCoeffLeft[0] + dx * mCoeffLeft[1];
		normal.y = left.y * mCoeffLeft[0] + dy * mCoeffLeft[1];
		normal.z = left.z * mCoeffLeft[0] + dz * mCoeffLeft[1];
		plane.constant = location.dot(normal);

		// right plane
		plane = mWorldPlanes[RIGHT_PLANE];
		normal = plane.normal;
		normal.x = left.x * mCoeffRight[0] + dx * mCoeffRight[1];
		normal.y = left.y * mCoeffRight[0] + dy * mCoeffRight[1];
		normal.z = left.z * mCoeffRight[0] + dz * mCoeffRight[1];
		plane.constant = location.dot(normal);

		// bottom plane
		plane = mWorldPlanes[BOTTOM_PLANE];
		normal = plane.normal;
		normal.x = up.x * mCoeffBottom[0] + dx * mCoeffBottom[1];
		normal.y = up.y * mCoeffBottom[0] + dy * mCoeffBottom[1];
		normal.z = up.z * mCoeffBottom[0] + dz * mCoeffBottom[1];
		plane.constant = location.dot(normal);

		// top plane
		plane = mWorldPlanes[TOP_PLANE];
		normal = plane.normal;
		normal.x = up.x * mCoeffTop[0] + dx * mCoeffTop[1];
		normal.y = up.y * mCoeffTop[0] + dy * mCoeffTop[1];
		normal.z = up.z * mCoeffTop[0] + dz * mCoeffTop[1];
		plane.constant = location.dot(normal);

		if (isParallelProjection())
		{
			mWorldPlanes[LEFT_PLANE].constant += mFrustumLeft;
			mWorldPlanes[RIGHT_PLANE].constant -= mFrustumRight;
			mWorldPlanes[TOP_PLANE].constant -= mFrustumTop;
			mWorldPlanes[BOTTOM_PLANE].constant += mFrustumBottom;
		}

		// far plane
		mWorldPlanes[FAR_PLANE].normal.setTo(-direction.x, -direction.y, -direction.z);
		mWorldPlanes[FAR_PLANE].constant = -(dirDotLocation + mFrustumFar);

		// near plane
		mWorldPlanes[NEAR_PLANE].normal.setTo(direction.x, direction.y, direction.z);
		mWorldPlanes[NEAR_PLANE].constant = dirDotLocation + mFrustumNear;

		mViewMatrix.fromFrame(location, direction, up, left);

		updateViewProjection();
	}

	/**
	 * Computes the z value in projection space from the z value in view space
	 * Note that the returned value is going non linearly from 0 to 1.
	 * for more explanations on non linear z buffer see
	 * http://www.sjbaker.org/steve/omniv/love_your_z_buffer.html
	 * @param viewZPos the z value in view space.
	 * @return the z value in projection space.
	 */
	public function getViewToProjectionZ(viewZPos:Float):Float
	{
		var far:Float = frustumFar;
		var near:Float = frustumNear;
		var a:Float = far / (far - near);
		var b:Float = far * near / (near - far);
		return a + b / viewZPos;
	}

	/**
	 * Computes a position in World space given a screen position in screen space (0,0 to width, height)
	 * and a z position in projection space ( 0 to 1 non linear).
	 * This former value is also known as the Z buffer value or non linear depth buffer.
	 * for more explanations on non linear z buffer see
	 * http://www.sjbaker.org/steve/omniv/love_your_z_buffer.html
	 *
	 * To compute the projection space z from the view space z (distance from cam to object) @see Camera#getViewToProjectionZ
	 *
	 * @param screenPos 2d coordinate in screen space
	 * @param projectionZPos non linear z value in projection space
	 * @return the position in world space.
	 */
	private static var tmpInverseMat:Matrix4f = new Matrix4f();
	public function getWorldCoordinates(screenX:Float, screenY:Float, projectionZPos:Float, result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		mViewProjectionMatrix.invert(tmpInverseMat);

		result.setTo((screenX / width - mViewPortLeft) / mViewPortWidth * 2 - 1,
					 (screenY / height - mViewPortBottom) / mViewPortHeight * 2 - 1,
					  projectionZPos * 2 - 1);

		var w:Float = tmpInverseMat.multProj(result, result);
		result.scaleLocal(1 / w);

		return result;
	}

	/**
	 * Converts the given position from world space to screen space.
	 *
	 * @see Camera#getScreenCoordinates(Vector3f, Vector3f)
	 */
	public function getScreenCoordinates(worldPos:Vector3f, result:Vector3f = null):Vector3f
	{
		if (result == null)
			result = new Vector3f();

		var w:Float = mViewProjectionMatrix.multProj(worldPos, result);
		result.scaleLocal(1 / w);

		result.x = ((result.x + 1) * mViewPortWidth * 0.5 + mViewPortLeft) * width;
		result.y = ((result.y + 1) * mViewPortHeight * 0.5 + mViewPortBottom) * height;
		result.z = (result.z + 1) * 0.5;

		return result;
	}
	
	
	private function get_viewPortBottom():Float
	{
		return mViewPortBottom;
	}

	private function set_viewPortBottom(bottom:Float):Float
	{
		mViewPortBottom = bottom;
		onViewPortChange();
		return mViewPortBottom;
	}

	
	private function get_viewPortLeft():Float
	{
		return mViewPortLeft;
	}

	private function set_viewPortLeft(left:Float):Float
	{
		mViewPortLeft = left;
		onViewPortChange();
		return mViewPortLeft;
	}

	
	private function get_viewPortRight():Float
	{
		return mViewPortRight;
	}

	private function set_viewPortRight(right:Float):Float
	{
		mViewPortRight = right;
		onViewPortChange();
		return mFrustumRight;
	}

	
	private function get_viewPortTop():Float
	{
		return mViewPortTop;
	}

	private function set_viewPortTop(top:Float):Float
	{
		mViewPortTop = top;
		onViewPortChange();
		return mViewPortTop;
	}
	
	public inline function getWorldPlane(planeId:Int):Plane
	{
        return mWorldPlanes[planeId];
    }

	/**
	 * <code>onFrustumChange</code> updates the frustum to reflect any changes
	 * made to the planes. The new frustum values are kept in a temporary
	 * location for use when calculating the new frame. The projection
	 * matrix is updated to reflect the current values of the frustum.
	 */
	public function onFrustumChange():Void
	{
		if (!isParallelProjection())
		{
			var nearSquared:Float = mFrustumNear * mFrustumNear;
			var leftSquared:Float = mFrustumLeft * mFrustumLeft;
			var rightSquared:Float = mFrustumRight * mFrustumRight;
			var bottomSquared:Float = mFrustumBottom * mFrustumBottom;
			var topSquared:Float = mFrustumTop * mFrustumTop;

			var inverseLength:Float = 1 / Math.sqrt(nearSquared + leftSquared);
			mCoeffLeft[0] = -mFrustumNear * inverseLength;
			mCoeffLeft[1] = -mFrustumLeft * inverseLength;

			inverseLength = 1 / Math.sqrt(nearSquared + rightSquared);
			mCoeffRight[0] = -mFrustumNear * inverseLength;
			mCoeffRight[1] = mFrustumRight * inverseLength;

			inverseLength = 1 / Math.sqrt(nearSquared + bottomSquared);
			mCoeffBottom[0] = mFrustumNear * inverseLength;
			mCoeffBottom[1] = -mFrustumBottom * inverseLength;

			inverseLength = 1 / Math.sqrt(nearSquared + topSquared);
			mCoeffTop[0] = -mFrustumNear * inverseLength;
			mCoeffTop[1] = mFrustumTop * inverseLength;
		}
		else
		{
			mCoeffLeft[0] = 1;
			mCoeffLeft[1] = 0;

			mCoeffRight[0] = -1;
			mCoeffRight[1] = 0;

			mCoeffBottom[0] = 1;
			mCoeffBottom[1] = 0;

			mCoeffTop[0] = -1;
			mCoeffTop[1] = 0;
		}

		mProjectionMatrix.fromFrustum(mFrustumNear, mFrustumFar, 
									mFrustumLeft, mFrustumRight, mFrustumTop, mFrustumBottom, 
									mParallelProjection);

		// The frame is effected by the frustum values update it as well
		onFrameChange();
	}

	/**
	 * @return true if parallel projection is enable, false if in normal perspective mode
	 * @see #setParallelProjection(Bool)
	 */
	public function isParallelProjection():Bool
	{
		return mParallelProjection;
	}

	/**
	 * Enable/disable parallel projection.
	 *
	 * @param value true to set_up this camera for parallel projection is enable, false to enter normal perspective mode
	 */
	public function setParallelProjection(value:Bool):Void
	{
		mParallelProjection = value;
		onFrustumChange();
	}
	
	private inline function get_planeState():Int
	{
		return mPlaneState;
	}

	private inline function set_planeState(value:Int):Int
	{
		return mPlaneState = value;
	}

	
	private function get_frustumBottom():Float
	{
		return mFrustumBottom;
	}

	/**
	 * <code>setFrustumBottom</code> sets the value of the bottom frustum
	 * plane.
	 *
	 * @param frustumBottom the value of the bottom frustum plane.
	 */
	private function set_frustumBottom(frustumBottom:Float):Float
	{
		mFrustumBottom = frustumBottom;
		onFrustumChange();
		return mFrustumBottom;
	}

	/**
	 * <code>getFrustumFar</code> returns the value of the far frustum
	 * plane.
	 *
	 * @return the value of the far frustum plane.
	 */
	
	private function get_frustumFar():Float
	{
		return mFrustumFar;
	}

	private function set_frustumFar(frustumFar:Float):Float
	{
		this.mFrustumFar = frustumFar;
		onFrustumChange();
		return mFrustumFar;
	}

	
	private function get_frustumLeft():Float
	{
		return mFrustumLeft;
	}

	private function set_frustumLeft(frustumLeft:Float):Float
	{
		mFrustumLeft = frustumLeft;
		onFrustumChange();
		return mFrustumLeft;
	}

	/**
	 * <code>getFrustumNear</code> returns the value of the near frustum
	 * plane.
	 *
	 * @return the value of the near frustum plane.
	 */
	
	private function get_frustumNear():Float
	{
		return mFrustumNear;
	}

	private function set_frustumNear(frustumNear:Float):Float
	{
		this.mFrustumNear = frustumNear;
		onFrustumChange();
		return mFrustumNear;
	}


	private function get_frustumRight():Float
	{
		return mFrustumRight;
	}

	private function set_frustumRight(frustumRight:Float):Float
	{
		mFrustumRight = frustumRight;
		onFrustumChange();
		return mFrustumRight;
	}


	private function get_frustumTop():Float
	{
		return mFrustumTop;
	}

	private function set_frustumTop(frustumTop:Float):Float
	{
		mFrustumTop = frustumTop;
		onFrustumChange();
		return mFrustumTop;
	}

	/**
	 * sets the frustum of this camera object.
	 *
	 * @param near   the near plane.
	 * @param far    the far plane.
	 * @param left   the left plane.
	 * @param right  the right plane.
	 * @param top    the top plane.
	 * @param bottom the bottom plane.
	 */
	public function setFrustum(near:Float, far:Float, left:Float, right:Float, top:Float, bottom:Float):Void
	{
		mFrustumNear = near;
		mFrustumFar = far;
		mFrustumLeft = left;
		mFrustumRight = right;
		mFrustumBottom = bottom;
		mFrustumTop = top;
		onFrustumChange();
	}

	public function setFrustumRect(left:Float, right:Float, top:Float, bottom:Float):Void
	{
		mFrustumLeft = left;
		mFrustumRight = right;
		mFrustumBottom = bottom;
		mFrustumTop = top;
		onFrustumChange();
	}

	/**
	 * <code>setFrustumPerspective</code> defines the frustum for the camera.  This
	 * frustum is defined by a viewing angle, aspect ratio, and near/far planes
	 *
	 * @param fovY   Frame of view angle along the Y in degrees.
	 * @param aspect Width:Height ratio
	 * @param near   Near view plane distance
	 * @param far    Far view plane distance
	 */
	public function setFrustumPerspective(fovY:Float, aspect:Float, near:Float, far:Float):Void
	{
		var h:Float = Math.tan(fovY * FastMath.DEGTORAD * 0.5) * near;
		var w:Float = h * aspect;

		mFrustumNear = near;
		mFrustumFar = far;
		mFrustumLeft = -w;
		mFrustumRight = w;
		mFrustumBottom = -h;
		mFrustumTop = h;
		
		// Camera is no longer parallel projection even if it was before
        mParallelProjection = false;

		onFrustumChange();
	}

}

