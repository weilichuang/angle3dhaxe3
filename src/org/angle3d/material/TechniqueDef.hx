package org.angle3d.material;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import assets.manager.misc.LoaderStatus;
import de.polygonal.core.util.Assert;
import flash.Vector;
import flash.events.Event;
import flash.events.EventDispatcher;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import org.angle3d.material.logic.TechniqueDefLogic;
import org.angle3d.material.shader.DefineList;
import org.angle3d.renderer.Caps;
import org.angle3d.utils.FastStringMap;
import org.angle3d.utils.Logger;
import org.angle3d.material.shader.Shader;

/**
 * Describes a technique definition.
 *
 */
class TechniqueDef extends EventDispatcher
{
	/**
     * The default technique name.
     *
     * The technique with this name is selected if no specific technique is
     * requested by the user. Currently set to "Default".
     */
    public static inline var DEFAULT_TECHNIQUE_NAME:String = "Default";
	
	public var name:String;
	
	private var sortId:Int;
	
	/**
	 *  the name of the vertex shader used in this technique.
	 */
	public var vertName:String;
	/**
	 *  the name of the fragment shader used in this technique.
	 */
	public var fragName:String;
	
	public var vertSource:String;
	public var fragSource:String;
	private var shaderPrologue:String;
	
	private var requiredCaps:Array<Caps>;
	
	private var defineNames:Vector<String>;
    private var defineTypes:Vector<VarType>;
    private var paramToDefineId:FastStringMap<Int>;
    private var definesToShaderMap:ObjectMap<DefineList, Shader>;
	
	private var lightMode:LightMode;
	public var shadowMode:TechniqueShadowMode;

	private var logic:TechniqueDefLogic;

	private var noRender:Bool = false;
	/**
	 * the render state that this technique is using
	 */
	public var renderState:RenderState;
	
	/**
	 * the force render state that this technique is using
	 */
	public var forcedRenderState:RenderState;
	
	/** 
	 * The space in which the light should be transposed before sending to the shader.
	 */
	private var lightSpace:LightSpace;
	

	/** 0-未加载，1-加载中，2-加载失败,3-加载完成*/
	private var _loadState:Int = 0;

	public function new(name:String,sortId:Int)
	{
		super();
		
		this.name = name;
		this.sortId = sortId;
		
		lightMode = LightMode.Disable;
		shadowMode = TechniqueShadowMode.Disable;
		
		defineNames = new Vector<String>();
		defineTypes = new Vector<VarType>();
		paramToDefineId = new FastStringMap<Int>();
		definesToShaderMap = new ObjectMap<DefineList,Shader>();

		requiredCaps = [];
	}
	
	/**
     * @return A unique sort ID. 
     * No other technique definition can have the same ID.
     */
    public inline function getSortId():Int
	{
        return sortId;
    }
	
	/**
     * Returns the light mode.
     * @see LightMode
     */
	public inline function getLightMode():LightMode
	{
		return lightMode;
	}
	
	/**
     * Set the light mode
     *
     * @param lightMode the light mode
     *
     * @see LightMode
     */
	public function setLightMode(lightMode:LightMode):Void
	{
		this.lightMode = lightMode;
		//if light space is not specified we set it toLegacy
		if (lightSpace == null)
		{
			if (lightMode == LightMode.MultiPass)
			{
				lightSpace = LightSpace.Legacy;
			}
			else
			{
				lightSpace = LightSpace.World;
			}
		}
	}
	
	public inline function setLogic(logic:TechniqueDefLogic):Void
	{
        this.logic = logic;
    }

    public inline function getLogic():TechniqueDefLogic
	{
        return logic;
    }
	
	/**
     * Sets if this technique should not be used to render.
     *
     * @param noRender not render or render ?
     */
    public function setNoRender(noRender:Bool):Void
	{
        this.noRender = noRender;
    }

    /**
     * Returns true if this technique should not be used to render.
     * (eg. to not render a material with default technique)
     *
     * @return true if this technique should not be rendered, false otherwise.
     *
     */
    public function isNoRender():Bool
	{
        return noRender;
    }
	
	/**
     * Returns the define name which the given material parameter influences.
     *
     * @param paramName The parameter name to look up
     * @return The define name
     *
     * @see #addShaderParamDefine(java.lang.String, java.lang.String)
     */
	public function getShaderParamDefine(paramName:String):String
	{
		if (paramToDefineId.exists(paramName))
		{
			return defineNames[paramToDefineId.get(paramName)];
		}
		else
			return null;
	}
	
	/* Get the define ID for a given material parameter.
     *
     * @param paramName The parameter name to look up
     * @return The define ID, or null if not found.
     */
	public function getShaderParamDefineId(paramName:String):Int
	{
		if(paramToDefineId.exists(paramName))
			return paramToDefineId.get(paramName);
		else
			return -1;
	}
	
	/**
     * Get the type of a particular define.
     *
     * @param defineId The define ID to lookup.
     * @return The type of the define, or null if not found.
     */
    public function getDefineIdType(defineId:Int):VarType
	{
        return defineId < defineTypes.length ? defineTypes[defineId] : null;
    }
	
	/**
     * Adds a define linked to a material parameter.
     * <p>
     * Any time the material parameter on the parent material is altered,
     * the appropriate define on the technique will be modified as well.
     * When set, the material parameter will be mapped to an integer define, 
     * typically <code>1</code> if it is set, unless it is an integer or a float,
     * in which case it will converted into an integer.
     *
     * @param paramName The name of the material parameter to link to.
     * @param paramType The type of the material parameter to link to.
     * @param defineName The name of the define parameter, e.g. USE_LIGHTING
     */
	public function addShaderParamDefine(paramName:String, paramType:VarType, defineName:String):Void
	{
		var definedId:Int = defineName.length;
		
		#if debug
		Assert.assert(definedId < DefineList.MAX_DEFINES, 'Cannot have more than ${DefineList.MAX_DEFINES} defines on a technique.');
		#end
		
		paramToDefineId.set(paramName, definedId);
		defineNames.push(defineName);
		defineTypes.push(paramType);
	}
	
	/**
     * Add an unmapped define which can only be set by define ID.
     * Unmapped defines are used by technique renderers to 
     * configure the shader internally before rendering.
     * @param defineName The define name to create
     * @return The define ID of the created define
     */
	public function addShaderUnmappedDefine(paramName:String, defineType:VarType):Int
	{
		var definedId:Int = defineNames.length;
		
		#if debug
		Assert.assert(definedId < DefineList.MAX_DEFINES, 'Cannot have more than ${DefineList.MAX_DEFINES} defines on a technique.');
		#end
		
		defineNames.push(paramName);
		defineTypes.push(defineType);
		return definedId;
	}
	
	/**
     * Get the names of all defines declared on this technique definition.
     *
     * The defines are returned in order of declaration.
     *
     * @return the names of all defines declared.
     */
	public function getDefineNames():Vector<String>
	{
		return defineNames;
	}
	
	/**
     * Get the types of all defines declared on this technique definition.
     *
     * The types are returned in order of declaration.
     *
     * @return the types of all defines declared.
     */
	public function getDefineTypes():Vector<VarType>
	{
		return defineTypes;
	}
	
	/**
     * Create a define list with the size matching the number
     * of defines on this technique.
     * 
     * @return a define list with the size matching the number
     * of defines on this technique.
     */
	public function createDefineList():DefineList
	{
		return new DefineList(defineNames.length);
	}
	
	public function getShader(defines:DefineList, rendererCaps:Array<Caps>):Shader
	{
		var shader:Shader = definesToShaderMap.get(defines);
		if (shader == null)
		{
			shader = loadShader(defines, rendererCaps);
			definesToShaderMap.set(defines.deepClone(), shader);
		}
		return shader;
	}
	
	private function loadShader(defines:DefineList, rendererCaps:Array<Caps>):Shader
	{
		var shader:Shader;
		
		defines.generateSource(defineNames, defineTypes);
		
		//var shaderKey:ShaderKey = new ShaderKey(getAllDefines(), def.vertName, def.fragName);
		
		var vertSource:String = this.vertSource;
		var fragSource:String = this.fragSource;
		
		if (this.lightMode == LightMode.SinglePass)
		{
			var nbLights:Int = cast paramDefines.get("NB_LIGHTS");
			
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
		
		var textureMap:FastStringMap<String> = new FastStringMap<String>();
		var textureParams:Array<MatParamTexture> = owner.getTextureParams();
		for (param in textureParams)
		{
			textureMap.set(param.name, cast param.texture.getFormat());
		}

		//加载完Shader后还不能直接使用，需要判断Shader里面的纹理具体类型(如果有)才能确认出最终Shader
		this.shader = ShaderManager.instance.registerShader(shaderKey, vertSource, fragSource, textureMap);
		
		needReload = false;
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
     * Set a string which is prepended to every shader used by this technique.
     * 
     * Typically this is used for preset defines.
     * 
     * @param shaderPrologue The prologue to append before the technique's shaders.
     */
    public function setShaderPrologue( shaderPrologue:String):Void {
        this.shaderPrologue = shaderPrologue;
    }
    
    /**
     * @return the shader prologue which is prepended to every shader.
     */
    public function getShaderPrologue():String {
        return shaderPrologue;
    }
	
	public inline function getDefineParams():FastStringMap<String>
	{
		return defineParams;
	}
	
	/**
     * Gets the Caps that are required by this technique.
     * 
     * @return the required renderer capabilities
     */
    public function getRequiredCaps():Array<Caps>
	{
        return requiredCaps;
    }
}
