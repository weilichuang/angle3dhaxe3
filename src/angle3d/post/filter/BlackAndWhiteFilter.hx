package angle3d.post.filter;

import angle3d.material.Material;
import angle3d.post.Filter;
import angle3d.renderer.RenderManager;
import angle3d.renderer.ViewPort;

/**
 * 黑白滤镜
 */
class BlackAndWhiteFilter extends Filter {
	public function new() {
		super("BlackAndWhiteFilter");
	}

	override public function isRequiresDepthTexture():Bool {
		return false;
	}

	override private function initFilter(renderManager:RenderManager, vp:ViewPort, w:Int, h:Int):Void {
		material = new Material();
		material.load(Angle3D.materialFolder + "material/blackandwhite.mat");
	}

	override public function getMaterial():Material {
		return material;
	}
}
