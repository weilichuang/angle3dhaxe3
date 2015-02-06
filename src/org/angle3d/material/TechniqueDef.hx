package org.angle3d.material;

import haxe.ds.StringMap;
import org.angle3d.material.shader.UniformBinding;
import org.angle3d.material.shader.UniformBindingManager;

/**
 * Describes a technique definition.
 *
 * @author Kirill Vainer
 */
class TechniqueDef
{
	public var name:String;
	
	public var lightMode:LightMode;
	public var shadowMode:ShadowMode;

	private var defineParams:StringMap<String>;
	private var worldBinds:Array<UniformBinding>;

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

	public function new()
	{
		lightMode = LightMode.Disable;
		shadowMode = ShadowMode.Disable;
		
		defineParams = new StringMap<String>();
		
		renderState = null;
		forcedRenderState = null;
	}
	
	public function isReady():Bool
	{
		return _isReady;
	}
	
	public function loadSource():Void
	{
		
	}
	
	public function setSource(vert:String, frag:String):Void
	{
		this.vertSource = vert;
		this.fragSource = frag;
		_isReady = true;
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
}
