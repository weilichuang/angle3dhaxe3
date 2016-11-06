package org.angle3d.shadow;
import flash.Vector;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.queue.GeometryList;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.debug.WireFrustum;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.TempVars;

/**
 * PointLightShadowRenderer renders shadows for a point light
 *
 */
class PointLightShadowRenderer extends AbstractShadowRenderer
{
    public static inline var CAM_NUMBER:Int = 6;
	
    private var light:PointLight;
    private var shadowCams:Vector<Camera>;
    private var frustums:Vector<Geometry>;
	
	private var X_AXIS:Vector3f = new Vector3f(1, 0, 0);
	private var INV_X_AXIS:Vector3f = new Vector3f( -1, 0, 0);
	private var Y_AXIS:Vector3f = new Vector3f( 0, 1, 0);
	private var INV_Y_AXIS:Vector3f = new Vector3f( 0, -1, 0);
	private var Z_AXIS:Vector3f = new Vector3f(0, 0, 1);
	private var INV_Z_AXIS:Vector3f = new Vector3f( 0, 0, -1);
	
	private var geometryFrustums:Vector<Geometry>;
	private var points2:Vector<Vector3f>;

    /**
     * Creates a PointLightShadowRenderer
     *
     * @param shadowMapSize the size of the rendered shadowmaps (256,512,1024,2048,etc...)
     */
    public function new(shadowMapSize:Int)
	{
        super(shadowMapSize, CAM_NUMBER);
        initPointLight(shadowMapSize);
    }

    private function initPointLight(shadowMapSize:Int):Void
	{
        shadowCams = new Vector<Camera>(CAM_NUMBER, true);
        for (i in 0...CAM_NUMBER)
		{
            shadowCams[i] = new Camera(shadowMapSize, shadowMapSize);
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
        //bottom
        shadowCams[0].setAxes(INV_X_AXIS, INV_Z_AXIS, INV_Y_AXIS);

        //top
        shadowCams[1].setAxes(INV_X_AXIS, Z_AXIS, Y_AXIS);

        //forward
        shadowCams[2].setAxes(INV_X_AXIS, Y_AXIS, INV_Z_AXIS);

        //backward
        shadowCams[3].setAxes(X_AXIS, Y_AXIS, Z_AXIS);

        //left
        shadowCams[4].setAxes(Z_AXIS, Y_AXIS, INV_X_AXIS);

        //right
        shadowCams[5].setAxes(INV_Z_AXIS, Y_AXIS, X_AXIS);

        for (i in 0...CAM_NUMBER)
		{
            shadowCams[i].setFrustumPerspective(90, 1, 0.1, light.radius);
            shadowCams[i].setLocation(light.position);
            shadowCams[i].update();
            //shadowCams[i].updateViewProjection();
        }
	}
	
	override function getOccludersToRender(shadowMapIndex:Int, sceneOccluders:GeometryList):GeometryList 
	{
		var scenes:Vector<Spatial> = viewPort.getScenes();
		for (i in 0...scenes.length)
		{
			var scene:Spatial = scenes[i];
            ShadowUtil.getGeometriesInCamFrustumFromScene(scene, shadowCams[shadowMapIndex], ShadowMode.Cast, shadowMapOccluders);
        }
        return shadowMapOccluders;
	}
	
	override public function getReceivers(lightReceivers:GeometryList):Void 
	{
		lightReceivers.clear();
        var scenes:Vector<Spatial> = viewPort.getScenes();
		for (i in 0...scenes.length)
		{
			var scene:Spatial = scenes[i];
            ShadowUtil.getLitGeometriesInViewPort(scene, viewPort.getCamera(), shadowCams, ShadowMode.Receive, lightReceivers);
        }
	}
	
	override function getShadowCam(shadowMapIndex:Int):Camera 
	{
		return shadowCams[shadowMapIndex];
	}
	
	override function doDisplayFrustumDebug(shadowMapIndex:Int):Void 
	{
		if (points2 == null)
		{
			points2 = new Vector<Vector3f>(8);
			for (i in 0...8)
			{
				points2[i] = new Vector3f();
			}
		}
		
		if (geometryFrustums == null)
		{
			geometryFrustums = new Vector<Geometry>(6);
		}
		
		
		ShadowUtil.updateFrustumPoints2(shadowCams[shadowMapIndex], points2);
		
		var scenes:Vector<Spatial> = viewPort.getScenes();
		
		if (geometryFrustums[shadowMapIndex] == null)
		{
			var scene:Node = cast scenes[0];
			
			geometryFrustums[shadowMapIndex] = createFrustum(points2, shadowMapIndex);
			scene.attachChild(geometryFrustums[shadowMapIndex]);
			scene.updateGeometricState();
		}
		else
		{
			cast(geometryFrustums[shadowMapIndex].getMesh(),WireFrustum).buildWireFrustum(points2);
		}
	}
	
	override private function removeFrustumDebug(shadowMapIndex:Int):Void
	{
		if (geometryFrustums == null || geometryFrustums.length == 0 || geometryFrustums[shadowMapIndex] == null)
			return;
			
		geometryFrustums[shadowMapIndex].removeFromParent();
		geometryFrustums[shadowMapIndex] = null;
	}
	
	override function setMaterialParameters(material:Material):Void 
	{
		material.setVector3("u_LightPos", light.position);
	}

    override function clearMaterialParameters(material:Material):Void 
	{
		material.clearParam("u_LightPos");
	}
    
    /**
     * gets the point light used to cast shadows with this processor
     *
     * @return the point light
     */
    public function getLight():PointLight 
	{
        return light;
    }

    /**
     * sets the light to use for casting shadows with this processor
     *
     * @param light the point light
     */
    public function setLight(light:PointLight):Void 
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
