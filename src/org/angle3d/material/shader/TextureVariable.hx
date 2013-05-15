package org.angle3d.material.shader;

import org.angle3d.texture.TextureMapBase;

/**
 *
 * @author Andy
 */
class TextureVariable extends ShaderVariable
{
	public var textureMap:TextureMapBase;

	public function new(name:String, size:Int)
	{
		super(name, size);
	}
}


