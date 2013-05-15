package org.angle3d.material;

import org.angle3d.material.technique.TechniqueVertexColor;


/**
 * 顶点颜色
 * Mesh中需要有color部分
 * @author andy
 */
class MaterialVertexColor extends Material
{
	private var _technique:TechniqueVertexColor;

	public function new()
	{
		super();

		_technique = new TechniqueVertexColor();

		addTechnique(_technique);

		sortingId = 4;
	}

	override private function set_alpha(alpha:Float):Float
	{
		_technique.setAlpha(alpha);

		return super.alpha = alpha;
	}
}

