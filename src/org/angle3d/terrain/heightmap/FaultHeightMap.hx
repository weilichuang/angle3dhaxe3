package org.angle3d.terrain.heightmap ;

import de.polygonal.core.math.random.ParkMiller;
import de.polygonal.core.math.random.Random;
import de.polygonal.core.math.random.Rng;
import flash.Vector;
import org.angle3d.math.FastMath;
import org.angle3d.utils.Logger;

/**
 * Creates an heightmap based on the fault algorithm. Each iteration, a random line
 * crossing the map is generated. On one side height values are raised, on the other side
 * lowered.
 * @author cghislai
 */
class FaultHeightMap extends AbstractHeightMap 
{
    /**
     * Values on one side are lowered, on the other side increased,
     * creating a step at the fault line
     */
    public static inline var FAULTTYPE_STEP:Int = 0;
    /**
     * Values on one side are lowered, then increase lineary while crossing
     * the fault line to the other side. The fault line will be a inclined
     * plane
     */
    public static inline var FAULTTYPE_LINEAR:Int = 1;
    /**
     * Values are lowered on one side, increased on the other, creating a
     * cosine curve on the fault line
     */
    public static inline var FAULTTYPE_COSINE:Int = 2;
    /**
     * Value are lowered on both side, but increased on the fault line
     * creating a smooth ridge on the fault line.
     */
    public static inline var FAULTTYPE_SINE:Int = 3;
    /**
     * A linear fault is created
     */
    public static inline var FAULTSHAPE_LINE:Int = 10;
    /**
     * A circular fault is created.
     */
    public static inline var FAULTSHAPE_CIRCLE:Int = 11;
	
    private var seed:Int; // A seed to feed the random
    private var iterations:Int; // iterations to perform
    private var minFaultHeight:Float; // the height modification applied
    private var maxFaultHeight:Float; // the height modification applied
    private var minRange:Float; // The range for linear and trigo faults
    private var maxRange:Float; // The range for linear and trigo faults
    private var minRadius:Float; // radii for circular fault
    private var maxRadius:Float;
    private var faultType:Int; // The type of fault
    private var faultShape:Int; // The type of fault

    /**
     * Constructor creates the fault. For faulttype other than STEP, a range can
     * be provided. For faultshape circle, min and max radii can be provided.
     * Don't forget to reload the map if you have set parameters after the constructor
     * call.
     * @param size The size of the heightmap
     * @param iterations Iterations to perform
     * @param faultType Type of fault
     * @param faultShape Shape of the fault -line or circle
     * @param minFaultHeight Height modified on each side
     * @param maxFaultHeight Height modified on each side
     * @param seed A seed to feed the Random generator
     * @see setFaultRange, setMinRadius, setMaxRadius
     */
    public function new(size:Int, iterations:Int, faultType:Int, faultShape:Int, minFaultHeight:Float, maxFaultHeight:Float, seed:Int = 1) 
	{
        if (size < 0 || iterations < 0)
		{
            throw ("Size and iterations must be greater than 0!");
        }
        this.size = size;
        this.iterations = iterations;
        this.faultType = faultType;
        this.faultShape = faultShape;
        this.minFaultHeight = minFaultHeight;
        this.maxFaultHeight = maxFaultHeight;
        this.seed = seed;
        this.minRange = minFaultHeight;
        this.maxRange = maxFaultHeight;
        this.minRadius = size / 10;
        this.maxRadius = size / 4;
        load();
    }

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
		
        var random:ParkMiller = new ParkMiller(seed);

        for (i in 0...iterations) 
		{
            addFault(tempBuffer, random);
        }

        for (i in 0...size)
		{
            for (j in 0...size)
			{
                setHeightAtPoint(tempBuffer[i][j], i, j);
            }
        }

        normalizeTerrain(AbstractHeightMap.NORMALIZE_RANGE);

        Logger.log("Fault heightmap generated");
        return true;
    }

    private function addFault(tempBuffer:Vector<Vector<Float>>, random:Rng):Void
	{
        var faultHeight:Float = minFaultHeight + random.randFloat() * (maxFaultHeight - minFaultHeight);
        var range:Float = minRange + random.randFloat() * (maxRange - minRange);
        switch (faultShape) 
		{
            case FAULTSHAPE_LINE:
                addLineFault(tempBuffer, random, faultHeight, range);
            case FAULTSHAPE_CIRCLE:
                addCircleFault(tempBuffer, random, faultHeight, range);
        }
    }

    private function addLineFault(tempBuffer:Vector<Vector<Float>>, random:Rng, faultHeight:Float, range:Float):Void
	{
        var x1:Int = Std.int(random.randFloat()*size);
        var x2:Int = Std.int(random.randFloat()*size);
        var y1:Int = Std.int(random.randFloat()*size);
        var y2:Int = Std.int(random.randFloat()*size);


        for (i in 0...size)
		{
            for (j in 0...size)
			{
                var dist:Float = ((x2 - x1) * (j - y1) - (y2 - y1) * (i - x1))
                        / (Math.sqrt(Math.sqrt(x2 - x1) + Math.sqrt(y2 - y1)));
                tempBuffer[i][j] += calcHeight(dist, random, faultHeight, range);
            }
        }
    }

    private function addCircleFault(tempBuffer:Vector<Vector<Float>>, random:Rng, faultHeight:Float, range:Float):Void
	{
        var radius:Float = random.randFloat() * (maxRadius - minRadius) + minRadius;
        var intRadius:Int = Math.floor(radius);
        // Allox circle center to be out of map if not by more than radius.
        // Unlucky cases will put them in the far corner, with the circle
        // entirely outside heightmap
        var x:Int = Std.int(random.randFloat() * (size + 2 * intRadius)) - intRadius;
        var y:Int = Std.int(random.randFloat() * (size + 2 * intRadius)) - intRadius;

        for (i in 0...size) 
		{
            for (j in 0...size)
			{
                var dist:Float;
                if (i != x || j != y)
				{
                    var dx:Int = i - x;
                    var dy:Int = j - y;
                    var dmag:Float = Math.sqrt(Math.sqrt(dx) + Math.sqrt(dy));
                    var rx:Float = x + dx / dmag * radius;
                    var ry:Float = y + dy / dmag * radius;
                    dist = FastMath.signum(dmag - radius)
                        * Math.sqrt(Math.sqrt(i - rx) + Math.sqrt(j - ry));
                } 
				else 
				{
                    dist = 0;
                }
                tempBuffer[i][j] += calcHeight(dist, random, faultHeight, range);
            }
        }
    }

    private function calcHeight(dist:Float, random:Rng, faultHeight:Float, range:Float):Float 
	{
        switch (faultType) 
		{
            case FAULTTYPE_STEP: 
			{
                return FastMath.signum(dist) * faultHeight;
            }
            case FAULTTYPE_LINEAR:
			{
                if (FastMath.abs(dist) > range) {
                    return FastMath.signum(dist) * faultHeight;
                }
                var f = FastMath.abs(dist) / range;
                return FastMath.signum(dist) * faultHeight * f;
            }
            case FAULTTYPE_SINE:
			{
                if (FastMath.abs(dist) > range) {
                    return -faultHeight;
                }
                var f = dist / range;
                // We want -1 at f=-1 and f=1; 1 at f=0
                return Math.sin((1 + 2 * f) * Math.PI / 2) * faultHeight;
            }
            case FAULTTYPE_COSINE: 
			{
                if (FastMath.abs(dist) > range) {
                    return -FastMath.signum(dist) * faultHeight;
                }
                var f = dist / range;
                var val =  Math.cos((1 + f) * Math.PI / 2) * faultHeight;
                return val;
            }
        }
        //shoudn't go here
        throw ("Code needs update to switch allcases");
    }

    public function getFaultShape():Int 
	{
        return faultShape;
    }

    public function setFaultShape( faultShape:Int):Void
	{
        this.faultShape = faultShape;
    }

    public function getFaultType():Int 
	{
        return faultType;
    }

    public function setFaultType( faultType:Int):Void
	{
        this.faultType = faultType;
    }

    public function getIterations():Int 
	{
        return iterations;
    }

    public function setIterations( iterations:Int):Void
	{
        this.iterations = iterations;
    }

    public function getMaxFaultHeight():Float 
	{
        return maxFaultHeight;
    }

    public function setMaxFaultHeight( maxFaultHeight:Float):Void
	{
        this.maxFaultHeight = maxFaultHeight;
    }

    public function getMaxRadius():Float 
	{
        return maxRadius;
    }

    public function setMaxRadius( maxRadius:Float):Void
	{
        this.maxRadius = maxRadius;
    }

    public function getMaxRange():Float 
	{
        return maxRange;
    }

    public function setMaxRange( maxRange:Float):Void 
	{
        this.maxRange = maxRange;
    }

    public function getMinFaultHeight():Float 
	{
        return minFaultHeight;
    }

    public function setMinFaultHeight( minFaultHeight:Float):Void
	{
        this.minFaultHeight = minFaultHeight;
    }

    public function getMinRadius():Float
	{
        return minRadius;
    }

    public function setMinRadius( minRadius:Float):Void 
	{
        this.minRadius = minRadius;
    }

    public function getMinRange():Float 
	{
        return minRange;
    }

    public function setMinRange( minRange:Float):Void 
	{
        this.minRange = minRange;
    }

    public function getSeed():Int
	{
        return seed;
    }

    public function setSeed( seed:Int):Void 
	{
        this.seed = seed;
    }
}
