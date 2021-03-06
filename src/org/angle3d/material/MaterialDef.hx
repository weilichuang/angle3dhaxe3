package org.angle3d.material;

import flash.Vector;
import org.angle3d.ds.FastStringMap;

/**
 * Material definition
 *
 */
class MaterialDef
{
	/**
	 * The debug name of the material definition.
	 */
	public var name:String;

	 /**
     * Returns the asset key name of the asset from which this material 
     * definition was loaded.
     */
	public var assetName:String;

	private var techniques:FastStringMap<Vector<TechniqueDef>>;
	private var matParams:FastStringMap<MatParam>;

	public function new()
	{
		techniques = new FastStringMap<Vector<TechniqueDef>>();
		matParams = new FastStringMap<MatParam>();
	}

	/**
	 * Adds a new material parameter.
	 *
	 * @param type Type of the parameter
	 * @param name Name of the parameter
	 * @param value Default value of the parameter
	 */
	public function addMaterialParam(type:VarType, name:String, value:Dynamic):Void
	{
		var param:MatParam;
		if (VarType.isTextureType(type))
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
	public inline function getMaterialParam(name:String):MatParam
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
	public inline function getMaterialParams():FastStringMap<MatParam>
	{
		return matParams;
	}

	/**
     * Adds a new technique definition to this material definition.
     *
     * @param technique The technique definition to add.
     */
	public function addTechniqueDef(technique:TechniqueDef):Void
	{
		var list:Vector<TechniqueDef> = techniques.get(technique.name);
		if (list == null)
		{
			list = new Vector<TechniqueDef>();
			techniques.set(technique.name, list);
		}
		
		list.push(technique);
	}
	
	/**
     * Returns technique definitions with the given name.
       * 
     * @param name The name of the technique definitions to find
       * 
     * @return The technique definitions, or null if cannot be found.
     */
	public function getTechniqueDefs(name:String):Vector<TechniqueDef>
	{
		return techniques.get(name);
	}
	
	/**
     *
     * @return the list of all the technique definitions names.
     */
    public function getTechniqueDefsNames():Array<String>
	{
        return techniques.keys();
    }
	
	public function dispose():Void
	{
		techniques = null;
		matParams = null;
	}
}
