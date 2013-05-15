package org.angle3d.material;

import org.angle3d.material.technique.TechniqueCPUParticle;
import org.angle3d.texture.TextureMapBase;

/**
 * CPU计算粒子运动，颜色变化等，GPU只负责渲染部分
 * @author andy
 */
class MaterialCPUParticle extends Material
{
	private var _technique:TechniqueCPUParticle;

	public function new(texture:TextureMapBase)
	{
		super();

		_technique = new TechniqueCPUParticle();
		addTechnique(_technique);

		this.texture = texture;
	}

	override private function set_influence(value:Float):Float
	{
		return value;
	}

	private function get_technique():TechniqueCPUParticle
	{
		return _technique;
	}

	public var texture(get, set):TextureMapBase;
	private function set_texture(value:TextureMapBase):TextureMapBase
	{
		return _technique.texture = value;
	}


	private function get_texture():TextureMapBase
	{
		return _technique.texture;
	}
}

