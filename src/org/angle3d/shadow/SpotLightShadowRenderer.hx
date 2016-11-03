package org.angle3d.shadow;
import flash.Vector;
import org.angle3d.light.SpotLight;
import org.angle3d.material.Material;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.queue.GeometryList;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;
import org.angle3d.scene.debug.WireFrustum;

/**
 * SpotLightShadowRenderer renderer use Parrallel Split Shadow Mapping technique
 * (pssm)<br> It splits the view frustum in several parts and compute a shadow
 * map for each one.<br> splits are distributed so that the closer they are from
 * the camera, the smaller they are to maximize the resolution used of the
 * shadow map.<br> This result in a better quality shadow than standard shadow
 * mapping.<br> for more informations on this read this <a
 * href="http://http.developer.nvidia.com/GPUGems3/gpugems3_ch10.html">http://http.developer.nvidia.com/GPUGems3/gpugems3_ch10.html</a><br>
 * <p/>
 */
class SpotLightShadowRenderer extends AbstractShadowRenderer
{
    private var light:SpotLight;
    private var shadowCam:Camera;
    private var points:Vector<Vector3f>;

    /**
     * Creates a SpotLightShadowRenderer
     *
     * @param shadowMapSize the size of the rendered shadowmaps (512,1024,2048,etc...)
     */
    public function new(shadowMapSize:Int)
	{
        super(shadowMapSize, 1);
        initSpotLight(shadowMapSize);
    }

    private function initSpotLight(shadowMapSize:Int):Void
	{
        shadowCam = new Camera(shadowMapSize, shadowMapSize);
		points = new Vector<Vector3f>(8, true);
        for (i in 0...8)
		{
            points[i] = new Vector3f();
        }
    }
	
	override function initFrustumCam():Void 
	{
		var viewCam:Camera = viewPort.getCamera();
        frustumCam = viewCam.clone("frustumCam");
        frustumCam.setFrustum(viewCam.frustumNear, zFarOverride, viewCam.frustumLeft, viewCam.frustumRight, viewCam.frustumTop, viewCam.frustumBottom);
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

        shadowCam.setFrustumPerspective(light.outerAngle * FastMath.RAD_TO_DEG * 2.0, 1, 1, light.spotRange);
        shadowCam.getRotation().lookAt(light.direction, shadowCam.getUp());
        shadowCam.setLocation(light.position);

        shadowCam.update();
	}
	
	override function getOccludersToRender(shadowMapIndex:Int, sceneOccluders:GeometryList):GeometryList 
	{
		var spatials:Vector<Spatial> = viewPort.getScenes();
		for (i in 0...spatials.length)
		{
            ShadowUtil.getGeometriesInCamFrustumFromScene(spatials[i], shadowCam, ShadowMode.Cast, shadowMapOccluders);
        }
        return shadowMapOccluders;
	}
	
	override public function getReceivers(lightReceivers:GeometryList):Void 
	{
		lightReceivers.clear();
		
		var cameras:Vector<Camera> = new Vector<Camera>(1);
        cameras[0] = shadowCam;
        var spatials:Vector<Spatial> = viewPort.getScenes();
		for (i in 0...spatials.length)
		{
            ShadowUtil.getLitGeometriesInViewPort(spatials[i], viewPort.getCamera(), cameras, ShadowMode.Receive, lightReceivers);
        }
	}
	
	override function getShadowCam(shadowMapIndex:Int):Camera 
	{
		return shadowCam;
	}
	
	private var geometryFrustum:Geometry;
	private var points2:Vector<Vector3f>;
	override function doDisplayFrustumDebug(shadowMapIndex:Int):Void 
	{
		if (points2 == null)
		{
			points2 = new Vector<Vector3f>(8);
			for (i in 0...8)
			{
				points2[i] = points[i].clone();
			}
		}
		
		ShadowUtil.updateFrustumPoints2(shadowCam, points2);
		
		var scenes:Vector<Spatial> = viewPort.getScenes();
		
		if (geometryFrustum == null)
		{
			var scene:Node = cast scenes[0];
			
			geometryFrustum = createFrustum(points2, shadowMapIndex);
			scene.attachChild(geometryFrustum);
			scene.updateGeometricState();
		}
		else
		{
			cast(geometryFrustum.getMesh(),WireFrustum).buildWireFrustum(points2);
		}
	}
	
	override private function removeFrustumDebug(shadowMapIndex:Int):Void
	{
		if (geometryFrustum != null)
		{
			geometryFrustum.removeFromParent();
			geometryFrustum = null;
			points2 = null;
		}
	}
	
	override function setMaterialParameters(material:Material):Void 
	{
		material.setVector3("u_LightPos", light.position);
		material.setVector3("u_LightDir", light.direction);
	}

    override function clearMaterialParameters(material:Material):Void 
	{
		material.clearParam("u_LightPos");
		material.clearParam("u_LightDir");
	}
	
	public function setFallOff(value:Bool):Void
	{
		postshadowMat.setBoolean("u_FallOff", value);
	}
    
    /**
     * gets the point light used to cast shadows with this processor
     *
     * @return the point light
     */
    public inline function getLight():SpotLight 
	{
        return light;
    }

    /**
     * sets the light to use for casting shadows with this processor
     *
     * @param light the point light
     */
    public function setLight(light:SpotLight):Void 
	{
        this.light = light;
    }
	
	override function checkCulling(viewCam:Camera):Bool 
	{
		var cam:Camera = viewCam;
        if (frustumCam != null)
		{
            cam = frustumCam;            
            cam.setLocation(viewCam.getLocation());
            cam.setRotation(viewCam.getRotation());
        }
        return light.intersectsFrustum(cam);
	}
}
