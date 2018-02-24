package angle3d.material;

import angle3d.shader.TextureParam;
import angle3d.material.Technique;
import angle3d.renderer.Renderer;
import angle3d.shader.VarType;
import angle3d.texture.image.ColorSpace;
import angle3d.texture.Texture;
import angle3d.utils.Logger;

class MatParamTexture extends MatParam {
	public var texture:Texture;
	/**
	 * the color space required by this texture param
	 */
	public var colorSpace:ColorSpace;

	public function new(type:VarType, name:String, texture:Texture,colorSpace:ColorSpace) {
		super(type, name, texture);
		this.texture = texture;
		this.colorSpace = colorSpace;
	}

	public function setTexture(value:Texture):Void {
		this.value = value;
		this.texture = value;
	}
}
