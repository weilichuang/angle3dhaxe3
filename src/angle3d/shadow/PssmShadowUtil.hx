package angle3d.shadow;

import angle3d.bounding.BoundingBox;
import angle3d.math.Matrix4f;
import angle3d.renderer.Camera;
import angle3d.renderer.queue.GeometryList;

/**
 * Includes various useful shadow mapping functions.
 *
 * @see
 * <ul>
 * <li><a href="http://appsrv.cse.cuhk.edu.hk/~fzhang/pssm_vrcia/">http://appsrv.cse.cuhk.edu.hk/~fzhang/pssm_vrcia/</a></li>
 * <li><a href="http://http.developer.nvidia.com/GPUGems3/gpugems3_ch10.html">http://http.developer.nvidia.com/GPUGems3/gpugems3_ch10.html</a></li>
 * </ul>
 * for more info.
 */
class PssmShadowUtil {

	/**
	 * Updates the frustum splits stores in `splits` using PSSM.
	 */
	public static function updateFrustumSplits(splits:Array<Float>, near:Float, far:Float, lambda:Float):Void {
		for (i in 0...splits.length) {
			var IDM:Float = i / splits.length;
			var log:Float = near * Math.pow((far / near), IDM);
			var uniform:Float = near + (far - near) * IDM;
			splits[i] = log * lambda + uniform * (1.0 - lambda);
		}

		// This is used to improve the correctness of the calculations. Our main near- and farplane
		// of the camera always stay the same, no matter what happens.
		splits[0] = near;
		splits[splits.length - 1] = far;
	}

	/**
	 * Compute the Zfar in the model vieuw to adjust the Zfar distance for the splits calculation
	 */
	public static function computeZFar(occ:GeometryList, recv:GeometryList, cam:Camera):Float {
		var mat:Matrix4f = cam.getViewMatrix();
		var bbOcc:BoundingBox = ShadowUtil.computeUnionBoundForMatrix4(occ, mat);
		var bbRecv:BoundingBox = ShadowUtil.computeUnionBoundForMatrix4(recv, mat);

		return Math.min(Math.max(bbOcc.zExtent - bbOcc.getCenter().z, bbRecv.zExtent - bbRecv.getCenter().z), cam.frustumFar);
	}

}