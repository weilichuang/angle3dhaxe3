package org.angle3d.texture;

import flash.display3D.Context3D;
import flash.display3D.Context3DMipFilter;
import flash.display3D.Context3DTextureFilter;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.Context3DWrapMode;
import flash.display3D.textures.TextureBase;
import flash.Vector;
/**
 * <code>Texture</code> defines a texture object to be used to display an
 * image on a piece of geometry. The image to be displayed is defined by the
 * <code>Image</code> class. All attributes required for texture mapping are
 * contained within this class. This includes mipmapping if desired,
 * magnificationFilter options, apply options and correction options. Default
 * values are as follows: minificationFilter - NearestNeighborNoMipMaps,
 * magnificationFilter - NearestNeighbor, wrap - EdgeClamp on S,T and R, apply -
 * Modulate, environment - None.
 *
 */
class TextureMapBase
{
	private static var TEXTURE_ID:Int = 0;
	
	public var id:Int;
	
	public var shaderKeys(get, null):Vector<String>;
	public var width(get, null):Int;
	public var height(get, null):Int;
	public var optimizeForRenderToTexture(get, set):Bool;
	public var mipFilter(get, set):Context3DMipFilter;
	public var textureFilter(get, set):Context3DTextureFilter;
	public var wrapMode(get, set):Context3DWrapMode;
	
	private var mWidth:Int;
	private var mHeight:Int;

	private var mMipmap:Bool;

	private var mDirty:Bool;

	private var mTexture:TextureBase;

	private var mOptimizeForRenderToTexture:Bool;

	private var mMipFilter:Context3DMipFilter;
	private var mTextureFilter:Context3DTextureFilter;
	private var mWrapMode:Context3DWrapMode;

	private var mFormat:Context3DTextureFormat;
	public var type:Int;

	public function new(mipmap:Bool = false)
	{
		this.id = TEXTURE_ID++;
		
		mMipmap = mipmap;
		mDirty = false;
		mOptimizeForRenderToTexture = false;
		
		
		mMipFilter = Context3DMipFilter.MIPNONE;
		mTextureFilter = Context3DTextureFilter.LINEAR;
		mWrapMode = Context3DWrapMode.CLAMP;

		mFormat = Context3DTextureFormat.BGRA;
		type = TextureType.TwoDimensional;
	}

	
	private function get_shaderKeys():Vector<String>
	{
		return Vector.ofArray([cast mFormat, cast mMipFilter, cast mTextureFilter, cast mWrapMode]);
	}

	private function get_wrapMode():Context3DWrapMode
	{
		return mWrapMode;
	}

	private function set_wrapMode(wrapMode:Context3DWrapMode):Context3DWrapMode
	{
		return this.mWrapMode = wrapMode;
	}

	public function getFormat():Context3DTextureFormat
	{
		return mFormat;
	}

	public function setFormat(format:Context3DTextureFormat):Void
	{
		this.mFormat = format;
	}

	/**
	 * @return the MinificationFilterMode of this texture.
	 */
	private function get_mipFilter():Context3DMipFilter
	{
		return mMipFilter;
	}

	/**
	 * @param minificationFilter
	 *            the new MinificationFilterMode for this texture.
	 * @throws IllegalArgumentException
	 *             if minificationFilter is null
	 */
	private function set_mipFilter(minFilter:Context3DMipFilter):Context3DMipFilter
	{
		return this.mMipFilter = minFilter;
	}

	/**
	 * @return the MagnificationFilterMode of this texture.
	 */
	private function get_textureFilter():Context3DTextureFilter
	{
		return mTextureFilter;
	}

	/**
	 * @param magnificationFilter
	 *            the new MagnificationFilter for this texture.
	 * @throws IllegalArgumentException
	 *             if magnificationFilter is null
	 */
	private function set_textureFilter(magFilter:Context3DTextureFilter):Context3DTextureFilter
	{
		return this.mTextureFilter = magFilter;
	}

	public function getTexture(context:Context3D):TextureBase
	{
		if (mTexture == null || mDirty)
		{
			if (mTexture != null)
				mTexture.dispose();

			mTexture = createTexture(context);
			uploadTexture();
			mDirty = false;
		}

		return mTexture;
	}

	public function setMipMap(value:Bool):Void
	{
		if (mMipmap != value)
		{
			mMipmap = value;
			mDirty = true;
		}
	}

	public function getMipMap():Bool
	{
		return mMipmap;
	}

	
	private function get_width():Int
	{
		return mWidth;
	}

	
	private function get_height():Int
	{
		return mHeight;
	}

	
	/**
	 *  如果纹理很可能用作呈现目标，则设置为 true。
	 */
	private function get_optimizeForRenderToTexture():Bool
	{
		return mOptimizeForRenderToTexture;
	}

	/**
	 *  如果纹理很可能用作呈现目标，则设置为 true。
	 */
	private function set_optimizeForRenderToTexture(value:Bool):Bool
	{
		if (mOptimizeForRenderToTexture != value)
		{
			mOptimizeForRenderToTexture = value;
			mDirty = true;
		}
		
		return mOptimizeForRenderToTexture;
	}

	public function invalidateContent():Void
	{
		mDirty = true;
	}

	public function dispose():Void
	{
		if (mTexture != null)
		{
			mTexture.dispose();
			mTexture = null;
			mDirty = false;
		}
	}

	private function createTexture(context:Context3D):TextureBase
	{
		return null;
	}

	private function uploadTexture():Void
	{

	}

	private function setSize(width:Int, height:Int):Void
	{
		if (mWidth != width || mHeight != height)
			dispose();

		mWidth = width;
		mHeight = height;
	}
}

