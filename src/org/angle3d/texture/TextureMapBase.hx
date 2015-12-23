package org.angle3d.texture;

import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;
import flash.Vector;
import org.angle3d.material.MipFilter;
import org.angle3d.material.TextureFilter;
import org.angle3d.material.WrapMode;
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
	
	private var mId:Int;
	
	public var id(get, null):Int;
	public var shaderKeys(get, null):Vector<String>;
	public var width(get, null):Int;
	public var height(get, null):Int;
	public var optimizeForRenderToTexture(get, set):Bool;
	public var mipFilter(get, set):String;
	public var textureFilter(get, set):String;
	public var wrapMode(get, set):String;
	
	private var mWidth:Int;
	private var mHeight:Int;

	private var mMipmap:Bool;

	private var mDirty:Bool;

	private var mTexture:TextureBase;

	private var mOptimizeForRenderToTexture:Bool;

	private var mMipFilter:String;
	private var mTextureFilter:String;
	private var mWrapMode:String;

	private var mFormat:Context3DTextureFormat;
	public var type:Int;

	public function new(mipmap:Bool = false)
	{
		this.id = TEXTURE_ID++;
		
		mMipmap = mipmap;
		mDirty = false;
		mOptimizeForRenderToTexture = false;
		
		
		mMipFilter = MipFilter.MIPNONE;
		mTextureFilter = TextureFilter.LINEAR;
		mWrapMode = WrapMode.CLAMP;

		mFormat = Context3DTextureFormat.BGRA;
		type = TextureType.TwoDimensional;
	}

	private inline function get_id():Int
	{
		return mId;
	}
	
	private function get_shaderKeys():Vector<String>
	{
		return Vector.ofArray([cast mFormat, mMipFilter, mTextureFilter, mWrapMode]);
	}

	private inline function get_wrapMode():String
	{
		return mWrapMode;
	}

	private function set_wrapMode(wrapMode:String):String
	{
		return this.mWrapMode = wrapMode;
	}

	public inline function getFormat():Context3DTextureFormat
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
	private inline function get_mipFilter():String
	{
		return mMipFilter;
	}

	/**
	 * @param minificationFilter
	 *            the new MinificationFilterMode for this texture.
	 * @throws IllegalArgumentException
	 *             if minificationFilter is null
	 */
	private function set_mipFilter(minFilter:String):String
	{
		return this.mMipFilter = minFilter;
	}

	/**
	 * @return the MagnificationFilterMode of this texture.
	 */
	private inline function get_textureFilter():String
	{
		return mTextureFilter;
	}

	/**
	 * @param magnificationFilter
	 *            the new MagnificationFilter for this texture.
	 * @throws IllegalArgumentException
	 *             if magnificationFilter is null
	 */
	private function set_textureFilter(magFilter:String):String
	{
		return this.mTextureFilter = magFilter;
	}

	public inline function getTexture(context:Context3D):TextureBase
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

