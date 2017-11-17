package org.angle3d.post;
import org.angle3d.material.FaceCullMode;
import org.angle3d.material.Material;
import org.angle3d.material.RenderState;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.renderer.queue.RenderQueue;
import org.angle3d.renderer.ViewPort;
import org.angle3d.renderer.RenderManager;

/**
 * Processor that lays depth first, this can improve performance in complex
 * scenes.
 */
class PreDepthProcessor implements SceneProcessor {
	private var rm:RenderManager;
	private var vp:ViewPort;
	private var preDepth:Material;
	private var forcedRS:RenderState;

	public function new() {
		this.preDepth = new Material();
		this.preDepth.load(Angle3D.materialFolder + "material/depth.mat");
		this.preDepth.getAdditionalRenderState().setCullMode(FaceCullMode.BACK);

		forcedRS = new RenderState();
		forcedRS.setDepthTest(true);
		forcedRS.setDepthWrite(false);
	}

	/* INTERFACE org.angle3d.post.SceneProcessor */

	public function initialize(rm:RenderManager, vp:ViewPort):Void {
		this.rm = rm;
		this.vp = vp;
	}

	public function isInitialized():Bool {
		return vp != null;
	}

	public function reshape(vp:ViewPort, w:Int, h:Int):Void {
		this.vp = vp;
	}

	public function preFrame(tpf:Float):Void {

	}

	public function postQueue(rq:RenderQueue):Void {
		//lay depth first
		rm.setForcedMaterial(preDepth);
		rq.renderQueue(QueueBucket.Opaque, rm, vp.camera, false);
		rm.setForcedMaterial(null);

		rm.setForcedRenderState(forcedRS);
	}

	public function postFrame(out:FrameBuffer):Void {
		rm.setForcedRenderState(null);
	}

	public function cleanup():Void {
		vp = null;
	}

}