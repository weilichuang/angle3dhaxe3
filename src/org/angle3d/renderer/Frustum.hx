package org.angle3d.renderer;

import org.angle3d.math.Matrix4f;
import org.angle3d.math.Plane;
import org.angle3d.math.Rect;
import org.angle3d.math.FastMath;
import flash.Vector;

class Frustum
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

	/**
	 * Distance from camera to near frustum plane.
	 */
	private var mFrustumNear:Float;
	/**
	 * Distance from camera to far frustum plane.
	 */
	private var mFrustumFar:Float;

	private var mFrustumRect:Rect;

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

	public function new()
	{
		initialize();
	}

	private function initialize():Void
	{
		mWorldPlanes = new Vector<Plane>(FRUSTUM_PLANES, true);
		for (i in 0...FRUSTUM_PLANES)
		{
			mWorldPlanes[i] = new Plane();
		}

		mProjectionMatrix = new Matrix4f();

		mFrustumNear = 1.0;
		mFrustumFar = 2.0;
		mFrustumRect = new Rect(-0.5, 0.5, -0.5, 0.5);

		mCoeffLeft = new Vector<Float>(2, true);
		mCoeffRight = new Vector<Float>(2, true);
		mCoeffBottom = new Vector<Float>(2, true);
		mCoeffTop = new Vector<Float>(2, true);
	}

	/**
	 * <code>onFrustumChange</code> updates the frustum to reflect any changes
	 * made to the planes. The new frustum values are kept in a temporary
	 * location for use when calculating the new frame. The projection
	 * matrix is updated to reflect the current values of the frustum.
	 */
	public function onFrustumChange():Void
	{
		if (!parallelProjection)
		{
			var nearSquared:Float = mFrustumNear * mFrustumNear;
			var leftSquared:Float = mFrustumRect.left * mFrustumRect.left;
			var rightSquared:Float = mFrustumRect.right * mFrustumRect.right;
			var bottomSquared:Float = mFrustumRect.bottom * mFrustumRect.bottom;
			var topSquared:Float = mFrustumRect.top * mFrustumRect.top;

			var inverseLength:Float = 1 / Math.sqrt(nearSquared + leftSquared);
			mCoeffLeft[0] = mFrustumNear * inverseLength;
			mCoeffLeft[1] = -mFrustumRect.left * inverseLength;

			inverseLength = 1 / Math.sqrt(nearSquared + rightSquared);
			mCoeffRight[0] = -mFrustumNear * inverseLength;
			mCoeffRight[1] = mFrustumRect.right * inverseLength;

			inverseLength = 1 / Math.sqrt(nearSquared + bottomSquared);
			mCoeffBottom[0] = mFrustumNear * inverseLength;
			mCoeffBottom[1] = -mFrustumRect.bottom * inverseLength;

			inverseLength = 1 / Math.sqrt(nearSquared + topSquared);
			mCoeffTop[0] = -mFrustumNear * inverseLength;
			mCoeffTop[1] = mFrustumRect.top * inverseLength;
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

		mProjectionMatrix.fromFrustum(mFrustumNear, mFrustumFar, mFrustumRect.left, mFrustumRect.right, mFrustumRect.top, mFrustumRect.bottom, mParallelProjection);

		// The frame is effected by the frustum values update it as well
		onFrameChange();
	}

	/**
	 * @return true if parallel projection is enable, false if in normal perspective mode
	 * @see #setParallelProjection(Bool)
	 */
	public var parallelProjection(get, set):Bool;
	private function get_parallelProjection():Bool
	{
		return mParallelProjection;
	}

	/**
	 * Enable/disable parallel projection.
	 *
	 * @param value true to set_up this camera for parallel projection is enable, false to enter normal perspective mode
	 */
	private function set_parallelProjection(value:Bool):Bool
	{
		mParallelProjection = value;
		onFrustumChange();
		return mParallelProjection;
	}

	/**
	 * <code>getFrustumBottom</code> returns the value of the bottom frustum
	 * plane.
	 *
	 * @return the value of the bottom frustum plane.
	 */
	public function getFrustumRect():Rect
	{
		return mFrustumRect;
	}

	public var frustumBottom(get, set):Float;
	private function get_frustumBottom():Float
	{
		return mFrustumRect.bottom;
	}

	/**
	 * <code>setFrustumBottom</code> sets the value of the bottom frustum
	 * plane.
	 *
	 * @param frustumBottom the value of the bottom frustum plane.
	 */
	private function set_frustumBottom(frustumBottom:Float):Float
	{
		mFrustumRect.bottom = frustumBottom;
		onFrustumChange();
		return mFrustumRect.bottom;
	}

	/**
	 * <code>getFrustumFar</code> returns the value of the far frustum
	 * plane.
	 *
	 * @return the value of the far frustum plane.
	 */
	public var frustumFar(get, set):Float;
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

	public var frustumLeft(get, set):Float;
	private function get_frustumLeft():Float
	{
		return mFrustumRect.left;
	}

	private function set_frustumLeft(frustumLeft:Float):Float
	{
		mFrustumRect.left = frustumLeft;
		onFrustumChange();
		return mFrustumRect.left;
	}

	/**
	 * <code>getFrustumNear</code> returns the value of the near frustum
	 * plane.
	 *
	 * @return the value of the near frustum plane.
	 */
	public var frustumNear(get, set):Float;
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


	public var frustumRight(get, set):Float;
	private function get_frustumRight():Float
	{
		return mFrustumRect.right;
	}

	private function set_frustumRight(frustumRight:Float):Float
	{
		mFrustumRect.right = frustumRight;
		onFrustumChange();
		return mFrustumRect.right;
	}

	public var frustumTop(get, set):Float;
	private function get_frustumTop():Float
	{
		return mFrustumRect.top;
	}

	private function set_frustumTop(frustumTop:Float):Float
	{
		mFrustumRect.top = frustumTop;
		onFrustumChange();
		return mFrustumRect.top;
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
	public function setFrustum(near:Float, far:Float, left:Float, right:Float, bottom:Float, top:Float):Void
	{
		mFrustumNear = near;
		mFrustumFar = far;

		mFrustumRect.setTo(left, right, bottom, top);
		onFrustumChange();
	}

	public function setFrustumRect(left:Float, right:Float, bottom:Float, top:Float):Void
	{
		mFrustumRect.setTo(left, right, bottom, top);
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
		var h:Float = Math.tan(fovY * FastMath.DEGTORAD() * 0.5) * near;
		var w:Float = h * aspect;

		mFrustumNear = near;
		mFrustumFar = far;
		mFrustumRect.setTo(-w, w, -h, h);

		onFrustumChange();
	}

	/**
	 * <code>onFrameChange</code> updates the view frame of the camera.
	 */
	public function onFrameChange():Void
	{

	}
}
