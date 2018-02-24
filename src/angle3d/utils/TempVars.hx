package angle3d.utils;

import angle3d.bounding.BoundingBox;
import angle3d.collision.bih.BIHStackData;
import angle3d.collision.CollisionResults;
import angle3d.math.Color;
import angle3d.math.Matrix3f;
import angle3d.math.Matrix4f;
import angle3d.math.Plane;
import angle3d.math.Quaternion;
import angle3d.math.Triangle;
import angle3d.math.Vector2f;
import angle3d.math.Vector3f;
import angle3d.math.Vector4f;

import angle3d.scene.Spatial;
import angle3d.error.Assert;

/**
 * Temporary variables . Engine classes may access
 * these temp variables with TempVars.getTempVars(), all retrieved TempVars
 * instances must be returned via TempVars.release().
 * This returns an available instance of the TempVar class ensuring this
 * particular instance is never used elsewhere in the mean time.
 */
class TempVars {
	/**
	 * Allow X instances of TempVars.
	 */
	private static var STACK_SIZE:Int = 5;

	private static var currentIndex:Int = 0;

	private static var varStack:Array<TempVars> = new Array<TempVars>(5);

	public static function getTempVars():TempVars {
		#if debug
		Assert.assert(currentIndex <= STACK_SIZE - 1,
		"Only Allow " + STACK_SIZE + " instances of TempVars");
		#end

		var instance:TempVars = varStack[currentIndex];
		if (instance == null) {
			instance = new TempVars();
			varStack[currentIndex] = instance;
		}

		currentIndex++;

		instance.isUsed = true;

		return instance;
	}

	public static inline function get():TempVars {
		return getTempVars();
	}

	private var isUsed:Bool;

	/**
	 * Fetching triangle from mesh
	 */
	public var triangle:Triangle;
	/**
	 * Color
	 */
	public var color:Color;

	/**
	 * General vectors.
	 */
	public var vect1:Vector3f;
	public var vect2:Vector3f;
	public var vect3:Vector3f;
	public var vect4:Vector3f;
	public var vect5:Vector3f;
	public var vect6:Vector3f;
	public var vect7:Vector3f;
	public var vect8:Vector3f;
	public var vect9:Vector3f;
	public var vect10:Vector3f;

	public var vect4f1:Vector4f;
	public var vect4f2:Vector4f;

	/**
	 * 2D vector
	 */
	public var vect2d:Vector2f;
	public var vect2d2:Vector2f;
	/**
	 * General matrices.
	 */
	public var tempMat3:Matrix3f;
	public var tempMat4:Matrix4f;
	public var tempMat42:Matrix4f;
	/**
	 * General quaternions.
	 */
	public var quat1:Quaternion;
	public var quat2:Quaternion;

	/**
	 * Plane
	 */
	public var plane:Plane;

	/**
	 * BoundingBox ray collision
	 */
	//public var fWdU:Array<Float>;
	//public var fAWdU:Array<Float>;
	//public var fDdU:Array<Float>;
	//public var fADdU:Array<Float>;
	//public var fAWxDdU:Array<Float>;

	/**
	 * BIHTree
	 */
	//public var bihSwapTmp:Array<Float>;
	//public var bihStack:Array<BIHStackData>;

	//public var spatialStack:Array<Spatial>;

	public var bbox:BoundingBox;

	public function new() {
		isUsed = false;

		triangle = new Triangle();

		color = new Color();

		vect1 = new Vector3f();
		vect2 = new Vector3f();
		vect3 = new Vector3f();
		vect4 = new Vector3f();
		vect5 = new Vector3f();
		vect6 = new Vector3f();
		vect7 = new Vector3f();
		vect8 = new Vector3f();
		vect9 = new Vector3f();
		vect10 = new Vector3f();

		vect4f1 = new Vector4f();
		vect4f2 = new Vector4f();

		vect2d = new Vector2f();
		vect2d2 = new Vector2f();

		tempMat3 = new Matrix3f();
		tempMat4 = new Matrix4f();
		tempMat42 = new Matrix4f();

		quat1 = new Quaternion();
		quat2 = new Quaternion();

		plane = new Plane();

		//fWdU = new Array<Float>(3);
		//fAWdU = new Array<Float>(3);
		//fDdU = new Array<Float>(3);
		//fADdU = new Array<Float>(3);
		//fAWxDdU = new Array<Float>(3);

		//bihSwapTmp= new Array<Float>(9);
		//bihStack = new Array<BIHStackData>();

		//spatialStack = new Array<Spatial>();

		bbox = new BoundingBox();
	}

	public inline function release():Void {
		#if debug
		Assert.assert(isUsed, "This instance of TempVars was already released!");
		#end

		isUsed = false;
		currentIndex--;

		#if debug
		Assert.assert(varStack[currentIndex] == this, "An instance of TempVars has not been released in a called method!");
		#end
	}
}

