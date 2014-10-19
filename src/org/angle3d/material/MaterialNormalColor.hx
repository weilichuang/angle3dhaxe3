package org.angle3d.material;

import org.angle3d.material.technique.TechniqueNormalColor;


/**
 * 顶点法线的Material
 * @author andy
 */
class MaterialNormalColor extends Material
{
	public var technique(get, null):TechniqueNormalColor;
	private var _technique:TechniqueNormalColor;

	public function new()
	{
		super();

		_technique = new TechniqueNormalColor();

		addTechnique(_technique);
	}

	override private function set_influence(value:Float):Float
	{
		return _technique.influence = value;
	}

	private function get_technique():TechniqueNormalColor
	{
		return _technique;
	}
}

