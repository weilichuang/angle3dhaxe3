package org.angle3d.material;

import org.angle3d.material.technique.TechniqueCPUParticle;
import org.angle3d.material.technique.TechniqueGPUParticle;
import org.angle3d.math.Vector3f;
import org.angle3d.texture.TextureMapBase;

/**
 * GPU计算粒子运动，旋转，缩放，颜色变化等
 * @author weilichuang
 */
class MaterialGPUParticle extends Material
{
	private var _technique:TechniqueGPUParticle;

	public function new(texture:TextureMapBase)
	{
		super();

		_technique = new TechniqueGPUParticle();
		setTechnique(_technique);

		this.texture = texture;
	}

	public var useLocalColor(get, set):Bool;
	private function get_useLocalColor():Bool
	{
		return _technique.useLocalColor;
	}
	private function set_useLocalColor(value:Bool):Bool
	{
		return _technique.useLocalColor = value;
	}

	
	public var useLocalAcceleration(get, set):Bool;
	private function get_useLocalAcceleration():Bool
	{
		return _technique.useLocalAcceleration;
	}
	private function set_useLocalAcceleration(value:Bool):Bool
	{
		return _technique.useLocalAcceleration = value;
	}

	public var blendMode(get, set):BlendMode;
	private function get_blendMode():BlendMode
	{
		return _technique.renderState.blendMode;
	}
	private function set_blendMode(mode:BlendMode):BlendMode
	{
		return _technique.renderState.blendMode = mode;
	}

	public var loop(get, set):Bool;
	private function get_loop():Bool
	{
		return _technique.loop;
	}
	private function set_loop(value:Bool):Bool
	{
		return _technique.loop = value;
	}

	

	/**
	 * 使用自转
	 */
	public var useSpin(get, set):Bool;
	private function get_useSpin():Bool
	{
		return _technique.getUseSpin();
	}
	private function set_useSpin(value:Bool):Bool
	{
		_technique.setUseSpin(value);
		return _technique.getUseSpin();
	}

	public function reset():Void
	{
		_technique.curTime = 0;
	}

	public function update(tpf:Float):Void
	{
		_technique.curTime += tpf;
	}

	public function setAcceleration(acceleration:Vector3f):Void
	{
		_technique.setAcceleration(acceleration);
	}

	/**
	 *
	 * @param animDuration 播放速度,多长时间播放一次（秒）
	 * @param col
	 * @param row
	 *
	 */
	public function setSpriteSheet(animDuration:Float, col:Int, row:Int):Void
	{
		_technique.setSpriteSheet(animDuration, col, row);
	}

	public function setParticleColor(start:UInt, end:UInt):Void
	{
		_technique.setColor(start, end);
	}

	public function setAlpha(start:Float, end:Float):Void
	{
		_technique.setAlpha(start, end);
	}

	public function setSize(start:Float, end:Float):Void
	{
		_technique.setSize(start, end);
	}

	override private function set_influence(value:Float):Float
	{
		return value;
	}

	public var technique(get, null):TechniqueGPUParticle;
	private function get_technique():TechniqueGPUParticle
	{
		return _technique;
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
}
