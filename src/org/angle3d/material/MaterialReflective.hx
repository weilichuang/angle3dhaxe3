package org.angle3d.material;

import org.angle3d.material.technique.TechniqueReflective;
import org.angle3d.texture.CubeTextureMap;
import org.angle3d.texture.TextureMapBase;

/**
 * Reflection mapping
 * @author andy
 */
class MaterialReflective extends Material
{
	public var technique(get, null):TechniqueReflective;
	
	private var _technique:TechniqueReflective;

	public function new(decalMap:TextureMapBase, environmentMap:CubeTextureMap, reflectivity:Float = 0.8)
	{
		super();

		_technique = new TechniqueReflective(decalMap, environmentMap, reflectivity);
		addTechnique(_technique);
	}

	override private function set_influence(value:Float):Float
	{
		return _technique.influence = value;
	}

	
	private function get_technique():TechniqueReflective
	{
		return _technique;
	}

	public var decalMap(get, set):TextureMapBase;
	private function get_decalMap():TextureMapBase
	{
		return _technique.decalMap;
	}
	private function set_decalMap(map:TextureMapBase):TextureMapBase
	{
		return _technique.decalMap = map;
	}

	public var environmentMap(get, set):CubeTextureMap;
	private function get_environmentMap():CubeTextureMap
	{
		return _technique.environmentMap;
	}
	private function set_environmentMap(map:CubeTextureMap):CubeTextureMap
	{
		return _technique.environmentMap = map;
	}

	public var reflectivity(get, set):Float;
	private function get_reflectivity():Float
	{
		return _technique.reflectivity;
	}
	private function set_reflectivity(reflectivity:Float):Float
	{
		return _technique.reflectivity = reflectivity;
	}
}

