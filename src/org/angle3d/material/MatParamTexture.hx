package org.angle3d.material;

import org.angle3d.material.shader.TextureParam;
import org.angle3d.material.Technique;
import org.angle3d.renderer.Renderer;
import org.angle3d.shader.VarType;
import org.angle3d.texture.Texture;
import org.angle3d.utils.Logger;

class MatParamTexture extends MatParam
{
	public var texture:Texture;

	public function new(type:VarType, name:String, texture:Texture)
	{
		super(type, name, texture);
		this.texture = texture;
	}
	
	public function setTexture(value:Texture):Void
	{
        this.value = value;
        this.texture = value;
    }
}
