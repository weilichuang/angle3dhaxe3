package angle3d.post;

import flash.display.Bitmap;
import flash.display.BitmapData;
import angle3d.texture.Texture2D;

import angle3d.material.Material;
import angle3d.renderer.Renderer;
import angle3d.texture.FrameBuffer;
import angle3d.texture.BitmapTexture;
import angle3d.texture.Texture;

/**
 * Pass are like filters in filters.
 * Some filters will need multiple passes before the final render
 */
class Pass {
	public var renderFrameBuffer:FrameBuffer;
	public var renderedTexture:Texture2D;
	public var depthTexture:Texture2D;
	public var passMaterial:Material;

	public function new() {

	}

	public function init(render:Renderer, width:Int, height:Int, renderDepth:Bool = false):Void {
		renderFrameBuffer = new FrameBuffer(width, height);

		renderedTexture = new Texture2D(width, height);
		renderFrameBuffer.setColorTexture(renderedTexture);

		if (renderDepth) {
			depthTexture = new Texture2D(width, height);
			renderFrameBuffer.addColorTexture(depthTexture);
		}
	}

	public function requiresSceneAsTexture():Bool {
		return false;
	}

	public function requiresDepthAsTexture():Bool {
		return false;
	}

	public function beforeRender():Void {

	}

	public function getRenderFrameBuffer():FrameBuffer {
		return renderFrameBuffer;
	}

	public function setRenderFrameBuffer(renderFrameBuffer:FrameBuffer):Void {
		this.renderFrameBuffer = renderFrameBuffer;
	}

	public function getDepthTexture():Texture2D {
		return depthTexture;
	}

	public function getRenderedTexture():Texture2D {
		return renderedTexture;
	}

	public function setRenderedTexture(renderedTexture:Texture2D):Void {
		this.renderedTexture = renderedTexture;
	}

	public function getPassMaterial():Material {
		return passMaterial;
	}

	public function setPassMaterial(passMaterial:Material):Void {
		this.passMaterial = passMaterial;
	}

	public function cleanup(r:Renderer):Void {
		renderFrameBuffer.dispose();
		if (renderedTexture != null) {
			renderedTexture.dispose();
			renderedTexture = null;
		}

		if (depthTexture != null) {
			depthTexture.dispose();
			depthTexture = null;
		}
	}
}

