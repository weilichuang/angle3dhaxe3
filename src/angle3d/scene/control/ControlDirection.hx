package angle3d.scene.control;

/**
 * ...
 * @author
 */
enum ControlDirection {
	/**
	 * Means, that the Camera's transform is "copied"
	 * to the Transform of the Spatial.
	 */
	CameraToSpatial;
	/**
	 * Means, that the Spatial's transform is "copied"
	 * to the Transform of the Camera.
	 */
	SpatialToCamera;
}