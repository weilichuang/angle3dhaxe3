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
	//private var _keys:Array<String>;
	//private var mShaderMap:StringMap<Shader>;
	//private var mPreDefineMap:StringMap<TechniquePredefine>;

	private var needReload:Bool = true;
	private var shader:Shader;
	
	public var def:TechniqueDef;
	public var owner:Material;
	
	private var defines:DefineList;

	public function new(owner:Material,def:TechniqueDef)
	{
		this.owner = owner;
		this.def = def;
		
		//_keys = [];
		//mShaderMap = new StringMap<Shader>();
		//mPreDefineMap = new StringMap<TechniquePredefine>();

		this.defines = new DefineList();
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

	//private function getPredefine(lightType:LightType, meshType:MeshType):TechniquePredefine
	//{
		//var predefine = { vertex:[], fragment:[] };
//
		//if (meshType == MeshType.KEYFRAME)
		//{
			//predefine.vertex.push("USE_KEYFRAME");
		//}
		//else if (meshType == MeshType.SKINNING)
		//{
			//predefine.vertex.push("USE_SKINNING");
		//}
//
		//return predefine;
	//}
	
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
	
	public function updateUniformParam(paramName:String, varType:String, value:Dynamic):Void
	{
        var u:Uniform = shader.getUniform(paramName);
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
		if (!isReady())
		{
			if (def != null)
				def.loadSource();
			return;
				
		}

		//var key:String = getKey(lightType, meshType);
		//var shader:Shader = mShaderMap.get(key);
		//if (shader == null)
		//{
			//if (!mPreDefineMap.exists(key))
			//{
				//mPreDefineMap.set(key, getPredefine(lightType, meshType));
			//}
			//var option:TechniquePredefine = mPreDefineMap.get(key);
			//shader = ShaderManager.instance.registerShader(key, vertexSource,fragmentSource,option.vertex,option.fragment);
			//mShaderMap.set(key,shader);
		//}
		
		var allDefines:DefineList = getAllDefines();
		
		this.shader = ShaderManager.instance.registerShader("", def.vertSource, def.fragSource);
		
		needReload = false;
	}
	
	//public function getWorldBindUniforms():Vector<Uniform>
	//{
		//return new Vector<Uniform>();
	//}
	
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

