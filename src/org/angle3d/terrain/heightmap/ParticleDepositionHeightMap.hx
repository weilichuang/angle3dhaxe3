package org.angle3d.terrain.heightmap ;
import flash.Vector;
import org.angle3d.utils.Logger;


/**
 * <code>ParticleDepositionHeightMap</code> creates a heightmap based on the
 * Particle Deposition algorithm based on Jason Shankel's paper from
 * "Game Programming Gems". A heightmap is created using a Molecular beam
 * epitaxy, or MBE, for depositing thin layers of atoms on a substrate.
 * We drop a sequence of particles and simulate their flow across a surface
 * of previously dropped particles. This creates a few high peaks, for further
 * realism we can define a caldera. Similar to the way volcano's form
 * islands, rock is deposited via lava, when the lava cools, it recedes
 * into the volcano, creating the caldera.
 *
 * @author Mark Powell
 * @version $Id$
 */
class ParticleDepositionHeightMap extends AbstractHeightMap 
{
    //Attributes.
    private var jumps:Int;
    private var peakWalk:Int;
    private var minParticles:Int;
    private var maxParticles:Int;
    private var caldera:Float;

    /**
     * Constructor sets the attributes of the Particle Deposition
     * Height Map and then generates the map.
     *
     * @param size the size of the terrain where the area is size x size.
     * @param jumps number of areas to drop particles. Can also think
     *              of it as the number of peaks.
     * @param peakWalk determines how much to agitate the drop point
     *              during a creation of a single peak. The lower the number
     *              the more the drop point will be agitated. 1 will insure
     *              agitation every round.
     * @param minParticles defines the minimum number of particles to
     *              drop during a single jump.
     * @param maxParticles defines the maximum number of particles to
     *              drop during a single jump.
     * @param caldera defines the altitude to invert a peak. This is
     *              represented as a percentage, where 0.0 will not invert
     *              anything, and 1.0 will invert all.
     *
     * @throws JmeException if any value is less than zero, and
     *              if caldera is not between 0 and 1. If minParticles is greater than
     *              max particles as well.
     */
    public function new(
            size:Int,
            jumps:Int,
            peakWalk:Int,
            minParticles:Int,
            maxParticles:Int,
            caldera:Float)
	{


        if (size <= 0
                || jumps < 0
                || peakWalk < 0
                || minParticles > maxParticles
                || minParticles < 0
                || maxParticles < 0)
		{
            throw ( "values must be greater than zero, "
                    + "and minParticles must be greater than maxParticles");
        }
		
        if (caldera < 0.0 || caldera > 1.0) 
		{
            throw (
                    "Caldera level must be " + "between 0 and 1");
        }


        this.size = size;
        this.jumps = jumps;
        this.peakWalk = peakWalk;
        this.minParticles = minParticles;
        this.maxParticles = maxParticles;
        this.caldera = caldera;


        load();
    }

    /**
     * <code>load</code> generates the heightfield using the Particle Deposition
     * algorithm. <code>load</code> uses the latest attributes, so a call
     * to <code>load</code> is recommended if attributes have changed using
     * the set methods.
     */
    override public function load():Bool 
	{
        var x:Int, y:Int;
        var calderaX:Int, calderaY:Int;
        var sx:Int, sy:Int;
        var tx:Int, ty:Int;
        var m:Int;
        var calderaStartPoint:Float;
        var cutoff:Float;
        var dx:Array<Int> = [0, 1, 0, size - 1, 1, 1, size - 1, size - 1];
        var dy:Array<Int> = [ 1, 0, size - 1, 0, size - 1, 1, size - 1, 1];
		

		var tempBuffer:Vector<Vector<Float>> = new Vector<Vector<Float>>(size);
		//map 0 unmarked, unvisited, 1 marked, unvisited, 2 marked visited.
		var calderaMap:Vector<Vector<Int>> = new Vector<Vector<Int>>(size);
		for (i in 0...size)
		{
			tempBuffer[i] = new Vector<Float>(size);
			calderaMap[i] = new Vector<Int>(size);
		}
		
		var done:Bool;


        var minx:Int, maxx:Int;
        var miny:Int, maxy:Int;


        if (null != heightData)
		{
            unloadHeightMap();
        }


        heightData = new Vector<Float>(size * size);


        //create peaks.
        for (i in 0...jumps) 
		{


            //pick a random point.
            x = Std.int(Std.int(Math.random() * (size - 1)));
            y = Std.int(Std.int(Math.random() * (size - 1)));


            //set the caldera point.
            calderaX = x;
            calderaY = y;


            var numberParticles:Int =
                    (Std.int(
                    (Math.random() * (maxParticles - minParticles))
                    + minParticles));
            //drop particles.
            for (j in 0...numberParticles) 
			{
                //check to see if we should aggitate the drop point.
                if (peakWalk != 0 && j % peakWalk == 0)
				{
                    m = Std.int(Std.int(Math.random() * 7));
                    x = (x + dx[m] + size) % size;
                    y = (y + dy[m] + size) % size;
                }


                //add the particle to the piont.
                tempBuffer[x][y] += 1;


                sx = x;
                sy = y;
                done = false;


                //cause the particle to "slide" down the slope and settle at
                //a low point.
                while (!done) 
				{
                    done = true;


                    //check neighbors to see if we are higher.
                    m = Std.int(Std.int((Math.random() * 8)));
                    for (jj in 0...8)
					{
                        tx = (sx + dx[(jj + m) % 8]) % (size);
                        ty = (sy + dy[(jj + m) % 8]) % (size);


                        //move to the neighbor.
                        if (tempBuffer[tx][ty] + 1.0 < tempBuffer[sx][sy])
						{
                            tempBuffer[tx][ty] += 1.0;
                            tempBuffer[sx][sy] -= 1.0;
                            sx = tx;
                            sy = ty;
                            done = false;
                            break;
                        }
                    }
                }


                //This point is higher than the current caldera point,
                //so move the caldera here.
                if (tempBuffer[sx][sy] > tempBuffer[calderaX][calderaY])
				{
                    calderaX = sx;
                    calderaY = sy;
                }
            }


            //apply the caldera.
            calderaStartPoint = tempBuffer[calderaX][calderaY];
            cutoff = calderaStartPoint * (1.0 - caldera);
            minx = calderaX;
            maxx = calderaX;
            miny = calderaY;
            maxy = calderaY;


            calderaMap[calderaX][calderaY] = 1;


            done = false;
            while (!done)
			{
                done = true;
                sx = minx;
                sy = miny;
                tx = maxx;
                ty = maxy;


                for (x in sx...(tx + 1)) 
				{
                    for (y in sy...(ty + 1))
					{

                        calderaX = (x + size) % size;
                        calderaY = (y + size) % size;


                        if (calderaMap[calderaX][calderaY] == 1) 
						{
                            calderaMap[calderaX][calderaY] = 2;


                            if (tempBuffer[calderaX][calderaY] > cutoff
                                    && tempBuffer[calderaX][calderaY]
                                    <= calderaStartPoint)
							{


                                done = false;
                                tempBuffer[calderaX][calderaY] =
                                        2 * cutoff - tempBuffer[calderaX][calderaY];


                                //check the left and right neighbors
                                calderaX = (calderaX + 1) % size;
                                if (calderaMap[calderaX][calderaY] == 0)
								{
                                    if (x + 1 > maxx)
									{
                                        maxx = x + 1;
                                    }
                                    calderaMap[calderaX][calderaY] = 1;
                                }


                                calderaX = (calderaX + size - 2) % size;
                                if (calderaMap[calderaX][calderaY] == 0)
								{
                                    if (x - 1 < minx) 
									{
                                        minx = x - 1;
                                    }
                                    calderaMap[calderaX][calderaY] = 1;
                                }


                                //check the upper and lower neighbors.
                                calderaX = (x + size) % size;
                                calderaY = (calderaY + 1) % size;
                                if (calderaMap[calderaX][calderaY] == 0)
								{
                                    if (y + 1 > maxy)
									{
                                        maxy = y + 1;
                                    }
                                    calderaMap[calderaX][calderaY] = 1;
                                }
                                calderaY = (calderaY + size - 2) % size;
                                if (calderaMap[calderaX][calderaY] == 0)
								{
                                    if (y - 1 < miny) 
									{
                                        miny = y - 1;
                                    }
                                    calderaMap[calderaX][calderaY] = 1;
                                }
                            }
                        }
                    }
                }
            }
        }

        //transfer the new terrain into the height map.
        for (i in 0...size)
		{
            for (j in 0...size)
			{
                setHeightAtPoint(tempBuffer[i][j], j, i);
            }
        }
        erodeTerrain();
        normalizeTerrain(AbstractHeightMap.NORMALIZE_RANGE);

        Logger.log("Created heightmap using Particle Deposition");


        return false;
    }

    /**
     * <code>setJumps</code> sets the number of jumps or peaks that will
     * be created during the next call to <code>load</code>.
     * @param jumps the number of jumps to use for next load.
     * @throws JmeException if jumps is less than zero.
     */
    public function setJumps(jumps:Int):Void
	{
        if (jumps < 0)
		{
            throw ("jumps must be positive");
        }
        this.jumps = jumps;
    }

    /**
     * <code>setPeakWalk</code> sets how often the jump point will be
     * aggitated. The lower the peakWalk, the more often the point will
     * be aggitated.
     *
     * @param peakWalk the amount to aggitate the jump point.
     * @throws JmeException if peakWalk is negative or zero.
     */
    public function setPeakWalk(peakWalk:Int):Void
	{
        if (peakWalk <= 0)
		{
            throw (
                    "peakWalk must be greater than " + "zero");
        }
        this.peakWalk = peakWalk;
    }

    /**
     * <code>setCaldera</code> sets the level at which a peak will be
     * inverted.
     *
     * @param caldera the level at which a peak will be inverted. This must be
     *              between 0 and 1, as it is represented as a percentage.
     * @throws JmeException if caldera is not between 0 and 1.
     */
    public function setCaldera(caldera:Float):Void
	{
        if (caldera < 0.0 || caldera > 1.0)
		{
            throw (
                    "Caldera level must be " + "between 0 and 1");
        }
        this.caldera = caldera;
    }

    /**
     * <code>setMaxParticles</code> sets the maximum number of particles
     * for a single jump.
     * @param maxParticles the maximum number of particles for a single jump.
     * @throws JmeException if maxParticles is negative or less than
     *              the current number of minParticles.
     */
    public function setMaxParticles(maxParticles:Int):Void
	{
        this.maxParticles = maxParticles;
    }

    /**
     * <code>setMinParticles</code> sets the minimum number of particles
     * for a single jump.
     * @param minParticles the minimum number of particles for a single jump.
     * @throws JmeException if minParticles are greater than
     *              the current maxParticles;
     */
    public function setMinParticles(minParticles:Int):Void 
	{
        if (minParticles > maxParticles) 
		{
            throw (
                    "minParticles must be less " + "than the current maxParticles");
        }
        this.minParticles = minParticles;
    }
}
