package org.angle3d.material;

import flash.Vector;
import flash.events.Event;
import org.angle3d.light.LightList;
import org.angle3d.material.logic.TechniqueDefLogic;
import org.angle3d.material.shader.DefineList;
import org.angle3d.material.shader.Shader;
import org.angle3d.renderer.Caps;
import org.angle3d.renderer.RenderManager;
import org.angle3d.scene.Geometry;
import org.angle3d.ds.FastStringMap;

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
	private var _isLoaded:Bool = false;

	private var paramDefines:DefineList;
	private var dynamicDefines:DefineList;

	public function new(owner:Material, def:TechniqueDef)
	{
		this.owner = owner;
		this.def = def;
	}
	
	private inline function get_def():TechniqueDef
	{
		return _def;
	}
	
	private function set_def(value:TechniqueDef):TechniqueDef
	{
		if (_def != null)
		{
			_def.removeEventListener(Event.COMPLETE, onDefLoadComplete);
		}
		
		_def = value;
		
		if (_def != null)
		{
			this.paramDefines = _def.createDefineList();
			this.dynamicDefines = _def.createDefineList();
			
			if(!_def.isLoaded())
				_def.addEventListener(Event.COMPLETE, onDefLoadComplete);
			else
				onDefLoadComplete(null);
		}
		
		return _def;
	}
	
	private function onDefLoadComplete(event:Event):Void
	{
		_isLoaded = _def.isLoaded();
	}
	
	public function getDef():TechniqueDef
	{
		return def;
	}
	
	public inline function isReady():Bool
	{
		return def != null && _isLoaded;
	}
	
	/**
     * Called by the material to tell the technique a parameter was modified.
     * Specify null for value if the param is to be cleared.
     */
    public function notifyParamChanged(paramName:String, type:VarType, value:Dynamic):Void
	{
        var defineId:Int = _def.getShaderParamDefineId(paramName);
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
	
	public function applyOverrides(defineList:DefineList,matOverrides:Vector<MatParamOverride>):Void
	{
		for (i in 0...matOverrides.length)
		{
			var matOverride:MatParamOverride = matOverrides[i];
			if (!matOverride.enabled)
				continue;
				
			var definedId:Int = def.getShaderParamDefineId(matOverride.name);
			if (definedId > -1)
			{
				if (_def.getDefineIdType(definedId) == matOverride.type)
				{
					defineList.setDynamic(definedId, matOverride.type, matOverride.value);
				}
			}
		}
	}
	
	/**
     * Called by the material to determine which shader to use for rendering.
     * 
     * The `TechniqueDefLogic` is used to determine the shader to use based on the `LightMode`.
     * 
     * @param renderManager The render manager for which the shader is to be selected.
	 * @param worldOverrides
	 * @param forcedOverrides
     * @param rendererCaps The renderer capabilities which the shader should support.
     * @return A compatible shader.
     */
    public function makeCurrent(renderManager:RenderManager, material:Material, 
								worldOverrides:Vector<MatParamOverride>,
								forcedOverrides:Vector<MatParamOverride>,
								lights:LightList, rendererCaps:Array<Caps> ):Shader
	{
		var logic:TechniqueDefLogic = _def.getLogic();
		
		var defines:DefineList;
		if (worldOverrides != null || forcedOverrides != null)
		{
			dynamicDefines.clear();
			dynamicDefines.setAll(paramDefines);
			
			if (worldOverrides != null && worldOverrides.length > 0)
			{
				applyOverrides(dynamicDefines, worldOverrides);
			}
			
			if (forcedOverrides != null && forcedOverrides.length > 0)
			{
				applyOverrides(dynamicDefines, forcedOverrides);
			}
			
			defines = dynamicDefines;
		}
		else
		{
			defines = paramDefines;
		}
		
		return logic.makeCurrent(renderManager, material, rendererCaps, lights, defines);
    }
	
	/**
     * Render the technique according to its `TechniqueDefLogic`.
     * 
     * @param renderManager The render manager to perform the rendering against.
     * @param shader The shader that was selected in `makeCurrent()`
     * @param geometry The geometry to render
     * @param lights Lights which influence the geometry.
	 * @param lastTexUnit
     */
	public function render(renderManager:RenderManager, shader:Shader, geometry:Geometry, lights:LightList):Void
	{
		var logic:TechniqueDefLogic = _def.getLogic();
		logic.render(renderManager, shader, geometry, lights);
	}
	
	/**
     * Get the `DefineList` for dynamic defines.
     * 
     * Dynamic defines are used to implement material parameter -> define
     * bindings as well as `TechniqueDefLogic` specific functionality.
     * 
     * @return all dynamic defines.
     */
    public function getDynamicDefines():DefineList
	{
        return dynamicDefines;
    }
	
	/**
     * Compute the sort ID. 
     * @return the sort ID for this technique instance.
     */
    public function getSortId():Int
	{
        var hash:Int = 17;
        hash = hash * 23 + def.sortId;
        hash = hash * 23 + paramDefines.hash;
        return hash;
    }
}

