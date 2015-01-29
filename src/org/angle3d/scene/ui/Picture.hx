package org.angle3d.scene.ui;

import org.angle3d.material.BlendMode;
import org.angle3d.material.MaterialTexture;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.scene.CullHint;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Quad;
import org.angle3d.texture.TextureMapBase;

/**
 * A Image represents a 2D image drawn on the screen.
 * It can be used to represent sprites or other background elements.
 */
class Picture extends Geometry
{
	private var mWidth:Float;
	private var mHeight:Float;

	public function new(name:String, flipY:Bool = false)
	{
		super(name, new Quad(1, 1, flipY));

		this.localQueueBucket = QueueBucket.Gui;
		this.localCullHint = CullHint.Never;
	}
	
	/**
     * Set the width in pixels of the picture, if the width
     * does not match the texture's width, then the texture will
     * be scaled to fit the picture.
     * 
     * @param width the width to set.
     */
	public function setWidth(width:Float):Void
	{
		mWidth = width;
		setLocalScaleXYZ(mWidth, mHeight, 1);
	}
	
	/**
     * Set the height in pixels of the picture, if the height
     * does not match the texture's height, then the texture will
     * be scaled to fit the picture.
     * 
     * @param height the height to set.
     */
	public function setHeight(height:Float):Void
	{
		mHeight = height;
		setLocalScaleXYZ(mWidth, mHeight, 1);
	}

	public function setSize(width:Float, height:Float):Void
	{
		mWidth = width;
		mHeight = height;
		setLocalScaleXYZ(mWidth, mHeight, 1);
	}

	/**
     * Set the position of the picture in pixels.
     * The origin (0, 0) is at the bottom-left of the screen.
     * 
     * @param x The x coordinate
     * @param y The y coordinate
     */
	public function setPosition(x:Float, y:Float):Void
	{
		var z:Float = this.translation.z;
		this.setTranslationXYZ(x, y, z);
	}

	public function setTexture(texture:TextureMapBase, useAlpha:Bool):Void
	{
		if (mMaterial == null)
		{
			mMaterial = new MaterialTexture(texture);
			this.setMaterial(mMaterial);
		}
		Std.instance(mMaterial, MaterialTexture).texture = texture;
		mMaterial.getAdditionalRenderState().setBlendMode(useAlpha ? BlendMode.Alpha : BlendMode.Off);
	}
}
