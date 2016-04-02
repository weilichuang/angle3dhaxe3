package org.angle3d.shadow;

import flash.Vector;
import org.angle3d.material.Material;
import org.angle3d.texture.MipFilter;
import org.angle3d.texture.TextureFilter;
import org.angle3d.texture.WrapMode;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;
import org.angle3d.post.SceneProcessor;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.RendererBase;
import org.angle3d.renderer.queue.GeometryList;
import org.angle3d.renderer.queue.OpaqueComparator;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.ui.DepthMap;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.texture.Texture2D;

/**
 * BasicShadowRenderer uses standard shadow mapping with one map
 * it's useful to render shadows in a small scene, but edges might look a bit jagged.
 *
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
    private var dispPic:DepthMap;
    private var noOccluders:Bool = false;
    private var points:Vector<Vector3f>;
    private var direction:Vector3f;
    private var shadowMapSize:Int;

    private var lightReceivers:GeometryList;
    private var shadowOccluders:GeometryList;
	
	private var frustaCenter:Vector3f;
	
	private var shadowInfo:Vector4f;
	
	private var bgColor:Color;
	
	private var usePCF:Bool = false;
	
	/**
     * true if the fallback material should be used, otherwise false
     */
    private var needsfallBackMaterial:Bool = false;
	
	private var postTechniqueName:String = "basicPostShadow";
	
	private var lightViewProjectionMatrix:Matrix4f;
	
	private var biasMatrix:Matrix4f;

	public function new(size:Int) 
	{
		direction = new Vector3f();
		frustaCenter = new Vector3f();
		
		bgColor = new Color(1, 1, 1, 1);
		
		shadowInfo = new Vector4f(1.0, 0.5, 0.5, 1 / size);
		
		lightViewProjectionMatrix = new Matrix4f();
		
		biasMatrix = new Matrix4f();
		biasMatrix.setTo( 0.5, 0.0, 0.0, 0.5,
							  0.0, 0.5, 0.0, 0.5,
							  0.0, 0.0, 0.5, 0.5,
							  0.0, 0.0, 0.0, 1.0);
		
		lightReceivers = new GeometryList(new OpaqueComparator());
		shadowOccluders = new GeometryList(new OpaqueComparator());
		
		shadowFB = new FrameBuffer(size, size);
        shadowMap = new Texture2D(size, size, true);
		shadowMap.optimizeForRenderToTexture = true;
		shadowMap.textureFilter = TextureFilter.NEAREST;
		shadowMap.mipFilter = MipFilter.MIPNONE;
		shadowMap.wrapMode = WrapMode.CLAMP;
        shadowFB.addColorTexture(shadowMap);
        shadowCam = new Camera(size, size);
              
        shadowMapSize = size;
        preshadowMat = new Material();
		preshadowMat.load(Angle3D.materialFolder + "material/depth.mat");
		
        postshadowMat = new Material();
		postshadowMat.load(Angle3D.materialFolder + "material/basicPostShadow.mat");
        postshadowMat.setTexture("u_ShadowMap", shadowMap);
		postshadowMat.setVector4("u_ShaderInfo", shadowInfo);
		
		dispPic = new DepthMap("depthMap");
		dispPic.setTexture(shadowMap, false);

		points = new Vector<Vector3f>(8);
        for (i in 0...8)
		{
            points[i] = new Vector3f();
        }
	}
	
	/**
	 * 
	 * @param bias solves "Shadow Acne"
	 * @param percent shadow percent
	 * @param usePCF Percentage Closer Filter
	 */
	public function setShadowInfo(bias:Float, percent:Float, usePCF:Bool):Void
	{
		shadowInfo.x = bias;
		shadowInfo.y = FastMath.clamp(percent, 0, 1);
		shadowInfo.z = 1 - shadowInfo.y;
		shadowInfo.w = 1 / shadowMapSize;
		
		this.usePCF = usePCF;
		
		postshadowMat.setBoolean("u_UsePCF", usePCF);
		postshadowMat.setVector4("u_ShaderInfo", shadowInfo);
	}
	
	public function getPreShadowMaterial():Material
	{
		return preshadowMat;
	}
	
	public function getPostShadowMaterial():Material
	{
		return postshadowMat;
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
		this.direction = direction;
        this.direction.normalizeLocal();
    }
	
	public function getPoints():Vector<Vector3f> 
	{
        return points;
    }
	
	public function getShadowCamera():Camera 
	{
        return shadowCam;
    }
	
	public function getDisplayPicture():DepthMap
	{
        return dispPic;
    }
	
	public function reshape(vp:ViewPort, w:Int, h:Int):Void 
	{
		dispPic.setPosition(0, 0);
        dispPic.setWidth(w / 4);
        dispPic.setHeight(h / 4);
	}
	
	public function preFrame(tpf:Float):Void 
	{
		
	}
	
	public function postQueue(rq:RenderQueue):Void 
	{
		for (scene in viewPort.getScenes()) 
		{
            ShadowUtil.getGeometriesInCamFrustumFromScene(scene, viewPort.getCamera(), ShadowMode.Receive, lightReceivers);
        }

        // update frustum points based on current camera
        var viewCam:Camera = viewPort.getCamera();
        ShadowUtil.updateFrustumPoints(viewCam, viewCam.frustumNear, viewCam.frustumFar, 1.0, points);

        frustaCenter.setTo(0, 0, 0);
        for (point in points) 
		{
            frustaCenter.addLocal(point);
        }
        frustaCenter.scaleLocal(1 / 8);

        // update light direction
        shadowCam.setProjectionMatrix(null);
        shadowCam.setParallelProjection(true);
        shadowCam.lookAtDirection(direction, Vector3f.Y_AXIS);
        shadowCam.setLocation(frustaCenter);
        shadowCam.update();

        // render shadow casters to shadow map
        ShadowUtil.updateShadowCameraFromViewPort(viewPort, lightReceivers, shadowCam, points, shadowOccluders, shadowMapSize);
        if (shadowOccluders.size == 0) 
		{
            noOccluders = true;
            return;
        } 
		
		
		lightViewProjectionMatrix.copyFrom(biasMatrix);
		lightViewProjectionMatrix.multLocal(shadowCam.getViewProjectionMatrix());

        noOccluders = false;
        
        var r:RendererBase = renderManager.getRenderer();
        renderManager.setCamera(shadowCam, false);
        renderManager.setForcedMaterial(preshadowMat);
		renderManager.setForcedTechnique("depth");
		
		var defaultColor:Color = r.backgroundColor;
		
        r.setFrameBuffer(shadowFB);
		r.backgroundColor = bgColor;
        r.clearBuffers(true, true, true);
        viewPort.getQueue().renderShadowQueue(shadowOccluders, renderManager, shadowCam, true);
		
        r.setFrameBuffer(viewPort.getOutputFrameBuffer());
		r.backgroundColor = defaultColor;
        renderManager.setForcedMaterial(null);
		renderManager.setForcedTechnique(null);
        renderManager.setCamera(viewCam, false);
		r.clearBuffers(true, true, true);
	}
	
	private function setMatParams(l:GeometryList):Void
	{
		needsfallBackMaterial = false;
		
        //iteration throught all the geometries of the list to gather the materials
        var matCache:Array<Material> = [];
        for (i in 0...l.size) 
		{
            var mat:Material = l.getGeometry(i).getMaterial();
			if (mat.getMaterialDef() == null)
				continue;
				
            //checking if the material has the post technique and adding it to the material cache
            if (mat.getMaterialDef().getTechniqueDef(postTechniqueName) != null) 
			{
                if (matCache.indexOf(mat) == -1) 
				{
                    matCache.push(mat);
                }
            } 
			else 
			{
                needsfallBackMaterial = true;
            }
        }

        //iterating through the mat cache and setting the parameters
        for (mat in matCache) 
		{
            mat.setMatrix4("u_LightViewProjectionMatrix", lightViewProjectionMatrix);
			mat.setVector4("u_ShaderInfo", shadowInfo);
			mat.setTexture("u_ShadowMap", shadowMap);
			mat.setBoolean("u_UsePCF", usePCF);
        }

        //At least one material of the receiving geoms does not support the post shadow techniques
        //so we fall back to the forced material solution (transparent shadows won't be supported for these objects)
        if (needsfallBackMaterial) 
		{
            setPostShadowParams();
        }
    }
	
	/**
     * for internal use only
     */
    private function setPostShadowParams():Void
	{
        postshadowMat.setMatrix4("u_LightViewProjectionMatrix", lightViewProjectionMatrix);
    }
	
	public function postFrame(out:FrameBuffer):Void 
	{
		if (!noOccluders)
		{
			setMatParams(lightReceivers);

            renderManager.setForcedMaterial(postshadowMat);
			renderManager.setForcedTechnique(postTechniqueName);
			
            viewPort.getQueue().renderShadowQueue(lightReceivers, renderManager, viewPort.getCamera(), true);
            renderManager.setForcedMaterial(null);
			renderManager.setForcedTechnique(null);
        }
	}
	
	public function cleanup():Void 
	{
		if (shadowFB != null)
		{
			shadowFB.dispose();
			shadowFB = null;
		}
		
		lightViewProjectionMatrix = null;
		biasMatrix = null;
		
		lightReceivers.clear();
		lightReceivers = null;
		
		shadowOccluders.clear();
		shadowOccluders = null;
		
		if (dispPic != null)
		{
			dispPic.removeFromParent();
			dispPic = null;
		}
		
		renderManager = null;
		shadowMap = null;
		
		if (preshadowMat != null)
		{
			preshadowMat.dispose();
			preshadowMat = null;
		}
		
		if (postshadowMat != null)
		{
			postshadowMat.dispose();
			postshadowMat = null;
		}
		
		points = null;
		bgColor = null;
		shadowInfo = null;
		frustaCenter = null;
		direction = null;
	}
	
}