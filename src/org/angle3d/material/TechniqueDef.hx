package org.angle3d.material;

import org.angle3d.error.Assert;
import flash.Vector;
import flash.events.Event;
import flash.events.EventDispatcher;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import org.angle3d.asset.FileInfo;
import org.angle3d.asset.FilesLoader;
import org.angle3d.asset.LoaderType;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.logic.TechniqueDefLogic;
import org.angle3d.material.shader.DefineList;
import org.angle3d.renderer.Caps;
import org.angle3d.texture.Texture;
import org.angle3d.ds.FastStringMap;
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
    public static inline var DEFAULT_TECHNIQUE_NAME:String = "default";
	
	/**
     * Returns the name of this technique as specified in the file.
     * Default
     * techniques have the name {@link #DEFAULT_TECHNIQUE_NAME}.
     */
	public var name:String;
	
	/**
     * A unique sort ID. 
     * No other technique definition can have the same ID.
     */
	public var sortId:Int;
	
	/**
	 *  the name of the vertex shader used in this technique.
	 */
	public var vertName:String;
	/**
	 *  the name of the fragment shader used in this technique.
	 */
	public var fragName:String;
	
	public var version:Int = 1;
	
	public var vertSource:String;
	public var fragSource:String;
	private var shaderPrologue:String;
	
	private var requiredCaps:Array<Caps>;
	
	private var defineNames:Vector<String>;
    private var defineTypes:Vector<VarType>;
    private var paramToDefineId:FastStringMap<Int>;
    private var definesToShaderMap:IntMap<Shader>;
	
	private var _lightMode:LightMode;
	private var _shadowMode:TechniqueShadowMode;
	
	public var lightMode(get,set):LightMode;
	public var shadowMode(get,set):TechniqueShadowMode;

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
	
	/** 0-未加载，1-加载中，2-加载失败, 3-加载完成**/
	private var _loadState:Int = 0;

	public function new()
	{
		super();

		lightMode = LightMode.Disable;
		shadowMode = TechniqueShadowMode.Disable;
		
		defineNames = new Vector<String>();
		defineTypes = new Vector<VarType>();
		paramToDefineId = new FastStringMap<Int>();
		definesToShaderMap = new IntMap<Shader>();

		requiredCaps = [];
	}
	
	public function init(name:String, sortId:Int):Void
	{
		this.name = name;
		this.sortId = sortId;
	}
	
	private inline function get_shadowMode():TechniqueShadowMode
	{
		return _shadowMode;
	}
	
	private inline function set_shadowMode(value:TechniqueShadowMode):TechniqueShadowMode
	{
		return _shadowMode = value;
	}
	
	/**
     * Returns the light mode.
     * @see LightMode
     */
	private inline function get_lightMode():LightMode
	{
		return _lightMode;
	}
	
	/**
     * Set the light mode
     *
     * @param lightMode the light mode
     *
     * @see LightMode
     */
	private function set_lightMode(lightMode:LightMode):LightMode
	{
		this._lightMode = lightMode;
		//if light space is not specified we set it toLegacy
		if (lightSpace == null)
		{
			if (_lightMode == LightMode.MultiPass)
			{
				lightSpace = LightSpace.Legacy;
			}
			else
			{
				lightSpace = LightSpace.World;
			}
		}
		return _lightMode;
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
     * @return The define ID, or -1 if not found.
     */
	public inline function getShaderParamDefineId(paramName:String):Int
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
        return defineId < defineTypes.length ? defineTypes[defineId] : VarType.NONE;
    }
	
	/**
     * Adds a define linked to a material parameter.
     * <p>
     * Any time the material parameter on the parent material is altered,
     * the appropriate define on the technique will be modified as well.
     * When set, the material parameter will be mapped to an integer define, 
     * typically `1` if it is set, unless it is an integer or a float,
     * in which case it will converted into an integer.
     *
     * @param paramName The name of the material parameter to link to.
     * @param paramType The type of the material parameter to link to.
     * @param defineName The name of the define parameter, e.g. USE_LIGHTING
     */
	public function addShaderParamDefine(paramName:String, paramType:VarType, defineName:String):Void
	{
		var definedId:Int = defineNames.length;
		
		#if debug
		Assert.assert(definedId < DefineList.MAX_DEFINES, 'Cannot have more than ${DefineList.MAX_DEFINES} defines on a technique.');
		#end
		
		paramToDefineId.set(paramName, definedId);
		defineNames.push(defineName);
		defineTypes.push(paramType);
	}
	
	/**
     * Add an unmapped define which can only be set by define ID.
     * Unmapped defines are used by technique renderers to configure the shader internally before rendering.
     * @param defineName The define name to create
     * @return The define ID of the created define
     */
	public function addShaderUnmappedDefine(defineName:String, defineType:VarType):Int
	{
		var definedId:Int = defineNames.length;
		
		#if debug
		Assert.assert(definedId < DefineList.MAX_DEFINES, 'Cannot have more than ${DefineList.MAX_DEFINES} defines on a technique.');
		#end
		
		defineNames.push(defineName);
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
	
	public function getShader(material:Material, defines:DefineList, rendererCaps:Array<Caps>):Shader
	{
		var shader:Shader = definesToShaderMap.get(defines.hash);
		if (shader == null)
		{
			shader = loadShader(material, defines, rendererCaps);
			definesToShaderMap.set(defines.hash, shader);
		}
		return shader;
	}
	
	private function loadShader(material:Material,defines:DefineList, rendererCaps:Array<Caps>):Shader
	{
		var defineSource:String = "#version " + this.version + "\n";
		
		defineSource += defines.generateSource(defineNames, defineTypes);
		
		//临时解决方案，需要修改
		/**
		 * 未定义NUM_BONES时，uniform vec4 u_BoneMatrices[NUM_BONES]解析会出错，
		 * 可能需要修改sgsl解析，使其完全过滤掉这种未使用到的情况
		 * #ifdef(NUM_BONES)
		 * {
		 * 		attribute vec4 a_boneWeights(BONE_WEIGHTS);
		 * 		attribute vec4 a_boneIndices(BONE_INDICES);
		 * 		uniform vec4 u_BoneMatrices[NUM_BONES];
		 * }
		 */
		var index:Int = defineNames.indexOf("NUM_BONES");
		if (index == -1 || defines.getFloat(index) == 0)
		{
			defineSource += "#define NUM_BONES 0\n";
		}
		
		var params:Array<MatParamTexture> = material.getTextureParams();
		if (params.length > 0)
		{
			for (i in 0...params.length)
			{
				var texture:Texture = params[i].texture;
				defineSource += "#textureformat " + params[i].name+" " + (cast texture.getFormat()) + "\n";
			}
		}
		
		var vs:String = defineSource + this.vertSource;
		var fs:String = defineSource + this.fragSource;

		var shader:Shader = ShaderManager.instance.registerShader(vs, fs);
		
		return shader;
	}
	
	/**
     * Sets the shaders that this technique definition will use.
     *
     * @param vertName vertex source file name
     * @param fragName fragment source file name
	 * @param version shader version
     */
    public function setShaderFile(vertName:String, fragName:String, version:Int = 1):Void
	{
		this.vertName = vertName;
		this.fragName = fragName;
		this.version = version;
		
		requiredCaps = [];
		if (version == 2)
		{
			requiredCaps.push(Caps.AGAL2);
		}
		else
		{
			requiredCaps.push(Caps.AGAL1);
		}
		
		this.loadSource();
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
		
		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueFile(Angle3D.materialFolder + this.vertName, LoaderType.TEXT);
		assetLoader.queueFile(Angle3D.materialFolder + this.fragName, LoaderType.TEXT);
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}
	
	private function _loadComplete(loader:FilesLoader):Void
	{
		var vertSource:String = "";
		var fragSource:String = "";

		var info:FileInfo = loader.getAssetByUrl(Angle3D.materialFolder + this.vertName);
		if (info.error)
		{
			Logger.warn(info.url + " load error");
			
			this._loadState = 2;
		}
		else
		{
			vertSource = info.info.content;
		}
		
		var info:FileInfo = loader.getAssetByUrl(Angle3D.materialFolder + this.fragName);
		if (info.error)
		{
			Logger.warn(info.url + " load error");
			
			this._loadState = 2;
		}
		else
		{
			fragSource = info.info.content;
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
     * Gets the Caps that are required by this technique.
     * 
     * @return the required renderer capabilities
     */
    public function getRequiredCaps():Array<Caps>
	{
        return requiredCaps;
    }
}
