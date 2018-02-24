package angle3d.terrain.heightmap ;

import angle3d.utils.Logger;

/**
 * `CombinerHeightMap` generates a new height map based on
 * two provided height maps. These had maps can either be added together
 * or substracted from each other. Each heightmap has a weight to
 * determine how much one will affect the other. By default it is set to
 * 0.5, 0.5 and meaning the two heightmaps are averaged evenly. This
 * value can be adjusted at will, as long as the two factors are equal
 * to 1.0.
 *
 */
class CombinerHeightMap extends AbstractHeightMap
{
    /**
     * Constant mode to denote adding the two heightmaps.
     */
    public static inline var ADDITION:Int = 0;
    /**
     * Constant mode to denote subtracting the two heightmaps.
     */
    public static inline var SUBTRACTION:Int = 1;
	
    //the two maps.
    private var map1:AbstractHeightMap;
    private var map2:AbstractHeightMap;
    //the two factors
    private var factor1:Float = 0.5;
    private var factor2:Float = 0.5;
    //the combine mode.
    private var mode:Int;

    /**
     * Constructor combines two given heightmaps by the specified mode.
     * The heightmaps will be evenly distributed. The heightmaps
     * must be of the same size.
     *
     * @param map1 the first heightmap to combine.
     * @param map2 the second heightmap to combine.
     * @param mode denotes whether to add or subtract the heightmaps, may
     *              be either ADDITION or SUBTRACTION.
     */
    public function new(
             map1:AbstractHeightMap,
             map2:AbstractHeightMap,
             mode:Int, factor1:Float = 0.5, factor2:Float = 0.5)
	{


        //insure all parameters are valid.
        if (null == map1 || null == map2)
		{
            throw "Height map may not be null";
        }


        if (map1.getSize() != map2.getSize()) 
		{
            throw "The two maps must be of the same size";
        }


        if ((factor1 + factor2) != 1.0) 
		{
            throw "factor1 and factor2 must add to 1.0";
        }


        this.size = map1.getSize();
        this.map1 = map1;
        this.map2 = map2;
		this.factor1 = factor1;
		this.factor2 = factor2;


        setMode(mode);

        load();
    }

    /**
     * `setFactors` sets the distribution of heightmaps.
     * For example, if factor1 is 0.6 and factor2 is 0.4, then 60% of
     * map1 will be used with 40% of map2. The two factors must add up
     * to 1.0.
     * @param factor1 the factor for map1.
     * @param factor2 the factor for map2.
     * if the factors do not add to 1.0.
     */
    public function setFactors(factor1:Float, factor2:Float):Void
	{
        if ((factor1 + factor2) != 1.0)
		{
            throw "factor1 and factor2 must add to 1.0";
        }

        this.factor1 = factor1;
        this.factor2 = factor2;
    }

    /**
     * `setHeightMaps` sets the height maps to combine.
     * The size of the height maps must be the same.
     * @param map1 the first height map.
     * @param map2 the second height map.
     */
    public function setHeightMaps(map1:AbstractHeightMap, map2:AbstractHeightMap):Void
	{
        if (null == map1 || null == map2) 
		{
            throw "Height map may not be null";
        }


        if (map1.getSize() != map2.getSize())
		{
            throw "The two maps must be of the same size";
        }


        this.size = map1.getSize();
        this.map1 = map1;
        this.map2 = map2;
    }

    /**
     * `setMode` sets the mode of the combiner. This may either
     * be ADDITION or SUBTRACTION.
     * @param mode the mode of the combiner.
     */
    public function setMode(mode:Int):Void
	{
        if (mode != ADDITION && mode != SUBTRACTION)
		{
            throw "Invalid mode";
        }
        this.mode = mode;
    }

    /**
     * `load` builds a new heightmap based on the combination of
     * two other heightmaps. The conditions of the combiner determine the
     * final outcome of the heightmap.
     *
     * @return boolean if the heightmap was successfully created.
     */
    override public function load():Bool 
	{
        if (null != heightData) 
		{
            unloadHeightMap();
        }


        heightData = new Array<Float>(size * size);

        var temp1:Array<Float> = map1.getHeightMap();
        var temp2:Array<Float> = map2.getHeightMap();


        if (mode == ADDITION) 
		{
            for (i in 0...size) 
			{
                for (j in 0...size) 
				{
                    heightData[i + (j * size)] =
                            (temp1[i + (j * size)] * factor1
                            + temp2[i + (j * size)] * factor2);
                }
            }
        } 
		else if (mode == SUBTRACTION)
		{
            for (i in 0...size) 
			{
                for (j in 0...size) 
				{
                    heightData[i + (j * size)] =
                             (temp1[i + (j * size)] * factor1
                            - temp2[i + (j * size)] * factor2);
                }
            }
        }


        Logger.log("Created heightmap using Combiner");


        return true;
    }
}
