package org.angle3d.terrain.heightmap ;

import de.polygonal.core.math.random.ParkMiller;
import de.polygonal.core.math.random.Rng;
import flash.Vector;
import org.angle3d.utils.Logger;

/**
 * <code>FluidSimHeightMap</code> generates a height map based using some
 * sort of fluid simulation. The heightmap is treated as a highly viscous and
 * rubbery fluid enabling to fine tune the generated heightmap using a number
 * of parameters.
 *
 * @author Frederik Boelthoff
 * @see <a href="http://www.gamedev.net/reference/articles/article2001.asp">Terrain Generation Using Fluid Simulation</a>
 * @version $Id$
 *
 */
class FluidSimHeightMap extends AbstractHeightMap 
{
    private var waveSpeed:Float = 100.0;  // speed at which the waves travel
    private var timeStep:Float = 0.033;  // constant time-step between each iteration
    private var nodeDistance:Float = 10.0;   // distance between each node of the surface
    private var viscosity:Float = 100.0; // viscosity of the fluid
    private var iterations:Int;    // number of iterations
    private var minInitialHeight:Float = -500; // min initial height
    private var maxInitialHeight:Float = 500; // max initial height
    private var seed:Int; // the seed for the random number generator
    public var coefA:Float;
	public var coefB:Float;
	public var coefC:Float; // pre-computed coefficients in the fluid equation

    /**
     * Constructor sets the attributes of the hill system and generates the
     * height map. It gets passed a number of tweakable parameters which
     * fine-tune the outcome.
     *
     * @param size
     *            size the size of the terrain to be generated
     * @param iterations
     *            the number of iterations to do
     * @param minInitialHeight
     *                        the minimum initial height of a terrain value
     * @param maxInitialHeight
     *                        the maximum initial height of a terrain value
     * @param viscosity
     *                        the viscosity of the fluid
     * @param waveSpeed
     *                        the speed at which the waves travel
     * @param timestep
     *                        the constant time-step between each iteration
     * @param nodeDistance
     *                        the distance between each node of the heightmap
     * @param seed
     *            the seed to generate the same heightmap again
     * @throws JmeException
     *             if size of the terrain is not greater that zero, or number of
     *             iterations is not greater that zero, or the minimum initial height
     *             is greater than the maximum (or the other way around)
     */
    public function new(size:Int, iterations:Int, minInitialHeight:Float = -500, maxInitialHeight:Float = 500, viscosity:Float = 100, waveSpeed:Float = 100, timestep:Float = 0.033, nodeDistance:Float = 10, seed:Int = 1)
	{
        if (size <= 0 || iterations <= 0 || minInitialHeight >= maxInitialHeight)
		{
            throw "Either size of the terrain is not greater that zero, "
                    + "or number of iterations is not greater that zero, "
                    + "or minimum height greater or equal as the maximum, "
                    + "or maximum height smaller or equal as the minimum.";
        }

        this.size = size;
        this.seed = seed;
        this.iterations = iterations;
        this.minInitialHeight = minInitialHeight;
        this.maxInitialHeight = maxInitialHeight;
        this.viscosity = viscosity;
        this.waveSpeed = waveSpeed;
        this.timeStep = timestep;
        this.nodeDistance = nodeDistance;

        load();
    }


    /*
     * Generates a heightmap using fluid simulation and the attributes set by
     * the constructor or the setters.
     */
    override public function load():Bool 
	{
        // Clean up data if needed.
        if (null != heightData) 
		{
            unloadHeightMap();
        }

        heightData = new Vector<Float>(size * size);
		
		var tempBuffer:Vector<Vector<Float>> = new Vector<Vector<Float>>(2);
		tempBuffer[0] = new Vector<Float>(size * size);
		tempBuffer[1] = new Vector<Float>(size * size);
		
        var random:Rng = new ParkMiller(seed);

        // pre-compute the coefficients in the fluid equation
        coefA = (4 - (8 * waveSpeed * waveSpeed * timeStep * timeStep) / (nodeDistance * nodeDistance)) / (viscosity * timeStep + 2);
        coefB = (viscosity * timeStep - 2) / (viscosity * timeStep + 2);
        coefC = ((2 * waveSpeed * waveSpeed * timeStep * timeStep) / (nodeDistance * nodeDistance)) / (viscosity * timeStep + 2);

        // initialize the heightmaps to random values except for the edges
        for (i in 0...size)
		{
            for (j in 0...size)
			{
                tempBuffer[0][j + i * size] = tempBuffer[1][j + i * size] = randomRange(random, minInitialHeight, maxInitialHeight);
            }
        }

        var curBuf:Int = 0;
        var ind:Int;

        var oldBuffer:Vector<Float>;
        var newBuffer:Vector<Float>;

        // Iterate over the heightmap, applying the fluid simulation equation.
        // Although it requires knowledge of the two previous timesteps, it only
        // accesses one pixel of the k-1 timestep, so using a simple trick we only
        // need to store the heightmap twice, not three times, and we can avoid
        // copying data every iteration.
        for (i in 0...iterations)
		{
            oldBuffer = tempBuffer[1 - curBuf];
            newBuffer = tempBuffer[curBuf];

            for (y in 0...size)
			{
                for (x in 0...size)
				{
                    ind = x + y * size;
					var neighborsValue:Float = 0;
					var neighbors:Int = 0;

                    if (x > 0)
					{
                        neighborsValue += newBuffer[ind - 1];
                        neighbors++;
                    }
                    if (x < size - 1) 
					{
                        neighborsValue += newBuffer[ind + 1];
                        neighbors++;
                    }
                    if (y > 0)
					{
                        neighborsValue += newBuffer[ind - size];
                        neighbors++;
                    }
                    if (y < size - 1) 
					{
                        neighborsValue += newBuffer[ind + size];
                        neighbors++;
                    }
                    if (neighbors != 4) 
					{
                        neighborsValue *= 4 / neighbors;
                    }
                    oldBuffer[ind] = coefA * newBuffer[ind] + coefB
                            * oldBuffer[ind] + coefC * (neighborsValue);
                }
            }

            curBuf = 1 - curBuf;
        }

        // put the normalized heightmap into the range [0...255] and into the heightmap
        for (y in 0...size)
		{
			for (x in 0...size)
			{
                heightData[x + y * size] = (tempBuffer[curBuf][x + y * size]);
            }
        }
        normalizeTerrain(AbstractHeightMap.NORMALIZE_RANGE);

        Logger.log("Created Heightmap using fluid simulation");

        return true;
    }

    private function randomRange(random:Rng, min:Float, max:Float):Float
	{
        return (random.randFloat() * (max - min)) + min;
    }

    /**
     * Sets the number of times the fluid simulation should be iterated over
     * the heightmap. The more often this is, the less features (hills, etc)
     * the terrain will have, and the smoother it will be.
     *
     * @param iterations
     *            the number of iterations to do
     * @throws JmeException
     *             if iterations if not greater than zero
     */
    public function setIterations(iterations:Int):Void
	{
        if (iterations <= 0)
		{
            throw "Number of iterations is not greater than zero";
        }
        this.iterations = iterations;
    }

    /**
     * Sets the maximum initial height of the terrain.
     *
     * @param maxInitialHeight
     *                        the maximum initial height
     * @see #setMinInitialHeight(int)
     */
    public function setMaxInitialHeight(maxInitialHeight:Float):Void
	{
        this.maxInitialHeight = maxInitialHeight;
    }

    /**
     * Sets the minimum initial height of the terrain.
     *
     * @param minInitialHeight
     *                        the minimum initial height
     * @see #setMaxInitialHeight(int)
     */
    public function setMinInitialHeight(minInitialHeight:Float):Void 
	{
        this.minInitialHeight = minInitialHeight;
    }

    /**
     * Sets the distance between each node of the heightmap.
     *
     * @param nodeDistance
     *                       the distance between each node
     */
    public function setNodeDistance(nodeDistance:Float):Void 
	{
        this.nodeDistance = nodeDistance;
    }

    /**
     * Sets the time-speed between each iteration of the fluid
     * simulation algortithm.
     *
     * @param timeStep
     *                       the time-step between each iteration
     */
    public function setTimeStep(timeStep:Float):Void 
	{
        this.timeStep = timeStep;
    }

    /**
     * Sets the viscosity of the simulated fuid.
     *
     * @param viscosity
     *                      the viscosity of the fluid
     */
    public function setViscosity(viscosity:Float):Void
	{
        this.viscosity = viscosity;
    }

    /**
     * Sets the speed at which the waves trave.
     *
     * @param waveSpeed
     *                      the speed at which the waves travel
     */
    public function setWaveSpeed(waveSpeed:Float):Void
	{
        this.waveSpeed = waveSpeed;
    }
}
