package org.angle3d.terrain ;
import de.polygonal.core.util.Assert;
import flash.Vector;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;

/**
 * Constructs heightfields to be used in Terrain.
 */
class GeoMap
{
	private var hdata:Vector<Float>;
	private var width:Int;
	private var height:Int;
	private var maxval:Int;

	public function new(heightData:Vector<Float>, width:Int, height:Int, maxval:Int = 1)
	{
		this.hdata = heightData;
		this.width = width;
		this.height = height;
		this.maxval = maxval;
	}
	
	public function getHeightArray():Vector<Float>
	{
		return hdata;
	}
	
	/**
     * @return The maximum possible value that <code>getValue()</code> can 
     * return. Mostly depends on the source data format (byte, short, int, etc).
     */
    public inline function getMaximumValue():Int
	{
        return maxval;
    }

    /**
     * Returns the height value for a given point.
     *
     * MUST return the same value as getHeight(y*getWidth()+x)
     *
     * @param x the X coordinate
     * @param y the Y coordinate
     * @return an arbitrary height looked up from the heightmap
     *
     * @throws NullPointerException If isLoaded() is false
     */
    public inline function getValue(x:Int, y:Int):Float
	{
        return hdata[y * width + x];
    }

    /**
     * Returns the height value at the given index.
     *
     * zero index is top left of map,
     * getWidth()*getHeight() index is lower right
     *
     * @param i The index
     * @return an arbitrary height looked up from the heightmap
     *
     * @throws NullPointerException If isLoaded() is false
     */
    //public inline function getValue(i:Int):Float
	//{
        //return hdata[i];
    //}


    /**
     * Returns the width of this Geomap
     *
     * @return the width of this Geomap
     */
    public inline function getWidth():Int
	{
        return width;
    }

    /**
     * Returns the height of this Geomap
     *
     * @return the height of this Geomap
     */
    public inline function getHeight():Int
	{
        return height;
    }

    /**
     * Returns true if the Geomap data is loaded in memory
     * If false, then the data is unavailable- must be loaded with load()
     * before the methods getHeight/getNormal can be used
     *
     * @return wether the geomap data is loaded in system memory
     */
    public function isLoaded():Bool
	{
        return true;
    }

    /**
     * Creates a normal array from the normal data in this Geomap
     *
     * @param store A preallocated FloatBuffer where to store the data (optional), size must be &gt;= getWidth()*getHeight()*3
     * @return store, or a new FloatBuffer if store is null
     *
     * @throws NullPointerException If isLoaded() or hasNormalmap() is false
     */
    public function writeNormalArray(store:Vector<Float>, scale:Vector3f):Vector<Float>
	{
		if (store == null)
			store = new Vector<Float>();
			
        var oppositePoint:Vector3f = new Vector3f();
        var adjacentPoint:Vector3f = new Vector3f();
        var rootPoint:Vector3f = new Vector3f();
        var tempNorm:Vector3f = new Vector3f();
        var normalIndex:Int = 0;

        for (y in 0...getHeight()) 
		{
            for (x in 0...getWidth())
			{
                rootPoint.setTo(x, getValue(x,y), y);
                if (y == getHeight() - 1) 
				{
					// case #4 : last row, last col
                    if (x == getWidth() - 1) 
					{  
                        // left cross up
//                            adj = normalIndex - getWidth();
//                            opp = normalIndex - 1;
                        adjacentPoint.setTo(x, getValue(x,y-1), y-1);
                        oppositePoint.setTo(x-1, getValue(x-1, y), y);
                    } 
					else // case #3 : last row, except for last col
					{                    
                        // right cross up
//                            adj = normalIndex + 1;
//                            opp = normalIndex - getWidth();
                        adjacentPoint.setTo(x+1, getValue(x+1,y), y);
                        oppositePoint.setTo(x, getValue(x,y-1), y-1);
                    }
                } 
				else
				{
					// case #2 : last column except for last row
                    if (x == getWidth() - 1)
					{  
                        // left cross down
                        adjacentPoint.setTo(x-1, getValue(x-1,y), y);
                        oppositePoint.setTo(x, getValue(x,y+1), y+1);
//                            adj = normalIndex - 1;
//                            opp = normalIndex + getWidth();
                    } 
					else // case #1 : most cases
					{                    
                        // right cross down
                        adjacentPoint.setTo(x, getValue(x,y+1), y+1);
                        oppositePoint.setTo(x+1, getValue(x+1,y), y);
//                            adj = normalIndex + getWidth();
//                            opp = normalIndex + 1;
                    }
                }



                tempNorm.copyFrom(adjacentPoint).subtractLocal(rootPoint)
                        .crossLocal(oppositePoint.subtractLocal(rootPoint));
                tempNorm.multLocal(scale).normalizeLocal();

				store[normalIndex * 3] = tempNorm.x;
				store[(normalIndex * 3) + 1] = tempNorm.y;
				store[(normalIndex * 3) + 2] = tempNorm.z;
						
                normalIndex++;
            }
        }

        return store;
    }
    
    /**
     * Creates a vertex array from the height data in this Geomap
     *
     * The scale argument specifies the scale to use for the vertex buffer.
     * For example, if scale is 10,1,10, then the greatest X value is getWidth()*10
     *
     * @param store A preallocated FloatBuffer where to store the data (optional), 
     * size must be &gt;= getWidth()*getHeight()*3
     * @param scale Created vertexes are scaled by this vector
     *
     * @return store, or a new FloatBuffer if store is null
     *
     * @throws NullPointerException If isLoaded() is false
     */
    public function writeVertexArray(store:Vector<Float>, scale:Vector3f, center:Bool):Vector<Float>
	{
        Assert.assert(hdata.length == height * width);
		
		if (store == null)
			store = new Vector<Float>();

        var offset:Vector3f = new Vector3f(-getWidth() * scale.x * 0.5,
                                       0,
                                       -getWidth() * scale.z * 0.5);
        if (!center)
            offset.setTo(0, 0, 0);

		var index:Int = 0;
        var i:Int = 0;
        for (z in 0...height)
		{
            for (x in 0...width)
			{
                store[index++] = x * scale.x + offset.x;
                store[index++] = hdata[i++] * scale.y;
                store[index++] = z * scale.z + offset.z;
            }
        }

        return store;
    }
    
    public inline function getUV(x:Int, y:Int, store:Vector2f):Vector2f
	{
        store.setTo( x / getWidth(),
                   y / getHeight());
        return store;
    }

    public function writeTexCoordArray(store:Vector<Float>, offset:Vector2f = null, scale:Vector2f = null):Vector<Float>
	{
		if (store == null)
			store = new Vector<Float>();
			
        if (offset == null)
            offset = new Vector2f();
		
		var sx:Float = 1;
		var sy:Float = 1;
		if (scale != null)
		{
			sx = scale.x;
			sy = scale.y;
		}

		var index:Int = 0;
        var tcStore:Vector2f = new Vector2f();
        for (y in 0...getHeight())
		{
            for (x in 0...getWidth())
			{
                getUV(x, y, tcStore);
                store[index++] = offset.x + tcStore.x * sx;
                store[index++] = offset.y + tcStore.y * sy;
            }

        }

        return store;
    }
    
    public function writeIndexArray(store:Vector<UInt>):Vector<UInt>
	{
		if (store == null)
			store = new Vector<UInt>();
			
        var faceN:Int = (getWidth() - 1) * (getHeight() - 1) * 2;

		var index:Int = 0;
        var i:Int = 0;
        for (z in 0...(getHeight() - 1))
		{
            for (x in 0...(getWidth() - 1))
			{
				store[index++] = i;
				store[index++] = i + getWidth();
				store[index++] = i + getWidth() + 1;
				
				store[index++] = i + getWidth() + 1;
				store[index++] = i + 1;
				store[index++] = i;
				
                i++;

                // TODO: There's probably a better way to do this..
                if (x == getWidth() - 2) 
					i++;
            }
        }
        return store;
    }
    
    public function createMesh(scale:Vector3f, tcScale:Vector2f, center:Bool):Mesh
	{
        var pb:Vector<Float> = writeVertexArray(null, scale, center);
        var tb:Vector<Float> = writeTexCoordArray(null, Vector2f.ZERO, tcScale);
        var nb:Vector<Float> = writeNormalArray(null, scale);
        var ib:Vector<UInt> = writeIndexArray(null);
        var m:Mesh = new Mesh();
        m.setVertexBuffer(BufferType.POSITION, 3, pb);
        m.setVertexBuffer(BufferType.NORMAL, 3, nb);
        m.setVertexBuffer(BufferType.TEXCOORD, 2, tb);
        m.setIndices(ib);
        m.setStatic();
        m.validate();
        return m;
    }
}