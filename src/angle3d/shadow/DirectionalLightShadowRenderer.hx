package angle3d.shadow;

import angle3d.light.DirectionalLight;
import angle3d.material.Material;
import angle3d.math.Color;
import angle3d.math.FastMath;
import angle3d.math.Vector3f;
import angle3d.math.Vector4f;
import angle3d.renderer.Camera;
import angle3d.renderer.queue.GeometryList;
import angle3d.renderer.queue.ShadowMode;
import angle3d.scene.debug.WireFrustum;
import angle3d.scene.Geometry;
import angle3d.scene.Node;
import angle3d.scene.Spatial;

/**
 * DirectionalLightShadowRenderer renderer use Parrallel Split Shadow Mapping
 * technique (pssm)<br> It splits the view frustum in several parts and compute
 * a shadow map for each one.<br> splits are distributed so that the closer they
 * are from the camera, the smaller they are to maximize the resolution used of
 * the shadow map.<br> This result in a better quality shadow than standard
 * shadow mapping.<br> for more informations on this read this <a
 * href="http://http.developer.nvidia.com/GPUGems3/gpugems3_ch10.html">http://http.developer.nvidia.com/GPUGems3/gpugems3_ch10.html</a><br>
 * <p/>
 */
class DirectionalLightShadowRenderer extends AbstractShadowRenderer {
	private var lambda:Float = 0.65;
	private var shadowCam:Camera;
	private var splits:Vector4f;
	private var splitsArray:Array<Float>;
	private var light:DirectionalLight;
	private var points:Array<Vector3f>;
	//Holding the info for fading shadows in the far distance
	private var stabilize:Bool = true;
	private var checkCasterCulling:Bool = true;
	/**
	 * Create a DirectionalLightShadowRenderer More info on the technique at <a
	 * href="http://http.developer.nvidia.com/GPUGems3/gpugems3_ch10.html">http://http.developer.nvidia.com/GPUGems3/gpugems3_ch10.html</a>
	 *
	 * @param assetManager the application asset manager
	 * @param shadowMapSize the size of the rendered shadowmaps (512,1024,2048,
	 * etc...)
	 * @param nbSplits the number of shadow maps rendered (the more shadow maps
	 * the more quality, the less fps).
	 */
	public function new(shadowMapSize:Int,nbSplits:Int) {
		super(shadowMapSize, nbSplits);
		initDirectionalLightMap(nbSplits, shadowMapSize);
	}

	private function initDirectionalLightMap(nbSplits:Int, shadowMapSize:Int):Void {
		nbShadowMaps = FastMath.maxInt(FastMath.minInt(nbSplits, 4), 1);
		if (nbShadowMaps != nbSplits) {
			throw 'Number of splits must be between 1 and 4. Given value : ${nbSplits}';
		}

		splits = new Vector4f(0, 0, 0, 0);
		splitsArray = new Array<Float>(nbSplits + 1);
		shadowCam = new Camera(shadowMapSize, shadowMapSize);
		shadowCam.setParallelProjection(true);

		points = new Array<Vector3f>(8,true);
		for (i in 0...8) {
			points[i] = new Vector3f();
		}
	}

	/**
	 * return the light used to cast shadows
	 *
	 * @return the DirectionalLight
	 */
	public function getLight():DirectionalLight {
		return light;
	}

	/**
	 * Sets the light to use to cast shadows
	 *
	 * @param light a DirectionalLight
	 */
	public function setLight(light:DirectionalLight):Void {
		this.light = light;
	}

	override function updateShadowCams(viewCam:Camera):Void {
		var zFar:Float = zFarOverride;
		if (zFar == 0) {
			zFar = viewCam.frustumFar;
		}

		//We prevent computing the frustum points and splits with zeroed or negative near clip value
		var frustumNear:Float = Math.max(viewCam.frustumNear, 0.001);
		ShadowUtil.updateFrustumPoints(viewCam, frustumNear, zFar, 1.0, points);

		shadowCam.frustumFar = zFar;
		shadowCam.getRotation().lookAt(light.direction, shadowCam.getUp());
		shadowCam.update();
		//shadowCam.updateViewProjection();

		PssmShadowUtil.updateFrustumSplits(splitsArray, frustumNear, zFar, lambda);

		// in parallel projection shadow position goe from 0 to 1
		if (viewCam.isParallelProjection()) {
			var distance:Float = zFar - frustumNear;
			for (i in 0...nbShadowMaps) {
				splitsArray[i] = splitsArray[i] / distance;
			}
		}

		var arrLen:Int = splitsArray.length;
		if (arrLen >= 5) {
			splits.w = splitsArray[4];
		}

		if (arrLen >= 4) {
			splits.z = splitsArray[3];
		}

		if (arrLen >= 3) {
			splits.y = splitsArray[2];
		}

		if (arrLen >= 2) {
			splits.x = splitsArray[1];
		}
	}

	override function getOccludersToRender(shadowMapIndex:Int, sceneOccluders:GeometryList):GeometryList {
		// update frustum points based on current camera and split
		ShadowUtil.updateFrustumPoints(viewPort.getCamera(), splitsArray[shadowMapIndex], splitsArray[shadowMapIndex + 1], 1.0, points);

		//Updating shadow cam with curent split frustra
		if (lightReceivers.size == 0) {
			var scenes:Array<Spatial> = viewPort.getScenes();
			var camera:Camera = viewPort.getCamera();
			for (i in 0...scenes.length) {
				var scene:Spatial = scenes[i];
				ShadowUtil.getGeometriesInCamFrustumFromScene(scene, camera, ShadowMode.Receive, lightReceivers);
			}
		}
		ShadowUtil.updateShadowCameraFromViewPort(viewPort, lightReceivers, shadowCam, points, shadowMapOccluders, stabilize ? shadowMapSize : 0, checkCasterCulling);

		return shadowMapOccluders;
	}

	override public function getReceivers(lightReceivers:GeometryList):Void {
		if (lightReceivers.size == 0) {
			var scenes:Array<Spatial> = viewPort.getScenes();
			var camera:Camera = viewPort.getCamera();
			for (i in 0...scenes.length) {
				var scene:Spatial = scenes[i];
				ShadowUtil.getGeometriesInCamFrustumFromScene(scene, camera, ShadowMode.Receive, lightReceivers);
			}
		}
	}

	override function getShadowCam(shadowMapIndex:Int):Camera {
		return shadowCam;
	}

	private var geometryFrustums:Array<Geometry>;
	private var frustumPoints:Array<Vector3f>;
	override function doDisplayFrustumDebug(shadowMapIndex:Int):Void {
		if (frustumPoints == null) {
			frustumPoints = new Array<Vector3f>(8);
			for (i in 0...8) {
				frustumPoints[i] = points[i].clone();
			}
		}

		if (geometryFrustums == null) {
			geometryFrustums = new Array<Geometry>(this.nbShadowMaps);
		}

		ShadowUtil.updateFrustumPoints2(shadowCam, frustumPoints);

		var scenes:Array<Spatial> = viewPort.getScenes();

		if (geometryFrustums[shadowMapIndex] == null) {
			var scene:Node = cast scenes[0];

			geometryFrustums[shadowMapIndex] = createFrustum(frustumPoints, shadowMapIndex);
			scene.attachChild(geometryFrustums[shadowMapIndex]);
			scene.updateGeometricState();
		} else
		{
			cast(geometryFrustums[shadowMapIndex].getMesh(),WireFrustum).buildWireFrustum(frustumPoints);
		}
	}

	override private function removeFrustumDebug(shadowMapIndex:Int):Void {
		if (geometryFrustums == null || geometryFrustums.length == 0 || geometryFrustums[shadowMapIndex] == null)
			return;

		geometryFrustums[shadowMapIndex].removeFromParent();
		geometryFrustums[shadowMapIndex] = null;
	}

	override function setMaterialParameters(material:Material):Void {
		material.setVector4("u_Splits", splits);
		material.setVector3("u_LightDir", light.direction);
		if (fadeInfo != null) {
			material.setVector2("u_FadeInfo", fadeInfo);
		}
	}

	override function clearMaterialParameters(material:Material):Void {
		material.clearParam("u_Splits");
		material.clearParam("u_FadeInfo");
		material.clearParam("u_LightDir");
	}

	/**
	 * returns the labda parameter see #setLambda(float lambda)
	 *
	 * @return lambda
	 */
	public function getLambda():Float {
		return lambda;
	}

	/*
	 * Adjust the repartition of the different shadow maps in the shadow extend
	 * usualy goes from 0.0 to 1.0
	 * a low value give a more linear repartition resulting in a constant quality in the shadow over the extends, but near shadows could look very jagged
	 * a high value give a more logarithmic repartition resulting in a high quality for near shadows, but the quality quickly decrease over the extend.
	 * the default value is set to 0.65f (theoric optimal value).
	 * @param lambda the lambda value.
	 */
	public function setLambda(lambda:Float):Void {
		this.lambda = lambda;
	}

	/**
	 * retruns true if stabilization is enabled
	 * @return
	 */
	public function isEnabledStabilization():Bool {
		return stabilize;
	}

	/**
	 * Enables the stabilization of the shadows's edges. (default is true)
	 * This prevents shadows' edges to flicker when the camera moves
	 * However it can lead to some shadow quality loss in some particular scenes.
	 * @param stabilize
	 */
	public function setEnabledStabilization(stabilize:Bool):Void {
		this.stabilize = stabilize;
	}

	/**
	 * Directional light are always in the view frustum
	 * @param viewCam
	 * @return
	 */
	override function checkCulling(viewCam:Camera):Bool {
		return true;
	}

	public function setCheckCasterCulling(value:Bool):Void {
		this.checkCasterCulling = value;
	}

	public function isCheckCasterCulling():Bool {
		return this.checkCasterCulling;
	}
}