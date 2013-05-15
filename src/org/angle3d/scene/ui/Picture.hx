package org.angle3d.scene.ui;

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

	public function setSize(width:Float, height:Float):Void
	{
		mWidth = width;
		mHeight = height;
		setScaleXYZ(mWidth, mHeight, 1);
	}

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
		cast(mMaterial,MaterialTexture).texture = texture;
	}
}
