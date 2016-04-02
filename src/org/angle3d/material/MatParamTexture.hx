package org.angle3d.material;

import org.angle3d.material.shader.TextureParam;
import org.angle3d.material.Technique;
import org.angle3d.renderer.RendererBase;
import org.angle3d.texture.Texture;

class MatParamTexture extends MatParam
{
	public var texture:Texture;

	public function new(type:VarType, name:String, texture:Texture)
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
