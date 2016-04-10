package org.angle3d.material.shader;

import org.angle3d.texture.Texture;

/**
 *
 
 */
class TextureParam extends ShaderParam
{
	public var textureMap:Texture;

	public function new(name:String, size:Int)
	{
		super(name, size);
	}
}


