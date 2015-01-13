package org.angle3d.material;

import flash.Vector;
import org.angle3d.material.technique.TechniqueColorFill;


/**
 * 单色的Material
 * @author weilichuang
 */
class MaterialColorFill extends Material
{
	public var color(get, set):UInt;
	public var technique(get, null):TechniqueColorFill;
	
	private var _technique:TechniqueColorFill;

	public function new(color:UInt = 0xFFFFF, alpha:Float = 1.0)
	{
		super();

		_technique = new TechniqueColorFill(color);
		addTechnique(_technique);

		this.alpha = alpha;

		sortingId = 1;
	}

	private function get_technique():TechniqueColorFill
	{
		return _technique;
	}

	override private function set_influence(value:Float):Float
	{
		return _technique.influence = value;
	}
	
	override private function set_skinningMatrices(data:Vector<Float>):Vector<Float>
	{
		return _technique.skinningMatrices = data;
	}

	override private function set_alpha(alpha:Float):Float
	{
		_technique.alpha = alpha;

		super.alpha = alpha;
		
		return _technique.alpha;
	}

	
	private function get_color():UInt
	{
		return _technique.color;
	}
	private function set_color(color:UInt):UInt
	{
		return _technique.color = color;
	}
}

