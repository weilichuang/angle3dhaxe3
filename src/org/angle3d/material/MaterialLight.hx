package org.angle3d.material;
import flash.Vector;
import org.angle3d.material.technique.TechniquePointLight;
import org.angle3d.math.Color;
import org.angle3d.texture.TextureMapBase;

/**
 * ...
 * @author 
 */
class MaterialLight extends Material
{
	private var _technique:TechniquePointLight;
	
	public function new() 
	{
		super();
		
		_technique = new TechniquePointLight();

		setTechnique(_technique);
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
	
	public var diffuseColor(get, set):Vector<Float>;
	public var specularColor(get, set):Vector<Float>;
	
	private function get_diffuseColor():Vector<Float>
	{
		return _technique.diffuseColor;
	}

	private function set_diffuseColor(value:Vector<Float>):Vector<Float>
	{
		return _technique.diffuseColor = value;
	}
	
	private function get_specularColor():Vector<Float>
	{
		return _technique.specularColor;
	}

	private function set_specularColor(value:Vector<Float>):Vector<Float>
	{
		return _technique.specularColor = value;
	}
	
}