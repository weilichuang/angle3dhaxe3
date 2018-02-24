package angle3d.terrain.heightmap ;

import angle3d.math.random.ParkMiller;
import angle3d.math.random.Rng;

import angle3d.math.FastMath;
import angle3d.utils.Logger;

/**
 * `MidpointDisplacementHeightMap` generates an heightmap based on
 * the midpoint displacement algorithm. 
 */
class MidpointDisplacementHeightMap extends AbstractHeightMap 
{
    private var range:Float; // The offset in which randomness will be added
    private var persistence:Float; // How the random offset evolves with increasing passes
    private var seed:Int; // seed for random number generator

    /**
     * The constructor generates the heightmap. After the first 4 corners are
     * randomly given an height, the center will be heighted to the average of
     * the 4 corners to which a random value is added. Then other passes fill
     * the heightmap by the same principle.
     * The random value is generated between the values `-range`
     * and `range`. The `range` parameter is multiplied by
     * the `persistence` parameter each pass to smoothen close cell heights.
     * Extends this class and override the getOffset function for more control of
     * the randomness (you can use the coordinates and/or the computed average height
     * to influence the random amount added.
     *
     * @param size
     *          The size of the heightmap, must be 2^N+1
     * @param range
     *          The range in which randomness will be added. A value of 1 will
     *          allow -1 to 1 value changes.
     * @param persistence
     *          The factor by which the range will evolve at each iteration.
     *          A value of 0.5f will halve the range at each iteration and is
     *          typically a good choice
     * @param seed
     *          A seed to feed the random number generator.
     * @throw Angle3Dxception if size is not a power of two plus one.
     */
    public function new(size:Int, range:Float, persistence:Float, seed:Int)
	{
        if (size < 0 || !FastMath.isPowerOfTwo(size - 1)) 
		{
            throw ("The size is negative or not of the form 2^N +1"
                    + " (a power of two plus one)");
        }
        this.size = size;
        this.range = range;
        this.persistence = persistence;
        this.seed = seed;
        load();
    }

    /**
     * Generate the heightmap.
     * @return
     */
	override public function load():Bool
	{
        // clean up data if needed.
        if (null != heightData)
		{
            unloadHeightMap();
        }
		
		heightData = new Array<Float>(size * size);
		
		var tempBuffer:Array<Array<Float>> = new Array<Array<Float>>(size);
		for (i in 0...size)
		{
			tempBuffer[i] = new Array<Float>(size);
		}
		
        var random:Rng = new ParkMiller(seed);
		
        tempBuffer[0][0] = random.randFloat();
        tempBuffer[0][size - 1] = random.randFloat();
        tempBuffer[size - 1][0] = random.randFloat();
        tempBuffer[size - 1][size - 1] = random.randFloat();

        var offsetRange:Float = range;
        var stepSize:Int = size - 1;
        while (stepSize > 1)
		{
            var nextCoords:Array<Int> = [0, 0];
            while (nextCoords != null)
			{
                nextCoords = doSquareStep(tempBuffer, nextCoords, stepSize, offsetRange, random);
            }
            nextCoords = [0, 0];
            while (nextCoords != null)
			{
                nextCoords = doDiamondStep(tempBuffer, nextCoords, stepSize, offsetRange, random);
            }
            stepSize = Std.int(stepSize / 2);
            offsetRange *= persistence;
        }

        for (i in 0...size) 
		{
            for (j in 0...size) 
			{
                setHeightAtPoint(tempBuffer[i][j], j, i);
            }
        }

        normalizeTerrain(AbstractHeightMap.NORMALIZE_RANGE);

        Logger.log("Midpoint displacement heightmap generated");
        return true;
    }

    /**
     * Will fill the value at (coords[0]+stepSize/2, coords[1]+stepSize/2) with
     * the average from the corners of the square with topleft corner at (coords[0],coords[1])
     * and width of stepSize.
     * @param tempBuffer the temprary heightmap
     * @param coords an int array of lenght 2 with the x coord in position 0
     * @param stepSize the size of the square
     * @param offsetRange the offset range within a random value is picked and added to the average
     * @param random the random generator
     * @return
     */
    private function doSquareStep(tempBuffer:Array<Array<Float>>, coords:Array<Int>, stepSize:Int, offsetRange:Float, random:Rng):Array<Int>
	{
        var cornerAverage:Float = 0;
        var x:Int = coords[0];
        var y:Int = coords[1];
        cornerAverage += tempBuffer[x][y];
        cornerAverage += tempBuffer[x + stepSize][y];
        cornerAverage += tempBuffer[x + stepSize][y + stepSize];
        cornerAverage += tempBuffer[x][y + stepSize];
        cornerAverage /= 4;
        var offset:Float = getOffset(random, offsetRange, coords, cornerAverage);
        tempBuffer[x + Std.int(stepSize / 2)][y + Std.int(stepSize / 2)] = cornerAverage + offset;

        // Only get to next square if the center is still in map
        if (x + stepSize * 3 / 2 < size)
		{
            return [x + stepSize, y];
        }
        if (y + stepSize * 3 / 2 < size)
		{
            return [0, y + stepSize];
        }
        return null;
    }

    /**
     * Will fill the cell at (x+stepSize/2, y) with the average of the 4 corners
     * of the diamond centered on that point with width and height of stepSize.
     * @param tempBuffer
     * @param coords
     * @param stepSize
     * @param offsetRange
     * @param random
     * @return
     */
    private function doDiamondStep(tempBuffer:Array<Array<Float>>, coords:Array<Int>, stepSize:Int, offsetRange:Float, random:Rng):Array<Int>
	{
        var cornerNbr:Int = 0;
        var cornerAverage:Float = 0;
        var x:Int = coords[0];
        var y:Int = coords[1];
        var dxs:Array<Int> = [0, Std.int(stepSize / 2), stepSize, Std.int(stepSize / 2)];
        var dys:Array<Int> = [0, Std.int(-stepSize / 2), 0, Std.int(stepSize / 2)];

        for (d in 0...4) 
		{
            var i:Int = x + dxs[d];
            if (i < 0 || i > size - 1) 
			{
                continue;
            }
            var j:Int = y + dys[d];
            if (j < 0 || j > size - 1) 
			{
                continue;
            }
            cornerAverage += tempBuffer[i][j];
            cornerNbr++;
        }
        cornerAverage /= cornerNbr;
        var offset:Float = getOffset(random, offsetRange, coords, cornerAverage);
        tempBuffer[x + Std.int(stepSize / 2)][y] = cornerAverage + offset;

        if (x + stepSize * 3 / 2 < size)
		{
            return [x + stepSize, y];
        }
        if (y + stepSize / 2 < size) 
		{
            if (x + stepSize == size - 1)
			{
                return [Std.int(-stepSize / 2), y + Std.int(stepSize / 2)];
            } else {
                return [0, y + Std.int(stepSize / 2)];
            }
        }
        return null;
    }

    /**
     * Generate a random value to add  to the computed average
     * @param random the random generator
     * @param offsetRange
     * @param coords
     * @param average
     * @return A semi-random value within offsetRange
     */
    private function getOffset(random:Rng, offsetRange:Float, coords:Array<Int>, average:Float):Float
	{
        return 2 * (random.randFloat() - 0.5) * offsetRange;
    }

    public function getPersistence():Float
	{
        return persistence;
    }

    public function setPersistence( persistence:Float):Void
	{
        this.persistence = persistence;
    }

    public function getRange():Float 
	{
        return range;
    }

    public function setRange( range:Float):Void 
	{
        this.range = range;
    }

    public function getSeed():Int 
	{
        return seed;
    }

    public function setSeed(seed:Int):Void 
	{
        this.seed = seed;
    }
}
