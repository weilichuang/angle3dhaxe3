package org.angle3d.shadow;
import flash.Vector;
import org.angle3d.material.CullMode;
import org.angle3d.material.Material;
import org.angle3d.material.RenderState;
import org.angle3d.material.TestFunction;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Vector2f;
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
import org.angle3d.scene.CullHint;
import org.angle3d.scene.debug.WireFrustum;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.ui.DepthMap;
import org.angle3d.scene.ui.Picture;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.texture.Texture2D;

/**
 * abstract shadow renderer that holds commons feature to have for a shadow
 * renderer
 *
 * apply to a viewport
 */
class AbstractShadowRenderer implements SceneProcessor
{
	private var nbShadowMaps:Int = 1;
	private var shadowMapSize:Float;
	//private var shadowIntensity:Float = 0.7;
	
	private var renderManager:RenderManager;
	private var viewPort:ViewPort;
	private var shadowFB:Vector<FrameBuffer>;
	private var shadowMaps:Vector<Texture2D>;

	private var preshadowMat:Material;
    private var postshadowMat:Material;
	
	private var lightViewProjectionsMatrices:Vector<Matrix4f>;
	private var debugShadowMap:Bool = false;
	private var edgesThickness:Float = 1.0;
	private var edgeFilteringMode:EdgeFilteringMode;
	
	private var dispPic:Vector<DepthMap>;
	
	/**
     * true if the fallback material should be used, otherwise false
     */
	public var needsfallBackMaterial:Bool = false;
	
	/**
     * name of the post material technique
     */
	private var postTechniqueName:String = "postShadow";
	
	/**
     * list of materials for post shadow queue geometries
     */
	private var matCache:Vector<Material>;
	private var lightReceivers:GeometryList;
	private var shadowMapOccluders:GeometryList;
	
	private var shadowMapStringCache:Vector<String>;
    private var lightViewStringCache:Vector<String>;
	
	/**
     * fade shadows at distance
     */
    private var zFarOverride:Float = 0;
    private var fadeInfo:Vector2f;
    private var fadeLength:Float;
    private var frustumCam:Camera;
    /**
     * true to skip the post pass when there are no shadow casters
     */
    public var skipPostPass:Bool;
	
	private var debugfrustums:Bool = false;
	
	private var bgColor:Color;
	
	private var shadowInfo:Vector4f;
	
	private var biasMatrix:Matrix4f;
	
	private var forcedRenderState:RenderState = new RenderState();
    private var renderBackFacesShadows:Bool = true;
	
	/**
     * Create an abstract shadow renderer. Subclasses invoke this constructor.
     *
     * @param shadowMapSize the size of the rendered shadow maps (512,1024,2048,
     * etc...)
     * @param nbShadowMaps the number of shadow maps rendered (the more shadow
     * maps the more quality, the fewer fps).
     */
	public function new(shadowMapSize:Int,nbShadowMaps:Int) 
	{
		edgeFilteringMode = EdgeFilteringMode.Nearest;

		lightReceivers = new GeometryList(new OpaqueComparator());
		shadowMapOccluders = new GeometryList(new OpaqueComparator());
		
		matCache = new Vector<Material>();
		
		biasMatrix = new Matrix4f();
		biasMatrix.setTo(0.5, 0.0, 0.0, 0.5,
						  0.0, 0.5, 0.0, 0.5,
						  0.0, 0.0, 0.5, 0.5,
						  0.0, 0.0, 0.0, 1.0);
		
		bgColor = new Color(1, 1, 1, 1);
		shadowInfo = new Vector4f(1.0, 0.5, 0.5, 1 / shadowMapSize);
		
		this.nbShadowMaps = nbShadowMaps;
        this.shadowMapSize = shadowMapSize;
        init(nbShadowMaps, shadowMapSize);
		//setRenderBackFacesShadows(false);
	}
	
	/**
	 * 
	 * @param	bias solves "Shadow Acne"
	 * @param	shadowIntensity Set the shadowIntensity, the value should be between 0 and 1, a 0 value
     * gives a bright and invisilble shadow, a 1 value gives a pitch black
	 */
	public function setShadowInfo(bias:Float,shadowIntensity:Float):Void
	{
		shadowInfo.x = bias;
		shadowInfo.y = FastMath.clamp(shadowIntensity, 0, 1);
		shadowInfo.z = 1 - shadowInfo.y;
		shadowInfo.w = 1 / shadowMapSize;
		
		postshadowMat.setVector4("u_ShaderInfo", shadowInfo);
	}
	
	private function init(nbShadowMaps:Int, shadowMapSize:Int):Void
	{
		preshadowMat = new Material();
		preshadowMat.load(Angle3D.materialFolder + "material/depth.mat");
		
        shadowFB = new Vector<FrameBuffer>(nbShadowMaps);
        shadowMaps = new Vector<Texture2D>(nbShadowMaps);
        dispPic = new Vector<DepthMap>(nbShadowMaps);
		
        lightViewProjectionsMatrices = new Vector<Matrix4f>(nbShadowMaps);
        shadowMapStringCache = new Vector<String>(nbShadowMaps);
        lightViewStringCache = new Vector<String>(nbShadowMaps);

        postshadowMat = new Material();
		postshadowMat.load(Angle3D.materialFolder + "material/postShadow.mat");
		postshadowMat.setVector4("u_ShaderInfo", shadowInfo);

        for (i in 0...nbShadowMaps) 
		{
            lightViewProjectionsMatrices[i] = new Matrix4f();
			
            shadowFB[i] = new FrameBuffer(shadowMapSize, shadowMapSize);
            shadowMaps[i] = new Texture2D(shadowMapSize, shadowMapSize);

            shadowFB[i].addColorTexture(shadowMaps[i]);

            shadowMapStringCache[i] = "u_ShadowMap" + i; 
            lightViewStringCache[i] = "u_LightViewProjectionMatrix" + i;

            postshadowMat.setTexture(shadowMapStringCache[i], shadowMaps[i]);

            //quads for debuging purpose
            dispPic[i] = new DepthMap("Picture" + i);
            dispPic[i].setTexture(shadowMaps[i], false);
        }
		
        setEdgeFilteringMode(edgeFilteringMode);
		initForcedRenderState();
    }
	
	private function initForcedRenderState():Void
	{
        forcedRenderState.setCullMode(CullMode.FRONT);
        forcedRenderState.setColorWrite(false);
        forcedRenderState.setDepthWrite(true);
        forcedRenderState.setDepthTest(true);
    }
	
	public function setPostShadowMaterial(material:Material):Void
	{
		this.postshadowMat = material;

		postshadowMat.setVector4("u_ShaderInfo", shadowInfo);
		
        for (i in 0...nbShadowMaps)
		{
            postshadowMat.setTexture(shadowMapStringCache[i], shadowMaps[i]);
        }
		
        setEdgeFilteringMode(edgeFilteringMode);
	}
	
	/**
     * Sets the filtering mode for shadow edges see {EdgeFilteringMode}
     * for more info
     *
     * @param filterMode
     */
    public function setEdgeFilteringMode(filterMode:EdgeFilteringMode):Void
	{
		if (filterMode == null)
			return;
			
		edgeFilteringMode = filterMode;
		
		postshadowMat.setInt("u_FilterMode", Type.enumIndex(filterMode));
        postshadowMat.setFloat("u_PCFEdge", edgesThickness);
    }

    /**
     * returns the the edge filtering mode
     *
     * @see EdgeFilteringMode
     * @return
     */
    public function getEdgeFilteringMode():EdgeFilteringMode 
	{
        return edgeFilteringMode;
    }
	
    /**
     * returns the edges thickness <br>
     *
     * @see #setEdgesThickness(int edgesThickness)
     * @return edgesThickness
     */
    public function getEdgesThickness():Float
	{
        return edgesThickness * 10;
    }

    /**
     * Sets the shadow edges thickness. default is 1, setting it to lower values
     * can help to reduce the jagged effect of the shadow edges
     *
     * @param edgesThickness
     */
    public function setEdgesThickness(edgesThickness:Float):Void
	{
		this.edgesThickness = Math.max(1, Math.min(edgesThickness, 10));
        this.edgesThickness *= 0.1;
        postshadowMat.setFloat("u_PCFEdge", this.edgesThickness);
    }

	/**
     * debug function to create a visible frustum
     */
    private function createFrustum(pts:Vector<Vector3f>, i:Int):Geometry
	{
        var frustum:WireFrustum = new WireFrustum(pts);
        var frustumMdl:Geometry = new Geometry("frustum_"+i, frustum);
        frustumMdl.localCullHint = CullHint.Never;
        frustumMdl.localShadowMode = ShadowMode.Off;
		
        var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/wireframe.mat");
		mat.getAdditionalRenderState().setDepthTest(false);
		mat.getAdditionalRenderState().setDepthFunc(TestFunction.ALWAYS);
        frustumMdl.setMaterial(mat);
		
        switch (i)
		{
            case 0:
                mat.setColor("u_color", Color.Pink());
            case 1:
                mat.setColor("u_color", Color.Red());
            case 2:
                mat.setColor("u_color", Color.Green());
            case 3:
                mat.setColor("u_color", Color.Blue());
            default:
                mat.setColor("u_color", Color.White());
        }

        frustumMdl.updateGeometricState();
        return frustumMdl;
    }
	
	public function initialize(rm:RenderManager, vp:ViewPort):Void 
	{
		this.renderManager = rm;
		this.viewPort = vp;
		this.postTechniqueName = "postShadow";
		if (zFarOverride > 0 && frustumCam == null)
		{
            initFrustumCam();
        }
	}
	
	/**
     * delegates the initialization of the frustum cam to child renderers
     */
	private function initFrustumCam():Void
	{
		
	}
	
	/**
     * Test whether this shadow renderer has been initialized.
     *
     * @return true if initialized, otherwise false
     */
	public function isInitialized():Bool 
	{
		return viewPort != null;
	}
	
	/**
     * This mehtod is called once per frame. it is responsible for updating the
     * shadow cams according to the light view.
     *
     * @param viewCam the scene cam
     */
    private function updateShadowCams(viewCam:Camera):Void
	{
		
	}
	
	/**
     * Returns a subclass-specific geometryList containing the occluders to be
     * rendered in the shadow map
     *
     * @param shadowMapIndex the index of the shadow map being rendered
     * @param sceneOccluders the occluders of the whole scene
     * @return
     */
    private function getOccludersToRender(shadowMapIndex:Int, 
										 sceneOccluders:GeometryList):GeometryList
	{
		return null;
	}

    /**
     * return the shadow camera to use for rendering the shadow map according
     * the given index
     *
     * @param shadowMapIndex the index of the shadow map being rendered
     * @return the shadowCam
     */
    private function getShadowCam(shadowMapIndex:Int):Camera
	{
		return null;
	}

    /**
     * responsible for displaying the frustum of the shadow cam for debug
     * purpose
     *
     * @param shadowMapIndex
     */
    private function doDisplayFrustumDebug(shadowMapIndex:Int):Void
	{
    }
	
	private function removeFrustumDebug(shadowMapIndex:Int):Void
	{
		
	}
	
	public function postQueue(rq:RenderQueue):Void 
	{
        lightReceivers.clear();
        skipPostPass = false;
        if (!checkCulling(viewPort.getCamera()))
		{
            skipPostPass = true;
            return;
        }

        updateShadowCams(viewPort.getCamera());
		
		var r:RendererBase = renderManager.getRenderer();
		var defaultColor:Color = r.backgroundColor;
        renderManager.setForcedMaterial(preshadowMat);
        renderManager.setForcedTechnique("depth");

        for (shadowMapIndex in 0...nbShadowMaps)
		{
			if (debugfrustums)
			{
				doDisplayFrustumDebug(shadowMapIndex);
			}
			else
			{
				removeFrustumDebug(shadowMapIndex);
			}
			renderShadowMap(shadowMapIndex,r);
		}

        //restore setting for future rendering
        r.setFrameBuffer(viewPort.getOutputFrameBuffer());
		r.backgroundColor = defaultColor;
        renderManager.setForcedMaterial(null);
        renderManager.setForcedTechnique(null);
        renderManager.setCamera(viewPort.getCamera(), false);
		r.clearBuffers(true, true, true);
	}
	
	private function renderShadowMap(shadowMapIndex:Int,render:RendererBase):Void
	{
        shadowMapOccluders = getOccludersToRender(shadowMapIndex, shadowMapOccluders);
		
        var shadowCam:Camera = getShadowCam(shadowMapIndex);

        //saving light view projection matrix for this split    
		lightViewProjectionsMatrices[shadowMapIndex].copyFrom(biasMatrix);
		lightViewProjectionsMatrices[shadowMapIndex].multLocal(shadowCam.getViewProjectionMatrix());

        renderManager.setCamera(shadowCam, false);

        render.setFrameBuffer(shadowFB[shadowMapIndex]);
		render.backgroundColor = bgColor;
        render.clearBuffers(true, true, true);
		
		//renderManager.setForcedRenderState(forcedRenderState);

        //render shadow casters to shadow map
        viewPort.getQueue().renderShadowQueue(shadowMapOccluders, renderManager, shadowCam, true);
		
		//renderManager.setForcedRenderState(null);
    }
	
	public function showFrustum(value:Bool):Void
	{
        debugfrustums = value;
    }
	
	public function isShowFrustum():Bool
	{
        return debugfrustums;
    }
	
	/**
     * For debugging purposes, display depth shadow maps.
     */
    private function displayShadowMap(r:RendererBase):Void
	{
        var cam:Camera = viewPort.getCamera();
        renderManager.setCamera(cam, true);
        var h:Int = cam.height;
        for (i in 0...dispPic.length) 
		{
			var pic:DepthMap = dispPic[i];
			
            pic.setPosition(130 * i, 0);
            pic.setWidth(128);
            pic.setHeight(128);
            pic.updateGeometricState();
            renderManager.renderGeometry(dispPic[i]);
        }
        renderManager.setCamera(cam, false);
    }
	
	private function hideShadowMap(r:RendererBase):Void
	{
        for (i in 0...dispPic.length) 
		{
			var pic:DepthMap = dispPic[i];
			if (pic != null && pic.parent != null)
				pic.removeFromParent();
        }
    }
	
	/**
     * For dubuging purpose Allow to "snapshot" the current frustrum to the
     * scene
     */
    public function showShadowMap(value:Bool):Void
	{
        debugShadowMap = value;
    }
	
	public function isShowShadowMap():Bool
	{
        return debugShadowMap;
    }
	
	public function getReceivers(lightReceivers:GeometryList):Void
	{
		return null;
	}
	
	public function postFrame(out:FrameBuffer):Void 
	{
		if (skipPostPass)
		{
            return;
        }
		
		if (debugShadowMap) 
		{
            displayShadowMap(renderManager.getRenderer());
        }
		else
		{
			hideShadowMap(renderManager.getRenderer());
		}

        getReceivers(lightReceivers);

        if (lightReceivers.size != 0) 
		{
            //setting params to recieving geometry list
            setMatParams(lightReceivers);

            var cam:Camera = viewPort.getCamera();
            //some materials in the scene does not have a post shadow technique so we're using the fall back material
            if (needsfallBackMaterial)
			{
                renderManager.setForcedMaterial(postshadowMat);
            }

            //forcing the post shadow technique and render state
            renderManager.setForcedTechnique(postTechniqueName);

            //rendering the post shadow pass
            viewPort.renderQueue.renderShadowQueue(lightReceivers, renderManager, cam, true);

            //resetting renderManager settings
            renderManager.setForcedTechnique(null);
            renderManager.setForcedMaterial(null);
            renderManager.setCamera(cam, false);
			
			//clearing the params in case there are some other shadow renderers
            clearMatParams();
        }
	}
	
	/**
     * This method is called once per frame and is responsible for clearing any
     * material parameters that subclasses may need to clear on the post material.
     *
     * @param material the material that was used for the post shadow pass     
     */
	private function clearMaterialParameters(material:Material):Void
	{
		return null;
	}
	
	private function clearMatParams():Void
	{
		var mat:Material;
		for (mat in matCache)
		{
			//clearing only necessary params, the others may be set by other 
            //renderers 
            //Note that j start at 1 because other shadow renderers will have 
            //at least 1 shadow map and will set it on each frame anyway.
            for (j in 1...nbShadowMaps)
			{
                mat.clearParam(lightViewStringCache[j]);
				mat.clearParam(shadowMapStringCache[j]);
            }
            mat.clearParam("u_FadeInfo");
            clearMaterialParameters(mat);
		}
		//No need to clear the postShadowMat params as the instance is locale to each renderer     
	}
	
	/**
     * This method is called once per frame and is responsible of setting the
     * material parameters than sub class may need to set on the post material
     *
     * @param material the materail to use for the post shadow pass
     */
    private function setMaterialParameters(material:Material):Void
	{
		
	}
	
	private function setMatParams(l:GeometryList):Void
	{
        //iteration throught all the geometries of the list to gather the materials
		buildMatCache(l);
		
        //iterating through the mat cache and setting the parameters
        for (mat in matCache) 
		{
            //mat.setFloat("u_ShadowMapSize", shadowMapSize);

            for (j in 0...nbShadowMaps) 
			{
                mat.setMatrix4(lightViewStringCache[j], lightViewProjectionsMatrices[j]);
				mat.setTexture(shadowMapStringCache[j], shadowMaps[j]);
            }

            mat.setInt("u_FilterMode", Type.enumIndex(edgeFilteringMode));
            mat.setFloat("u_PCFEdge", edgesThickness);
			mat.setVector4("u_ShaderInfo", shadowInfo);
            //mat.setFloat("u_ShadowIntensity", shadowIntensity);
			if (fadeInfo != null) 
			{
               mat.setVector2("u_FadeInfo", fadeInfo);
            }
			mat.setBoolean("u_BackfaceShadows", renderBackFacesShadows);
            setMaterialParameters(mat);
        }

        //At least one material of the receiving geoms does not support the post shadow techniques
        //so we fall back to the forced material solution (transparent shadows won't be supported for these objects)
        if (needsfallBackMaterial) 
		{
            setPostShadowParams();
        }
    }
	
	private function buildMatCache(list:GeometryList):Void
	{
		matCache.length = 0;
        for (i in 0...list.size) 
		{
            var mat:Material = list.getGeometry(i).getMaterial();
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
	}
	
	/**
     * for internal use only
     */
    public function setPostShadowParams():Void
	{
        setMaterialParameters(postshadowMat);
        for (j in 0...nbShadowMaps) 
		{
            postshadowMat.setMatrix4(lightViewStringCache[j], lightViewProjectionsMatrices[j]);
            postshadowMat.setTexture(shadowMapStringCache[j], shadowMaps[j]);
        }
		
		if (fadeInfo != null)
		{
            postshadowMat.setVector2("u_FadeInfo", fadeInfo);
        }
		postshadowMat.setBoolean("u_BackfaceShadows", renderBackFacesShadows);
    }
	
	/**
     * How far the shadows are rendered in the view
     *
     * @see #setShadowZExtend(float zFar)
     * @return shadowZExtend
     */
    public function getShadowZExtend():Float
	{
        return zFarOverride;
    }

    /**
     * Set the distance from the eye where the shadows will be rendered default
     * value is dynamicaly computed to the shadow casters/receivers union bound
     * zFar, capped to view frustum far value.
     *
     * @param zFar the zFar values that override the computed one
     */
    public function setShadowZExtend(zFar:Float):Void
	{
        this.zFarOverride = zFar;        
        if (zFarOverride == 0)
		{
            fadeInfo = null;
            frustumCam = null;
        }
		else
		{
            if (fadeInfo != null)
			{
                fadeInfo.setTo(zFarOverride - fadeLength, 1 / fadeLength);
            }
            if (frustumCam == null && viewPort != null)
			{
                initFrustumCam();
            }
        }
    }
    
    /**
     * Define the length over which the shadow will fade out when using a
     * shadowZextend This is useful to make dynamic shadows fade into baked
     * shadows in the distance.
     *
     * @param length the fade length in world units
     */
    public function setShadowZFadeLength(length:Float):Void
	{
        if (length == 0) 
		{
            fadeInfo = null;
            fadeLength = 0;
            postshadowMat.clearParam("u_FadeInfo");
        } 
		else 
		{
            if (zFarOverride == 0)
			{
                fadeInfo = new Vector2f(0, 0);
            } 
			else 
			{
                fadeInfo = new Vector2f(zFarOverride - length, 1.0 / length);
            }
            fadeLength = length;
            postshadowMat.setVector2("u_FadeInfo", fadeInfo);
        }
    }

    /**
     * get the length over which the shadow will fade out when using a
     * shadowZextend
     *
     * @return the fade length in world units
     */
    public function getShadowZFadeLength():Float
	{
        if (fadeInfo != null)
		{
            return zFarOverride - fadeInfo.x;
        }
        return 0;
    }
	
	/**
     * returns true if the light source bounding box is in the view frustum
     * @return 
     */
	private function checkCulling(viewCam:Camera):Bool
	{
		return false;
	}
	
	public function preFrame(tpf:Float):Void 
	{
		
	}
	
	public function cleanup():Void 
	{
		
	}
	
	public function reshape(vp:ViewPort, w:Int, h:Int):Void 
	{
		
	}
	
	/**
     * returns the pre shadows pass render state.
     * use it to adjust the RenderState parameters of the pre shadow pass.
     * Note that this will be overriden if the preShadow technique in the material has a ForcedRenderState
     * @return the pre shadow render state.
     */
    public function getPreShadowForcedRenderState():RenderState
	{
        return forcedRenderState;
    }

    /**
     * Set to true if you want back faces shadows on geometries.
     * Note that back faces shadows will be blended over dark lighten areas and may produce overly dark lighting.
     *
     * Also note that setting this parameter will override this parameter for ALL materials in the scene.
     * You can alternatively change this parameter on a single material using {@link Material#setBoolean(String, boolean)}
     *
     * This also will automatically adjust the faceCullMode and the PolyOffset of the pre shadow pass.
     * You can modify them by using {@link #getPreShadowForcedRenderState()}
     *
     * @param renderBackFacesShadows true or false.
     */
    public function setRenderBackFacesShadows(renderBackFacesShadows:Bool):Void
	{
        this.renderBackFacesShadows = renderBackFacesShadows;
        if (renderBackFacesShadows)
		{
            //getPreShadowForcedRenderState().setPolyOffset(5, 3);
            getPreShadowForcedRenderState().setCullMode(CullMode.BACK);
        }
		else
		{
            //getPreShadowForcedRenderState().setPolyOffset(0, 0);
            getPreShadowForcedRenderState().setCullMode(CullMode.FRONT);
        }
    }

    /**
     * if this processor renders back faces shadows
     * @return true if this processor renders back faces shadows
     */
    public function isRenderBackFacesShadows():Bool
	{
        return renderBackFacesShadows;
    }
}