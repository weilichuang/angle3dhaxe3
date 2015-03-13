package org.angle3d.shadow;

import flash.Vector;
import org.angle3d.material.Material;
import org.angle3d.math.Vector3f;
import org.angle3d.post.SceneProcessor;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.IRenderer;
import org.angle3d.renderer.queue.GeometryList;
import org.angle3d.renderer.queue.OpaqueComparator;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.ui.Picture;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.texture.BitmapTexture;

/**
 * BasicShadowRenderer uses standard shadow mapping with one map
 * it's useful to render shadows in a small scene, but edges might look a bit jagged.
 */
class BasicShadowRenderer implements SceneProcessor
{
	private var renderManager:RenderManager;
    private var viewPort:ViewPort;
    private var shadowFB:FrameBuffer;
    private var shadowMap:Texture2D;
    private var shadowCam:Camera;
    private var preshadowMat:Material;
    private var postshadowMat:Material;
    private var dispPic:Picture;
    private var noOccluders:Bool = false;
    private var points:Vector<Vector3f>;
    private var direction:Vector3f;
    private var shadowMapSize:Int;

    private var lightReceivers:GeometryList;
    private var shadowOccluders:GeometryList;

	public function new(size:Int) 
	{
		direction = new Vector3f();
		
		lightReceivers = new GeometryList(new OpaqueComparator());
		shadowOccluders = new GeometryList(new OpaqueComparator());
		
		shadowFB = new FrameBuffer(size, size, 1);
        //shadowMap = new Texture2D(size, size);
        shadowFB.setDepthTexture(shadowMap);
        shadowCam = new Camera(size, size);
              
        shadowMapSize = size;
        preshadowMat = new Material();
		preshadowMat.load("assets/material/preshadow.mat");
		
        postshadowMat = new Material();
		postshadowMat.load("assets/material/basicPostShadow.mat");
        postshadowMat.setTexture("ShadowMap", shadowMap);
		
		dispPic = new Picture("Picture");
		dispPic.setTexture(shadowMap, false);

		points = new Vector<Vector3f>(8);
        for (i in 0...8)
		{
            points[i] = new Vector3f();
        }
	}
	
	public function initialize(rm:RenderManager, vp:ViewPort):Void 
	{
		renderManager = rm;
        viewPort = vp;

        reshape(vp, vp.getCamera().width, vp.getCamera().height);
	}
	
	public function isInitialized():Bool 
	{
		return viewPort != null;
	}
	
	/**
     * returns the light direction used for this processor
     * @return 
     */
    public function getDirection():Vector3f 
	{
        return direction;
    }

    /**
     * sets the light direction to use to computs shadows
     * @param direction 
     */
    public function setDirection(direction:Vector3f):Void
	{
        this.direction.copyFrom(direction).normalizeLocal();
    }
	
	public function getPoints():Vector<Vector3f> 
	{
        return points;
    }
	
	public function getShadowCamera():Camera 
	{
        return shadowCam;
    }
	
	public function getDisplayPicture():Picture
	{
        return dispPic;
    }
	
	public function reshape(vp:ViewPort, w:Int, h:Int):Void 
	{
		dispPic.setPosition(w / 20, h / 20);
        dispPic.setWidth(w / 5);
        dispPic.setHeight(h / 5);
	}
	
	public function preFrame(tpf:Float):Void 
	{
		
	}
	
	public function postQueue(rq:RenderQueue):Void 
	{
		for (scene in viewPort.getScenes()) 
		{
            ShadowUtil.getGeometriesInCamFrustum(scene, viewPort.getCamera(), ShadowMode.Receive, lightReceivers);
        }

        // update frustum points based on current camera
        var viewCam:Camera = viewPort.getCamera();
        ShadowUtil.updateFrustumPoints(viewCam,
                viewCam.getFrustumNear(),
                viewCam.getFrustumFar(),
                1.0,
                points);

        var frustaCenter:Vector3f = new Vector3f();
        for (point in points) 
		{
            frustaCenter.addLocal(point);
        }
        frustaCenter.multLocal(1 / 8);

        // update light direction
        shadowCam.setProjectionMatrix(null);
        shadowCam.setParallelProjection(true);
//        shadowCam.setFrustumPerspective(45, 1, 1, 20);

        shadowCam.lookAtDirection(direction, Vector3f.Y_AXIS);
        shadowCam.update();
        shadowCam.setLocation(frustaCenter);
        shadowCam.update();
        shadowCam.updateViewProjection();

        // render shadow casters to shadow map
        ShadowUtil.updateShadowCamera(viewPort, lightReceivers, shadowCam, points, shadowOccluders, shadowMapSize);
        if (shadowOccluders.size == 0) 
		{
            noOccluders = true;
            return;
        } 
		else 
		{
            noOccluders = false;
        }            
        
        var r:IRenderer = renderManager.getRenderer();
        renderManager.setCamera(shadowCam, false);
        renderManager.setForcedMaterial(preshadowMat);

        r.setFrameBuffer(shadowFB);
        r.clearBuffers(false, true, false);
        viewPort.getQueue().renderShadowQueue(shadowOccluders, renderManager, shadowCam, true);
        r.setFrameBuffer(viewPort.getOutputFrameBuffer());

        renderManager.setForcedMaterial(null);
        renderManager.setCamera(viewCam, false);
	}
	
	public function postFrame(out:FrameBuffer):Void 
	{
		if (!noOccluders)
		{
            postshadowMat.setMatrix4("LightViewProjectionMatrix", shadowCam.getViewProjectionMatrix());
            renderManager.setForcedMaterial(postshadowMat);
            viewPort.getQueue().renderShadowQueue(lightReceivers, renderManager, viewPort.getCamera(), true);
            renderManager.setForcedMaterial(null);
        }
	}
	
	public function cleanup():Void 
	{
		
	}
	
}