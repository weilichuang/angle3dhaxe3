package org.angle3d.effect.cpu;

import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.control.Control;
import org.angle3d.scene.Spatial;

/**
 * ...
 * @author andy
 */
class ParticleEmitterControl implements Control
{
	private var particleEmitter:ParticleEmitter;

	public function new(parentEmitter:ParticleEmitter)
	{
		this.particleEmitter = parentEmitter;
	}

	public function cloneForSpatial(spatial:Spatial):Control
	{
		return this;
	}

	public var spatial(get, set):Spatial;
	private function set_spatial(spatial:Spatial):Spatial
	{
		return spatial;
	}

	private function get_spatial():Spatial
	{
		return null;
	}

	public var enabled(get, set):Bool;
	private function set_enabled(enabled:Bool):Bool
	{
		return particleEmitter.enabled = enabled;
	}

	private function get_enabled():Bool
	{
		return particleEmitter.enabled;
	}

	public function update(tpf:Float):Void
	{
		particleEmitter.updateFromControl(tpf);
	}

	public function render(rm:RenderManager, vp:ViewPort):Void
	{
		particleEmitter.renderFromControl(rm, vp);
	}

	public function clone():Control
	{
		return new ParticleEmitterControl(this.particleEmitter);
	}
}

