package org.angle3d.material;
import org.angle3d.material.technique.Technique;

/**
 * ...
 * @author 
 */
class SinglePassMaterial extends Material
{
	public var technique(get, set):Technique;
	
	private var _technique:Technique;

	public function new() 
	{
		super();
	}
	
	public function get_technique():Technique
	{
		return _technique;
	}
	
	public function set_technique(value:Technique):Technique
	{
		_technique = value;
		mTechniques[0] = _technique;
		return _technique;
	}
	
}