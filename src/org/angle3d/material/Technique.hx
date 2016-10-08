package org.angle3d.material;

import flash.Vector;
import flash.events.Event;
import org.angle3d.light.LightList;
import org.angle3d.material.logic.TechniqueDefLogic;
import org.angle3d.material.shader.DefineList;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.Uniform;
import org.angle3d.renderer.Caps;
import org.angle3d.renderer.RenderManager;
import org.angle3d.scene.Geometry;
import org.angle3d.utils.FastStringMap;

/**
 * Represents a technique instance.
 */
@:final class Technique
{
	/**
	 * The material that will own this technique
	 */
	public var owner:Material;
	
	/**
	 * the technique definition that is implemented by this technique
	 */
	public var def(get, set):TechniqueDef;
	
	private var _def:TechniqueDef;
	private var mIsDefLoaded:Bool = false;
	
	private var needReload:Bool = true;
	private var shader:Shader;
	
	private var paramDefines:DefineList;
	private var dynamicDefines:DefineList;

	public function new(owner:Material,def:TechniqueDef)
	{
		this.owner = owner;
		this.def = def;
		
		this.paramDefines = def.createDefineList();
		this.dynamicDefines = def.createDefineList();
	}
	
	private inline function get_def():TechniqueDef
	{
		return _def;
	}
	
	private inline function set_def(value:TechniqueDef):TechniqueDef
	{
		if (_def != null)
		{
			_def.removeEventListener(Event.COMPLETE, onDefLoadComplete);
		}
		this._def = value;
		mIsDefLoaded = this._def.isLoaded();
		if (_def != null)
		{
			_def.addEventListener(Event.COMPLETE, onDefLoadComplete);
		}
		return this._def;
	}
	
	private function onDefLoadComplete(event:Event):Void
	{
		mIsDefLoaded = _def.isLoaded();
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
    public function notifyParamChanged(paramName:String, type:VarType, value:Dynamic):Void
	{
        var defineId:Int = def.getShaderParamDefineId(paramName);
        if (defineId > -1)
		{
            paramDefines.setDynamic(defineId, type, value);
        }
    }
	
	/**
     * Called by the material to tell the technique that it has been made
     * current.
     * The technique updates dynamic defines based on the
     * currently set material parameters.
     */
	public function notifyTechniqueSwitched():Void
	{
		var paramMap:FastStringMap<MatParam> = owner.getParamsMap();
		
		paramDefines.clear();
		
		var keys:Array<String> = paramMap.keys();
		for (i in 0...keys.length)
		{
			var param:MatParam = paramMap.get(keys[i]);
			notifyParamChanged(param.name, param.type, param.value);
		}
	}
	
	public function applyOverrides(defineList:DefineList,overrides:Vector<MatParamOverride>):Void
	{
		for (i in 0...overrides.length)
		{
			var matOverride:MatParamOverride = overrides[i];
			if (!matOverride.enabled)
				continue;
				
			var definedId:Int = def.getShaderParamDefineId(matOverride.name);
			if (definedId > -1)
			{
				if (def.getDefineIdType(definedId) == matOverride.type)
				{
					defineList.setDynamic(definedId, matOverride.type, matOverride.value);
				}
			}
		}
	}
	
	public inline function updateUniformParam(paramName:String, varType:VarType, value:Dynamic):Void
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
    public function makeCurrent(rm:RenderManager, worldOverrides:Vector<MatParamOverride>,
								forcedOverrides:Vector<MatParamOverride>,
								lights:LightList,rendererCaps:Array<Caps> ):Shader
	{
		var logic:TechniqueDefLogic = def.getLogic();
		
		dynamicDefines.clear();
		dynamicDefines.setAll(paramDefines);
		
		if (worldOverrides != null)
		{
			applyOverrides(dynamicDefines, worldOverrides);
		}
		
		if (forcedOverrides != null)
		{
			applyOverrides(dynamicDefines, forcedOverrides);
		}
		
		return logic.makeCurrent(rm, rendererCaps, lights, dynamicDefines);
		
        //if (techniqueSwitched)
		//{
			////TODO 优化此处判断，场景中物品非常多时，此处相当耗时
            //if (paramDefines.update(owner.getParamsMap(), def)) 
			//{
                //needReload = true;
            //}
			//
            //if (getDef().lightMode == LightMode.SinglePass)
			//{
				//var nbLights:Int = cast paramDefines.get("NB_LIGHTS");
				//var count:Int = rm.getSinglePassLightBatchSize();
				//if (nbLights != count * 3 )
				//{
					//paramDefines.set("NB_LIGHTS", VarType.FLOAT, count * 3);
					//needReload = true;
					//
					//for (i in 1...4)
					//{
						//if (i < count)
						//{
							//paramDefines.set("SINGLE_PASS_LIGHTING" + i, VarType.BOOL, true);
						//}
						//else
						//{
							//paramDefines.set("SINGLE_PASS_LIGHTING" + i, VarType.BOOL, false);
						//}
					//}
				//}
            //}
			//else
			//{
				//paramDefines.remove("NB_LIGHTS");
			//}
			//
			////TODO bone
        //}
//
        //if (needReload) 
		//{
            //loadShader(rendererCaps);
        //}
    }
	
	public function render(renderManager:RenderManager, shader:Shader, geometry:Geometry, lights:LightList, lastTexUnit:Int):Void
	{
		var logic:TechniqueDefLogic = def.getLogic();
		logic.render(renderManager, shader, geometry, lights, lastTexUnit);
	}
	
	/**
     * Get the {@link DefineList} for dynamic defines.
     * 
     * Dynamic defines are used to implement material parameter -> define
     * bindings as well as {@link TechniqueDefLogic} specific functionality.
     * 
     * @return all dynamic defines.
     */
    public function getDynamicDefines():DefineList
	{
        return dynamicDefines;
    }
	
	/**
     * Compute the sort ID. Similar to {@link Object#hashCode()} but used
     * for sorting geometries for rendering.
     * 
     * @return the sort ID for this technique instance.
     */
    public function getSortId():Int
	{
        var hash:Int = 17;
        hash = hash * 23 + def.sortId;
        hash = hash * 23 + paramDefines.hashCode();
        return hash;
    }
}

