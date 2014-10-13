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

	public function setSpatial(spatial:Spatial):Void
	{
	}

	public function isEnabled():Bool
	{
		return _enabled;
	}
	
	public function setEnabled(enabled:Bool):Void
	{
		_enabled = enabled;
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

