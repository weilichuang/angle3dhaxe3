package org.angle3d.material.shader;

import org.angle3d.texture.TextureMapBase;

/**
 *
 * @author weilichuang
 */
class TextureParam extends ShaderParam
{
	public var textureMap:TextureMapBase;

	public function new(name:String, size:Int)
	{
		super(name, size);
	}
}


