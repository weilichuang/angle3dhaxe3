package org.angle3d.material;

import org.angle3d.texture.TextureMapBase;

/**
 * GPU计算粒子运动，旋转，缩放，颜色变化等
 * @author weilichuang
 */
class MaterialGPUParticle extends Material
{
	private var _curTime:Float = 0;
	public function new(texture:TextureMapBase)
	{
		super();

		load("assets/material/gpuparticle.mat");
		
		setTexture("s_texture", texture);
	}

	public function reset():Void
	{
		_curTime = 0;
		setFloat("u_curTime", 0);
	}

	public function update(tpf:Float):Void
	{
		_curTime += tpf;
		setFloat("u_curTime", _curTime);
	}
}
