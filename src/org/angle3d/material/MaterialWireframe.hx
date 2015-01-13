package org.angle3d.material;

import org.angle3d.light.LightList;
import org.angle3d.material.technique.TechniqueWireframe;
import org.angle3d.renderer.RenderManager;
import org.angle3d.scene.Geometry;

/**
 * 线框模式
 * @author weilichuang
 */

class MaterialWireframe extends Material
{
	private var _technique:TechniqueWireframe;
	
	public var thickness(get, set):Float;
	public var technique(get, null):TechniqueWireframe;
	public var color(get, set):UInt;
	public var useVertexColor(get, set):Bool;

	public function new(color:UInt = 0xFF0000, thickness:Float = 1.0)
	{
		super();

		_technique = new TechniqueWireframe(color, thickness);

		addTechnique(_technique);

		sortingId = 3;
	}

	override public function render(g:Geometry,lightList:LightList, rm:RenderManager):Void
	{
		super.render(g, lightList, rm);
	}
	
	private function get_useVertexColor():Bool
	{
		return _technique.useVertexColor;
	}
	
	private function set_useVertexColor(value:Bool):Bool
	{
		return _technique.useVertexColor = value;
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

