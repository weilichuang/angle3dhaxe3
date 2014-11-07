package org.angle3d.terrain.heightmap ;
import de.polygonal.core.math.Limits;
import de.polygonal.core.math.Mathematics;
import de.polygonal.core.math.random.ParkMiller;
import de.polygonal.core.math.random.RNG;
import flash.Vector;
import org.angle3d.utils.Logger;

/**
 * <code>HillHeightMap</code> generates a height map base on the Hill
 * Algorithm. Terrain is generatd by growing hills of random size and height at
 * random points in the heightmap. The terrain is then normalized and valleys
 * can be flattened.
 * 
 * @author Frederik Blthoff
 * @see <a href="http://www.robot-frog.com/3d/hills/hill.html">Hill Algorithm</a>
 */
class HillHeightMap extends AbstractHeightMap
{

    private var iterations:Int; // how many hills to generate
    private var minRadius:Float; // the minimum size of a hill radius
    private var maxRadius:Float; // the maximum size of a hill radius
    private var seed:Int; // the seed for the random number generator

    /**
     * Constructor sets the attributes of the hill system and generates the
     * height map.
     *
     * @param size
     *            size the size of the terrain to be generated
     * @param iterations
     *            the number of hills to grow
     * @param minRadius
     *            the minimum radius of a hill
     * @param maxRadius
     *            the maximum radius of a hill
     * @param seed
     *            the seed to generate the same heightmap again
     * @
     * @throws JmeException
     *             if size of the terrain is not greater that zero, or number of
     *             iterations is not greater that zero
     */
    public function new(size:Int, iterations:Int, minRadius:Float, maxRadius:Float, seed:Int)
	{
        if (size <= 0 || iterations <= 0 || minRadius <= 0 || maxRadius <= 0
                || minRadius >= maxRadius)
		{
            throw (
                    "Either size of the terrain is not greater that zero, "
                    + "or number of iterations is not greater that zero, "
                    + "or minimum or maximum radius are not greater than zero, "
                    + "or minimum radius is greater than maximum radius, "
                    + "or power of flattening is below one");
        }
        Logger.log("Contructing hill heightmap using seed: " + seed);
        this.size = size;
        this.seed = seed;
        this.iterations = iterations;
        this.minRadius = minRadius;
        this.maxRadius = maxRadius;

        load();
    }

    /*
     * Generates a heightmap using the Hill Algorithm and the attributes set by
     * the constructor or the setters.
     */
    override public function load():Bool
	{
        // clean up data if needed.
        if (null != heightData)
		{
            unloadHeightMap();
        }
        heightData = new Vector<Float>(size * size);
		
		var tempBuffer:Vector<Vector<Float>> = new Vector<Vector<Float>>(size);
		for (i in 0...size)
		{
			tempBuffer[i] = new Vector<Float>(size);
		}
		
        var random:RNG = new ParkMiller(seed);

        // Add the hills
        for (i in 0...iterations)
		{
            addHill(tempBuffer, random);
        }

        // transfer temporary buffer to final heightmap
        for (i in 0...size)
		{
            for (j in 0...size) 
			{
                setHeightAtPoint(tempBuffer[i][j], j, i);
            }
        }

        normalizeTerrain(AbstractHeightMap.NORMALIZE_RANGE);

        Logger.log("Created Heightmap using the Hill Algorithm");

        return true;
    }

    /**
     * Generates a new hill of random size and height at a random position in
     * the heightmap. This is the actual Hill algorithm. The <code>Random</code>
     * object is used to guarantee the same heightmap for the same seed and
     * attributes.
     *
     * @param tempBuffer
     *            the temporary height map buffer
     * @param random
     *            the random number generator
     */
    private function addHill(tempBuffer:Vector<Vector<Float>>, random:RNG):Void
	{
        // Pick the radius for the hill
        var radius:Float = randomRange(random, minRadius, maxRadius);

        // Pick a centerpoint for the hill
        var x:Float = randomRange(random, -radius, size + radius);
        var y:Float = randomRange(random, -radius, size + radius);

        var radiusSq:Float = radius * radius;
        var distSq:Float;
        var height:Float;

        // Find the range of hills affected by this hill
        var xMin:Int = Math.round(x - radius - 1);
        var xMax:Int = Math.round(x + radius + 1);

        var yMin:Int = Math.round(y - radius - 1);
        var yMax:Int = Math.round(y + radius + 1);

        // Don't try to affect points outside the heightmap
        if (xMin < 0)
		{
            xMin = 0;
        }
        if (xMax > size)
		{
            xMax = size - 1;
        }

        if (yMin < 0) 
		{
            yMin = 0;
        }
        if (yMax > size)
		{
            yMax = size - 1;
        }

        for (i in xMin...(xMax + 1))
		{
            for (j in yMin...(yMax + 1))
			{
                distSq = (x - i) * (x - i) + (y - j) * (y - j);
                height = radiusSq - distSq;

                if (height > 0)
				{
                    tempBuffer[i][j] += height;
                }
            }
        }
    }

    private function randomRange(random:RNG, min:Float, max:Float):Float
	{
        return (random.random() * (max - min) / Limits.INT32_MAX) + min;
    }

    /**
     * Sets the number of hills to grow. More hills usually mean a nicer
     * heightmap.
     *
     * @param iterations
     *            the number of hills to grow
     * @
     * @throws JmeException
     *             if iterations if not greater than zero
     */
    public function setIterations(iterations:Int):Void
	{
        if (iterations <= 0) {
            throw (
                    "Number of iterations is not greater than zero");
        }
        this.iterations = iterations;
    }

    /**
     * Sets the minimum radius of a hill.
     *
     * @param maxRadius
     *            the maximum radius of a hill
     * @
     * @throws JmeException
     *             if the maximum radius if not greater than zero or not greater
     *             than the minimum radius
     */
    public function setMaxRadius( maxRadius:Float):Void
	{
        if (maxRadius <= 0 || maxRadius <= minRadius) 
		{
            throw ("The maximum radius is not greater than 0, "
                    + "or not greater than the minimum radius");
        }
        this.maxRadius = maxRadius;
    }

    /**
     * Sets the maximum radius of a hill.
     *
     * @param minRadius
     *            the minimum radius of a hill
     * @
     * @throws JmeException if the minimum radius is not greater than zero or not
     *        lower than the maximum radius
     */
    public function setMinRadius(minRadius:Float):Void
	{
        if (minRadius <= 0 || minRadius >= maxRadius)
		{
            throw ("The minimum radius is not greater than 0, "
                    + "or not lower than the maximum radius");
        }
        this.minRadius = minRadius;
    }
}
