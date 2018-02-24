package angle3d.scene.control;
import angle3d.bounding.BoundingBox;
import angle3d.bounding.BoundingSphere;
import angle3d.bounding.BoundingVolume;
import angle3d.bounding.BoundingVolumeType;

/**
 * AreaUtils is used to calculate the area of various objects, such as bounding volumes.
 * These functions are very loose approximations.
 */
class AreaUtils {

	/**
	* Estimate the screen area of a bounding volume. If the volume isn't a
	* BoundingSphere, BoundingBox, or OrientedBoundingBox, 0 is returned.
	*
	* @param bound The bounds to calculate the volume from.
	* @param distance The distance from camera to object.
	* @param screenWidth The width of the screen.
	* @return The area in pixels on the screen of the bounding volume.
	*/
	public static function calcScreenArea(bound:BoundingVolume, distance:Float, screenWidth:Float):Float {
		if (bound.type == BoundingVolumeType.Sphere) {
			return calcScreenAreaSphere(cast bound, distance, screenWidth);
		} else if (bound.type == BoundingVolumeType.AABB) {
			return calcScreenAreaBox(cast bound, distance, screenWidth);
		}
		return 0.0;
	}

	private static function calcScreenAreaSphere(bound:BoundingSphere, distance:Float, screenWidth:Float):Float {
		// Where is the center point and a radius point that lies in a plan parallel to the view plane?
		//    // Calc radius based on these two points and plug into circle area formula.
		//    Vector2f centerSP = null;
		//    Vector2f outerSP = null;
		//    float radiusSq = centerSP.subtract(outerSP).lengthSquared();
		var radius:Float = (bound.radius * screenWidth) / (distance * 2);
		return radius * radius * Math.PI;
	}

	private static function calcScreenAreaBox(bound:BoundingBox, distance:Float, screenWidth:Float):Float {
		// Calc as if we are a BoundingSphere for now...
		var radiusSquare:Float = bound.xExtent * bound.xExtent
		+ bound.yExtent * bound.yExtent
		+ bound.zExtent * bound.zExtent;
		return ((radiusSquare * screenWidth * screenWidth) / (distance * distance * 4)) * Math.PI;
	}

}