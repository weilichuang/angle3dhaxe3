package org.angle3d.material;

import org.angle3d.material.Technique;
import org.angle3d.renderer.IRenderer;
import org.angle3d.texture.TextureMapBase;

class MatParamTexture extends MatParam
{
	public var texture:TextureMapBase;
	public var index:Int;

	public function new(type:String, name:String, texture:TextureMapBase, index:Int)
	{
		super(type, name, texture);
		this.texture = texture;
		this.index = index;
	}

	override public function apply(r:IRenderer, technique:Technique):Void
	{
		r.setTextureAt(index, texture);
		technique.updateUniformParam(name, type, index);
	}
}
