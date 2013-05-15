package org.angle3d.material;

import org.angle3d.material.technique.TechniqueWireframe;

/**
 * 线框模式
 * @author andy
 */

class MaterialWireframe extends Material
{
	private var _technique:TechniqueWireframe;
	
	public var thickness(get, set):Float;
	public var technique(get, null):TechniqueWireframe;
	public var color(get, set):UInt;

	public function new(color:UInt = 0xFF0000, thickness:Float = 1.0)
	{
		super();

		_technique = new TechniqueWireframe(color, thickness);

		addTechnique(_technique);

		sortingId = 3;
	}

	
	private function set_thickness(thickness:Float):Float
	{
		return _technique.thickness = thickness;
	}

	
	private function get_thickness():Float
	{
		return _technique.thickness;
	}

	
	private function get_technique():TechniqueWireframe
	{
		return _technique;
	}

	override private function set_alpha(alpha:Float):Float
	{
		return _technique.alpha = alpha;
	}

	
	private function set_color(color:UInt):UInt
	{
		return _technique.color = color;
	}

	private function get_color():UInt
	{
		return _technique.color;
	}

}

