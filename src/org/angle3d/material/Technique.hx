package org.angle3d.material;

import org.angle3d.manager.ShaderManager;
import org.angle3d.material.shader.DefineList;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderKey;
import org.angle3d.material.shader.Uniform;
import org.angle3d.renderer.Caps;
import org.angle3d.renderer.RenderManager;

/**
 * Represents a technique instance.
 */
class Technique
{
	public var def:TechniqueDef;
	public var owner:Material;
	
	private var needReload:Bool = true;
	private var shader:Shader;
	
	private var defines:DefineList;

	public function new(owner:Material,def:TechniqueDef)
	{
		this.owner = owner;
		this.def = def;
		
		this.defines = new DefineList();
	}
	
	/**
     * Returns true if the technique must be reloaded.
     * <p>
     * If a technique needs to reload, then the Material should
     * call makeCurrent on this technique.
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
	
	/**
     * Called by the material to tell the technique a parameter was modified.
     * Specify null for value if the param is to be cleared.
     */
    public function notifyParamChanged(paramName:String, type:String, value:Dynamic):Void
	{
        // Check if there's a define binding associated with this parameter.
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
                //u.setValue(VarType.FLOAT, value);
            default:
                u.setValue(varType, value);
        }
    }
	
	/**
     * Prepares the technique for use by loading the shader and setting
     * the proper defines based on material parameters.
     * 
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
		this.shader = null;
		
		if (!isReady())
		{
			if (def != null)
				def.loadSource();
			return;
				
		}
		
		var shaderKey:ShaderKey = new ShaderKey(getAllDefines(), def.vertName, def.fragName);
		this.shader = ShaderManager.instance.registerShader(shaderKey, def.vertSource, def.fragSource);
		
		needReload = false;
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

