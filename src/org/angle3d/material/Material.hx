package org.angle3d.material;


import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import assets.manager.misc.FileType;
import assets.manager.misc.LoaderStatus;
import de.polygonal.ds.error.Assert;
import flash.Vector;
import haxe.Json;
import org.angle3d.io.parser.material.MaterialParser;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.Light;
import org.angle3d.light.LightList;
import org.angle3d.light.LightType;
import org.angle3d.light.PointLight;
import org.angle3d.light.SpotLight;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.Uniform;
import org.angle3d.material.Technique;
import org.angle3d.material.LightMode;
import org.angle3d.math.Color;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;
import org.angle3d.renderer.Caps;
import org.angle3d.renderer.RendererBase;
import org.angle3d.renderer.RenderManager;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.Texture;
import org.angle3d.texture.TextureType;
import org.angle3d.utils.ArrayUtil;
import org.angle3d.utils.FastStringMap;
import org.angle3d.utils.Logger;


/**
 * Material describes the rendering style for a given Geometry.
 * <p>A material is essentially a list of parameters,
 * those parameters map to uniforms which are defined in a shader.
 * Setting the parameters can modify the behavior of a
 * shader.
 * <p/>
 * 
 */
class Material
{
	private static var materialCache:FastStringMap<String>;
	
	private static var nullDirLight:Vector<Float>;
	
	private static var additiveLight:RenderState;
	
	public static var DEFAULT_TECHNIQUE:String;
	
	/**
	 * 特殊函数，用于执行一些static变量的定义等(有这个函数时，static变量预先赋值必须也放到这里面)
	 */
	static function __init__():Void
	{
		DEFAULT_TECHNIQUE = "default";
		
		materialCache = new FastStringMap<String>();
		
		nullDirLight = Vector.ofArray([0.0, -1.0, 0.0, -1.0]);
		
		additiveLight = new RenderState();
		additiveLight.setBlendMode(BlendMode.AlphaAdditive);
		additiveLight.setDepthWrite(false);
	}
	
	public var name:String;
	
	private var cacheParamValue:FastStringMap<MatParam>;
	
	private var defFile:String;
	private var def:MaterialDef;
	
	private var paramValuesMap:FastStringMap<MatParam>;
	private var paramValueList:Array<MatParam>;
	private var paramTextureList:Array<MatParamTexture>;
	
	private var mTechnique:Technique;
	private var techniques:FastStringMap<Technique>;
	private var additionalState:RenderState;
    private var mergedRenderState:RenderState;
	private var sortingId:Int = -1;
	
	private var transparent:Bool = false;
	private var receivesShadows:Bool = false;
	
	private var ambientLightColor:Color;
	
	public function new(defFile:String = "")
	{
		additionalState = null;
		mergedRenderState = new RenderState();

		paramValuesMap = new FastStringMap<MatParam>();
		paramValueList = [];
		paramTextureList = [];
		
		mTechnique = null;
		techniques = new FastStringMap<Technique>();
		
		ambientLightColor = new Color(0, 0, 0, 1);
		
		if (defFile != null && defFile != "")
		{
			load(defFile);
		}
	}
	
	public function load(defFile:String, onComplete:Material->Void = null):Void
	{
		this.defFile = defFile;
		if (materialCache.exists(defFile))
		{
			var def:MaterialDef = MaterialParser.parse(defFile, Json.parse(materialCache.get(defFile)));
			this.setMaterialDef(def);
			if (onComplete != null)
			{
				onComplete(this);
			}
		}
		else
		{
			var assetLoader:FileLoader = new FileLoader();
			assetLoader.loadFile(defFile,FileType.TEXT,function(fileInfo:FileInfo):Void
			{
				if (fileInfo.status == LoaderStatus.LOADED)
				{
					var defSource:String = fileInfo.data;
					
					materialCache.set(defFile, defSource);
					
					var def:MaterialDef = MaterialParser.parse(defFile, Json.parse(defSource));
					this.setMaterialDef(def);
					if (onComplete != null)
					{
						onComplete(this);
					}
				}
			});
		}
	}
	
	/**
     * Returns the currently active technique.
     * <p>
     * The technique is selected automatically by the RenderManager
     * based on system capabilities. Users may select their own
     * technique by using
     * {#selectTechnique(String, com.jme3.renderer.RenderManager) }.
     *
     * @return the currently active technique.
     *
     * @see #selectTechnique(String, com.jme3.renderer.RenderManager)
     */
	public inline function getActiveTechnique():Technique
	{
        return mTechnique;
    }
	
	public function setMaterialDef(def:MaterialDef):Void
	{
		this.def = def;
		
		if (this.def == null)
		{
			paramValuesMap = new FastStringMap<MatParam>();
			paramValueList = [];
			paramTextureList = [];
			return;
		}
		
		// Load default values from definition (if any)
		var map:FastStringMap<MatParam> = def.getMaterialParams();
		var keys = map.keys();
		for (key in keys)
		{
			var param:MatParam = map.get(key);
			if (param.value != null)
			{
				setParam(param.name, param.type, param.value);
			}
		}
		
		//从cacheParamValue中取值放到paramValues中
		if (cacheParamValue != null)
		{
			var keys = cacheParamValue.keys();
			for (paramName in keys)
			{
				var param:MatParam = cacheParamValue.get(paramName);
				setParam(param.name, param.type, param.value);
			}
			cacheParamValue = null;
		}
	}
	
	/**
     * Get the material definition (j3md file info) that <code>this</code>
     * material is implementing.
     *
     * @return the material definition this material implements.
     */
    public inline function getMaterialDef():MaterialDef
	{
        return def;
    }
	
	 /**
     * Acquire the additional {RenderState render state} to apply
     * for this material.
     *
     * <p>The first call to this method will create an additional render
     * state which can be modified by the user to apply any render
     * states in addition to the ones used by the renderer. Only render
     * states which are modified in the additional render state will be applied.
     *
     * @return The additional render state.
     */
    public inline function getAdditionalRenderState():RenderState
	{
        if (additionalState == null) 
		{
            additionalState = RenderState.ADDITIONAL.clone();
        }
        return additionalState;
    }
	
	public inline function getTechnique():Technique
	{
		return mTechnique;
	}

	public function setTechnique(t:Technique):Void
	{
		mTechnique = t;
	}
	
	/**
     * Check if the transparent value marker is set on this material.
     * @return True if the transparent value marker is set on this material.
     * @see #setTransparent(boolean)
     */
    public function isTransparent():Bool
	{
        return transparent;
    }

    /**
     * Set the transparent value marker.
     *
     * <p>This value is merely a marker, by itself it does nothing.
     * Generally model loaders will use this marker to indicate further
     * up that the material is transparent and therefore any geometries
     * using it should be put into the {Bucket#Transparent transparent
     * bucket}.
     *
     * @param transparent the transparent value marker.
     */
    public function setTransparent(transparent:Bool):Void
	{
        this.transparent = transparent;
    }

    /**
     * Check if the material should receive shadows or not.
     *
     * @return True if the material should receive shadows.
     *
     * @see Material#setReceivesShadows(boolean)
     */
    public function isReceivesShadows():Bool
	{
        return receivesShadows;
    }

    /**
     * Set if the material should receive shadows or not.
     *
     * <p>This value is merely a marker, by itself it does nothing.
     * Generally model loaders will use this marker to indicate
     * the material should receive shadows and therefore any
     * geometries using it should have the {ShadowMode#Receive} set
     * on them.
     *
     * @param receivesShadows if the material should receive shadows or not.
     */
    public function setReceivesShadows(receivesShadows:Bool):Void
	{
        this.receivesShadows = receivesShadows;
    }

	public function getSortId():Int
	{
		var t:Technique = getActiveTechnique();
        if (sortingId == -1 && t != null && t.getShader() != null)
		{
            var texId:Int = -1;
			for (param in paramTextureList)
			{
				var tex:MatParamTexture = param;
				if (tex.texture != null) 
				{
					if (texId == -1) 
					{
						texId = 0;
					}
					texId += tex.texture.id % 0xff;
				}
			}
            sortingId = texId + t.getShader().id * 1000;
        }
        return sortingId;
	}

	/**
     * Clones this material. The result is returned.
     */
	public function clone():Material
	{
		var mat:Material = new Material();
		mat.transparent = transparent;
		mat.receivesShadows = receivesShadows;
		if (additionalState != null)
		{
			mat.additionalState = additionalState.clone();
		}
		
		if (cacheParamValue != null)
		{
			mat.cacheParamValue = new FastStringMap<MatParam>();
			var keys = cacheParamValue.keys();
			for (paramName in keys)
			{
				mat.cacheParamValue.set(paramName, cacheParamValue.get(paramName));
			}
		}
		
		mat.defFile = defFile;
		if (this.def != null)
		{
			mat.setMaterialDef(this.def);
		}
		else if(this.defFile != null)
		{
			mat.load(this.defFile);
		}
		
		for (i in 0...paramValueList.length)
		{
			var param:MatParam = paramValueList[i];
			
			var value:Dynamic;
			if (Reflect.hasField(param.value, "clone"))
			{
				value = untyped param.value.clone();
			}
			else
			{
				value = param.value;
			}
			
			mat.setParam(param.name, param.type, value);
		}
		
		return mat;
	}
	
	public function contentEquals(other:Material):Bool
	{
		// Early exit if the material are the same object
		if (other == this)
			return true;
			
		// Check material definition        
        if (this.getMaterialDef() != other.getMaterialDef())
		{
            return false;
        }
		
		// Early exit if the size of the params is different
        if (paramValueList.length != other.paramValueList.length)
		{
            return false;
        }
        
        // Checking technique
        if (this.mTechnique != null || other.mTechnique != null)
		{
            // Techniques are considered equal if their names are the same
            // E.g. if user chose custom technique for one material but 
            // uses default technique for other material, the materials 
            // are not equal.
            var thisDefName:String = this.mTechnique != null ? this.mTechnique.getDef().name : "default";
            var otherDefName:String = other.mTechnique != null ? other.mTechnique.getDef().name : "default";
            if (thisDefName != otherDefName)
			{
                return false;
            }
        }

        // Comparing parameters
        for (thisParam in paramValueList)
		{
            var otherParam:MatParam = other.getParam(thisParam.name);

            // This param does not exist in compared mat
            if (otherParam == null)
			{
                return false;
            }

            if (!otherParam.equals(thisParam)) 
			{
                return false;
            }
        }

        // Comparing additional render states
        if (additionalState == null)
		{
            if (other.additionalState != null)
			{
                return false;
            }
        } 
		else 
		{
            if (!additionalState.equals(other.additionalState)) 
			{
                return false;
            }
        }
        
        return true;
	}
	
	private function getAmbientColor(lightList:LightList,removeLights:Bool):Color
	{
		ambientLightColor.setTo(0, 0, 0, 1);
			
		var index:Int = 0;
		while(index < lightList.getSize())
		{
            var l:Light = lightList.getLightAt(index);
            if (l.type == LightType.Ambient) 
			{
                ambientLightColor.addLocal(l.color);
				if (removeLights)
				{
					lightList.removeLight(l);
					index--;
				}
            }
			
			index++;
        }
		
        ambientLightColor.a = 1.0;
        return ambientLightColor;
    }
	
	/**
     * Uploads the lights in the light list as two uniform arrays.<br/><br/> *
     * <p>
     * <code>uniform vec4 g_LightColor[numLights];</code><br/> //
     * g_LightColor.rgb is the diffuse/specular color of the light.<br/> //
     * g_Lightcolor.a is the type of light, 0 = Directional, 1 = Point, <br/> //
     * 2 = Spot. <br/> <br/>
     * <code>uniform vec4 g_LightPosition[numLights];</code><br/> //
     * g_LightPosition.xyz is the position of the light (for point lights)<br/>
     * // or the direction of the light (for directional lights).<br/> //
     * g_LightPosition.w is the inverse radius (1/r) of the light (for
     * attenuation) <br/> </p>
     */
    private function updateLightListUniforms(shader:Shader, g:Geometry, lightList:LightList, numLights:Int, rm:RenderManager, startIndex:Int):Int
	{
		// this shader does not do lighting, ignore.
        if (numLights == 0) 
		{ 
            return 0;
        }

        var lightData:Uniform = shader.getUniform("gu_LightData");     
        lightData.setVector4Length(numLights * 3);//4 lights * max 3        
        var ambientColor:Uniform = shader.getUniform("gu_AmbientLightColor");
        
        if (startIndex != 0)
		{        
            // apply additive blending for 2nd and future passes
            rm.getRenderer().applyRenderState(additiveLight);
            ambientColor.setColor(Color.Black());            
        }
		else
		{
            ambientColor.setColor(getAmbientColor(lightList,true));
        }
        
        var lightDataIndex:Int = 0;
        var tmpVec:Vector4f = new Vector4f();
        var curIndex:Int = startIndex;
        var endIndex:Int = numLights + startIndex;
        while (curIndex < endIndex && curIndex < lightList.getSize())
		{    
			var l:Light = lightList.getLightAt(curIndex);              
			if (l.type == LightType.Ambient)
			{
				endIndex++;   
				curIndex++;
				continue;
			}
			
			var color:Color = l.color;
			//Color
			lightData.setVector4InArray(color.r, color.g, color.b, l.type.toInt(), lightDataIndex);
			lightDataIndex++;
			
			switch (l.type)
			{
				case LightType.Directional:
					var dl:DirectionalLight = cast l;
					var dir:Vector3f = dl.direction;                      
					//Data directly sent in view space to avoid a matrix mult for each pixel
					tmpVec.setTo(dir.x, dir.y, dir.z, 0.0);
					rm.getCurrentCamera().getViewMatrix().multVec4(tmpVec, tmpVec);      
//                        tmpVec.divideLocal(tmpVec.w);
//                        tmpVec.normalizeLocal();
					lightData.setVector4InArray(tmpVec.x, tmpVec.y, tmpVec.z, -1, lightDataIndex);
					lightDataIndex++;
					//PADDING
					lightData.setVector4InArray(0, 0, 0, 0, lightDataIndex);
					lightDataIndex++;
					
				case LightType.Point:
					var pl:PointLight = cast l;
					var pos:Vector3f = pl.position;
					var invRadius:Float = pl.invRadius;
					tmpVec.setTo(pos.x, pos.y, pos.z, 1.0);
					rm.getCurrentCamera().getViewMatrix().multVec4(tmpVec, tmpVec);    
					//tmpVec.divideLocal(tmpVec.w);
					lightData.setVector4InArray(tmpVec.x, tmpVec.y, tmpVec.z, invRadius, lightDataIndex);
					lightDataIndex++;
					//PADDING
					lightData.setVector4InArray(0, 0, 0, 0, lightDataIndex);
					lightDataIndex++;
					
				case LightType.Spot:                      
					var sl:SpotLight = cast l;
					var pos2:Vector3f = sl.position;
					var dir2:Vector3f = sl.direction;
					var invRange:Float = sl.invSpotRange;
					var spotAngleCos:Float = sl.packedAngleCos;
					tmpVec.setTo(pos2.x, pos2.y, pos2.z,  1.0);
					rm.getCurrentCamera().getViewMatrix().multVec4(tmpVec, tmpVec);   
				   // tmpVec.divideLocal(tmpVec.w);
					lightData.setVector4InArray(tmpVec.x, tmpVec.y, tmpVec.z, invRange, lightDataIndex);
					lightDataIndex++;
					
					//We transform the spot direction in view space here to save 5 varying later in the lighting shader
					//one vec4 less and a vec4 that becomes a vec3
					//the downside is that spotAngleCos decoding happens now in the frag shader.
					tmpVec.setTo(dir2.x, dir2.y, dir2.z,  0.0);
					rm.getCurrentCamera().getViewMatrix().multVec4(tmpVec, tmpVec);                           
					tmpVec.normalize();
					lightData.setVector4InArray(tmpVec.x, tmpVec.y, tmpVec.z, spotAngleCos, lightDataIndex);
					lightDataIndex++;                  
				default:
					throw ("Unknown type of light: " + l.type);
			}
			curIndex++;
        }
      
        //Padding of unsued buffer space
        while (lightDataIndex < numLights * 3)
		{
            lightData.setVector4InArray(0, 0, 0, 0, lightDataIndex);
            lightDataIndex++;             
        } 
        return curIndex;
    }
	
	/**
	 * 多重灯光渲染
	 * @param	shader
	 * @param	g
	 * @param	rm
	 */
	private var tmpLightDirection:Vector<Float>;
	private var tmpLightPosition:Vector<Float>;
	private var tmpColors:Vector<Float>;
	private function renderMultipassLighting(shader:Shader, g:Geometry, lightList:LightList, rm:RenderManager):Void
	{
		var r:RendererBase = rm.getRenderer();

		var lightDir:Uniform = shader.getUniform("gu_LightDirection");
		var lightColor:Uniform = shader.getUniform("gu_LightColor");
		var lightPos:Uniform = shader.getUniform("gu_LightPosition");
		var ambientColor:Uniform = shader.getUniform("gu_AmbientLightColor");
		
		var isFirstLight:Bool = true;
		var isSecondLight:Bool = false;
		var numLight:Int = lightList.getSize();
		for (i in 0...numLight)
		{
			var l:Light = lightList.getLightAt(i);
			if (l.type == LightType.Ambient)
			{
				continue;
			}
			
			if (isFirstLight)
			{
				// set ambient color for first light only
				ambientColor.setColor(getAmbientColor(lightList,false));
				isFirstLight = false;
				isSecondLight = true;
			}
			else if (isSecondLight)
			{
				ambientColor.setColor(Color.Black());
				// apply additive blending for 2nd and future lights
				r.applyRenderState(additiveLight);
				isSecondLight = false;
			}
			
			if(tmpLightDirection == null)
				tmpLightDirection = new Vector<Float>(4, true);
			if(tmpLightPosition == null)
			    tmpLightPosition = new Vector<Float>(4, true);
			if (tmpColors == null)
				tmpColors = new Vector<Float>(4, true);

			l.color.toVector(tmpColors);
			tmpColors[3] = l.type.toInt();
			lightColor.setVector(tmpColors);
			
			switch(l.type)
			{
				case LightType.Directional:
					var dl:DirectionalLight = cast l;
					var dir:Vector3f = dl.direction;
					
					tmpLightPosition[0] = dir.x;
					tmpLightPosition[1] = dir.y;
					tmpLightPosition[2] = dir.z;
					tmpLightPosition[3] = -1;
					lightPos.setVector(tmpLightPosition);
					
					tmpLightDirection[0] = 0;
					tmpLightDirection[1] = 0;
					tmpLightDirection[2] = 0;
					tmpLightDirection[3] = 0;
					lightDir.setVector(tmpLightDirection);
					
				case LightType.Point:
					var pl:PointLight = cast l;
					var pos:Vector3f = pl.position;
					tmpLightPosition[0] = pos.x;
					tmpLightPosition[1] = pos.y;
					tmpLightPosition[2] = pos.z;
					tmpLightPosition[3] = pl.invRadius;
					lightPos.setVector(tmpLightPosition);
					
					tmpLightDirection[0] = 0;
					tmpLightDirection[1] = 0;
					tmpLightDirection[2] = 0;
					tmpLightDirection[3] = 0;
					lightDir.setVector(tmpLightDirection);
					
				case LightType.Spot:
					var sl:SpotLight = cast l;
					var pos:Vector3f = sl.position;
					var dir:Vector3f = sl.direction;
					
					tmpLightPosition[0] = pos.x;
					tmpLightPosition[1] = pos.y;
					tmpLightPosition[2] = pos.z;
					tmpLightPosition[3] = sl.invSpotRange;
					lightPos.setVector(tmpLightPosition);
					
					var tmpVec:Vector4f = new Vector4f();
					tmpVec.setTo(dir.x, dir.y, dir.z, 0);
					
					rm.getCurrentCamera().getViewMatrix().multVec4(tmpVec, tmpVec);
					
					//We transform the spot directoin in view space here to save 5 varying later in the lighting shader
                    //one vec4 less and a vec4 that becomes a vec3
                    //the downside is that spotAngleCos decoding happen now in the frag shader.
					tmpLightDirection[0] = tmpVec.x;
					tmpLightDirection[1] = tmpVec.y;
					tmpLightDirection[2] = tmpVec.z;
					tmpLightDirection[3] = sl.packedAngleCos;
					
					lightDir.setVector(tmpLightDirection);
					
				default:
					Assert.assert(false, "Unknown type of light: " + l.type);
			}
			
			r.setShader(shader);
			renderMeshFromGeometry(r, g);
		}
		
		if (isFirstLight)
		{
			// Either there are no lights at all, or only ambient lights.
            // Render a dummy "normal light" so we can see the ambient color.
			ambientColor.setVector(getAmbientColor(lightList,false).toVector());
			lightColor.setVector(Color.BlackNoAlpha().toVector());
			lightPos.setVector(nullDirLight);
			
			r.setShader(shader);
			renderMeshFromGeometry(r, g);
		}
	}
	
	
	/**
     * Called by RenderManager to render the geometry by
     * using this material.
     * <p>
     * The material is rendered as follows:
     * <ul>
     * <li>Determine which technique to use to render the material - 
     * either what the user selected via 
     * {#selectTechnique(String, com.jme3.renderer.RenderManager) 
     * Material.selectTechnique()}, 
     * or the first default technique that the renderer supports 
     * (based on the technique's {TechniqueDef#getRequiredCaps() requested rendering capabilities})<ul>
     * <li>If the technique has been changed since the last frame, then it is notified via 
     * {Technique#makeCurrent(com.jme3.asset.AssetManager, boolean, java.util.EnumSet) 
     * Technique.makeCurrent()}. 
     * If the technique wants to use a shader to render the model, it should load it at this part - 
     * the shader should have all the proper defines as declared in the technique definition, 
     * including those that are bound to material parameters. 
     * The technique can re-use the shader from the last frame if 
     * no changes to the defines occurred.</li></ul>
     * <li>Set the {RenderState} to use for rendering. The render states are 
     * applied in this order (later RenderStates override earlier RenderStates):<ol>
     * <li>{TechniqueDef#getRenderState() Technique Definition's RenderState}
     * - i.e. specific renderstate that is required for the shader.</li>
     * <li>{#getAdditionalRenderState() Material Instance Additional RenderState}
     * - i.e. ad-hoc renderstate set per model</li>
     * <li>{RenderManager#getForcedRenderState() RenderManager's Forced RenderState}
     * - i.e. renderstate requested by a {com.jme3.post.SceneProcessor} or
     * post-processing filter.</li></ol>
     * <li>If the technique {TechniqueDef#isUsingShaders() uses a shader}, then the uniforms of the shader must be updated.<ul>
     * <li>Uniforms bound to material parameters are updated based on the current material parameter values.</li>
     * <li>Uniforms bound to world parameters are updated from the RenderManager.
     * Internally {UniformBindingManager} is used for this task.</li>
     * <li>Uniforms bound to textures will cause the texture to be uploaded as necessary. 
     * The uniform is set to the texture unit where the texture is bound.</li></ul>
     * <li>If the technique uses a shader, the model is then rendered according 
     * to the lighting mode specified on the technique definition.<ul>
     * <li>{LightMode#SinglePass single pass light mode} fills the shader's light uniform arrays 
     * with the first 4 lights and renders the model once.</li>
     * <li>{LightMode#MultiPass multi pass light mode} light mode renders the model multiple times, 
     * for the first light it is rendered opaque, on subsequent lights it is 
     * rendered with {BlendMode#AlphaAdditive alpha-additive} blending and depth writing disabled.</li>
     * </ul>
     * <li>The mesh is uploaded and rendered.</li>
     * </ul>
     * </ul>
     *
     * @param geom The geometry to render
     * @param lights Presorted and filtered light list to use for rendering
     * @param rm The render manager requesting the rendering
     */
	private static var EMPTY_LIGHTS:LightList = new LightList();
    public function render(geom:Geometry, lights:LightList, rm:RenderManager):Void
	{
		if (this.def == null)
			return;
				
        autoSelectTechnique(rm);
		
		if (mTechnique == null || !mTechnique.isReady())
			return;

        var techDef:TechniqueDef = mTechnique.getDef();

		var r:RendererBase = rm.getRenderer();
        if (rm.getForcedRenderState() != null)
		{
            r.applyRenderState(rm.getForcedRenderState());
        } 
		else
		{
            if (techDef.renderState != null)
			{
                r.applyRenderState(techDef.renderState.copyMergedTo(additionalState, mergedRenderState));
            } 
			else 
			{
                r.applyRenderState(RenderState.DEFAULT.copyMergedTo(additionalState, mergedRenderState));
            }
        }

		var shader:Shader = mTechnique.getShader();

        // reset unchanged uniform flag
        shader.clearUniformsSetByCurrent();
		
        rm.updateShaderBinding(shader);
        
        // setup textures and uniforms
        for (param in paramValueList)
		{
            param.apply(r, mTechnique);
        }
		
		r.clearTextures();
		
		// any unset uniforms will be set to 0
		shader.resetUniformsNotSetByCurrent();

		var lightMode:LightMode = techDef.lightMode;
		if (lightMode != LightMode.Disable)
		{
			if (lights == null)
			{
				lights = EMPTY_LIGHTS;
				lights.setOwner(geom);
			}
		}
		
        // send lighting information, if needed
        switch (lightMode)
		{
            case LightMode.Disable:
				// upload and bind shader
				r.setShader(shader);
				renderMeshFromGeometry(r, geom);
            case LightMode.SinglePass:
                var nbRenderedLights:Int = 0;
				if (lights.getSize() == 0)
				{
                    nbRenderedLights = updateLightListUniforms(shader, geom, lights, rm.getSinglePassLightBatchSize(), rm, 0);
                    r.setShader(shader);
                    renderMeshFromGeometry(r, geom);
                } 
				else
				{
					//如果灯光数量超过上限，则会分成多次渲染
                    while (nbRenderedLights < lights.getSize())
					{
						nbRenderedLights = updateLightListUniforms(shader, geom, lights, rm.getSinglePassLightBatchSize(), rm, nbRenderedLights);
						r.setShader(shader);
						renderMeshFromGeometry(r, geom);
					}
                }
            case LightMode.MultiPass:
                renderMultipassLighting(shader, geom, lights, rm);
        }
    }
	
	private function renderMeshFromGeometry(render:RendererBase, geom:Geometry):Void
	{
		var mesh:Mesh = geom.getMesh();
        var lodLevel:Int = geom.getLodLevel();
		render.renderMesh(mesh, lodLevel);
	}
	
	
	/**
     * Select the technique to use for rendering this material.
     * <p>
     * If name is "default", then one of the
     * {MaterialDef#getDefaultTechniques() default techniques}
     * on the material will be selected. Otherwise, the named technique
     * will be found in the material definition.
     * <p>
     * Any candidate technique for selection (either default or named)
     * must be verified to be compatible with the system, for that, the
     * <code>renderManager</code> is queried for capabilities.
     *
     * @param name The name of the technique to select, pass "Default" to
     * select one of the default techniques.
     * @param renderManager The {RenderManager render manager}
     * to query for capabilities.
     *
     * @throws If "Default" is passed and no default
     * techniques are available on the material definition, or if a name
     * is passed but there's no technique by that name.
     * @throws If no candidate technique supports the system capabilities.
     */
    public function selectTechnique(name:String, renderManager:RenderManager):Void
	{
        // check if already created
        var tech:Technique = techniques.get(name);
		var rendererCaps:Array<Caps> = renderManager.getRenderer().getCaps();
        if (tech == null)
		{
            if (name == DEFAULT_TECHNIQUE)
			{
                var techDefs:Vector<TechniqueDef> = def.getDefaultTechniques();
				
				#if debug
                if (techDefs == null || techDefs.length == 0)
				{
                    throw ("No default techniques are available on material '" + def.name + "'");
                }
				#end

                var lastTech:TechniqueDef = null;
                for (techDef in techDefs)
				{
                    if (ArrayUtil.containsAll(rendererCaps,techDef.getRequiredCaps())) 
					{
                        // use the first one that supports all the caps
                        tech = new Technique(this, techDef);
                        techniques.set(name, tech);
                        if(techDef.lightMode == renderManager.getPreferredLightMode() ||
						   techDef.lightMode == LightMode.Disable)
					    {
                            break;  
                        }
                    }
                    lastTech = techDef;
                }
				
				#if debug
                if (tech == null) 
				{
                    throw ("No default technique on material '" + def.name + "'\n"
                            + " is supported by the video hardware. The caps "
                            + lastTech.getRequiredCaps() + " are required.");
                }
				#end
            } 
			else
			{
                // create "special" technique instance
                var techDef:TechniqueDef = def.getTechniqueDef(name);
				
				#if debug
                if (techDef == null)
				{
                    throw ("For material " + def.name + ", technique not found: " + name);
                }

                if (!ArrayUtil.containsAll(rendererCaps, techDef.getRequiredCaps()))
				{
                    throw ("The explicitly chosen technique '" + name + "' on material '" + def.name + "'\n"
                            + "requires caps " + techDef.getRequiredCaps() + " which are not "
                            + "supported by the video renderer");
                }
				#end

                tech = new Technique(this, techDef);
                techniques.set(name, tech);
            }
        } 
		
		// attempting to switch to an already active technique.
		if (mTechnique == tech)
		{
            return;
        }

        mTechnique = tech;
        tech.makeCurrent(true, rendererCaps, renderManager);

        // shader was changed
        sortingId = -1;
    }
	
	private function autoSelectTechnique(rm:RenderManager):Void
	{
        if (mTechnique == null) 
		{
            selectTechnique(DEFAULT_TECHNIQUE, rm);
        } 
		else 
		{
            mTechnique.makeCurrent(false, rm.getRenderer().getCaps(), rm);
        }
    }
	
	/**
     * Check if setting the parameter given the type and name is allowed.
     * @param type The type that the "set" function is designed to set
     * @param name The name of the parameter
     */
	#if debug
    private inline function checkSetParam(type:VarType, name:String):Void
	{
        var paramDef:MatParam = def.getMaterialParam(name);
        if (paramDef == null) 
		{
            Logger.warn ("Material parameter is not defined: " + name);
			return;
        }
        if (type != VarType.NONE && paramDef.type != type) 
		{
            Logger.warn('Material parameter being set: ${name} with type ${type} doesnt match definition types ${paramDef.type}');
        }
    }
	#end
	
	public inline function getParam(name:String):MatParam
	{
		return paramValuesMap.get(name);
	}
	
	/**
     * Returns the ListMap of all parameters set on this material.
     *
     * @return a ListMap of all parameters set on this material.
     *
     * @see #setParam(String, com.jme3.shader.VarType, java.lang.Object)
     */
    public inline function getParamsMap():FastStringMap<MatParam>
	{
        return paramValuesMap;
    }
	
	/**
     * Returns the texture parameter set on this material with the given name,
     * returns <code>null</code> if the parameter is not set.
     *
     * @param name The parameter name to look up.
     * @return The MatParamTexture if set, or null if not set.
     */
    public function getTextureParam(name:String):MatParamTexture
	{
        var param:MatParam = paramValuesMap.get(name);
        if (param != null && Std.is(param, MatParamTexture))
		{
            return cast param;
        }
		else
			return null;
    }
	
	private function checkMaterialDef(name:String, type:VarType, value:Dynamic):Bool
	{
		if (this.def == null)
		{
			if (cacheParamValue == null)
				cacheParamValue = new FastStringMap<MatParam>();
				
			var param:MatParam = cacheParamValue.get(name);
			if (param == null)
			{
				if (type == VarType.TEXTURE2D || type == VarType.TEXTURECUBEMAP)
				{
					cacheParamValue.set(name, new MatParamTexture(type, name, value));
				}
				else
				{
					cacheParamValue.set(name, new MatParam(type, name, value));
				}
			}
			else
			{
				param.value = value;
			}
	
			return false;
		}
		else
		{
			return true;
		}
	}
	
	public function setParam(name:String, type:VarType, value:Dynamic):Void
	{
		if (!checkMaterialDef(name, type, value))
		{
			return;
		}
		
		#if debug
		checkSetParam(type, name);
		#end
		
		if (type == VarType.TEXTURE2D || type == VarType.TEXTURECUBEMAP)
		{
			setTextureParam(name, type, cast value);
		}
		else
		{
			var param:MatParam = getParam(name);
			if (param == null)
			{
				var newParam:MatParam = new MatParam(type, name, value);
				paramValueList.push(newParam);
				paramValuesMap.set(name, newParam);
			}
			else
			{
				param.value = value;
			}
			
			if (mTechnique != null)
			{
				mTechnique.notifyParamChanged(name, type, value);
			}
		}
	}
	
	/**
     * Clear a parameter from this material. The parameter must exist
     * @param name the name of the parameter to clear
     */
    public function clearParam(name:String):Void
	{
		#if debug
        checkSetParam(VarType.NONE, name);
		#end
		
        var matParam:MatParam = getParam(name);
        if (matParam == null) 
		{
            return;
        }
        
		paramValueList.remove(matParam);
        paramValuesMap.remove(name);
		
        if (Std.is(matParam, MatParamTexture))
		{
			paramTextureList.remove(cast matParam);
            sortingId = -1;
        }
		
        if (mTechnique != null)
		{
            mTechnique.notifyParamChanged(name, VarType.NONE, null);
        }
    }
	
	public function setTextureParam(name:String, type:VarType, value:Texture):Void
	{
		if (!checkMaterialDef(name, type, value))
		{
			return;
		}
		
		if (value == null) 
		{
            // clear it
            clearParam(name);
            return;
        }
		
		#if debug
		checkSetParam(type, name);
		#end
		
        var textureParam:MatParamTexture = getTextureParam(name);
        if (textureParam == null) 
		{
            var paramDef:MatParamTexture = cast def.getMaterialParam(name);
			
			var newParam:MatParamTexture = new MatParamTexture(type, name, value);
			paramValueList.push(newParam);
			paramTextureList.push(newParam);
            paramValuesMap.set(name, newParam);
        } 
		else
		{
            textureParam.texture = value;
        }

        // need to recompute sort ID
        sortingId = -1;
	}
	
	public function getTextureParams():Array<MatParamTexture>
	{
		return paramTextureList;
	}
	
	/**
     * Pass a texture to the material shader.
     *
     * @param name the name of the texture defined in the material definition
     * (j3md) (for example Texture for Lighting.j3md)
     * @param value the Texture object previously loaded by the asset manager
     */
	public function setTexture(name:String, value:Texture):Void
	{
		if (value == null)
		{
			clearParam(name);
			return;
		}
		
		var paramType:VarType = VarType.NONE;
        switch (value.type)
		{
            case TextureType.TwoDimensional:
                paramType = VarType.TEXTURE2D;
            case TextureType.CubeMap:
                paramType = VarType.TEXTURECUBEMAP;
            default:
                throw ("Unknown texture type: " + value.type);
        }
		
		if (!checkMaterialDef(name, paramType, value))
		{
			return;
		}

        setTextureParam(name, paramType, value);
	}
	
	public inline function setBoolean(name:String, value:Bool):Void
	{
		setParam(name, VarType.BOOL, value);
	}

	public inline function setInt(name:String, value:Int):Void
	{
		setParam(name, VarType.INT, value);
	}

	public inline function setFloat(name:String, value:Float):Void
	{
		setParam(name, VarType.FLOAT, value);
	}

	public inline function setColor(name:String, value:Color):Void
	{
		setParam(name, VarType.COLOR, value);
	}
	
	public inline function setMatrix4(name:String, value:Matrix4f):Void
	{
		setParam(name, VarType.MATRIX4, value);
	}
	
	public inline function setVector4(name:String, value:Vector4f):Void
	{
		setParam(name, VarType.VECTOR4, value);
	}
	
	public inline function setVector3(name:String, value:Vector3f):Void
	{
		setParam(name, VarType.VECTOR3, value);
	}
	
	public inline function setVector2(name:String, value:Vector2f):Void
	{
		setParam(name, VarType.VECTOR2, value);
	}
	
	public function dispose():Void
	{
		if (paramValuesMap != null)
		{
			paramValuesMap.clear();
			paramValuesMap = null;
		}
		
		if (techniques != null)
		{
			techniques.clear();
			techniques = null;
		}
		
		mTechnique = null;
		
		additionalState = null;
		mergedRenderState = null;
		
		if (def != null)
		{
			def.dispose();
			def = null;
		}
	}
}

