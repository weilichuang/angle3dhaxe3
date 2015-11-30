package org.angle3d.material;

import flash.Vector;
import org.angle3d.utils.FastStringMap;

/**
 * Material definition
 *
 */
class MaterialDef
{
	/**
	 * The debug name of the material definition.
	 *
	 * @return debug name of the material definition.
	 */
	public var name:String;

	public var assetName:String;

	private var defaultTechs:Vector<TechniqueDef>;

	private var techniques:FastStringMap<TechniqueDef>;
	
	private var matParams:FastStringMap<MatParam>;

	public function new()
	{
		defaultTechs = new Vector<TechniqueDef>();

		techniques = new FastStringMap<TechniqueDef>();
		matParams = new FastStringMap<MatParam>();
	}

	/**
	 * Adds a new material parameter.
	 *
	 * @param type Type of the parameter
	 * @param name Name of the parameter
	 * @param value Default value of the parameter
	 * @param ffBinding Fixed function binding for the parameter
	 */
	public function addMaterialParam(type:String, name:String, value:Dynamic):Void
	{
		var param:MatParam;
		if (type == VarType.TEXTURE2D || type == VarType.TEXTURECUBEMAP)
		{
			param = new MatParamTexture(type, name, value);
		}
		else
		{
			param = new MatParam(type, name, value);
		}
		matParams.set(name,param);
	}

	/**
	 * Returns the material parameter with the given name.
	 *
	 * @param name The name of the parameter to retrieve
	 *
	 * @return The material parameter, or null if it does not exist.
	 */
	public function getMaterialParam(name:String):MatParam
	{
		return matParams.get(name);
	}

	/**
	 * Returns a collection of all material parameters declared in this
	 * material definition.
	 * <p>
	 * Modifying the material parameters or the collection will lead
	 * to undefined results.
	 *
	 * @return All material parameters declared in this definition.
	 */
	public function getMaterialParams():FastStringMap<MatParam>
	{
		return matParams;
	}

	/**
	 * Adds a new technique definition to this material definition.
	 * <p>
	 * If the technique name is "Default", it will be added
	 * to the list of {MaterialDef#getDefaultTechniques() default techniques}.
	 *
	 * @param technique The technique definition to add.
	 */
	public function addTechniqueDef(technique:TechniqueDef):Void
	{
		if (technique.name == "default")
		{
			defaultTechs.push(technique);
		}
		else
		{
			techniques.set(technique.name,technique);
		}
	}

	/**
	 * Returns a list of all default techniques.
	 *
	 * @return a list of all default techniques.
	 */
	public function getDefaultTechniques():Vector<TechniqueDef>
	{
		return defaultTechs;
	}

	/**
	 * Returns a technique definition with the given name.
	 * This does not include default techniques which can be
	 * retrieved via {MaterialDef#getDefaultTechniques() }.
	 *
	 * @param name The name of the technique definition to find
	 *
	 * @return The technique definition, or null if cannot be found.
	 */
	public function getTechniqueDef(name:String):TechniqueDef
	{
		return techniques.get(name);
	}
	
	public function dispose():Void
	{
		defaultTechs = null;
		techniques = null;
		matParams = null;
	}
}
