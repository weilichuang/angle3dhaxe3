package org.angle3d.terrain.geomipmap ;

import flash.Vector;
import haxe.ds.ObjectMap;
import org.angle3d.bounding.BoundingBox;
import org.angle3d.material.Material;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.terrain.heightmap.HeightMap;
import org.angle3d.terrain.heightmap.HeightMapGrid;
import org.angle3d.utils.Logger;

/**
 * <p>
 * TerrainGrid itself is an actual TerrainQuad. Its four children are the visible four tiles.</p>
 * </p><p>
 * The grid is indexed by cells. Each cell has an integer XZ coordinate originating at 0,0.
 * TerrainGrid will piggyback on the TerrainLodControl so it can use the camera for its
 * updates as well. It does this in the overwritten update() method.
 * </p><p>
 * It uses an LRU (Least Recently Used) cache of 16 terrain tiles (full TerrainQuadTrees). The
 * center 4 are the ones that are visible. As the camera moves, it checks what camera cell it is in
 * and will attach the now visible tiles.
 * </p><p>
 * The 'quadIndex' variable is a 4x4 array that represents the tiles. The center
 * four (index numbers: 5, 6, 9, 10) are what is visible. Each quadIndex value is an
 * offset vector. The vector contains whole numbers and represents how many tiles in offset
 * this location is from the center of the map. So for example the index 11 [Vector3f(2, 0, 1)]
 * is located 2*terrainSize in X axis and 1*terrainSize in Z axis.
 * </p><p>
 * As the camera moves, it tests what cameraCell it is in. Each camera cell covers four quad tiles
 * and is half way inside each one.
 * </p><pre>
 * +-------+-------+
 * | 1     |     3 |    Four terrainQuads that make up the grid
 * |    *..|..*    |    with the cameraCell in the middle, covering
 * |----|--|--|----|    all four quads.
 * |    *..|..*    |
 * | 2     |     4 |
 * +-------+-------+
 * </pre><p>
 * This results in the effect of when the camera gets half way across one of the sides of a quad to
 * an empty (non-loaded) area, it will trigger the system to load in the next tiles.
 * </p><p>
 * The tile loading is done on a background thread, and once the tile is loaded, then it is
 * attached to the qrid quad tree, back on the OGL thread. It will grab the terrain quad from
 * the LRU cache if it exists. If it does not exist, it will load in the new TerrainQuad tile.
 * </p><p>
 * The loading of new tiles triggers events for any TerrainGridListeners. The events are:
 * <ul>
 *  <li>tile Attached
 *  <li>tile Detached
 *  <li>grid moved.
 * </ul>
 * <p>
 * These allow physics to update, and other operation (often needed for loading the terrain) to occur
 * at the right time.
 * </p>

 */
class TerrainGrid extends TerrainQuad
{
    public var currentCamCell:Vector3f = new Vector3f(0, 0, 0);
    public var quarterSize:Int; // half of quadSize
    public var quadSize:Int;
    public var heightMapGrid:HeightMapGrid;
    public var gridTileLoader:TerrainGridTileLoader;
    public var quadIndex:Vector<Vector3f>;
    public var listeners:Array<TerrainGridListener> = new Array<TerrainGridListener>();
    public var material:Material;
    //cache  needs to be 1 row (4 cells) larger than what we care is cached
    public var cache:ObjectMap<Vector3f, TerrainQuad> = new ObjectMap<Vector3f,TerrainQuad>();
    public var cellsLoaded:Int = 0;
    public var gridOffset:Vector<Int>;
    public var runOnce:Bool = false;

    public function isCenter(quadIndex:Int):Bool
	{
        return quadIndex == 9 || quadIndex == 5 || quadIndex == 10 || quadIndex == 6;
    }

    public function getQuadrantAt(quadIndex:Int):Int
	{
        if (quadIndex == 5)
		{
            return 1;
        }
		else if (quadIndex == 9)
		{
            return 2;
        }
		else if (quadIndex == 6) 
		{
            return 3;
        } 
		else if (quadIndex == 10) 
		{
            return 4;
        }
        return 0; // error
    }
	
	public function new(name:String, patchSize:Int, maxVisibleSize:Int,
						scale:Vector3f, terrainQuadGrid:TerrainGridTileLoader,
						offset:Vector2f = null, offsetAmount:Float = 0) 
	{
		super(name);
		
		this.name = name;
        this.patchSize = patchSize;
        this.size = maxVisibleSize;
        this.stepScale = scale == null ? new Vector3f(1, 1, 1) : scale;
        this.offset = offset;
        this.offsetAmount = offsetAmount;
        initData();
		
        this.gridTileLoader = terrainQuadGrid;
        terrainQuadGrid.setPatchSize(this.patchSize);
        terrainQuadGrid.setQuadSize(this.quadSize);
        //addControl(new UpdateControl());
        
        fixNormalEdges(new BoundingBox(new Vector3f(0, 0, 0), new Vector3f(size * 2, FastMath.INT32_MAX, size * 2)));
        addControl(new NormalRecalcControl(this));
		
	}

    private function initData():Void
	{
        var maxVisibleSize:Int = size;
        this.quarterSize = maxVisibleSize >> 2;
        this.quadSize = (maxVisibleSize + 1) >> 1;
        this.totalSize = maxVisibleSize;
        this.gridOffset = Vector.ofArray([0, 0]);

        /*
         *        -z
         *         | 
         *        1|3 
         *  -x ----+---- x
         *        2|4
         *         |
         *         z
         */
        this.quadIndex = Vector.ofArray([
            new Vector3f(-1, 0, -1), new Vector3f(0, 0, -1), new Vector3f(1, 0, -1), new Vector3f(2, 0, -1),
            new Vector3f(-1, 0, 0), new Vector3f(0, 0, 0), new Vector3f(1, 0, 0), new Vector3f(2, 0, 0),
            new Vector3f(-1, 0, 1), new Vector3f(0, 0, 1), new Vector3f(1, 0, 1), new Vector3f(2, 0, 1),
            new Vector3f( -1, 0, 2), new Vector3f(0, 0, 2), new Vector3f(1, 0, 2), new Vector3f(2, 0, 2)]);

    }

    /**
     * Get the location in cell-coordinates of the specified location.
     * Cell coordinates are integer corrdinates, usually with y=0, each 
     * representing a cell in the world.
     * For example, moving right in the +X direction:
     * (0,0,0) (1,0,0) (2,0,0), (3,0,0)
     * and then down the -Z direction:
     * (3,0,-1) (3,0,-2) (3,0,-3)
     */
    public function getCamCell(location:Vector3f):Vector3f
	{
        var tile:Vector3f = getTileCell(location);
        var offsetHalf:Vector3f = new Vector3f(-0.5, 0, -0.5);
        var shifted:Vector3f = tile.subtract(offsetHalf);
        return new Vector3f(Math.floor(shifted.x), 0, Math.floor(shifted.z));
    }

    /**
     * Centered at 0,0.
     * Get the tile index location in integer form:
     * @param location world coordinate
     */
    public function getTileCell(location:Vector3f):Vector3f 
	{
        var tileLoc:Vector3f = location.divide(this.getWorldScale().scale(this.quadSize));
        return tileLoc;
    }

    public function getGridTileLoader():TerrainGridTileLoader
	{
        return gridTileLoader;
    }
    
    /**
     * Get the terrain tile at the specified world location, in XZ coordinates.
     */
    public function getTerrainAt(worldLocation:Vector3f):Terrain
	{
        if (worldLocation == null)
            return null;
			
		worldLocation.y = 0;
        var tileCell:Vector3f = getTileCell(worldLocation);
        tileCell = new Vector3f(Math.round(tileCell.x), tileCell.y, Math.round(tileCell.z));
        return cache.get(tileCell);
    }
    
    /**
     * Get the terrain tile at the specified XZ cell coordinate (not world coordinate).
     * @param cellCoordinate integer cell coordinates
     * @return the terrain tile at that location
     */
    public function getTerrainAtCell(cellCoordinate:Vector3f):Terrain
	{
        return cache.get(cellCoordinate);
    }
    
    /**
     * Convert the world location into a cell location (integer coordinates)
     */
    public function toCellSpace(worldLocation:Vector3f):Vector3f
	{
        var tileCell:Vector3f = getTileCell(worldLocation);
        tileCell = new Vector3f(Math.round(tileCell.x), tileCell.y, Math.round(tileCell.z));
        return tileCell;
    }
    
    /**
     * Convert the cell coordinate (integer coordinates) into world coordinates.
     */
    public function toWorldSpace(cellLocation:Vector3f):Vector3f
	{
        return cellLocation.mult(getLocalScale()).scaleLocal(quadSize - 1);
    }
    
    public function removeQuad(q:TerrainQuad):Void 
	{
        if (q != null && ( (q.getQuadrant() > 0 && q.getQuadrant() < 5) || q.parent != null) )
		{
            for (l in listeners)
			{
                l.tileDetached(getTileCell(q.getWorldTranslation()), q);
            }
            q.setQuadrant(0);
            this.detachChild(q);
            cellsLoaded++; // For gridoffset calc., maybe the run() method is a better location for this.
        }
    }

    /**
     * Runs on the rendering thread
     * @param shifted quads are still attached to the parent and don't need to re-load
     */
    public function attachQuadAt(q:TerrainQuad, quadrant:Int, quadCell:Vector3f, shifted:Bool):Void
	{
        q.setQuadrant(quadrant);
        if (!shifted)
            this.attachChild(q);

        var loc:Vector3f = quadCell.scale(this.quadSize - 1).subtract(new Vector3f(quarterSize, 0, quarterSize));// quadrant location handled TerrainQuad automatically now
        q.setLocalTranslation(loc);

        if (!shifted)
		{
            for (l in listeners) 
			{
                l.tileAttached(quadCell, q);
            }
        }
        updateModelBound();
        
    }

    
    /**
     * Called when the camera has moved into a new cell. We need to
     * update what quads are in the scene now.
     * 
     * Step 1: touch cache
     * LRU cache is used, so elements that need to remain
     * should be touched.
     *
     * Step 2: load new quads in background thread
     * if the camera has moved into a new cell, we load in new quads
     * @param camCell the cell the camera is in
     */
    public function updateChildren(camCell:Vector3f):Void
	{

        var dx:Int = 0;
        var dy:Int = 0;
        if (currentCamCell != null) {
            dx = Std.int(camCell.x - currentCamCell.x);
            dy = Std.int(camCell.z - currentCamCell.z);
        }

        var xMin:Int = 0;
        var xMax:Int = 4;
        var yMin:Int = 0;
        var yMax:Int = 4;
        if (dx == -1) { // camera moved to -X direction
            xMax = 3;
        } else if (dx == 1) { // camera moved to +X direction
            xMin = 1;
        }

        if (dy == -1) { // camera moved to -Y direction
            yMax = 3;
        } else if (dy == 1) { // camera moved to +Y direction
            yMin = 1;
        }

        // Touch the items in the cache that we are and will be interested in.
        // We activate cells in the direction we are moving. If we didn't move 
        // either way in one of the axes (say X or Y axis) then they are all touched.
        for (i in yMin...yMax)
		{
            for (j in xMin...xMax)
			{
                cache.get(camCell.add(quadIndex[i * 4 + j]));
            }
        }
        
        // ---------------------------------------------------
        // ---------------------------------------------------

        //if (cacheExecutor == null) {
            //// use the same executor as the LODControl
            //cacheExecutor = createExecutorService();
        //}

        //cacheExecutor.submit(new UpdateQuadCache(camCell));

        this.currentCamCell = camCell;
    }

    public function addListener(listener:TerrainGridListener):Void
	{
        this.listeners.push(listener);
    }

    public function getCurrentCell():Vector3f
	{
        return this.currentCamCell;
    }

    public function removeListener(listener:TerrainGridListener):Void
	{
        this.listeners.remove(listener);
    }

	override public function setMaterial(material:Material):Void 
	{
		this.material = material;
        super.setMaterial(material);
	}

    public function setQuadSize(quadSize:Int):Void
	{
        this.quadSize = quadSize;
    }
	
	override public function adjustHeights(xz:Array<Vector2f>, height:Vector<Float>):Void 
	{
		var currentGridLocation:Vector3f = getCurrentCell().mult(getLocalScale()).scaleLocal(quadSize - 1);
        for (vect in xz) 
		{
            vect.x -= currentGridLocation.x;
            vect.y -= currentGridLocation.z;
        }
        super.adjustHeights(xz, height);
	}
    
    override function getHeightmapHeightXZ(x:Int, z:Int):Float 
	{
		return super.getHeightmapHeightXZ(x - gridOffset[0], z - gridOffset[1]);
	}
	
	override public function getNumMajorSubdivisions():Int 
	{
		return 2;
	}
	
	override public function getMaterialAt(worldLocation:Vector3f):Material 
	{
		if (worldLocation == null)
            return null;
        var tileCell:Vector3f = getTileCell(worldLocation);
        var terrain:Terrain = cache.get(tileCell);
        if (terrain == null)
            return null; // terrain not loaded for that cell yet!
        return terrain.getMaterialAt(worldLocation);
	}

    /**
     * This will print out any exceptions from the thread
     */
    //private ExecutorService createExecutorService() {
        //final ThreadFactory threadFactory = new ThreadFactory() {
            //public Thread newThread(Runnable r) {
                //Thread th = new Thread(r);
                //th.setName("Angle3D TerrainGrid Thread");
                //th.setDaemon(true);
                //return th;
            //}
        //};
        //ThreadPoolExecutor ex = new ThreadPoolExecutor(1, 1,
                                    //0L, TimeUnit.MILLISECONDS,
                                    //new LinkedBlockingQueue<Runnable>(), 
                                    //threadFactory) {
            //private void afterExecute(Runnable r, Throwable t) {
                //super.afterExecute(r, t);
                //if (t == null && r instanceof Future<?>) {
                    //try {
                        //Future<?> future = (Future<?>) r;
                        //if (future.isDone())
                            //future.get();
                    //} catch (CancellationException ce) {
                        //t = ce;
                    //} catch (ExecutionException ee) {
                        //t = ee.getCause();
                    //} catch (InterruptedException ie) {
                        //Thread.currentThread().interrupt(); // ignore/reset
                    //}
                //}
                //if (t != null)
                    //t.printStackTrace();
            //}
        //};
        //return ex;
    //}
	
}

class UpdateQuadCache
{
	private var terrain:TerrainGrid;
	private var location:Vector3f;

	public function new(terrain:TerrainGrid,location:Vector3f)
	{
		this.terrain = terrain;
		this.location = location;
	}

	/**
	 * This is executed if the camera has moved into a new CameraCell and will load in
	 * the new TerrainQuad tiles to be children of this TerrainGrid parent.
	 * It will first check the LRU cache to see if the terrain tile is already there,
	 * if it is not there, it will load it in and then cache that tile.
	 * The terrain tiles get added to the quad tree back on the OGL thread using the
	 * attachQuadAt() method. It also resets any cached values in TerrainQuad (such as
	 * neighbours).
	 */
	public function run() 
	{
		for (i in 0...4)
		{
			for (j in 0...4)
			{
				var quadIdx:Int = i * 4 + j;
				var quadCell:Vector3f = location.add(terrain.quadIndex[quadIdx]);
				var q:TerrainQuad = terrain.cache.get(quadCell);
				if (q == null)
				{
					if (terrain.heightMapGrid != null)
					{
						// create the new Quad since it doesn't exist
						var heightMapAt:HeightMap = terrain.heightMapGrid.getHeightMapAt(quadCell);
						q = new TerrainQuad(terrain.name + "Quad" + quadCell);
						q.init2(terrain.patchSize, terrain.quadSize, new Vector3f(1, 1, 1), heightMapAt == null ? null : heightMapAt.getHeightMap());
						q.setMaterial(terrain.material.clone());
						Logger.log('Loaded TerrainQuad ${q.name} from HeightMapGrid');
					} 
					else if (terrain.gridTileLoader != null)
					{
						q = terrain.gridTileLoader.getTerrainQuadAt(quadCell);
						// only clone the material to the quad if it doesn't have a material of its own
						if (q.getMaterial() == null) 
							q.setMaterial(terrain.material.clone());
						Logger.log('Loaded TerrainQuad ${q.name} from TerrainQuadGrid');
					}
				}
				terrain.cache.set(quadCell, q);

				
				var quadrant:Int = terrain.getQuadrantAt(quadIdx);
				var newQuad:TerrainQuad = q;
				
				if (terrain.isCenter(quadIdx)) 
				{
					// if it should be attached as a child right now, attach it
					//getControl(UpdateControl).enqueue(new Callable() {
						//// back on the OpenGL thread:
						//public Object call() throws Exception {
							//if (newQuad.parent != null) {
								//attachQuadAt(newQuad, quadrant, quadCell, true);
							//}
							//else {
								//attachQuadAt(newQuad, quadrant, quadCell, false);
							//}
							//return null;
						//}
					//});
				}
				else 
				{
					//getControl(UpdateControl.class).enqueue(new Callable() {
						//public Object call() throws Exception {
							//removeQuad(newQuad);
							//return null;
						//}
					//});
				}
			}
		}

		//getControl(UpdateControl.class).enqueue(new Callable() {
				//// back on the OpenGL thread:
				//public Object call() throws Exception {
					//for (Spatial s : getChildren()) {
						//if (s instanceof TerrainQuad) {
							//TerrainQuad tq = (TerrainQuad)s;
							//tq.resetCachedNeighbours();
						//}
					//}
					//System.out.println("fixed normals "+location.clone().mult(size));
					//setNeedToRecalculateNormals();
					//return null;
				//}
		//});
	}
}