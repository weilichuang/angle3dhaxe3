package angle3d.effect.cpu;

import angle3d.renderer.RenderManager;
import angle3d.renderer.ViewPort;
import angle3d.scene.control.Control;
import angle3d.scene.Spatial;

/**
 * ...

 */
class ParticleEmitterControl implements Control {
	private var particleEmitter:ParticleEmitter;

	public function new(parentEmitter:ParticleEmitter) {
		this.particleEmitter = parentEmitter;
	}

	public function dispose():Void {
		particleEmitter = null;
	}

	public function cloneForSpatial(spatial:Spatial):Control {
		return this;
	}

	public function setSpatial(spatial:Spatial):Void {
	}

	public function setEnabled(enabled:Bool):Void {
		particleEmitter.enabled = enabled;
	}

	public function isEnabled():Bool {
		return particleEmitter.enabled;
	}

	public function update(tpf:Float):Void {
		particleEmitter.updateFromControl(tpf);
	}

	public function render(rm:RenderManager, vp:ViewPort):Void {
		particleEmitter.renderFromControl(rm, vp);
	}

	public function clone():Control {
		return new ParticleEmitterControl(this.particleEmitter);
	}
}

