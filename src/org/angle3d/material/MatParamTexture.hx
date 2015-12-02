package org.angle3d.material;

import org.angle3d.material.shader.TextureParam;
import org.angle3d.material.Technique;
import org.angle3d.renderer.RendererBase;
import org.angle3d.texture.TextureMapBase;

class MatParamTexture extends MatParam
{
	public var texture:TextureMapBase;

	public function new(type:Int, name:String, texture:TextureMapBase)
	{
		super(type, name, texture);
		this.texture = texture;
	}

	override public function apply(r:RendererBase, technique:Technique):Void
	{
		var textureParam:TextureParam = technique.getShader().getTextureParam(this.name);
		if (textureParam == null)
		{
			//throw "Cant find TextureParam: " + this.name;
			return;
		}
		
		r.setTextureAt(textureParam.location, texture);
	}
}
