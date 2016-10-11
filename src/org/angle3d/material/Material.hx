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
import org.angle3d.material.LightMode;
import org.angle3d.material.Technique;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.TextureParam;
import org.angle3d.material.shader.Uniform;
import org.angle3d.material.shader.UniformList;
import org.angle3d.math.Color;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;
import org.angle3d.renderer.Caps;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.Stage3DRenderer;
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
 * Setting the parameters can modify the behavior of a shader.
 * <p/>
 * 
 */
class Material
{
	private static var materialCache:FastStringMap<String> = new FastStringMap<String>();
	
	/**
     * the name of the material (not the same as the asset name)
     */
	public var name:String;
	
	private var defFile:String;
	private var def:MaterialDef;
	
	/**
	 * def未加载完成时，设置的数据会存在这里
	 */
	private var cacheParamValue:FastStringMap<MatParam>;
	private var paramValuesMap:FastStringMap<MatParam>;
	private var paramValueList:Array<MatParam>;
	private var paramTextureList:Array<MatParamTexture>;
	
	private var technique:Technique;
	private var techniqueMap:FastStringMap<Technique>;
	
	private var additionalState:RenderState;
    private var mergedRenderState:RenderState;
	
	private var transparent:Bool = false;
	private var receivesShadows:Bool = false;
	
	private var sortingId:Int = -1;

	public function new()
	{
		additionalState = null;
		mergedRenderState = new RenderState();

		paramValuesMap = new FastStringMap<MatParam>();
		paramValueList = [];
		paramTextureList = [];
		
		technique = null;
		techniqueMap = new FastStringMap<Technique>();
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
     * technique by using `selectTechnique`.
     *
     * @return the currently active technique.
     *
     * @see `selectTechnique`
     */
	public inline function getActiveTechnique():Technique
	{
        return technique;
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
		var keys:Array<String> = map.keys();
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
			var keys:Array<String> = cacheParamValue.keys();
			for (paramName in keys)
			{
				var param:MatParam = cacheParamValue.get(paramName);
				setParam(param.name, param.type, param.value);
			}
			cacheParamValue = null;
		}
	}
	
	/**
     * Get the material definition (j3md file info) that `this`
     * material is implementing.
     *
     * @return the material definition this material implements.
     */
    public inline function getMaterialDef():MaterialDef
	{
        return def;
    }
	
	 /**
     * Acquire the additional render state to apply
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
	
	/**
     * Check if the transparent value marker is set on this material.
     * @return True if the transparent value marker is set on this material.
     * @see setTransparent(boolean)
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
        if (sortingId == -1 && technique != null)
		{
			sortingId = technique.getSortId() << 16;
            var texturesSortId:Int = 17;
			for (param in paramTextureList)
			{
				if (param.texture == null) 
				{
					continue;
				}
				
				var textureId:Int = param.texture.id;
				if (textureId == -1) 
				{
					textureId = 0;
				}
				
				texturesSortId = texturesSortId * 23 + textureId;
			}
            sortingId |= texturesSortId & 0xFFFF;
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
        if (this.technique != null || other.technique != null)
		{
            // Techniques are considered equal if their names are the same
            // E.g. if user chose custom technique for one material but 
            // uses default technique for other material, the materials 
            // are not equal.
            var thisDefName:String = this.technique != null ? this.technique.getDef().name : TechniqueDef.DEFAULT_TECHNIQUE_NAME;
            var otherDefName:String = other.technique != null ? other.technique.getDef().name : TechniqueDef.DEFAULT_TECHNIQUE_NAME;
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
	
	private function applyOverrides(renderer:Stage3DRenderer, shader:Shader, overrides:Vector<MatParamOverride>, unit:Int):Int
	{
        for (matOverride in overrides)
		{
            var type:VarType = matOverride.type;

            var paramDef:MatParam = def.getMaterialParam(matOverride.name);

            if (paramDef == null || paramDef.type != type || !matOverride.enabled) {
                continue;
            }

            var uniform:Uniform = shader.getUniform(matOverride.name);

            if (matOverride.value != null)
			{
                if (VarType.isTextureType(type))
				{
                    renderer.setTextureAt(unit, cast matOverride.value);
                    uniform.setInt(unit);
                    unit++;
                } 
				else
				{
                    uniform.setValue(type, matOverride.value);
                }
            } 
			else
			{
                uniform.clearValue();
            }
        }
        return unit;
    }

    private function updateShaderMaterialParameters(renderer:Stage3DRenderer, shader:Shader,
													worldOverrides:Vector<MatParamOverride>, forcedOverrides:Vector<MatParamOverride>):Int
    {

        var unit:Int = 0;
        if (worldOverrides != null && worldOverrides.length > 0) 
		{
            unit = applyOverrides(renderer, shader, worldOverrides, unit);
        }
		
        if (forcedOverrides != null && forcedOverrides.length > 0) 
		{
            unit = applyOverrides(renderer, shader, forcedOverrides, unit);
        }

        for (i in 0...paramValueList.length) 
		{
            var param:MatParam = paramValueList[i];
            var type:VarType = param.type;
			
			if (VarType.isTextureType(type))
			{
				var textureParam:TextureParam = shader.getTextureParam(param.name);
				renderer.setTextureAt(textureParam.location, cast param.value);
			}
			else
			{
				var uniform:Uniform = shader.getUniform(param.name);
				if (uniform.isSetByCurrentMaterial()) 
				{
					continue;
				}
				uniform.setValue(type, param.value);
			}
            
        }

        //TODO HACKY HACK remove this when texture unit is handled by the uniform.
        return unit;
    }

    private function updateRenderState(renderManager:RenderManager, renderer:Stage3DRenderer,  techniqueDef:TechniqueDef):Void
	{
        if (renderManager.getForcedRenderState() != null)
		{
            renderer.applyRenderState(renderManager.getForcedRenderState());
        }
		else
		{
            if (techniqueDef.renderState != null)
			{
                renderer.applyRenderState(techniqueDef.renderState.copyMergedTo(additionalState, mergedRenderState));
            } 
			else 
			{
                renderer.applyRenderState(RenderState.DEFAULT.copyMergedTo(additionalState, mergedRenderState));
            }
        }
    }
	
	private function clearUniformsSetByCurrent(shader:Shader):Void
	{
        var uniforms:UniformList = shader.getUniformList(ShaderType.VERTEX);
        var size:Int = uniforms.getUniforms().length;
        for (i in 0...size)
		{
            var u:Uniform = uniforms.getUniformAt(i);
            u.clearSetByCurrentMaterial();
        }
		
		uniforms = shader.getUniformList(ShaderType.FRAGMENT);
        size = uniforms.getUniforms().length;
        for (i in 0...size)
		{
            var u:Uniform = uniforms.getUniformAt(i);
            u.clearSetByCurrentMaterial();
        }
    }

    private function resetUniformsNotSetByCurrent(shader:Shader):Void
	{
        var uniforms:UniformList = shader.getUniformList(ShaderType.VERTEX);
        var size:Int = uniforms.getUniforms().length;
        for (i in 0...size)
		{
            var u:Uniform = uniforms.getUniformAt(i);
            if (!u.isSetByCurrentMaterial())
			{
                if (u.binding == -1)
				{
                    // Don't reset world globals!
                    // The benefits gained from this are very minimal
                    // and cause lots of matrix -> FloatBuffer conversions.
                    u.clearValue();
                }
            }
        }
		
		uniforms = shader.getUniformList(ShaderType.FRAGMENT);
		size = uniforms.getUniforms().length;
        for (i in 0...size)
		{
            var u:Uniform = uniforms.getUniformAt(i);
            if (!u.isSetByCurrentMaterial())
			{
                if (u.binding == -1)
				{
                    // Don't reset world globals!
                    // The benefits gained from this are very minimal
                    // and cause lots of matrix -> FloatBuffer conversions.
                    u.clearValue();
                }
            }
        }
    }

	/**
     * Called by 'RenderManager' to render the geometry by
     * using this material.
     * <p>
     * The material is rendered as follows:
     * <ul>
     * <li>Determine which technique to use to render the material -
     * either what the user selected via
     * {@link #selectTechnique(String, com.jme3.renderer.RenderManager)
     * Material.selectTechnique()},
     * or the first default technique that the renderer supports
     * (based on the technique's {@link TechniqueDef#getRequiredCaps() requested rendering capabilities})<ul>
     * <li>If the technique has been changed since the last frame, then it is notified via
     * {@link Technique#makeCurrent(com.jme3.asset.AssetManager, boolean, java.util.EnumSet)
     * Technique.makeCurrent()}.
     * If the technique wants to use a shader to render the model, it should load it at this part -
     * the shader should have all the proper defines as declared in the technique definition,
     * including those that are bound to material parameters.
     * The technique can re-use the shader from the last frame if
     * no changes to the defines occurred.</li></ul>
     * <li>Set the {@link RenderState} to use for rendering. The render states are
     * applied in this order (later RenderStates override earlier RenderStates):<ol>
     * <li>{@link TechniqueDef#getRenderState() Technique Definition's RenderState}
     * - i.e. specific renderstate that is required for the shader.</li>
     * <li>{@link #getAdditionalRenderState() Material Instance Additional RenderState}
     * - i.e. ad-hoc renderstate set per model</li>
     * <li>{@link RenderManager#getForcedRenderState() RenderManager's Forced RenderState}
     * - i.e. renderstate requested by a {@link com.jme3.post.SceneProcessor} or
     * post-processing filter.</li></ol>
     * <li>If the technique {@link TechniqueDef#isUsingShaders() uses a shader}, then the uniforms of the shader must be updated.<ul>
     * <li>Uniforms bound to material parameters are updated based on the current material parameter values.</li>
     * <li>Uniforms bound to world parameters are updated from the RenderManager.
     * Internally {@link UniformBindingManager} is used for this task.</li>
     * <li>Uniforms bound to textures will cause the texture to be uploaded as necessary.
     * The uniform is set to the texture unit where the texture is bound.</li></ul>
     * <li>If the technique uses a shader, the model is then rendered according
     * to the lighting mode specified on the technique definition.<ul>
     * <li>{@link LightMode#SinglePass single pass light mode} fills the shader's light uniform arrays
     * with the first 4 lights and renders the model once.</li>
     * <li>{@link LightMode#MultiPass multi pass light mode} light mode renders the model multiple times,
     * for the first light it is rendered opaque, on subsequent lights it is
     * rendered with {@link BlendMode#AlphaAdditive alpha-additive} blending and depth writing disabled.</li>
     * </ul>
     * <li>For techniques that do not use shaders,
     * fixed function OpenGL is used to render the model (see {@link GL1Renderer} interface):<ul>
     * <li>OpenGL state ({@link FixedFuncBinding}) that is bound to material parameters is updated. </li>
     * <li>The texture set on the material is uploaded and bound.
     * Currently only 1 texture is supported for fixed function techniques.</li>
     * <li>If the technique uses lighting, then OpenGL lighting state is updated
     * based on the light list on the geometry, otherwise OpenGL lighting is disabled.</li>
     * <li>The mesh is uploaded and rendered.</li>
     * </ul>
     * </ul>
     *
     * @param geometry The geometry to render
     * @param lights Presorted and filtered light list to use for rendering
     * @param renderManager The render manager requesting the rendering
     */
    public function render(geometry:Geometry, lights:LightList, renderManager:RenderManager):Void
	{
		if (this.def == null)
			return;
			
		if (technique == null)
		{
			selectTechnique(TechniqueDef.DEFAULT_TECHNIQUE_NAME, renderManager);
		}
		
		if (technique == null)
			return;

        var techniqueDef:TechniqueDef = technique.getDef();
		if (techniqueDef.isNoRender())
			return;
			
		if (!techniqueDef.isLoaded())
			return;
		
		var renderer:Stage3DRenderer = renderManager.getRenderer();
		var rendererCaps:Array<Caps> = renderer.getCaps();
		
		// Apply render state
		updateRenderState(renderManager, renderer, techniqueDef);
		
		// Get world overrides
		var overrides:Vector<MatParamOverride> = geometry.getWorldMatParamOverrides();
		
		// Select shader to use
		var shader:Shader = technique.makeCurrent(renderManager, overrides, renderManager.getForcedMatParams(), lights, rendererCaps);
		
		// Begin tracking which uniforms were changed by material.
		clearUniformsSetByCurrent(shader);
        
        // Set uniform bindings
        renderManager.updateUniformBindings(shader);
        
        // Set material parameters
        var unit:Int = updateShaderMaterialParameters(renderer, shader, overrides, renderManager.getForcedMatParams());

        // Clear any uniforms not changed by material.
        resetUniformsNotSetByCurrent(shader);
        
        // Delegate rendering to the technique
        technique.render(renderManager, shader, geometry, lights, unit);
    }

	/**
     * Select the technique to use for rendering this material.
     * <p>
     * Any candidate technique for selection (either default or named)
     * must be verified to be compatible with the system, for that, the
     * <code>renderManager</code> is queried for capabilities.
     *
     * @param name The name of the technique to select, pass
     * {@link TechniqueDef#DEFAULT_TECHNIQUE_NAME} to select one of the default
     * techniques.
     * @param renderManager The {@link RenderManager render manager}
     * to query for capabilities.
     *
     */
    public function selectTechnique(name:String, renderManager:RenderManager):Void
	{
        // check if already created
        var tech:Technique = techniqueMap.get(name);
		// When choosing technique, we choose one that supports all the caps.
        if (tech == null)
		{
			var rendererCaps:Array<Caps> = renderManager.getRenderer().getCaps();

			var techDefs:Vector<TechniqueDef> = def.getTechniqueDefs(name);
			
			if (techDefs == null || techDefs.length == 0)
			{
				return;
				//throw 'The requested technique $name is not available on material ${def.name}';
			}
			
			var lastTech:TechniqueDef = null;
			var techDef:TechniqueDef = null;
			for (i in 0...techDefs.length)
			{
				techDef = techDefs[i];
				if (ArrayUtil.containsAll(rendererCaps,techDef.getRequiredCaps()))
				{
					// use the first one that supports all the caps
					if (techDef.lightMode == renderManager.getPreferredLightMode() ||
						techDef.lightMode == LightMode.Disable)
					{
						tech = new Technique(this, techDef);
						techniqueMap.set(name, tech);
						break;
					}
				}
				lastTech = techDef;
			}

			#if debug
			if (tech == null)
			{
				throw 'No technique $name on material  ${def.name} is supported by the video hardware. The capabilities ${lastTech.getRequiredCaps()} are required.';
			}
			#end
        }
		else if (technique == tech)
		{
			// attempting to switch to an already active technique.
            return;
		}

        technique = tech;
        technique.notifyTechniqueSwitched();

        // shader was changed
        sortingId = -1;
    }
	
	/**
     * Check if setting the parameter given the type and name is allowed.
     * @param type The type that the "set" function is designed to set
     * @param name The name of the parameter
     */
	#if debug
    private function checkSetParam(type:VarType, name:String):Void
	{
        var paramDef:MatParam = def.getMaterialParam(name);
        if (paramDef == null) 
		{
            throw ("Material parameter is not defined: " + name);
        }
        if (type != VarType.NONE && paramDef.type != type) 
		{
            throw ('Material parameter being set: ${name} with type ${type} doesnt match definition types ${paramDef.type}');
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
     * @see setParam(String, org.angle3d.shader.VarType, java.lang.Object)
     */
    public inline function getParamsMap():FastStringMap<MatParam>
	{
        return paramValuesMap;
    }
	
	/**
     * Returns the texture parameter set on this material with the given name,
     * returns `null` if the parameter is not set.
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
		
		if (VarType.isTextureType(type))
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
			
			if (technique != null)
			{
				technique.notifyParamChanged(name, type, value);
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
		
        if (technique != null)
		{
            technique.notifyParamChanged(name, VarType.NONE, null);
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
			paramValuesMap.set(name, newParam);
			paramValueList.push(newParam);
			paramTextureList.push(newParam);
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
     * @param value the Texture object previously loaded by the asset manager
     */
	public function setTexture(name:String, value:Texture):Void
	{
		if (value == null)
		{
			// clear it
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
		
		if (techniqueMap != null)
		{
			techniqueMap.clear();
			techniqueMap = null;
		}
		
		technique = null;
		
		additionalState = null;
		mergedRenderState = null;
		
		if (def != null)
		{
			def.dispose();
			def = null;
		}
	}
}

