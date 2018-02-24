package angle3d.scene.ui;

import angle3d.material.BlendMode;
import angle3d.material.FaceCullMode;
import angle3d.material.Material;
import angle3d.renderer.queue.QueueBucket;
import angle3d.scene.CullHint;
import angle3d.scene.Geometry;
import angle3d.scene.shape.Quad;
import angle3d.texture.Texture;

/**
 * A Image represents a 2D image drawn on the screen.
 * It can be used to represent sprites or other background elements.
 */
class Picture extends Geometry {
	private var mWidth:Float = 1;
	private var mHeight:Float = 1;

	public function new(name:String, flipY:Bool = false) {
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
	public function setWidth(width:Float):Void {
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
	public function setHeight(height:Float):Void {
		mHeight = height;
		setLocalScaleXYZ(mWidth, mHeight, 1);
	}

	public function setSize(width:Float, height:Float):Void {
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
	public function setPosition(x:Float, y:Float):Void {
		var z:Float = this.localTranslation.z;
		this.setTranslationXYZ(x, y, z);
	}

	public function setTexture(texture:Texture, useAlpha:Bool):Void {
		if (mMaterial == null) {
			mMaterial = new Material();
			mMaterial.load(Angle3D.materialFolder + "material/unshaded.mat");
			this.setMaterial(mMaterial);
		}
		mMaterial.setTexture("u_DiffuseMap", texture);
		mMaterial.setTransparent(useAlpha);
		mMaterial.getAdditionalRenderState().setBlendMode(useAlpha ? BlendMode.Alpha : BlendMode.Off);
	}
}