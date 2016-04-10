package org.angle3d.terrain.heightmap ;

import flash.Vector;

/**
 * `AbstractHeightMap` provides a base implementation of height
 * data for terrain rendering. The loading of the data is dependent on the
 * subclass. The abstract implementation provides a means to retrieve the height
 * data and to save it.
 *
 * It is the general contract that any subclass provide a means of editing
 * required attributes and calling `load` again to recreate a
 * heightfield with these new parameters.
 *
 * @author Mark Powell
 * @version $Id: AbstractHeightMap.java 4133 2009-03-19 20:40:11Z blaine.dev $
 */
class AbstractHeightMap implements HeightMap
{
    /** Height data information. */
    private var heightData:Vector<Float> = null;
    /** The size of the height map's width. */
    private var size:Int = 0;
    /** Allows scaling the Y height of the map. */
    private var heightScale:Float = 1.0;
    /** The filter is used to erode the terrain. */
    private var filter:Float = 0.5;
    /** The range used to normalize terrain */
    public static var NORMALIZE_RANGE:Float = 255;

    /**
     * `unloadHeightMap` clears the data of the height map. This
     * insures it is ready for reloading.
     */
    public function unloadHeightMap():Void
	{
        heightData = null;
    }

    /**
     * `setHeightScale` sets the scale of the height values.
     * Typically, the height is a little too extreme and should be scaled to a
     * smaller value (i.e. 0.25), to produce cleaner slopes.
     *
     * @param scale
     *            the scale to multiply height values by.
     */
    public function setHeightScale( scale:Float):Void
	{
        heightScale = scale;
    }

    /**
     * `setHeightAtPoint` sets the height value for a given
     * coordinate. It is recommended that the height value be within the 0 - 255
     * range.
     *
     * @param height
     *            the new height for the coordinate.
     * @param x
     *            the x (east/west) coordinate.
     * @param z
     *            the z (north/south) coordinate.
     */
    public function setHeightAtPoint( height:Float, x:Int, z:Int):Void
	{
        heightData[x + (z * size)] = height;
    }

    /**
     * `setSize` sets the size of the terrain where the area is
     * size x size.
     *
     * @param size
     *            the new size of the terrain.
     * @throws Exception 
     *
     * @throws JmeException
     *             if the size is less than or equal to zero.
     */
    public function setSize( size:Int):Void
	{
        if (size <= 0) 
		{
            throw "size must be greater than zero.";
        }

        this.size = size;
    }

    /**
     * `setFilter` sets the erosion value for the filter. This
     * value must be between 0 and 1, where 0.2 - 0.4 produces arguably the best
     * results.
     *
     * @param filter
     *            the erosion value.
     * @throws Exception 
     *             if filter is less than 0 or greater than 1.
     */
    public function setMagnificationFilter( filter:Float):Void
	{
        if (filter < 0 || filter >= 1) 
		{
            throw ("filter must be between 0 and 1");
        }
        this.filter = filter;
    }

    /**
     * `getTrueHeightAtPoint` returns the non-scaled value at the
     * point provided.
     *
     * @param x
     *            the x (east/west) coordinate.
     * @param z
     *            the z (north/south) coordinate.
     * @return the value at (x,z).
     */
    public function getTrueHeightAtPoint( x:Int, z:Int):Float 
	{
        //Logger.fine( heightData[x + (z*size)]);
        return heightData[x + (z * size)];
    }

    /**
     * `getScaledHeightAtPoint` returns the scaled value at the
     * point provided.
     *
     * @param x
     *            the x (east/west) coordinate.
     * @param z
     *            the z (north/south) coordinate.
     * @return the scaled value at (x, z).
     */
    public function getScaledHeightAtPoint( x:Int, z:Int):Float
	{
        return ((heightData[x + (z * size)]) * heightScale);
    }

    /**
     * `getInterpolatedHeight` returns the height of a point that
     * does not fall directly on the height posts.
     *
     * @param x
     *            the x coordinate of the point.
     * @param z
     *            the y coordinate of the point.
     * @return the interpolated height at this point.
     */
    public function getInterpolatedHeight( x:Float, z:Float):Float
	{
        var low:Float, highX:Float, highZ:Float;
        var intX:Float, intZ:Float;
        var interpolation:Float;

        low = getScaledHeightAtPoint(Std.int(x), Std.int(z));

        if (x + 1 >= size)
		{
            return low;
        }

        highX = getScaledHeightAtPoint(Std.int(x), Std.int(z));

        interpolation = x - Std.int(x);
        intX = ((highX - low) * interpolation) + low;

        if (z + 1 >= size)
		{
            return low;
        }

        highZ = getScaledHeightAtPoint(Std.int(x), Std.int(z) + 1);

        interpolation = z - Std.int(z);
        intZ = ((highZ - low) * interpolation) + low;

        return ((intX + intZ) / 2);
    }

    /**
     * `getHeightMap` returns the entire grid of height data.
     *
     * @return the grid of height data.
     */
    public function getHeightMap():Vector<Float>
	{
        return heightData;
    }

    /**
     * Build a new array of height data with the scaled values.
     * @return
     */
    public function getScaledHeightMap():Vector<Float>
	{
        var hm:Vector<Float> = new Vector<Float>(heightData.length);
        for (i in 0...heightData.length)
		{
            hm[i] = heightScale * heightData[i];
        }
        return hm;
    }

    /**
     * `getSize` returns the size of one side the height map. Where
     * the area of the height map is size x size.
     *
     * @return the size of a single side.
     */
    public function getSize():Int
	{
        return size;
    }

    /**
     * `normalizeTerrain` takes the current terrain data and
     * converts it to values between 0 and `value`.
     *
     * @param value
     *            the value to normalize to.
     */
    public function normalizeTerrain(value:Float):Void
	{
        var currentMin:Float, currentMax:Float;
        var height:Float;

        currentMin = heightData[0];
        currentMax = heightData[0];

        //find the min/max values of the height fTemptemptempBuffer
        for (i in 0...size)
		{
            for (j in 0...size)
			{
                if (heightData[i + j * size] > currentMax)
				{
                    currentMax = heightData[i + j * size];
                } 
				else if (heightData[i + j * size] < currentMin)
				{
                    currentMin = heightData[i + j * size];
                }
            }
        }

        //find the range of the altitude
        if (currentMax <= currentMin) 
		{
            return;
        }

        height = currentMax - currentMin;

        //scale the values to a range of 0-255
        for (i in 0...size)
		{
            for (j in 0...size)
			{
                heightData[i + j * size] = ((heightData[i + j * size] - currentMin) / height) * value;
            }
        }
    }

    /**
     * Find the minimum and maximum height values.
     * @return a float array with two value: min height, max height
     */
    public function findMinMaxHeights():Vector<Float>
	{
        var minmax:Vector<Float> = new Vector<Float>(2);

        var currentMin:Float, currentMax:Float;
        currentMin = heightData[0];
        currentMax = heightData[0];

        for (i in 0...heightData.length)
		{
            if (heightData[i] > currentMax) 
			{
                currentMax = heightData[i];
            }
			else if (heightData[i] < currentMin)
			{
                currentMin = heightData[i];
            }
        }
        minmax[0] = currentMin;
        minmax[1] = currentMax;
        return minmax;
    }

    /**
     * `erodeTerrain` is a convenience method that applies the FIR
     * filter to a given height map. This simulates water errosion.
     *
     * @see setFilter
     */
    public function erodeTerrain():Void
	{
        //erode left to right
        var v:Float;

        for (i in 0...size) 
		{
            v = heightData[i];
            for (j in 1...size)
			{
                heightData[i + j * size] = filter * v + (1 - filter) * heightData[i + j * size];
                v = heightData[i + j * size];
            }
        }

        //erode right to left
		var i:Int = size - 1;
        while ( i >= 0)
		{
            v = heightData[i];
            for (j in 0...size)
			{
                heightData[i + j * size] = filter * v + (1 - filter) * heightData[i + j * size];
                v = heightData[i + j * size];
                //erodeBand(tempBuffer[size * i + size - 1], -1);
            }
			
			i--;
        }

        //erode top to bottom
        for (i in 0...size)
		{
            v = heightData[i];
            for (j in 0...size)
			{
                heightData[i + j * size] = filter * v + (1 - filter) * heightData[i + j * size];
                v = heightData[i + j * size];
            }
        }

        //erode from bottom to top
		var i:Int = size - 1;
        while ( i >= 0)
        {
            v = heightData[i];
            for (j in 0...size)
			{
                heightData[i + j * size] = filter * v + (1 - filter) * heightData[i + j * size];
                v = heightData[i + j * size];
            }
			
			i--;
        }
    }

    /**
     * Flattens out the valleys. The flatten algorithm makes the valleys more
     * prominent while keeping the hills mostly intact. This effect is based on
     * what happens when values below one are squared. The terrain will be
     * normalized between 0 and 1 for this function to work.
     *
     * @param flattening
     *            the power of flattening applied, 1 means none
     */
    public function flatten(flattening:Int):Void
	{
        // If flattening is one we can skip the calculations
        // since it wouldn't change anything. (e.g. 2 power 1 = 2)
        if (flattening <= 1)
		{
            return;
        }

        var minmax:Vector<Float> = findMinMaxHeights();

        normalizeTerrain(1);

        for (x in 0...size)
		{
            for (y in 0...size)
			{
                var flat:Float = 1.0;
                var original:Float = heightData[x + y * size];

                // Flatten as many times as desired;
                for (i in 0...flattening) 
				{
                    flat *= original;
                }
                heightData[x + y * size] = flat;
            }
        }

        // re-normalize back to its oraginal height range
        var height:Float = minmax[1] - minmax[0];
        normalizeTerrain(height);
    }

    /**
     * Smooth the terrain. For each node, its 8 neighbors heights
     * are averaged and will participate in the  node new height
     * by a factor `np` between 0 and 1
     * 
     * You must first load() the heightmap data before this will have any effect.
     * 
     * @param np
     *          The factor to what extend the neighbors average has an influence.
     *          Value of 0 will ignore neighbors (no smoothing)
     *          Value of 1 will ignore the node old height.
     */
    public function smooth( np:Float):Void
	{
        smoothWithRadius(np, 1);
    }
    
    /**
     * Smooth the terrain. For each node, its X(determined by radius) neighbors heights
     * are averaged and will participate in the  node new height
     * by a factor `np` between 0 and 1
     *
     * You must first load() the heightmap data before this will have any effect.
     * 
     * @param np
     *          The factor to what extend the neighbors average has an influence.
     *          Value of 0 will ignore neighbors (no smoothing)
     *          Value of 1 will ignore the node old height.
     */
    public function smoothWithRadius( np:Float, radius:Int):Void
	{
        if (np < 0 || np > 1)
		{
            return;
        }
        if (radius == 0)
            radius = 1;
        
        for (x in 0...size)
		{
            for (y in 0...size)
			{
                var neighNumber:Int = 0;
                var neighAverage:Float = 0;
				var rx:Int = -radius;
                while (rx <= radius) 
				{
					var ry:Int = -radius;
                    while ( ry <= radius) 
					{
                        if (x + rx < 0 || x+rx >= size)
						{
							ry++;
							continue;
                        }
                        if (y + ry < 0 || y+ry >= size)
						{
							ry++;
                            continue;
                        }
                        neighNumber++;
                        neighAverage += heightData[(x + rx) + (y + ry) * size];
						
						ry++;
                    }
					
					rx++;
                }

                neighAverage /= neighNumber;
                var cp:Float = 1 - np;
                heightData[x + y * size] = neighAverage * np + heightData[x + y * size] * cp;
            }
        }
    }
	
	public function load():Bool
	{
		return false;
	}
}
