package org.angle3d.material;

import flash.Vector;
import org.angle3d.material.technique.TechniqueStandard;
import org.angle3d.material.technique.TechniqueTexture;
import org.angle3d.texture.CubeTextureMap;
import org.angle3d.texture.TextureMapBase;

class StandardMaterial extends Material
{
	private var _technique:TechniqueStandard;

	public function new()
	{
		super();

		_technique = new TechniqueStandard();
		setTechnique(_technique);

		sortingId = 3;
	}

	override private function set_skinningMatrices(data:Vector<Float>):Vector<Float>
	{
		return _technique.skinningMatrices = data;
	}

	override private function set_influence(value:Float):Float
	{
		return _technique.influence = value;
	}

	public var technique(get, null):TechniqueStandard;
	private function get_technique():TechniqueStandard
	{
		return _technique;
	}
	
	public var isRefract(get, set):Bool;
	private function get_isRefract():Bool
	{
		return _technique.isRefract;
	}
	
	private function set_isRefract(value:Bool):Bool
	{
		return _technique.isRefract = value;
	}
	
	public var isReflect(get, set):Bool;
	private function get_isReflect():Bool
	{
		return _technique.isReflect;
	}
	
	private function set_isReflect(value:Bool):Bool
	{
		return _technique.isReflect = value;
	}

	public var useTexCoord2(get, set):Bool;
	private function get_useTexCoord2():Bool
	{
		return _technique.useTexCoord2;
	}
	
	private function set_useTexCoord2(value:Bool):Bool
	{
		return _technique.useTexCoord2 = value;
	}
	
	public var texture(get, set):TextureMapBase;
	private function get_texture():TextureMapBase
	{
		return _technique.texture;
	}

	private function set_texture(value:TextureMapBase):TextureMapBase
	{
		return _technique.texture = value;
	}

	public var lightmap(get, set):TextureMapBase;
	private function get_lightmap():TextureMapBase
	{
		return _technique.lightmap;
	}
	
	private function set_lightmap(value:TextureMapBase):TextureMapBase
	{
		return _technique.lightmap = value;
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
	
	public var transmittance(get, set):Float;
	private function get_transmittance():Float
	{
		return _technique.transmittance;
	}
	private function set_transmittance(transmittance:Float):Float
	{
		return _technique.transmittance = transmittance;
	}
	
	public var etaRatio(get, set):Float;
	private function get_etaRatio():Float
	{
		return _technique.etaRatio;
	}
	private function set_etaRatio(etaRatio:Float):Float
	{
		return _technique.etaRatio = etaRatio;
	}
}

