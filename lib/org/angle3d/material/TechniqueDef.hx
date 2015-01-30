package org.angle3d.material;

import haxe.ds.StringMap;

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

	/**
	 *  the language of the vertex shader used in this technique.
	 */
	public var vertLanguage:String;
	/**
	 *  the language of the fragment shader used in this technique.
	 */
	public var fragLanguage:String;
	
	/**
	 * the render state that this technique is using
	 */
	public var renderState:RenderState;
	
	/**
	 * the force render state that this technique is using
	 */
	public var forcedRenderState:RenderState;

	public function new()
	{
		lightMode = LightMode.Disable;
		shadowMode = ShadowMode.Disable;
		
		defineParams = new StringMap<String>();
		
		renderState = null;
		forcedRenderState = null;
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
}
