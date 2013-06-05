package org.angle3d.shadow;
import flash.Vector;
import org.angle3d.material.Material;
import org.angle3d.material.ShadowMode;
import org.angle3d.math.Color;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.IRenderer;
import org.angle3d.renderer.queue.GeometryList;
import org.angle3d.scene.CullHint;
import org.angle3d.scene.debug.WireFrustum;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.ui.Picture;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.renderer.ViewPort;
import org.angle3d.texture.Texture2D;
import org.angle3d.texture.TextureMapBase;

import org.angle3d.material.post.SceneProcessor;
import org.angle3d.renderer.RenderManager;

/**
 * ...
 * @author 
 */
class AbstractShadowRenderer implements SceneProcessor
{
	public var isInitialized(get, set):Bool;
	
	private var mIsInitialized:Bool;
	
	private var nbShadowMaps:Int;
	private var shadowMapSize:Float;
	private var renderManager:RenderManager;
	private var viewPort:ViewPort;
	private var shadowFB:Vector<FrameBuffer>;
	private var shadowMaps:Vector<Texture2D>;
	
	private var preshadowMat:Material;
    private var postshadowMat:Material;
	private var lightViewProjectionsMatrices:Vector<Matrix4f>;
	private var debug:Bool;
	private var dispPic:Vector<Picture>;
	private var needsfallBackMaterial:Bool;
	private var postTechniqueName:String;
	private var matCache:Vector<Material>;
	private var sceneReceivers:GeometryList;
	private var lightReceivers:GeometryList;
	private var shadowMapOccluders:GeometryList;
	
	private var shadowMapStringCache:Vector<String>;
    private var lightViewStringCache:Vector<String>;
	
	public function new(shadowMapSize:Int,nbShadowMaps:Int) 
	{
		this.nbShadowMaps = nbShadowMaps;
        this.shadowMapSize = shadowMapSize;
        init(nbShadowMaps, shadowMapSize);
	}
	
	public function setPostShadowMaterial(material:Material):Void
	{
		this.postshadowMat = material;
        postshadowMat.setFloat("ShadowMapSize", shadowMapSize);
		
        for (i in 0...nbShadowMaps)
		{
            postshadowMat.setTexture(shadowMapStringCache[i], shadowMaps[i]);
        }
		
		this.shadowCompareMode = shadowCompareMode;
		this.edgeFilteringMode = edgeFilteringMode;
		this.shadowIntensity = shadowIntensity;
	}
	
	/* INTERFACE org.angle3d.material.post.SceneProcessor */
	
	private function get_isInitialized():Bool 
	{
		return mIsInitialized;
	}
	
	private function set_isInitialized(value:Bool):Bool 
	{
		return mIsInitialized = value;
	}
	
	private var mShadowIntensity:Float;
	public var shadowIntensity(get, set):Float;
	/**
     * returns the shdaow intensity
     *
     * @see #setShadowIntensity(float shadowIntensity)
     * @return shadowIntensity
     */
    private function get_shadowIntensity():Float
	{
        return mShadowIntensity;
    }

    /**
     * Set the shadowIntensity, the value should be between 0 and 1, a 0 value
     * gives a bright and invisilble shadow, a 1 value gives a pitch black
     * shadow, default is 0.7
     *
     * @param shadowIntensity the darkness of the shadow
     */
    private function set_shadowIntensity(shadowIntensity:Float):Float
	{
       return mShadowIntensity = shadowIntensity;
    }
	
	private var mEdgesThickness:Float;
	public var edgesThickness(get, set):Float;
    /**
     * returns the edges thickness <br>
     *
     * @see #setEdgesThickness(int edgesThickness)
     * @return edgesThickness
     */
    public function get_edgesThickness():Float
	{
        return mEdgesThickness * 10;
    }

    /**
     * Sets the shadow edges thickness. default is 1, setting it to lower values
     * can help to reduce the jagged effect of the shadow edges
     *
     * @param edgesThickness
     */
    public function set_edgesThickness(edgesThickness:Float):Float
	{
		mEdgesThickness = Math.max(1, Math.min(edgesThickness, 10));
        mEdgesThickness *= 0.1;
        postshadowMat.setFloat("PCFEdge", mEdgesThickness);
        return mEdgesThickness;
    }
	
	private var mFlushQueues:Bool;
	public var flushQueues(get, set):Bool;
    /**
     * returns true if the PssmRenderer flushed the shadow queues
     *
     * @return flushQueues
     */
    private function get_flushQueues():Bool
	{
        return mFlushQueues;
    }

    /**
     * Set this to false if you want to use several PssmRederers to have
     * multiple shadows cast by multiple light sources. Make sure the last
     * PssmRenderer in the stack DO flush the queues, but not the others
     *
     * @param flushQueues
     */
    private function set_flushQueues(value:Bool):Bool
	{
        return mFlushQueues = value;
    }
	
	private var mShadowCompareMode:CompareMode;
	public var shadowCompareMode(get, set):CompareMode;
    /**
     * sets the shadow compare mode see {@link CompareMode} for more info
     *
     * @param compareMode
     */
    private function set_shadowCompareMode(compareMode:CompareMode):CompareMode 
	{
		mShadowCompareMode = compareMode;
		//for (shadowMap in shadowMaps) 
		//{
            //if (compareMode == CompareMode.Hardware) 
			//{
                //shadowMap.setShadowCompareMode(ShadowCompareMode.LessOrEqual);
                //if (edgeFilteringMode == EdgeFilteringMode.Bilinear) 
				//{
                    //shadowMap.setMagFilter(MagFilter.Bilinear);
                    //shadowMap.setMinFilter(MinFilter.BilinearNoMipMaps);
                //}
				//else 
				//{
                    //shadowMap.setMagFilter(MagFilter.Nearest);
                    //shadowMap.setMinFilter(MinFilter.NearestNoMipMaps);
                //}
            //} 
			//else 
			//{
                //shadowMap.setShadowCompareMode(ShadowCompareMode.Off);
                //shadowMap.setMagFilter(MagFilter.Nearest);
                //shadowMap.setMinFilter(MinFilter.NearestNoMipMaps);
            //}
        //}
        postshadowMat.setBoolean("HardwareShadows", compareMode == CompareMode.Hardware);
		return mShadowCompareMode;
    }

    /**
     * returns the shadow compare mode
     *
     * @see CompareMode
     * @return the shadowCompareMode
     */
    private function get_shadowCompareMode():CompareMode 
	{
        return mShadowCompareMode;
    }
	
	private var mEdgeFilteringMode:EdgeFilteringMode;
	public var edgeFilteringMode(get,set):EdgeFilteringMode;
    /**
     * Sets the filtering mode for shadow edges see {@link EdgeFilteringMode}
     * for more info
     *
     * @param filterMode
     */
    private function set_edgeFilteringMode(filterMode:EdgeFilteringMode):EdgeFilteringMode
	{
		mEdgeFilteringMode = filterMode;
		
		//postshadowMat.setInt("FilterMode", Type.enumIndex(filterMode));
        //postshadowMat.setFloat("PCFEdge", edgesThickness);
        //if (shadowCompareMode == CompareMode.Hardware) 
		//{
            //for (shadowMap in shadowMaps) 
			//{
                //if (filterMode == EdgeFilteringMode.Bilinear) 
				//{
                    //shadowMap.setMagFilter(MagFilter.Bilinear);
                    //shadowMap.setMinFilter(MinFilter.BilinearNoMipMaps);
                //} 
				//else 
				//{
                    //shadowMap.setMagFilter(MagFilter.Nearest);
                    //shadowMap.setMinFilter(MinFilter.NearestNoMipMaps);
                //}
            //}
        //}
		
        return mEdgeFilteringMode;
    }

    /**
     * returns the the edge filtering mode
     *
     * @see EdgeFilteringMode
     * @return
     */
    private function get_edgeFilteringMode():EdgeFilteringMode 
	{
        return mEdgeFilteringMode;
    }
	
	private function init(nbShadowMaps:Int, shadowMapSize:Int):Void
	{
        this.postshadowMat = new Material();// "Common/MatDefs/Shadow/PostShadow.j3md");
        shadowFB = new Vector<FrameBuffer>(nbShadowMaps);
        shadowMaps = new Vector<Texture2D>(nbShadowMaps);
        dispPic = new Vector<Picture>(nbShadowMaps);
        lightViewProjectionsMatrices = new Vector<Matrix4f>(nbShadowMaps);
        shadowMapStringCache = new Vector<String>(nbShadowMaps);
        lightViewStringCache = new Vector<String>(nbShadowMaps);

        preshadowMat = new Material();//"Common/MatDefs/Shadow/PreShadow.j3md");
        postshadowMat.setFloat("ShadowMapSize", shadowMapSize);

        for (i in 0...nbShadowMaps) 
		{
            //lightViewProjectionsMatrices[i] = new Matrix4f();
            //shadowFB[i] = new FrameBuffer(shadowMapSize, shadowMapSize, 1);
            //shadowMaps[i] = new Texture2D(shadowMapSize, shadowMapSize, Format.Depth);
//
            //shadowFB[i].setDepthTexture(shadowMaps[i]);
//
            //shadowMapStringCache[i] = "ShadowMap" + i; 
            //lightViewStringCache[i] = "LightViewProjectionMatrix" + i;
//
            //postshadowMat.setTexture(shadowMapStringCache[i], shadowMaps[i]);
//
            //quads for debuging purpose
            //dispPic[i] = new Picture("Picture" + i);
            //dispPic[i].setTexture(shadowMaps[i], false);
        }
		
		shadowCompareMode = CompareMode.Hardware;
		edgeFilteringMode = EdgeFilteringMode.Bilinear;
		shadowIntensity = 1.0;
    }
	
	//debug function that create a displayable frustrum
    private function createFrustum(pts:Vector<Vector3f>, i:Int):Geometry
	{
        var frustum:WireFrustum = new WireFrustum(pts);
        var frustumMdl:Geometry = new Geometry("f", frustum);
        //frustumMdl.cullHint = CullHint.Never;
        //frustumMdl.shadowMode = ShadowMode.Off;
        //var mat:Material = new Material("Common/MatDefs/Misc/Unshaded.j3md");
        //mat.getAdditionalRenderState().setWireframe(true);
        //frustumMdl.setMaterial(mat);
        //switch (i) {
            //case 0:
                //frustumMdl.getMaterial().setColor("Color", Color.Pink);
            //case 1:
                //frustumMdl.getMaterial().setColor("Color", Color.Red);
            //case 2:
                //frustumMdl.getMaterial().setColor("Color", Color.Green);
            //case 3:
                //frustumMdl.getMaterial().setColor("Color", Color.Blue);
            //default:
                //frustumMdl.getMaterial().setColor("Color", Color.White);
        //}

        frustumMdl.updateGeometricState();
        return frustumMdl;
    }
	
	/**
     * This mehtod is called once per frame. it is responsible for updating the
     * shadow cams according to the light view.
     *
     * @param viewCam the scene cam
     */
    public function updateShadowCams( viewCam:Camera):Void
	{
		
	}
	
	/**
     * this method must return the geomtryList that contains the oclluders to be
     * rendered in the shadow map
     *
     * @param shadowMapIndex the index of the shadow map being rendered
     * @param sceneOccluders the occluders of the whole scene
     * @param sceneReceivers the recievers of the whole scene
     * @return
     */
    private function getOccludersToRender(shadowMapIndex:Int, 
										 sceneOccluders:GeometryList,
										 sceneReceivers:GeometryList, 
										 shadowMapOccluders:GeometryList):GeometryList
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

	public function initialize(rm:RenderManager, vp:ViewPort):Void 
	{
		
	}
	
	public function reshape(vp:ViewPort, w:Int, h:Int):Void 
	{
		
	}
	
	public function preFrame(tpf:Float):Void 
	{
		
	}
	
	public function postQueue(rq:RenderQueue):Void 
	{
		//var occluders:GeometryList = rq.getShadowQueueContent(ShadowMode.Cast);
        //sceneReceivers = rq.getShadowQueueContent(ShadowMode.Receive);
        //if (sceneReceivers.size == 0 || occluders.size == 0) 
		//{
            //return;
        //}
//
        //updateShadowCams(viewPort.camera);
//
        //var r:IRenderer = renderManager.getRenderer();
        //renderManager.setForcedMaterial(preshadowMat);
        //renderManager.setForcedTechnique("PreShadow");
//
        //for (shadowMapIndex in 0...nbShadowMaps) 
		//{
            //if (debugfrustums)
			//{
                //doDisplayFrustumDebug(shadowMapIndex);
            //}
            //renderShadowMap(shadowMapIndex, occluders, sceneReceivers);
        //}
//
        //debugfrustums = false;
        //if (flushQueues) 
		//{
            //occluders.clear();
        //}
        //restore setting for future rendering
        //r.setFrameBuffer(viewPort.getOutputFrameBuffer());
        //renderManager.setForcedMaterial(null);
        //renderManager.setForcedTechnique(null);
        //renderManager.setCamera(viewPort.getCamera(), false);
	}
	
	private function renderShadowMap(shadowMapIndex:Int, 
									occluders:GeometryList, 
									receivers:GeometryList):Void
	{
        //shadowMapOccluders = getOccludersToRender(shadowMapIndex, occluders, receivers, shadowMapOccluders);
        //var shadowCam:Camera = getShadowCam(shadowMapIndex);
//
        //saving light view projection matrix for this split            
        //lightViewProjectionsMatrices[shadowMapIndex].set(shadowCam.getViewProjectionMatrix());
        //renderManager.setCamera(shadowCam, false);
//
        //renderManager.getRenderer().setFrameBuffer(shadowFB[shadowMapIndex]);
        //renderManager.getRenderer().clearBuffers(false, true, false);
//
        // render shadow casters to shadow map
        //viewPort.getQueue().renderShadowQueue(shadowMapOccluders, renderManager, shadowCam, true);
    }
	
	
    private var debugfrustums:Bool = false;
    public function displayFrustum():Void
	{
        debugfrustums = true;
    }

    //debug only : displays depth shadow maps
    private function displayShadowMap(r:IRenderer):Void
	{
        //var cam:Camera = viewPort.camera;
        //renderManager.setCamera(cam, true);
        //var h:Int = cam.getHeight();
        //for (i in 0...dispPic.length) 
		//{
            //dispPic[i].setPosition((128 * i) + (150 + 64 * (i + 1)), h / 20);
            //dispPic[i].setWidth(128);
            //dispPic[i].setHeight(128);
            //dispPic[i].updateGeometricState();
            //renderManager.renderGeometry(dispPic[i]);
        //}
        //renderManager.setCamera(cam, false);
    }

    /**
     * For dubuging purpose Allow to "snapshot" the current frustrum to the
     * scene
     */
    public function displayDebug():Void
	{
        debug = true;
    }

    public function getReceivers(sceneReceivers:GeometryList, 
								lightReceivers:GeometryList):GeometryList
	{
		return null;
	}

	
	public function postFrame(out:FrameBuffer):Void 
	{
		//if (debug) 
		//{
            //displayShadowMap(renderManager.getRenderer());
        //}
//
        //lightReceivers = getReceivers(sceneReceivers, lightReceivers);
//
        //if (lightReceivers.size != 0) 
		//{
            //setting params to recieving geometry list
            //setMatParams();
//
            //var cam:Camera = viewPort.camera;
            //some materials in the scene does not have a post shadow technique so we're using the fall back material
            //if (needsfallBackMaterial)
			//{
                //renderManager.setForcedMaterial(postshadowMat);
            //}
//
            //forcing the post shadow technique and render state
            //renderManager.setForcedTechnique(postTechniqueName);
//
            //rendering the post shadow pass
            //viewPort.renderQueue.renderShadowQueue(lightReceivers, renderManager, cam, true);
            //if (flushQueues)
			//{
                //sceneReceivers.clear();
            //}
//
            //resetting renderManager settings
            //renderManager.setForcedTechnique(null);
            //renderManager.setForcedMaterial(null);
            //renderManager.setCamera(cam, false);
//
        //}
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

    private function setMatParams():Void
	{
        //var l:GeometryList = viewPort.renderQueue.getShadowQueueContent(ShadowMode.Receive);
//
        //iteration throught all the geometries of the list to gather the materials
//
        //matCache.clear();
        //for (i in 0...l.size) 
		//{
            //var mat:Material = l.getGeometry(i).getMaterial();
            //checking if the material has the post technique and adding it to the material cache
            //if (mat.getMaterialDef().getTechniqueDef(postTechniqueName) != null) 
			//{
                //if (!matCache.contains(mat)) 
				//{
                    //matCache.add(mat);
                //}
            //} 
			//else 
			//{
                //needsfallBackMaterial = true;
            //}
        //}
//
        //iterating through the mat cache and setting the parameters
        //for (mat in matCache) 
		//{
//
            //mat.setFloat("ShadowMapSize", shadowMapSize);
//
            //for (j in 0...nbShadowMaps) 
			//{
                //mat.setMatrix4(lightViewStringCache[j], lightViewProjectionsMatrices[j]);
            //}
            //for (j in 0...nbShadowMaps) 
			//{
                //mat.setTexture(shadowMapStringCache[j], shadowMaps[j]);
            //}
            //mat.setBoolean("HardwareShadows", shadowCompareMode == CompareMode.Hardware);
            //mat.setInt("FilterMode", edgeFilteringMode.getMaterialParamValue());
            //mat.setFloat("PCFEdge", edgesThickness);
            //mat.setFloat("ShadowIntensity", shadowIntensity);
//
            //setMaterialParameters(mat);
        //}
//
        //At least one material of the receiving geoms does not support the post shadow techniques
        //so we fall back to the forced material solution (transparent shadows won't be supported for these objects)
        //if (needsfallBackMaterial) 
		//{
            //setPostShadowParams();
        //}

    }

    /**
     * for internal use only
     */
    private function setPostShadowParams():Void
	{
        setMaterialParameters(postshadowMat);
        for (j in 0...nbShadowMaps) 
		{
            postshadowMat.setMatrix4(lightViewStringCache[j], lightViewProjectionsMatrices[j]);
            postshadowMat.setTexture(shadowMapStringCache[j], shadowMaps[j]);
        }
    }
	
	public function cleanup():Void 
	{
		
	}
	
}