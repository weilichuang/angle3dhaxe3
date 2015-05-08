package org.angle3d.shadow;
import flash.Vector;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.queue.GeometryList;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
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
		if (light == null)
		{
            throw "The light can't be null for a PointLightShadowRenderer";
        }

        //bottom
        shadowCams[0].setAxes(Vector3f.X_AXIS.scale(-1), Vector3f.Z_AXIS.scale(-1), Vector3f.Y_AXIS.scale(-1));

        //top
        shadowCams[1].setAxes(Vector3f.X_AXIS.scale(-1), Vector3f.Z_AXIS, Vector3f.Y_AXIS);

        //forward
        shadowCams[2].setAxes(Vector3f.X_AXIS.scale(-1), Vector3f.Y_AXIS, Vector3f.Z_AXIS.scale(-1));

        //backward
        shadowCams[3].setAxes(Vector3f.X_AXIS, Vector3f.Y_AXIS, Vector3f.Z_AXIS);

        //left
        shadowCams[4].setAxes(Vector3f.Z_AXIS, Vector3f.Y_AXIS, Vector3f.X_AXIS.scale(-1));

        //right
        shadowCams[5].setAxes(Vector3f.Z_AXIS.scale(-1), Vector3f.Y_AXIS, Vector3f.X_AXIS);

        for (i in 0...CAM_NUMBER)
		{
            shadowCams[i].setFrustumPerspective(90, 1, 0.1, light.radius);
            shadowCams[i].setLocation(light.position);
            shadowCams[i].update();
            shadowCams[i].updateViewProjection();
        }
	}
	
	override function getOccludersToRender(shadowMapIndex:Int, sceneOccluders:GeometryList):GeometryList 
	{
		for (scene in viewPort.getScenes())
		{
            ShadowUtil.getGeometriesInCamFrustum2(scene, shadowCams[shadowMapIndex], ShadowMode.Cast, shadowMapOccluders);
        }
        return shadowMapOccluders;
	}
	
	override public function getReceivers(lightReceivers:GeometryList):Void 
	{
		lightReceivers.clear();
        for (scene in viewPort.getScenes())
		{
            ShadowUtil.getLitGeometriesInViewPort(scene, viewPort.getCamera(), shadowCams, ShadowMode.Receive, lightReceivers);
        }
	}
	
	override function getShadowCam(shadowMapIndex:Int):Camera 
	{
		return shadowCams[shadowMapIndex];
	}
	
	override function doDisplayFrustumDebug(shadowMapIndex:Int):Void 
	{
		if (frustums == null) 
		{
            frustums = new Vector<Geometry>(CAM_NUMBER);
            var points:Vector<Vector3f> = new Vector<Vector3f>(8);
            for (i in 0...8)
			{
                points[i] = new Vector3f();
            }
            for (i in 0...CAM_NUMBER) 
			{
                ShadowUtil.updateFrustumPoints2(shadowCams[i], points);
                frustums[i] = createFrustum(points, i);
            }
        }
        if (frustums[shadowMapIndex].getParent() == null)
		{
            cast(viewPort.getScenes()[0],Node).attachChild(frustums[shadowMapIndex]);
        }
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
        var vars:TempVars = TempVars.get();
        var intersects:Bool = light.intersectsFrustum(cam,vars);
        vars.release();
        return intersects;
	}
}
