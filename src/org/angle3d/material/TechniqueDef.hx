package org.angle3d.material;

import flash.utils.ByteArray;
import haxe.ds.StringMap;
import hu.vpmedia.assets.AssetLoader;
import hu.vpmedia.assets.AssetLoaderVO;
import hu.vpmedia.assets.loaders.AssetLoaderType;
import hu.vpmedia.assets.parsers.AssetParserType;
import org.angle3d.material.shader.DefineList;
import org.angle3d.material.shader.UniformBinding;
import org.angle3d.material.shader.UniformBindingManager;
import org.angle3d.renderer.Caps;

/**
 * Describes a technique definition.
 *
 */
class TechniqueDef
{
	public var name:String;
	
	public var lightMode:LightMode;
	public var shadowMode:ShadowMode;

	private var defineParams:StringMap<String>;
	private var worldBinds:Array<UniformBinding>;
	
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
	
	private var _isReady:Bool = false;
	
	private var presetDefines:DefineList;
	
	private var _isLoading:Bool = false;

	public function new()
	{
		lightMode = LightMode.Disable;
		shadowMode = ShadowMode.Disable;
		
		defineParams = new StringMap<String>();
		
		renderState = null;
		forcedRenderState = null;
		
		requiredCaps = [];
	}
	
	public function isReady():Bool
	{
		return _isReady;
	}
	
	public function loadSource():Void
	{
		if (this._isReady)
			return;
		
		if (this._isLoading)
			return;
			
		this._isLoading = true;
		
		var assetLoader:AssetLoader = new AssetLoader();
		assetLoader.signalSet.completed.add(_loadComplete);
		assetLoader.signalSet.failed.add(_loadFailed);
		assetLoader.add(Material.GLOBAL_PATH + this.vertName,AssetLoaderType.TEXT_LOADER,AssetParserType.TXT_PARSER);
		assetLoader.add(Material.GLOBAL_PATH + this.fragName,AssetLoaderType.TEXT_LOADER,AssetParserType.TXT_PARSER);
		assetLoader.execute();
	}
	
	private function _loadComplete(loader:AssetLoader):Void
	{
		this._isReady = true;
		this._isLoading = false;
		
		var vertVO:AssetLoaderVO = loader.get(Material.GLOBAL_PATH + this.vertName);
		var fragVO:AssetLoaderVO = loader.get(Material.GLOBAL_PATH + this.fragName);
		
		this.vertSource = vertVO.data;
		this.fragSource = fragVO.data;
		
		loader.dispose();
	}
	
	private function _loadFailed(loader:AssetLoader):Void
	{
		this._isReady = false;
		
		loader.close();
		loader.dispose();
	}
	
	/**
     * Returns the {@link DefineList} for the preset defines.
     * 
     * @return the {@link DefineList} for the preset defines.
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
     * {@link DefineList#set(java.lang.String, com.jme3.shader.VarType, java.lang.Object) }
     * to see why it matters.
     * 
     * @param value The value of the define
     */
	public function addShaderPresetDefine(defineName:String, type:String, value:Dynamic):Void
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

	/**
	 * Adds a define linked to a material parameter.
	 * <p>
	 * Any time the material parameter on the parent material is altered,
	 * the appropriate define on the technique will be modified as well.
	 * See the method
	 * {@link DefineList#set(java.lang.String, org.angle3d.shader.VarType, java.lang.Object) }
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
     * Adds a new world parameter by the given name.
     * 
     * @param name The world parameter to add.
     * @return True if the world parameter name was found and added
     * to the list of world parameters, false otherwise.
     */
    public function addWorldParam(name:String):Bool
	{
        if (worldBinds == null)
			worldBinds = [];
			
		var uniform:UniformBinding = Type.createEnum(UniformBinding, name);
		if (uniform != null && worldBinds.indexOf(uniform) == -1)
		{
			worldBinds.push(uniform);
			return true;
		}
		else
		{
			return false;
		}
    }
	
	public function getWorldBinds():Array<UniformBinding>
	{
		return worldBinds;
	}
	
	/**
     * Gets the {@link Caps renderer capabilities} that are required
     * by this technique.
     * 
     * @return the required renderer capabilities
     */
    public function getRequiredCaps():Array<Caps>
	{
        return requiredCaps;
    }
}
