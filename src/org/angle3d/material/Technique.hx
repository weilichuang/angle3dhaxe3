package org.angle3d.material;

import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.light.LightType;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.RenderState;
import org.angle3d.material.shader.DefineList;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.Uniform;
import org.angle3d.renderer.Caps;
import org.angle3d.renderer.RenderManager;
import org.angle3d.scene.mesh.MeshType;

typedef TechniquePredefine = {
	var vertex:Array<String>;
	var fragment:Array<String>;
}

class Technique
{
	public var name(default, null):String;
	public var renderState(get, null):RenderState;
	public var requiresLight(get,set):Bool;

	private var mShaderMap:StringMap<Shader>;
	private var mPreDefineMap:StringMap<TechniquePredefine>;

	private var mRenderState:RenderState;

	private var mRequiresLight:Bool;

	private var _keys:Array<String>;
	
	private var vertexSource:String;
	private var fragmentSource:String;
	
	private var needReload:Bool = true;
	private var shader:Shader;
	
	public var def:TechniqueDef;
	public var owner:Material;
	
	private var defines:DefineList;

	public function new()
	{
		initialize();
	}
	
	/**
     * Returns true if the technique must be reloaded.
     * <p>
     * If a technique needs to reload, then the {@link Material} should
     * call {@link #makeCurrent(com.jme3.asset.AssetManager) } on this
     * technique.
     * 
     * @return true if the technique must be reloaded.
     */
    public function isNeedReload():Bool
	{
        return needReload;
    }
	
	public function getDef():TechniqueDef
	{
		return def;
	}
	
	public function isReady():Bool
	{
		return def != null && def.isReady();
	}
	
	private function initSouce():Void
	{
		vertexSource = getVertexSource();
		fragmentSource = getFragmentSource();
	}
	
	private function get_renderState():RenderState
	{
		return mRenderState;
	}

	/**
	 * 更新Shader属性
	 *
	 * @param	shader
	 */
	public function updateShader(shader:Shader):Void
	{

	}

	/**
     * Returns the shader currently used by this technique instance.
     * <p>
     * Shaders are typically loaded dynamically when the technique is first
     * used, therefore, this variable will most likely be null most of the time.
     * 
     * @return the shader currently used by this technique instance.
     */
	public function getShader():Shader
	{
		return shader;
	}

	private function initialize():Void
	{
		name = Type.getClassName(Type.getClass(this)).split(".").pop();
		
		_keys = [];
		
		mShaderMap = new StringMap<Shader>();
		mPreDefineMap = new StringMap<TechniquePredefine>();

		mRenderState = new RenderState();
		mRequiresLight = false;
		
		this.defines = new DefineList();
		
		initSouce();
	}

	private function get_requiresLight():Bool
	{
		return mRequiresLight;
	}
	
	private function set_requiresLight(value:Bool):Bool
	{
		return mRequiresLight = value;
	}

	
	private function getVertexSource():String
	{
		return "";
	}

	private function getFragmentSource():String
	{
		return "";
	}

	private function getPredefine(lightType:LightType, meshType:MeshType):TechniquePredefine
	{
		var predefine = { vertex:[], fragment:[] };

		if (meshType == MeshType.KEYFRAME)
		{
			predefine.vertex.push("USE_KEYFRAME");
		}
		else if (meshType == MeshType.SKINNING)
		{
			predefine.vertex.push("USE_SKINNING");
		}

		return predefine;
	}

	private function getKey(lightType:LightType, meshType:MeshType):String
	{
		return name + "_" + meshType.getName();
	}
	
	/**
     * Called by the material to tell the technique a parameter was modified.
     * Specify <code>null</code> for value if the param is to be cleared.
     */
    public function notifyParamChanged(paramName:String, type:String, value:Dynamic):Void
	{
        // Check if there's a define binding associated with this
        // parameter.
        var defineName:String = def.getShaderParamDefine(paramName);
        if (defineName != null)
		{
            // There is a define. Change it on the define list.
            // The "needReload" variable will determine
            // if the shader will be reloaded when the material
            // is rendered.
            
            if (value == null) 
			{
                // Clear the define.
                needReload = defines.remove(defineName) || needReload;
            } 
			else 
			{
                // Set the define.
                needReload = defines.set(defineName, type, value) || needReload;
            }
        }
    }
	
	public function updateUniformParam(shaderType:ShaderType,paramName:String, varType:String, value:Dynamic):Void
	{
        var u:Uniform = shader.getUniform(shaderType,paramName);
        switch (varType)
		{
            case VarType.TEXTURE2D,VarType.TEXTURECUBEMAP:
                u.setValue(VarType.FLOAT, value);
            default:
                u.setValue(varType, value);
        }
    }
	
	/**
     * Prepares the technique for use by loading the shader and setting
     * the proper defines based on material parameters.
     * 
     * @param assetManager The asset manager to use for loading shaders.
     */
    public function makeCurrent(techniqueSwitched:Bool, rendererCaps:Array<Caps>, rm:RenderManager):Void
	{
        if (techniqueSwitched)
		{
            if (defines.update(owner.getParamsMap(), def)) 
			{
                needReload = true;
            }
			
            if (getDef().lightMode == LightMode.SinglePass)
			{
                defines.set("SINGLE_PASS_LIGHTING", VarType.BOOL, true);
                defines.set("NB_LIGHTS", VarType.FLOAT, rm.getSinglePassLightBatchSize() * 3);
            } 
			else 
			{
                defines.set("SINGLE_PASS_LIGHTING", VarType.BOOL, null);
            }
        }

        if (needReload) 
		{
            loadShader(rendererCaps);
        }
    }
	
	private function loadShader(caps:Array<Caps>):Void
	{
				//var key:String = getKey(lightType, meshType);
//
		//var shader:Shader = mShaderMap.get(key);
//
		//if (shader == null)
		//{
			//if (!mPreDefineMap.exists(key))
			//{
				//mPreDefineMap.set(key, getPredefine(lightType, meshType));
			//}
//
			//var option:TechniquePredefine = mPreDefineMap.get(key);
//
			//shader = ShaderManager.instance.registerShader(key, vertexSource,fragmentSource,option.vertex,option.fragment);
//
			//mShaderMap.set(key,shader);
		//}
		
		needReload = false;
	}
	
	public function getWorldBindUniforms():Vector<Uniform>
	{
		return new Vector<Uniform>();
	}
	
	/**
     * Computes the define list
     * @return the complete define list
     */
    public function getAllDefines():DefineList
	{
        var allDefines:DefineList = new DefineList();
        allDefines.addFrom(def.getShaderPresetDefines());
        allDefines.addFrom(defines);
        return allDefines;
    }
}

