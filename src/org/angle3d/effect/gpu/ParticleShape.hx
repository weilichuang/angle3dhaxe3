package org.angle3d.effect.gpu;

import org.angle3d.material.BlendMode;
import org.angle3d.material.MaterialGPUParticle;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.texture.TextureMapBase;

class ParticleShape extends Geometry
{
	public var useLocalAcceleration(get, set):Bool;
	public var useLocalColor(get, set):Bool;
	public var blendMode(get, set):BlendMode;
	public var useSpin(get, set):Bool;
	public var loop(get, set):Bool;
	public var startTime(get, set):Float;
	public var isDead(get, null):Bool;
	
	//开始时间
	private var _startTime:Float;

	//当前时间
	private var _currentTime:Float;

	//生命
	private var _totalLife:Float;

	private var _gpuMaterial:MaterialGPUParticle;

	/**
	 *
	 * @param name 名字
	 * @param texture 贴图
	 * @param totalLife 生命周期
	 * @param startTime 开始时间
	 *
	 */
	public function new(name:String, texture:TextureMapBase, totalLife:Float, startTime:Float = 0)
	{
		super(name);

		_startTime = startTime;
		_totalLife = totalLife;

		_gpuMaterial = new MaterialGPUParticle(texture);
		setMaterial(_gpuMaterial);
		localShadowMode = ShadowMode.Off;
		localQueueBucket = QueueBucket.Transparent;

		loop = true;
		_currentTime = 0;
	}

	/**
	 * 使用粒子单独加速度
	 */
	
	private function get_useLocalAcceleration():Bool
	{
		return _gpuMaterial.useLocalAcceleration;
	}
	private function set_useLocalAcceleration(value:Bool):Bool
	{
		return _gpuMaterial.useLocalAcceleration = value;
	}

	
	private function get_useLocalColor():Bool
	{
		return _gpuMaterial.useLocalColor;
	}
	private function set_useLocalColor(value:Bool):Bool
	{
		return _gpuMaterial.useLocalColor = value;
	}

	
	
	private function get_blendMode():BlendMode
	{
		return _gpuMaterial.blendMode;
	}
	private function set_blendMode(mode:BlendMode):BlendMode
	{
		return _gpuMaterial.blendMode = mode;
	}

	/**
	 * 使用自转
	 */
	
	private function get_useSpin():Bool
	{
		return _gpuMaterial.useSpin;
	}
	private function set_useSpin(value:Bool):Bool
	{
		return _gpuMaterial.useSpin = value;
	}

	/**
	 * 设置全局加速度，会影响每一个粒子
	 */
	public function setAcceleration(acceleration:Vector3f):Void
	{
		_gpuMaterial.setAcceleration(acceleration);
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
		_gpuMaterial.setSpriteSheet(animDuration, col, row);
	}

	public function setColor(start:UInt, end:UInt):Void
	{
		_gpuMaterial.setParticleColor(start, end);
	}

	public function setAlpha(start:Float, end:Float):Void
	{
		_gpuMaterial.setAlpha(start, end);
	}

	public function setSize(start:Float, end:Float):Void
	{
		_gpuMaterial.setSize(start, end);
	}

	
	private function get_loop():Bool
	{
		return _gpuMaterial.loop;
	}
	private function set_loop(value:Bool):Bool
	{
		return _gpuMaterial.loop = value;
	}

	public function reset():Void
	{
		_currentTime = 0;
		_gpuMaterial.reset();
		visible = false;
	}

	
	private function get_startTime():Float
	{
		return _startTime;
	}
	private function set_startTime(value:Float):Float
	{
		return _startTime = value;
	}

	
	private function get_isDead():Bool
	{
		return !loop && (_currentTime - _startTime) > _totalLife;
	}

	/**
	 * 内部调用
	 */
	public function updateMaterial(tpf:Float):Void
	{
		_currentTime += tpf;
		_gpuMaterial.update(tpf);
	}
}
