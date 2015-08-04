package org.angle3d.terrain.heightmap ;

import flash.display.BitmapData;
import flash.Vector;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;

/**
 * <code>ImageBasedHeightMap</code> is a height map created from the grayscale
 * conversion of an image. The image used currently must have an equal height
 * and width, although future work could scale an incoming image to a specific
 * height and width.
 * 
 * @author Mike Kienenberger
 * @version $id$
 */
class ImageBasedHeightMap extends AbstractHeightMap implements ImageHeightmap
{
    private var colorImage:BitmapData;
    private var backwardsCompScale:Float = 255;
	private var flipX:Bool = false;
	private var flipY:Bool = false;

    
    public function setImage(image:BitmapData):Void
	{
        this.colorImage = image;
    }
    
    /**
     * Creates a HeightMap from an Image. The image will be converted to
     * grayscale, and the grayscale values will be used to generate the height
     * map. White is highest point while black is lowest point.
     * 
     * Currently, the Image used must be square (width == height), but future
     * work could rescale the image.
     * 
     * @param colorImage
     *            Image to map to the height map.
     */
    public function new(colorImage:BitmapData, heightScale:Float = 1,flipX:Bool = false, flipY:Bool = false)
	{
    	this.colorImage = colorImage;
        this.heightScale = heightScale;
		this.flipX = flipX;
		this.flipY = flipY;
    }

    /**
     * Get the grayscale value, or override in your own sub-classes
     */
    private function calculateHeight(red:Float, green:Float, blue:Float):Float
	{
        return (0.299 * red + 0.587 * green + 0.114 * blue);
    }
    
    private function calculateHeightColor(color:Int):Float
	{
		var invert:Float = FastMath.INVERT_255;
		var r = (color >> 16 & 0xFF) * invert;
		var g = (color >> 8 & 0xFF) * invert;
		var b = (color & 0xFF) * invert;
        return (0.299 * r + 0.587 * g + 0.114 * b);
    }
    
    override public function load():Bool 
	{

        var imageWidth:Int = colorImage.width;
        var imageHeight:Int = colorImage.height;

        if (imageWidth != imageHeight)
                throw ("imageWidth: " + imageWidth
                        + " != imageHeight: " + imageHeight);

        size = imageWidth;

        heightData = new Vector<Float>(imageWidth * imageHeight);

        var index:Int = 0;
        if (flipY) 
		{
            for (h in 0...imageHeight)
			{
                if (flipX) 
				{
					var w:Int = imageWidth - 1;
                    while ( w >= 0) 
					{
                        heightData[index++] = calculateHeightColor(colorImage.getPixel(w, h)) * heightScale * backwardsCompScale;
						
						--w;
                    }
                } 
				else 
				{
                    for (w in 0...imageWidth)
					{
                        heightData[index++] = calculateHeightColor(colorImage.getPixel(w, h)) * heightScale * backwardsCompScale;
                    }
                }
            }
        }
		else
		{
			var h:Int = imageHeight - 1; 
            while (h >= 0)
			{
                if (flipX)
				{
					var w:Int = imageWidth - 1;
                    while ( w >= 0)
					{
                        heightData[index++] = calculateHeightColor(colorImage.getPixel(w, h)) * heightScale * backwardsCompScale;
						--w;
                    }
                } 
				else 
				{
                    for (w in 0...imageWidth)
					{
                        heightData[index++] = calculateHeightColor(colorImage.getPixel(w, h)) * heightScale * backwardsCompScale;
                    }
                }
				
				--h;
            }
        }

        return true;
    }
    
    /*private float getHeightAtPostion(ImageRaster image, int position, ColorRGBA store) {
        switch (image.getFormat()){
            case RGBA8:
                buf.position( position * 4 );
                store.set(byte2float(buf.get()), byte2float(buf.get()), byte2float(buf.get()), byte2float(buf.get()));
                return calculateHeight(store.r, store.g, store.b);
            case ABGR8:
                buf.position( position * 4 );
                float a = byte2float(buf.get());
                float b = byte2float(buf.get());
                float g = byte2float(buf.get());
                float r = byte2float(buf.get());
                store.set(r,g,b,a);
                return calculateHeight(store.r, store.g, store.b);
            case RGB8:
                buf.position( position * 3 );
                store.set(byte2float(buf.get()), byte2float(buf.get()), byte2float(buf.get()), 1);
                return calculateHeight(store.r, store.g, store.b);
            case Luminance8:
                buf.position( position );
                return byte2float(buf.get())*255*heightScale;
            case Luminance16:
                ShortBuffer sbuf = buf.asShortBuffer();
                sbuf.position( position );
                return (sbuf.get() & 0xFFFF) / 65535f * 255f * heightScale;
            default:
                throw new UnsupportedOperationException("Image format: "+image.getFormat());
        }
    }
    
    private float byte2float(byte b){
        return ((float)(b & 0xFF)) / 255f;
    }*/
}