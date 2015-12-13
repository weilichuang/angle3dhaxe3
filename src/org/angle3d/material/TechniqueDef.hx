package org.angle3d.material;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import assets.manager.misc.LoaderStatus;
import flash.events.Event;
import flash.events.EventDispatcher;
import haxe.ds.StringMap;
import org.angle3d.material.shader.DefineList;
import org.angle3d.renderer.Caps;
import org.angle3d.utils.FastStringMap;
import org.angle3d.utils.Logger;

enum TechniqueShadowMode 
{
	Disable;
	InPass;
	PostPass;
}

/**
 * Describes a technique definition.
 *
 */
class TechniqueDef extends EventDispatcher
{
	public var name:String;
	
	public var lightMode:Int;
	public var shadowMode:TechniqueShadowMode;

	private var defineParams:FastStringMap<String>;

	private var requiredCaps:Array<Caps>;

	/**
	 *  the name of the vertex shader used in this technique.
	 */
	public var vertName:String;
	/**
	 *  the name of the fragment shader used in this technique.
	 */
	public var fragName:String;
	
	/**
	 * the render state that this technique is using
	 */
	public var renderState:RenderState;
	
	/**
	 * the force render state that this technique is using
	 */
	public var forcedRenderState:RenderState;
	
	public var vertSource:String;
	
	public var fragSource:String;
	
	private var presetDefines:DefineList;
	
	/** 0-未加载，1-加载中，2-加载失败,3-加载完成*/
	private var _loadState:Int = 0;

	public function new()
	{
		super();
		
		lightMode = LightMode.Disable;
		shadowMode = TechniqueShadowMode.Disable;
		
		defineParams = new FastStringMap<String>();
		
		renderState = null;
		forcedRenderState = null;
		
		requiredCaps = [];
	}
	
	public inline function isLoaded():Bool
	{
		return _loadState == 3;
	}
	
	public function loadSource():Void
	{
		if (this._loadState == 3)
			return;
		
		if (this._loadState != 0)
			return;
			
		this._loadState = 1;
		
		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueText(Angle3D.materialFolder + this.vertName);
		assetLoader.queueText(Angle3D.materialFolder + this.fragName);
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}
	
	private function _loadComplete(fileMap:StringMap<FileInfo>):Void
	{
		var vertSource:String = "";
		var fragSource:String = "";

		var info:FileInfo = fileMap.get(Angle3D.materialFolder + this.vertName);
		if (info.status != LoaderStatus.LOADED)
		{
			Logger.warn(info.id + " load error:" + info.status);
			
			this._loadState = 2;
		}
		else
		{
			vertSource = info.data;
		}
		
		var info:FileInfo = fileMap.get(Angle3D.materialFolder + this.fragName);
		if (info.status != LoaderStatus.LOADED)
		{
			Logger.warn(info.id + " load error:" + info.status);
			
			this._loadState = 2;
		}
		else
		{
			fragSource = info.data;
		}
		
		if (vertSource != "" && fragSource != "")
			setShaderSource(vertSource, fragSource);
	}

	public function setShaderSource(vert:String, frag:String):Void
	{
		this.vertSource = vert;
		this.fragSource = frag;
		this._loadState = 3;
		
		dispatchEvent(new Event(Event.COMPLETE));
	}
	
	/**
     * Returns the {DefineList} for the preset defines.
     * 
     * @return the {DefineList} for the preset defines.
     * 
     * @see #addShaderPresetDefine(java.lang.String, com.jme3.shader.VarType, java.lang.Object) 
     */
	public function getShaderPresetDefines():DefineList
	{
		return presetDefines;
	}
	
	/**
     * Adds a preset define. 
     * <p>
     * Preset defines do not depend upon any parameters to be activated,
     * they are always passed to the shader as long as this technique is used.
     * 
     * @param defineName The name of the define parameter, e.g. USE_LIGHTING
     * @param type The type of the define. See 
     * {DefineList#set(java.lang.String, com.jme3.shader.VarType, java.lang.Object) }
     * to see why it matters.
     * 
     * @param value The value of the define
     */
	public function addShaderPresetDefine(defineName:String, type:Int, value:Dynamic):Void
	{
		if (presetDefines == null)
			presetDefines = new DefineList();
			
		presetDefines.set(defineName, type, value);
	}

	/**
	 * Returns the define name which the given material parameter influences.
	 *
	 * @param paramName The parameter name to look up
	 * @return The define name
	 *
	 * @see #addShaderParamDefine(java.lang.String, java.lang.String)
	 */
	public inline function getShaderParamDefine(paramName:String):String
	{
		return defineParams.get(paramName);
	}
	
	public inline function getDefineParams():FastStringMap<String>
	{
		return defineParams;
	}

	/**
	 * Adds a define linked to a material parameter.
	 * <p>
	 * Any time the material parameter on the parent material is altered,
	 * the appropriate define on the technique will be modified as well.
	 * See the method
	 * {DefineList#set(java.lang.String, org.angle3d.shader.VarType, java.lang.Object) }
	 * on the exact details of how the material parameter changes the define.
	 *
	 * @param paramName The name of the material parameter to link to.
	 * @param defineName The name of the define parameter, e.g. USE_LIGHTING
	 */
	public inline function addShaderParamDefine(paramName:String, defineName:String):Void
	{
		defineParams.set(paramName, defineName);
	}
	
	/**
     * Gets the {Caps renderer capabilities} that are required
     * by this technique.
     * 
     * @return the required renderer capabilities
     */
    public function getRequiredCaps():Array<Caps>
	{
        return requiredCaps;
    }
}
