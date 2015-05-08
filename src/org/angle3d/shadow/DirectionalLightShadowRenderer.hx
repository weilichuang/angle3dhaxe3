package org.angle3d.shadow;
import flash.Vector;
import org.angle3d.light.DirectionalLight;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.queue.GeometryList;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;

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
class DirectionalLightShadowRenderer extends AbstractShadowRenderer
{
	private var lambda:Float = 0.65;    
    private var shadowCam:Camera;
    private var splits:Color;
    private var splitsArray:Vector<Float>;
    private var light:DirectionalLight;
    private var points:Vector<Vector3f>;
    //Holding the info for fading shadows in the far distance   
    private var stabilize:Bool = true;

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
	public function new(shadowMapSize:Int,nbSplits:Int) 
	{
		super(shadowMapSize, nbSplits);
		initDirectionalLightMap(nbSplits, shadowMapSize);
	}
	
	private function initDirectionalLightMap(nbSplits:Int, shadowMapSize:Int):Void
	{
		nbShadowMaps = FastMath.maxInt(FastMath.minInt(nbSplits, 4), 1);
        if (nbShadowMaps != nbSplits)
		{
            throw 'Number of splits must be between 1 and 4. Given value : ${nbSplits}';
        }
		
        splits = new Color();
        splitsArray = new Vector<Float>(nbSplits + 1);
        shadowCam = new Camera(shadowMapSize, shadowMapSize);
        shadowCam.setParallelProjection(true);
		
		points = new Vector<Vector3f>(8,true);
        for (i in 0...8)
		{
            points[i] = new Vector3f();
        }
	}
	
	/**
     * return the light used to cast shadows
     *
     * @return the DirectionalLight
     */
    public function getLight():DirectionalLight
	{
        return light;
    }

    /**
     * Sets the light to use to cast shadows
     *
     * @param light a DirectionalLight
     */
    public function setLight(light:DirectionalLight):Void
	{
        this.light = light;
    }

	override function updateShadowCams(viewCam:Camera):Void 
	{
        var zFar:Float = zFarOverride;
        if (zFar == 0) 
		{
            zFar = viewCam.frustumFar;
        }

        //We prevent computing the frustum points and splits with zeroed or negative near clip value
        var frustumNear:Float = Math.max(viewCam.frustumNear, 0.001);
        ShadowUtil.updateFrustumPoints(viewCam, frustumNear, zFar, 1.0, points);

        //shadowCam.setDirection(direction);
        shadowCam.getRotation().lookAt(light.direction, shadowCam.getUp());
        shadowCam.update();
        shadowCam.updateViewProjection();

        PssmShadowUtil.updateFrustumSplits(splitsArray, frustumNear, zFar, lambda);

        // in parallel projection shadow position goe from 0 to 1
        if (viewCam.isParallelProjection())
		{
			var distance:Float = zFar - frustumNear;
            for (i in 0...nbShadowMaps)
			{
                splitsArray[i] = splitsArray[i] / distance;
            }
        }

        switch (splitsArray.length) 
		{
            case 5:
                splits.a = splitsArray[4];
            case 4:
                splits.b = splitsArray[3];
            case 3:
                splits.g = splitsArray[2];
            case 2,1:
                splits.r = splitsArray[1];
        }

    }
    
	override function getOccludersToRender(shadowMapIndex:Int, sceneOccluders:GeometryList):GeometryList 
	{
        // update frustum points based on current camera and split
        ShadowUtil.updateFrustumPoints(viewPort.getCamera(), splitsArray[shadowMapIndex], splitsArray[shadowMapIndex + 1], 1.0, points);

        //Updating shadow cam with curent split frustra
        if (lightReceivers.size == 0) 
		{
            for (scene in viewPort.getScenes())
			{
				ShadowUtil.getGeometriesInCamFrustum2(scene, viewPort.getCamera(), ShadowMode.Receive, lightReceivers);
            }
        }
        ShadowUtil.updateShadowCamera2(viewPort, lightReceivers, shadowCam, points, shadowMapOccluders, stabilize?shadowMapSize:0);

        return shadowMapOccluders;
    }

	override public function getReceivers(lightReceivers:GeometryList):Void 
	{
		if (lightReceivers.size == 0)
		{
            for (scene in viewPort.getScenes())
			{
                ShadowUtil.getGeometriesInCamFrustum2(scene, viewPort.getCamera(), ShadowMode.Receive, lightReceivers);
            }
        }
	}

	override function getShadowCam(shadowMapIndex:Int):Camera 
	{
		return shadowCam;
	}

	override function doDisplayFrustumDebug(shadowMapIndex:Int):Void 
	{
		var scenes:Vector<Spatial> = viewPort.getScenes();
		cast(scenes[0], Node).attachChild(createFrustum(points, shadowMapIndex));
		ShadowUtil.updateFrustumPoints2(shadowCam, points);
		cast(scenes[0], Node).attachChild(createFrustum(points, shadowMapIndex));
	}

	override function setMaterialParameters(material:Material):Void 
	{
		material.setColor("u_Splits", splits);
        if (fadeInfo != null) 
		{
            material.setVector2("u_FadeInfo", fadeInfo);
        }
	}
	
	override function clearMaterialParameters(material:Material):Void 
	{
		material.clearParam("u_Splits");
        material.clearParam("u_FadeInfo");
	}

    /**
     * returns the labda parameter see #setLambda(float lambda)
     *
     * @return lambda
     */
    public function getLambda():Float
	{
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
    public function setLambda(lambda:Float):Void
	{
        this.lambda = lambda;
    }

    
    /**
     * retruns true if stabilization is enabled
     * @return 
     */
    public function isEnabledStabilization():Bool
	{
        return stabilize;
    }
    
    /**
     * Enables the stabilization of the shadows's edges. (default is true)
     * This prevents shadows' edges to flicker when the camera moves
     * However it can lead to some shadow quality loss in some particular scenes.
     * @param stabilize 
     */
    public function setEnabledStabilization(stabilize:Bool):Void
	{
        this.stabilize = stabilize;
    }
	
    /**
     * Directional light are always in the view frustum
     * @param viewCam
     * @return 
     */
	override function checkCulling(viewCam:Camera):Bool 
	{
		return true;
	}
}