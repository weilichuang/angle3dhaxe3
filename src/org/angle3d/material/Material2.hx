package org.angle3d.material;

import flash.errors.Error;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.Light;
import org.angle3d.light.LightList;
import org.angle3d.light.LightType;
import org.angle3d.light.PointLight;
import org.angle3d.light.SpotLight;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.Uniform;
import org.angle3d.material.technique.Technique;
import org.angle3d.math.Color;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;
import org.angle3d.renderer.IRenderer;
import org.angle3d.renderer.RenderManager;
import org.angle3d.scene.Geometry;
import org.angle3d.texture.TextureMapBase;
import org.angle3d.texture.TextureType;
import org.angle3d.utils.Assert;
import org.angle3d.utils.Logger;


/**
 * 一个Material可能有多个Technique
 * @author weilichuang
 *
 */
class Material2
{
	private static var nullDirLight:Vector<Float>;
	
	private static var additiveLight:RenderState;
	
	private static var depthOnly:RenderState;
	
	/**
	 * 特殊函数，用于执行一些static变量的定义等(有这个函数时，static变量预先赋值必须也放到这里面)
	 */
	static function __init__():Void
	{
		nullDirLight = Vector.ofArray([0.0, -1.0, 0.0, -1.0]);
		
		depthOnly = new RenderState();
		depthOnly.setDepthTest(true);
		depthOnly.setDepthWrite(true);
		depthOnly.setCullMode(CullMode.BACK);
		depthOnly.setColorWrite(false);
		
		additiveLight = new RenderState();
		additiveLight.setBlendMode(BlendMode.AlphaAdditive);
		additiveLight.setDepthWrite(false);
	}
	
	public var name:String;
	public var transparent:Bool;

	public var def:MaterialDef;
	
	public var sortingId:Int;

	public var receivesShadows(get, set):Bool;
	

	private var additionalState:RenderState;
    private var mergedRenderState:RenderState;
	
	private var mReceivesShadows:Bool;

	private var paramValues:StringMap<MatParam>;
	private var technique:Technique;
	private var techniques:StringMap<Technique>;

	private var nextTexUnit:Int;

	public function new(def:MaterialDef)
	{
		this.def = def;

		paramValues = new StringMap<MatParam>();
		techniques = new StringMap<Technique>();
		
		transparent = false;
		mReceivesShadows = false;
		sortingId = -1;
		nextTexUnit = 0;
		
		additionalState = null;
		mergedRenderState = new RenderState();
		
		initParams();
	}
	
	private function initParams():Void
	{
		// Load default values from definition (if any)
		var paramsMap:StringMap<MatParam> = def.getMaterialParams();
		var interator:Iterator<MatParam> = paramsMap.iterator();
        for (param in interator) 
		{
            if (param.value != null) 
			{
                setParam(param.name, param.type, parseJsonValue(param.type, param.value));
            }
        }
	}
	
	/**
	 * 解析Json中保持的参数值
	 * @param	type
	 * @param	value
	 * @return
	 */
	private function parseJsonValue(type:String, value:Dynamic):Dynamic
	{
		var realValue:Dynamic = null;
		switch(type)
		{
			case VarType.COLOR:
				realValue = new Color(value[0], value[1], value[2], value[3]);
			case VarType.VECTOR2:
				realValue = new Vector2f(value[0], value[1]);
			case VarType.VECTOR3:
				realValue = new Vector3f(value[0], value[1], value[2]);
			case VarType.VECTOR4:
				realValue = new Vector4f(value[0], value[1], value[2], value[3]);
			case VarType.QUATERNION:
				realValue = new Quaternion(value[0], value[1], value[2], value[3]);
			default:
				realValue = value;
		}
		return realValue;
	}

	/**
	 * get_the material definition (j3md file info) that <code>this</code>
	 * material is implementing.
	 *
	 * @return the material definition this material implements.
	 */
	public function getMaterialDef():MaterialDef
	{
		return def;
	}

	/**
	 * Check if setting the parameter given the type and name is allowed.
	 * @param type The type that the "set" function is designed to set
	 * @param name The name of the parameter
	 */
	private function checkSetParam(type:String, name:String):Void
	{
		var paramDef:MatParam = def.getMaterialParam(name);
		if (paramDef == null)
		{
			throw new Error("Material parameter is not defined: " + name);
		}
		
		if (type != null && paramDef.type != type) 
		{
			Logger.warn("Material parameter being set: {$name} with "
				+ "type {$type} doesn''t match definition types {$paramDef.type}");
		}
	}

	/**
	 * Pass a parameter to the material shader.
	 *
	 * @param name the name of the parameter defined in the material definition (j3md)
	 * @param type the type of the parameter {@link VarType}
	 * @param value the value of the parameter
	 */
	public function setParam(name:String, type:String, value:Dynamic):Void
	{
		checkSetParam(type, name);

		if (VarType.isTextureType(type))
		{
			setTextureParam(name, type, Std.instance(value,TextureMapBase));
		}
		else
		{
			var matParam:MatParam = getParam(name);
			if (matParam == null)
			{
				paramValues.set(name, new MatParam(type, name, value));
			}
			else
			{
				matParam.value = value;
			}

			if (technique != null)
			{
				technique.notifyParamChanged(name, type, value);
			}
		}
	}

	/**
	 * Returns the parameter set_on this material with the given name,
	 * returns <code>null</code> if the parameter is not set.
	 *
	 * @param name The parameter name to look up.
	 * @return The MatParam if set, or null if not set.
	 */
	public inline function getParam(name:String):MatParam
	{
		return paramValues.get(name);
	}

	/**
	 * Clear a parameter from this material. The parameter must exist
	 * @param name the name of the parameter to clear
	 */
	public function clearParam(name:String):Void
	{
		checkSetParam(null, name);

		var matParam:MatParam = getParam(name);
		if (matParam == null)
		{
			return;
		}

		paramValues.remove(name);
		if (Std.is(matParam,MatParamTexture))
		{
			var texUnit:Int = Std.instance(matParam,MatParamTexture).index;
			nextTexUnit--;
			var param:MatParam;
			var keys:Iterator<String> = paramValues.keys();
			for (key in keys)
			{
				var param:MatParam = paramValues.get(key);
				if (Std.is(param,MatParamTexture))
				{
					var texParam:MatParamTexture = Std.instance(param, MatParamTexture);
					if (texParam.index > texUnit)
					{
						texParam.index = texParam.index - 1;
					}
				}
			}
			sortingId = -1;
		}
		
		if (technique != null)
		{
			technique.notifyParamChanged(name, null, null);
		}
	}


	/**
	 * set a texture parameter.
	 *
	 * @param name The name of the parameter
	 * @param type The variable type {@link VarType}
	 * @param value The texture value of the parameter.
	 */
	public function setTextureParam(name:String, type:String, value:TextureMapBase):Void
	{
		Assert.assert(value != null, "贴图不能为null");

		checkSetParam(type, name);
		
		var matParam:MatParamTexture = getTextureParam(name);
		if (matParam == null)
		{
			paramValues.set(name, new MatParamTexture(type, name, value, nextTexUnit++));
		}
		else
		{
			matParam.texture = value;
		}

		if (technique != null)
		{
			technique.notifyParamChanged(name, type, nextTexUnit - 1);
		}

		// need to recompute sort ID
		sortingId = -1;
	}

	/**
	 * Returns the texture parameter set_on this material with the given name,
	 * returns <code>null</code> if the parameter is not set.
	 *
	 * @param name The parameter name to look up.
	 * @return The MatParamTexture if set, or null if not set.
	 */
	public function getTextureParam(name:String):MatParamTexture
	{
		var param:MatParam = paramValues.get(name);
		if (Std.is(param,MatParamTexture))
		{
			return Std.instance(param,MatParamTexture);
		}
		return null;
	}

	/**
	 * Pass a texture to the material shader.
	 *
	 * @param name the name of the texture defined in the material definition
	 * (j3md) (for example Texture for Lighting.j3md)
	 * @param value the Texture object previously loaded by the asset_manager
	 */
	public function setTexture(name:String, value:TextureMapBase):Void
	{
		if (value == null)
		{
			// clear it
			clearParam(name);
			return;
		}

		var paramType:String = null;
		switch (value.type)
		{
			case TextureType.TwoDimensional:
				paramType = VarType.TEXTURE2D;
			case TextureType.CubeMap:
				paramType = VarType.TEXTURECUBEMAP;
			default:
				throw new Error("Unknown texture type: " + value.type);
		}

		setTextureParam(name, paramType, value);
	}

	/**
	 * Pass a Matrix4f to the material shader.
	 *
	 * @param name the name of the matrix defined in the material definition (j3md)
	 * @param value the Matrix4f object
	 */
	public inline function setMatrix4(name:String, value:Matrix4f):Void
	{
		setParam(name, VarType.MATRIX4, value);
	}

	/**
	 * Pass a Bool to the material shader.
	 *
	 * @param name the name of the Bool defined in the material definition (j3md)
	 * @param value the Bool value
	 */
	public inline function setBool(name:String, value:Bool):Void
	{
		setParam(name, VarType.BOOL, value);
	}

	/**
	 * Pass a float to the material shader.
	 *
	 * @param name the name of the float defined in the material definition (j3md)
	 * @param value the float value
	 */
	public inline function setFloat(name:String, value:Float):Void
	{
		setParam(name, VarType.FLOAT, value);
	}

	/**
	 * Pass an int to the material shader.
	 *
	 * @param name the name of the int defined in the material definition (j3md)
	 * @param value the int value
	 */
	public inline function setInt(name:String, value:Int):Void
	{
		setParam(name, VarType.FLOAT, value);
	}

	/**
	 * Pass a Color to the material shader.
	 *
	 * @param name the name of the color defined in the material definition (j3md)
	 * @param value the ColorRGBA value
	 */
	public inline function setColor(name:String, value:Color):Void
	{
		setParam(name, VarType.VECTOR4, value);
	}

	/**
	 * Pass a Vector2f to the material shader.
	 *
	 * @param name the name of the Vector2f defined in the material definition (j3md)
	 * @param value the Vector2f value
	 */
	public inline function setVector2(name:String, value:Vector2f):Void
	{
		setParam(name, VarType.VECTOR2, value);
	}

	/**
	 * Pass a Vector3f to the material shader.
	 *
	 * @param name the name of the Vector3f defined in the material definition (j3md)
	 * @param value the Vector3f value
	 */
	public inline function setVector3(name:String, value:Vector3f):Void
	{
		setParam(name, VarType.VECTOR3, value);
	}

	/**
	 * Pass a Vector4f to the material shader.
	 *
	 * @param name the name of the Vector4f defined in the material definition (j3md)
	 * @param value the Vector4f value
	 */
	public inline function setVector4(name:String, value:Vector4f):Void
	{
		setParam(name, VarType.VECTOR4, value);
	}

	/**
	 * Check if the material should receive shadows or not.
	 *
	 * @return True if the material should receive shadows.
	 *
	 * @see Material#setReceivesShadows(Bool)
	 */
	private inline function get_receivesShadows():Bool
	{
		return mReceivesShadows;
	}

	/**
	 * set if the material should receive shadows or not.
	 *
	 * <p>This value is merely a marker, by itself it does nothing.
	 * Generally model loaders will use this marker to indicate
	 * the material should receive shadows and therefore any
	 * geometries using it should have the {@link ShadowMode#Receive} set
	 * on them.
	 *
	 * @param receivesShadows if the material should receive shadows or not.
	 */
	private inline function set_receivesShadows(receivesShadows:Bool):Bool
	{
		return mReceivesShadows = receivesShadows;
	}
	
	/**
     * Uploads the lights in the light list as two uniform arrays.<br/><br/>
     *      * <p>
     * <code>uniform vec4 g_LightColor[numLights];</code><br/>
     * // g_LightColor.rgb is the diffuse/specular color of the light.<br/>
     * // g_Lightcolor.a is the type of light, 0 = Directional, 1 = Point, <br/>
     * // 2 = Spot. <br/>
     * <br/>
     * <code>uniform vec4 g_LightPosition[numLights];</code><br/>
     * // g_LightPosition.xyz is the position of the light (for point lights)<br/>
     * // or the direction of the light (for directional lights).<br/>
     * // g_LightPosition.w is the inverse radius (1/r) of the light (for attenuation) <br/>
     * </p>
     */
	private function updateLightListUniforms(shader:Shader, g:Geometry, numLights:Int):Void
	{
		// this shader does not do lighting, ignore.
		if (numLights == 0)
		{
			return;
		}
		
		var lightList:LightList = g.getWorldLightList();
		
		var lightColor:Uniform = shader.getUniform(ShaderType.VERTEX, "u_LightColor");
		var lightPos:Uniform = shader.getUniform(ShaderType.VERTEX, "u_LightPosition");
		var lightDir:Uniform = shader.getUniform(ShaderType.VERTEX, "u_LightDirection");
		
		var lightColorVec:Vector<Float> = new Vector<Float>(numLights * 4,true);
		var lightPosVec:Vector<Float> = new Vector<Float>(numLights * 4,true);
		var lightDirVec:Vector<Float> = new Vector<Float>(numLights * 4,true);
		
		var ambientColor:Uniform = shader.getUniform(ShaderType.VERTEX, "u_Ambient");
		ambientColor.setColor(lightList.getAmbientColor());
		
		var lighSize:Int = lightList.getSize();
		
		var lightIndex:Int = 0;
		for (i in 0...numLights)
		{
			if (lighSize <= i)
			{
				for (j in 0...4)
				{
					lightColorVec[lightIndex * 4 + j] = 0.0;
					lightPosVec[lightIndex * 4 + j] = 0.0;
				}
			}
			else
			{
				var light:Light = lightList.getLightAt(i);
				var color:Color = light.color;
				
				lightColorVec[i * 4 + 0] = color.r;
				lightColorVec[i * 4 + 1] = color.g;
				lightColorVec[i * 4 + 2] = color.b;
				lightColorVec[i * 4 + 3] = Type.enumIndex(light.type) - 1;
				
				switch(light.type)
				{
					case LightType.Directional:
						
						var dl:DirectionalLight = Std.instance(light, DirectionalLight);
						var dir:Vector3f = dl.direction;
					
						lightPosVec[lightIndex * 4 + 0] = dir.x;
						lightPosVec[lightIndex * 4 + 1] = dir.y;
						lightPosVec[lightIndex * 4 + 2] = dir.z;
						lightPosVec[lightIndex * 4 + 3] = -1;
						
					case LightType.Point:
						
						var pl:PointLight = Std.instance(light, PointLight);
						var pos:Vector3f = pl.position;
						var invRadius:Float = pl.invRadius;
						
						lightPosVec[lightIndex * 4 + 0] = pos.x;
						lightPosVec[lightIndex * 4 + 1] = pos.y;
						lightPosVec[lightIndex * 4 + 2] = pos.z;
						lightPosVec[lightIndex * 4 + 3] = invRadius;
						
					case LightType.Spot:
						
						var sl:SpotLight = Std.instance(light, SpotLight);
						var pos:Vector3f = sl.position;
						var dir:Vector3f = sl.direction;

						lightPosVec[lightIndex * 4 + 0] = pos.x;
						lightPosVec[lightIndex * 4 + 1] = pos.y;
						lightPosVec[lightIndex * 4 + 2] = pos.z;
						lightPosVec[lightIndex * 4 + 3] = sl.invSpotRange;
						
						lightDirVec[lightIndex * 4 + 0] = dir.x;
						lightDirVec[lightIndex * 4 + 1] = dir.y;
						lightDirVec[lightIndex * 4 + 2] = dir.z;
						lightDirVec[lightIndex * 4 + 3] = sl.packedAngleCos;
						
					case LightType.Ambient:
						// skip this light. Does not increase lightIndex
						continue;
					default:
						Assert.assert(false, "Unknown type of light: " + light.type);
			    }
			}
			
			lightIndex++;
		}
		
		while (lightIndex < numLights)
		{
			for (j in 0...4)
			{
				lightColorVec[lightIndex * 4 + j] = 0.0;
				lightPosVec[lightIndex * 4 + j] = 0.0;
			}	
			
			lightIndex++;
		}
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
	private function renderMultipassLighting(shader:Shader, g:Geometry, rm:RenderManager):Void
	{
		var r:IRenderer = rm.getRenderer();
		var lightList:LightList = g.getWorldLightList();
		var numLight:Int = lightList.getSize();
		
		var lightDir:Uniform = shader.getUniform(ShaderType.VERTEX, "u_LightDirection");
		var lightColor:Uniform = shader.getUniform(ShaderType.VERTEX, "u_LightColor");
		var lightPos:Uniform = shader.getUniform(ShaderType.VERTEX, "u_LightPosition");
		var ambientColor:Uniform = shader.getUniform(ShaderType.VERTEX, "u_Ambient");
		
		
		var isFirstLight:Bool = true;
		var isSecondLight:Bool = false;
		
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
				ambientColor.setColor(lightList.getAmbientColor());
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

			l.color.toUniform(tmpColors);
			tmpColors[3] = Type.enumIndex(l.type) - 1;
			lightColor.setVector(tmpColors);
			
			switch(l.type)
			{
				case LightType.Directional:
					
					var dl:DirectionalLight = Std.instance(l, DirectionalLight);
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
					
					var pl:PointLight = Std.instance(l, PointLight);
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
					
					var sl:SpotLight = Std.instance(l, SpotLight);
					var pos:Vector3f = sl.position;
					var dir:Vector3f = sl.direction;
					
					tmpLightPosition[0] = pos.x;
					tmpLightPosition[1] = pos.y;
					tmpLightPosition[2] = pos.z;
					tmpLightPosition[3] = sl.invSpotRange;
					lightPos.setVector(tmpLightPosition);
					
					var tmpVec:Vector4f = new Vector4f();
					tmpVec.setTo(dir.x, dir.y, dir.z, 0);
					
					rm.getCamera().getViewMatrix().multVec4(tmpVec, tmpVec);
					
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
			r.renderMesh(g.getMesh());
		}
		
		//只有环境光
		if (isFirstLight && numLight > 0)
		{
			// There are only ambient lights in the scene. Render
            // a dummy "normal light" so we can see the ambient
			ambientColor.setVector(lightList.getAmbientColor().toUniform());
			lightColor.setVector(Color.BlackNoAlpha().toUniform());
			lightPos.setVector(nullDirLight);
			
			r.setShader(shader);
			r.renderMesh(g.getMesh());
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
     * {@link #selectTechnique(java.lang.String, com.jme3.renderer.RenderManager) 
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
     * @param geom The geometry to render
     * @param rm The render manager requesting the rendering
     */
	public function render(geometry:Geometry,rm:RenderManager):Void
	{
		var r:IRenderer = rm.getRenderer();
		
		if (rm.forcedRenderState != null) 
		{
            r.applyRenderState(rm.forcedRenderState);
        } 
		else
		{
            if (technique.renderState != null) 
			{
                r.applyRenderState(technique.renderState.copyMergedTo(additionalState, mergedRenderState));
            } 
			else
			{
                r.applyRenderState(RenderState.DEFAULT.copyMergedTo(additionalState, mergedRenderState));
            }
        }
	}
}
