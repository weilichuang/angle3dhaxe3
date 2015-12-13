package org.angle3d.material;

import flash.events.Event;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.node.ProgramNode;
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
	public var owner:Material;
	public var def(get, set):TechniqueDef;
	
	private var mDef:TechniqueDef;
	private var mIsDefLoaded:Bool = false;
	
	private var needReload:Bool = true;
	private var shader:Shader;
	
	private var defines:DefineList;
	
	

	public function new(owner:Material,def:TechniqueDef)
	{
		this.defines = new DefineList();
		
		this.owner = owner;
		this.def = def;
	}
	
	private inline function get_def():TechniqueDef
	{
		return mDef;
	}
	
	private inline function set_def(value:TechniqueDef):TechniqueDef
	{
		if (mDef != null)
		{
			mDef.removeEventListener(Event.COMPLETE, onDefLoadComplete);
		}
		this.mDef = value;
		mIsDefLoaded = this.mDef.isLoaded();
		if (mDef != null)
		{
			mDef.addEventListener(Event.COMPLETE, onDefLoadComplete);
		}
		return this.mDef;
	}
	
	private function onDefLoadComplete(event:Event):Void
	{
		mIsDefLoaded = mDef.isLoaded();
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
	
	public inline function isReady():Bool
	{
		return def != null && def.isLoaded();
	}

	/**
     * Returns the shader currently used by this technique instance.
     * <p>
     * Shaders are typically loaded dynamically when the technique is first
     * used, therefore, this variable will most likely be null most of the time.
     * 
     * @return the shader currently used by this technique instance.
     */
	public inline function getShader():Shader
	{
		return shader;
	}
	
	/**
     * Called by the material to tell the technique a parameter was modified.
     * Specify null for value if the param is to be cleared.
     */
    public function notifyParamChanged(paramName:String, type:Int, value:Dynamic):Void
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
	
	public inline function updateUniformParam(paramName:String, varType:Int, value:Dynamic):Void
	{
        var u:Uniform = shader.getUniform(paramName);
		if (u != null)
			u.setValue(varType, value);
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
			//TODO 优化此处判断，场景中物品非常多时，此处相当耗时
            if (defines.update(owner.getParamsMap(), def)) 
			{
                needReload = true;
            }
			
            if (getDef().lightMode == LightMode.SinglePass)
			{
				var nbLights:Int = cast defines.get("NB_LIGHTS");
				var count:Int = rm.getSinglePassLightBatchSize();
				if (nbLights != count * 3 )
				{
					defines.set("NB_LIGHTS", VarType.FLOAT, count * 3);
					needReload = true;
					
					for (i in 1...4)
					{
						if (i < count)
						{
							defines.set("SINGLE_PASS_LIGHTING" + i, VarType.BOOL, true);
						}
						else
						{
							defines.set("SINGLE_PASS_LIGHTING" + i, VarType.BOOL, false);
						}
					}
				}
            }
			else
			{
				defines.remove("NB_LIGHTS");
			}
			
			//TODO bone
        }

        if (needReload) 
		{
            loadShader(rendererCaps);
        }
    }
	
	//private var _vertProgram:ProgramNode;
	//private var _fragProgram:ProgramNode;
	private function loadShader(caps:Array<Caps>):Void
	{
		this.shader = null;
		
		if (def == null)
			return;
		
		if (!def.isLoaded())
		{
			def.loadSource();
			return;	
		}
		
		//_vertProgram = ShaderManager.instance.sgslParser.exec(def.vertSource);
		//_fragProgram = ShaderManager.instance.sgslParser.exec(def.fragSource);
		
		var shaderKey:ShaderKey = new ShaderKey(getAllDefines(), def.vertName, def.fragName);
		
		var vertSource:String = def.vertSource;
		var fragSource:String = def.fragSource;
		
		if (getDef().lightMode == LightMode.SinglePass)
		{
			var nbLights:Int = cast defines.get("NB_LIGHTS");
			
			vertSource = StringTools.replace(vertSource, "[NB_LIGHTS]", "[" + nbLights + "]");
			fragSource = StringTools.replace(fragSource, "[NB_LIGHTS]", "[" + nbLights + "]");
		}
		
		if (owner.getMaterialDef().getMaterialParam("NumberOfBones") != null)
		{
			var numBones:Int = cast owner.getParam("NumberOfBones").value;
			if (numBones < 1)
				numBones = 1;
			
			vertSource = StringTools.replace(vertSource, "[NUM_BONES]", "[" + numBones + "]");
		}
		
		//加载完Shader后还不能直接使用，需要判断Shader里面的纹理具体类型(如果有)才能确认出最终Shader
		this.shader = ShaderManager.instance.registerShader(shaderKey, vertSource, fragSource);
		
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

