package org.angle3d.texture;

/**
 * ...
 * @author weilichuang
 */
class Texture2D extends TextureMapBase
{

	public function new(width:Int,height:Int,mipmap:Bool=false) 
	{
		super(mipmap);
		
		setSize(width, height);
		invalidateContent();
	}
	
}