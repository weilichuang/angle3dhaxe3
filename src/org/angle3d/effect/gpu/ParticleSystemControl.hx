package org.angle3d.effect.gpu;

import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.Spatial;
import org.angle3d.scene.control.Control;

/**
 * ...
 * @author andy
 */
class ParticleSystemControl implements Control
{
	private var particleSystem:ParticleSystem;
	private var _enabled:Bool;

	public function new(particleSystem:ParticleSystem)
	{
		this.particleSystem = particleSystem;
		_enabled = true;
	}

	public function cloneForSpatial(spatial:Spatial):Control
	{
		return this;
	}

	public var spatial(get, set):Spatial;
	private function get_spatial():Spatial
	{
		return null;
	}
	private function set_spatial(spatial:Spatial):Spatial
	{
		return null;
	}

	public var enabled(get, set):Bool;
	private function get_enabled():Bool
	{
		return _enabled;
	}
	private function set_enabled(enabled:Bool):Bool
	{
		return _enabled = enabled;
	}

	

	public function update(tpf:Float):Void
	{
		if (!_enabled)
			return;

		particleSystem.updateFromControl(tpf);
	}

	public function render(rm:RenderManager, vp:ViewPort):Void
	{
	}

	public function clone():Control
	{
		return new ParticleSystemControl(this.particleSystem);
	}
}

