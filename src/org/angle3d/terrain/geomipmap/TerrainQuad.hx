package org.angle3d.terrain.geomipmap;
import flash.Vector;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import org.angle3d.bounding.BoundingBox;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.collision.Collidable;
import org.angle3d.collision.CollisionResults;
import org.angle3d.material.Material;
import org.angle3d.math.FastMath;
import org.angle3d.math.Ray;
import org.angle3d.scene.CullHint;
import org.angle3d.scene.debug.WireBox;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Spatial;
import org.angle3d.terrain.geomipmap.lodcalc.LodCalculator;
import org.angle3d.terrain.geomipmap.picking.BresenhamTerrainPicker;
import org.angle3d.terrain.geomipmap.picking.TerrainPickData;
import org.angle3d.terrain.geomipmap.picking.TerrainPicker;
import org.angle3d.terrain.ProgressMonitor;
import org.angle3d.math.Vector3f;
import org.angle3d.utils.Logger;
import org.angle3d.utils.TangentBinormalGenerator;

import org.angle3d.math.Vector2f;
import org.angle3d.scene.Node;

/**
 * <p>
 * TerrainQuad is a heightfield-based terrain system. Heightfield terrain is fast and can
 * render large areas, and allows for easy Level of Detail control. However it does not
 * permit caves easily.
 * TerrainQuad is a quad tree, meaning that the root quad has four children, and each of
 * those children have four children. All the way down until you reach the bottom, the actual
 * geometry, the TerrainPatches.
 * If you look at a TerrainQuad in wireframe mode with the TerrainLODControl attached, you will
 * see blocks that change their LOD level together; these are the TerrainPatches. The TerrainQuad
 * is just an organizational structure for the TerrainPatches so patches that are not in the
 * view frustum get culled quickly.
 * TerrainQuads size are a power of 2, plus 1. So 513x513, or 1025x1025 etc.
 * Each point in the terrain is one unit apart from its neighbour. So a 513x513 terrain
 * will be 513 units wide and 513 units long.
 * Patch size can be specified on the terrain. This sets how large each geometry (TerrainPatch)
 * is. It also must be a power of 2 plus 1 so the terrain can be subdivided equally.
 * </p>
 * <p>
 * The height of the terrain can be modified at runtime using setHeight()
 * </p>
 * <p>
 * A terrain quad is a node in the quad tree of the terrain system.
 * The root terrain quad will be the only one that receives the update() call every frame
 * and it will determine if there has been any LOD change.
 * </p><p>
 * The leaves of the terrain quad tree are Terrain Patches. These have the real geometry mesh.
 * </p><p>
 * Heightmap coordinates start from the bottom left of the world and work towards the
 * top right.
 * </p><pre>
 *  +x
 *  ^
 *  | ......N = length of heightmap
 *  | :     :
 *  | :     :
 *  | 0.....:
 *  +---------&gt; +z
 * (world coordinates)
 * </pre>
 * @author Brent Owens
 */
class TerrainQuad extends Node implements Terrain
{
	private var offset:Vector2f;

    private var totalSize:Int; // the size of this entire terrain tree (on one side)

    private var size:Int; // size of this quad, can be between totalSize and patchSize

    private var patchSize:Int; // size of the individual patches

    private var stepScale:Vector3f;

    private var offsetAmount:Float;

    private var quadrant:Int = 0; // 1=upper left, 2=lower left, 3=upper right, 4=lower right
    private var maxLod:Int = -1;
    private var affectedAreaBBox:BoundingBox; // only set in the root quad

    private var picker:TerrainPicker;
    private var lastScale:Vector3f = new Vector3f(1, 1, 1);

    private var neighbourFinder:NeighbourFinder;

	public function new(name:String, patchSize:Int, quadSize:Int, totalSize:Int,
						heightMap:Vector<Float>,  scale:Vector3f = null,
						offset:Vector2f = null, offsetAmount:Float = 0)
	{
		super(name);
		
		if (heightMap == null)
			heightMap = generateDefaultHeightMap(quadSize);
		
		if (!FastMath.isPowerOfTwo(quadSize-1))
		{
			throw "size given: " + quadSize + "  Terrain quad sizes may only be (2^N + 1)";
		}
		
		if (heightMap.length > quadSize * quadSize)
		{
			Logger.warn("Heightmap size is larger than the terrain size. Make sure your heightmap image is the same size as the terrain!");
		}
		
		if(offset != null)
			this.offset = offset.clone();
		else
			this.offset = new Vector2f(1, 1);
			
        this.offsetAmount = offsetAmount;
        this.totalSize = totalSize;
        this.size = quadSize;
        this.patchSize = patchSize;
		if(scale != null)
			this.stepScale = scale.clone();
		else
			this.stepScale = new Vector3f(1, 1, 1);
        split(patchSize, heightMap);
	}
	
	public function setNeighbourFinder(neighbourFinder:NeighbourFinder):Void
	{
        this.neighbourFinder = neighbourFinder;
        resetCachedNeighbours();
    }
	
	/**
     * Forces the recalculation of all normals on the terrain.
     */
    public function recalculateAllNormals():Void
	{
        affectedAreaBBox = new BoundingBox(new Vector3f(0, 0, 0), new Vector3f(totalSize * 2, Math.POSITIVE_INFINITY, totalSize * 2));
    }
	
	/**
     * Create just a flat heightmap
     */
    private function generateDefaultHeightMap(size:Int):Vector<Float>
	{
        var heightMap:Vector<Float> = new Vector<Float>(size * size, true);
        return heightMap;
    }
	
	/**
     * update the normals if there were any height changes recently.
     * Should only be called on the root quad
     */
    private function updateNormals():Void
	{

        if (needToRecalculateNormals())
		{
            //TODO background-thread this if it ends up being expensive
            fixNormals(affectedAreaBBox); // the affected patches
            fixNormalEdges(affectedAreaBBox); // the edges between the patches
            
            setNormalRecalcNeeded(null); // set to false
        }
    }
    
    /**
     * Caches the transforms (except rotation) so the LOD calculator,
     * which runs on a separate thread, can access them safely.
     */
    private function cacheTerrainTransforms():Void
	{
		var i:Int = children.length;
        while (--i >= 0)
		{
            var child:Spatial = children[i];
            if (Std.is(child,TerrainQuad))
			{
                cast(child, TerrainQuad).cacheTerrainTransforms();
            } 
			else if (Std.is(child, TerrainPatch))
			{
                cast(child,TerrainPatch).cacheTerrainTransforms();
            }
        }
    }

    private function collideWithRay(ray:Ray, results:CollisionResults):Int
	{
        if (picker == null)
            picker = new BresenhamTerrainPicker(this);

        var intersection:Vector3f = picker.getTerrainIntersection(ray, results);
        if (intersection != null)
		{
            if (ray.getLimit() < Math.POSITIVE_INFINITY) 
			{
                if (results.getClosestCollision().distance <= ray.getLimit())
                    return 1; // in range
                else
                    return 0; // out of range
            } else
                return 1;
        } else
            return 0;
    }

    /**
     * Generate the entropy values for the terrain for the "perspective" LOD
     * calculator. This routine can take a long time to run!
     * @param progressMonitor optional
     */
    public function generateEntropy(progressMonitor:ProgressMonitor):Void
	{
        // only check this on the root quad
        if (isRootQuad())
		{
            if (progressMonitor != null) 
			{
                var numCalc:Int = Std.int((totalSize-1) / (patchSize-1)); // make it an even number
                progressMonitor.setMonitorMax(numCalc*numCalc);
            }
		}

        if (children != null)
		{
            var i:Int = children.length;
			while (--i >= 0)
			{
				var child:Spatial = children[i];
				if (Std.is(child,TerrainQuad))
				{
					cast(child, TerrainQuad).generateEntropy(progressMonitor);
				} 
				else if (Std.is(child, TerrainPatch))
				{
					cast(child,TerrainPatch).generateLodEntropies();
                    if (progressMonitor != null)
                        progressMonitor.incrementProgress(1);
				}
            }
        }

        // only do this on the root quad
        if (isRootQuad())
		{
            if (progressMonitor != null)
                progressMonitor.progressComplete();
		}
    }

    private function isRootQuad():Bool 
	{
        return (getParent() != null && !(Std.is(getParent(),TerrainQuad)) );
    }

    public function getMaterial():Material 
	{
        return getMaterialAt(null);
    }
    
    public function getMaterialAt(worldLocation:Vector3f):Material 
	{
        // get the material from one of the children. They all share the same material
		if (children != null)
		{
            var i:Int = children.length;
			while (--i >= 0)
			{
				var child:Spatial = children[i];
				if (Std.is(child,TerrainQuad))
				{
					return cast(child, TerrainQuad).getMaterialAt(worldLocation);
				} 
				else if (Std.is(child, TerrainPatch))
				{
					return cast(child,TerrainPatch).getMaterial();
				}
            }
        }
		
        return null;
    }

    public function getNumMajorSubdivisions():Int 
	{
        return 1;
    }
    

    private function calculateLod(location:Array<Vector3f>, updates:StringMap<UpdatedTerrainPatch>, lodCalculator:LodCalculator):Bool 
	{
        var lodChanged:Bool = false;
		
		if (children != null)
		{
            var i:Int = children.length;
			while (--i >= 0)
			{
				var child:Spatial = children[i];
				if (Std.is(child,TerrainQuad))
				{
					var b:Bool = cast(child, TerrainQuad).calculateLod(location, updates, lodCalculator);
					if (b)
                        lodChanged = true;
				} 
				else if (Std.is(child, TerrainPatch))
				{
					var b:Bool = lodCalculator.calculateLod(cast child, location, updates);
                    if (b)
                        lodChanged = true;
				}
            }
        }

        return lodChanged;
    }

    private function findNeighboursLod(updated:StringMap<UpdatedTerrainPatch>):Void 
	{
		if (children != null)
		{
            var i:Int = children.length;
			while (--i >= 0)
			{
				var child:Spatial = children[i];
				if (Std.is(child,TerrainQuad))
				{
					cast(child, TerrainQuad).findNeighboursLod(updated);
				} 
				else if (Std.is(child, TerrainPatch))
				{
					var patch:TerrainPatch = cast child;
                    if (!patch.searchedForNeighboursAlready)
					{
                        // set the references to the neighbours
                        patch.rightNeighbour = findRightPatch(patch);
                        patch.bottomNeighbour = findDownPatch(patch);
                        patch.leftNeighbour = findLeftPatch(patch);
                        patch.topNeighbour = findTopPatch(patch);
                        patch.searchedForNeighboursAlready = true;
                    }
                    var right:TerrainPatch = patch.rightNeighbour;
                    var down:TerrainPatch = patch.bottomNeighbour;
                    var left:TerrainPatch = patch.leftNeighbour;
                    var top:TerrainPatch = patch.topNeighbour;

                    var utp:UpdatedTerrainPatch = updated.get(patch.name);
                    if (utp == null) 
					{
                        utp = new UpdatedTerrainPatch(patch, patch.lod);
                        updated.set(utp.getName(), utp);
                    }

                    if (right != null)
					{
                        var utpR:UpdatedTerrainPatch = updated.get(right.name);
                        if (utpR == null)
						{
                            utpR = new UpdatedTerrainPatch(right);
                            updated.set(utpR.getName(), utpR);
                            utpR.setNewLod(right.lod);
                        }
                        utp.setRightLod(utpR.getNewLod());
                        utpR.setLeftLod(utp.getNewLod());
                    }
                    if (down != null) 
					{
                        var utpD:UpdatedTerrainPatch = updated.get(down.name);
                        if (utpD == null)
						{
                            utpD = new UpdatedTerrainPatch(down);
                            updated.set(utpD.getName(), utpD);
                            utpD.setNewLod(down.lod);
                        }
                        utp.setBottomLod(utpD.getNewLod());
                        utpD.setTopLod(utp.getNewLod());
                    }
                    
                    if (left != null)
					{
                        var utpL:UpdatedTerrainPatch = updated.get(left.name);
                        if (utpL == null)
						{
                            utpL = new UpdatedTerrainPatch(left);
                            updated.set(utpL.getName(), utpL);
                            utpL.setNewLod(left.lod);
                        }
                        utp.setLeftLod(utpL.getNewLod());
                        utpL.setRightLod(utp.getNewLod());
                    }
                    if (top != null)
					{
                        var utpT:UpdatedTerrainPatch = updated.get(top.name);
                        if (utpT == null)
						{
                            utpT = new UpdatedTerrainPatch(top);
                            updated.set(utpT.getName(), utpT);
                            utpT.setNewLod(top.lod);
                        }
                        utp.setTopLod(utpT.getNewLod());
                        utpT.setBottomLod(utp.getNewLod());
                    }
				}
            }
        }
    }

    /**
     * Reset the cached references of neighbours.
     * TerrainQuad caches neighbours for faster LOD checks.
     * Sometimes you might want to reset this cache (for instance in TerrainGrid)
     */
    public function resetCachedNeighbours():Void 
	{
		if (children != null)
		{
            var i:Int = children.length;
			while (--i >= 0)
			{
				var child:Spatial = children[i];
				if (Std.is(child,TerrainQuad))
				{
					cast(child, TerrainQuad).resetCachedNeighbours();
				} 
				else if (Std.is(child, TerrainPatch))
				{
                    cast(child, TerrainPatch).searchedForNeighboursAlready = false;
				}
            }
        }
    }
    
    /**
     * Find any neighbours that should have their edges seamed because another neighbour
     * changed its LOD to a greater value (less detailed)
     */
    private function fixEdges(updated:StringMap<UpdatedTerrainPatch>):Void 
	{
		if (children != null)
		{
            var i:Int = children.length;
			while (--i >= 0)
			{
				var child:Spatial = children[i];
				if (Std.is(child,TerrainQuad))
				{
					cast(child, TerrainQuad).fixEdges(updated);
				} 
				else if (Std.is(child, TerrainPatch))
				{
                    var patch:TerrainPatch = cast child;
                    var utp:UpdatedTerrainPatch = updated.get(patch.name);

                    if (utp != null && utp.lodChanged())
					{
                        if (!patch.searchedForNeighboursAlready)
						{
                            // set the references to the neighbours
                            patch.rightNeighbour = findRightPatch(patch);
                            patch.bottomNeighbour = findDownPatch(patch);
                            patch.leftNeighbour = findLeftPatch(patch);
                            patch.topNeighbour = findTopPatch(patch);
                            patch.searchedForNeighboursAlready = true;
                        }
                        var right:TerrainPatch = patch.rightNeighbour;
                        var down:TerrainPatch = patch.bottomNeighbour;
                        var top:TerrainPatch = patch.topNeighbour;
                        var left:TerrainPatch = patch.leftNeighbour;
                        if (right != null) 
						{
                            var utpR:UpdatedTerrainPatch = updated.get(right.name);
                            if (utpR == null)
							{
                                utpR = new UpdatedTerrainPatch(right);
                                updated.set(utpR.getName(), utpR);
                                utpR.setNewLod(right.lod);
                            }
                            utpR.setLeftLod(utp.getNewLod());
                            utpR.setFixEdges(true);
                        }
                        if (down != null)
						{
                            var utpD:UpdatedTerrainPatch = updated.get(down.name);
                            if (utpD == null)
							{
                                utpD = new UpdatedTerrainPatch(down);
                                updated.set(utpD.getName(), utpD);
                                utpD.setNewLod(down.lod);
                            }
                            utpD.setTopLod(utp.getNewLod());
                            utpD.setFixEdges(true);
                        }
                        if (top != null)
						{
                            var utpT:UpdatedTerrainPatch = updated.get(top.name);
                            if (utpT == null)
							{
                                utpT = new UpdatedTerrainPatch(top);
                                updated.set(utpT.getName(), utpT);
                                utpT.setNewLod(top.lod);
                            }
                            utpT.setBottomLod(utp.getNewLod());
                            utpT.setFixEdges(true);
                        }
                        if (left != null)
						{
                            var utpL:UpdatedTerrainPatch = updated.get(left.name);
                            if (utpL == null)
							{
                                utpL = new UpdatedTerrainPatch(left);
                                updated.set(utpL.getName(), utpL);
                                utpL.setNewLod(left.lod);
                            }
                            utpL.setRightLod(utp.getNewLod());
                            utpL.setFixEdges(true);
                        }
                    }
				}
            }
        }
    }

    private function reIndexPages(updated:StringMap<UpdatedTerrainPatch>, usesVariableLod:Bool):Void 
	{
		if (children != null)
		{
            var i:Int = children.length;
			while (--i >= 0)
			{
				var child:Spatial = children[i];
				if (Std.is(child,TerrainQuad))
				{
					cast(child, TerrainQuad).reIndexPages(updated, usesVariableLod);
				} 
				else if (Std.is(child, TerrainPatch))
				{
                    cast(child, TerrainPatch).reIndexGeometry(updated, usesVariableLod);
				}
            }
        }
    }

    /**
     * <code>split</code> divides the heightmap data for four children. The
     * children are either quads or patches. This is dependent on the size of the
     * children. If the child's size is less than or equal to the set block
     * size, then patches are created, otherwise, quads are created.
     *
     * @param blockSize
     *			the blocks size to test against.
     * @param heightMap
     *			the height data.
     */
    private function split(blockSize:Int, heightMap:Vector<Float>):Void 
	{
        if ((size >> 1) + 1 <= blockSize) 
		{
            createQuadPatch(heightMap);
        } 
		else
		{
            createQuad(blockSize, heightMap);
        }

    }

    /**
     * Quadrants, world coordinates, and heightmap coordinates (Y-up):
     * 
     *         -z
     *      -u | 
     *    -v  1|3 
     *  -x ----+---- x
     *        2|4 u
     *         | v
     *         z
     * <code>createQuad</code> generates four new quads from this quad.
     * The heightmap's top left (0,0) coordinate is at the bottom, -x,-z
     * coordinate of the terrain, so it grows in the positive x.z direction.
     */
    private function createQuad(blockSize:Int, heightMap:Vector<Float>):Void 
	{
        // create 4 terrain quads
        var quarterSize:Int = size >> 2;

        var split:Int = (size + 1) >> 1;

        var tempOffset:Vector2f = new Vector2f();
        offsetAmount += quarterSize;

        //if (lodCalculator == null)
        //    lodCalculator = createDefaultLodCalculator(); // set a default one

        // 1 upper left of heightmap, upper left quad
        var heightBlock1:Vector<Float> = createHeightSubBlock(heightMap, 0, 0, split);

        var origin1:Vector3f = new Vector3f(-quarterSize * stepScale.x, 0,
                        -quarterSize * stepScale.z);

        tempOffset.x = offset.x;
        tempOffset.y = offset.y;
        tempOffset.x += origin1.x;
        tempOffset.y += origin1.z;

        var quad1:TerrainQuad = new TerrainQuad(this.name + "Quad1", blockSize,
                        split, totalSize, heightBlock1, stepScale, 
						tempOffset,offsetAmount);
        quad1.setLocalTranslation(origin1);
        quad1.quadrant = 1;
        this.attachChild(quad1);

        // 2 lower left of heightmap, lower left quad
        var heightBlock2:Vector<Float> = createHeightSubBlock(heightMap, 0, split - 1,
                        split);

        var origin2:Vector3f = new Vector3f(-quarterSize * stepScale.x, 0,
                        quarterSize * stepScale.z);

        tempOffset = new Vector2f();
        tempOffset.x = offset.x;
        tempOffset.y = offset.y;
        tempOffset.x += origin2.x;
        tempOffset.y += origin2.z;

        var quad2:TerrainQuad = new TerrainQuad(this.name + "Quad2", blockSize,
                        split, totalSize, heightBlock2, stepScale, tempOffset,
                        offsetAmount);
        quad2.setLocalTranslation(origin2);
        quad2.quadrant = 2;
        this.attachChild(quad2);

        // 3 upper right of heightmap, upper right quad
        var heightBlock3:Vector<Float> = createHeightSubBlock(heightMap, split - 1, 0,
                        split);

        var origin3:Vector3f = new Vector3f(quarterSize * stepScale.x, 0,
                        -quarterSize * stepScale.z);

        tempOffset = new Vector2f();
        tempOffset.x = offset.x;
        tempOffset.y = offset.y;
        tempOffset.x += origin3.x;
        tempOffset.y += origin3.z;

        var quad3:TerrainQuad = new TerrainQuad(this.name + "Quad3", blockSize,
                        split, totalSize, heightBlock3, stepScale, tempOffset,
                        offsetAmount);
        quad3.setLocalTranslation(origin3);
        quad3.quadrant = 3;
        this.attachChild(quad3);
        
        // 4 lower right of heightmap, lower right quad
        var heightBlock4:Vector<Float> = createHeightSubBlock(heightMap, split - 1,
                        split - 1, split);

        var origin4:Vector3f = new Vector3f(quarterSize * stepScale.x, 0,
                        quarterSize * stepScale.z);

        tempOffset = new Vector2f();
        tempOffset.x = offset.x;
        tempOffset.y = offset.y;
        tempOffset.x += origin4.x;
        tempOffset.y += origin4.z;

        var quad4:TerrainQuad = new TerrainQuad(this.name + "Quad4", blockSize,
                        split, totalSize, heightBlock4, stepScale , tempOffset,
                        offsetAmount);
        quad4.setLocalTranslation(origin4);
        quad4.quadrant = 4;
        this.attachChild(quad4);

    }

    public function generateDebugTangents(mat:Material):Void
	{
		if (children != null)
		{
            var i:Int = children.length;
			while (--i >= 0)
			{
				var child:Spatial = children[i];
				if (Std.is(child,TerrainQuad))
				{
					cast(child, TerrainQuad).generateDebugTangents(mat);
				} 
				else if (Std.is(child, TerrainPatch))
				{
                    var debug:Geometry = new Geometry( "Debug " + name,
                    TangentBinormalGenerator.genTbnLines( cast(child,TerrainPatch).getMesh(), 0.8));
					attachChild(debug);
					debug.setLocalTranslation(child.getLocalTranslation());
					debug.setCullHint(CullHint.Never);
					debug.setMaterial(mat);
				}
            }
        }
    }

    /**
     * <code>createQuadPatch</code> creates four child patches from this quad.
     */
    private function createQuadPatch(heightMap:Vector<Float>):Void
	{
        // create 4 terrain patches
        var quarterSize:Int = size >> 2;
        var halfSize:Int = size >> 1;
        var split:Int = (size + 1) >> 1;

        //if (lodCalculator == null)
        //    lodCalculator = createDefaultLodCalculator(); // set a default one

        offsetAmount += quarterSize;

        // 1 lower left
        var heightBlock1:Vector<Float> = createHeightSubBlock(heightMap, 0, 0, split);

        var origin1:Vector3f = new Vector3f(-halfSize * stepScale.x, 0, -halfSize
                        * stepScale.z);

        var tempOffset1:Vector2f = new Vector2f();
        tempOffset1.x = offset.x;
        tempOffset1.y = offset.y;
        tempOffset1.x += origin1.x / 2;
        tempOffset1.y += origin1.z / 2;

        var patch1:TerrainPatch = new TerrainPatch(this.name + "Patch1", split,
                        stepScale, heightBlock1, origin1, totalSize, tempOffset1,
                        offsetAmount);
        patch1.setQuadrant(1);
        this.attachChild(patch1);
        patch1.setModelBound(new BoundingBox());
        patch1.updateModelBound();
        //patch1.setLodCalculator(lodCalculator);
        //TangentBinormalGenerator.generate(patch1);

        // 2 upper left
        var heightBlock2:Vector<Float> = createHeightSubBlock(heightMap, 0, split - 1,
                        split);

        var origin2:Vector3f = new Vector3f(-halfSize * stepScale.x, 0, 0);

        var tempOffset2:Vector2f = new Vector2f();
        tempOffset2.x = offset.x;
        tempOffset2.y = offset.y;
        tempOffset2.x += origin1.x / 2;
        tempOffset2.y += quarterSize * stepScale.z;

        var patch2:TerrainPatch = new TerrainPatch(this.name + "Patch2", split,
                        stepScale, heightBlock2, origin2, totalSize, tempOffset2,
                        offsetAmount);
        patch2.setQuadrant(2);
        this.attachChild(patch2);
        patch2.setModelBound(new BoundingBox());
        patch2.updateModelBound();
        //patch2.setLodCalculator(lodCalculator);
        //TangentBinormalGenerator.generate(patch2);

        // 3 lower right
        var heightBlock3:Vector<Float> = createHeightSubBlock(heightMap, split - 1, 0,
                        split);

        var origin3:Vector3f = new Vector3f(0, 0, -halfSize * stepScale.z);

        var tempOffset3:Vector2f = new Vector2f();
        tempOffset3.x = offset.x;
        tempOffset3.y = offset.y;
        tempOffset3.x += quarterSize * stepScale.x;
        tempOffset3.y += origin3.z / 2;

        var patch3:TerrainPatch = new TerrainPatch(this.name + "Patch3", split,
                        stepScale, heightBlock3, origin3, totalSize, tempOffset3,
                        offsetAmount);
        patch3.setQuadrant(3);
        this.attachChild(patch3);
        patch3.setModelBound(new BoundingBox());
        patch3.updateModelBound();
        //patch3.setLodCalculator(lodCalculator);
        //TangentBinormalGenerator.generate(patch3);

        // 4 upper right
        var heightBlock4:Vector<Float> = createHeightSubBlock(heightMap, split - 1,
                        split - 1, split);

        var origin4:Vector3f = new Vector3f(0, 0, 0);

        var tempOffset4:Vector2f = new Vector2f();
        tempOffset4.x = offset.x;
        tempOffset4.y = offset.y;
        tempOffset4.x += quarterSize * stepScale.x;
        tempOffset4.y += quarterSize * stepScale.z;

        var patch4:TerrainPatch = new TerrainPatch(this.name + "Patch4", split,
                        stepScale, heightBlock4, origin4, totalSize, tempOffset4,
                        offsetAmount);
        patch4.setQuadrant(4);
        this.attachChild(patch4);
        patch4.setModelBound(new BoundingBox());
        patch4.updateModelBound();
        //patch4.setLodCalculator(lodCalculator);
        //TangentBinormalGenerator.generate(patch4);
    }

    public function createHeightSubBlock(heightMap:Vector<Float>, x:Int, y:Int, side:Int):Vector<Float> 
	{
        var rVal:Vector<Float> = new Vector<Float>(side * side, true);
        var bsize:Int = Std.int(Math.sqrt(heightMap.length));
        var count:Int = 0;
        for (i in y...(side + y))
		{
            for (j in x...(side + x))
			{
                if (j < bsize && i < bsize)
                    rVal[count] = heightMap[j + (i * bsize)];
                count++;
            }
        }
        return rVal;
    }

    /**
     * A handy method that will attach all bounding boxes of this terrain
     * to the node you supply.
     * Useful to visualize the bounding boxes when debugging.
     *
     * @param parent that will get the bounding box shapes of the terrain attached to
     */
    public function attachBoundChildren(parent:Node):Void
	{
        for (i in 0...this.numChildren)
		{
			var child:Spatial = this.getChildAt(i);
            if (Std.is(child, TerrainQuad))
			{
                cast(child,TerrainQuad).attachBoundChildren(parent);
            } 
			else if (Std.is(child, TerrainPatch))
			{
                var bv:BoundingVolume = child.getWorldBound();
                if (Std.is(bv, BoundingBox))
				{
                    attachBoundingBox(cast bv, parent);
                }
            }
        }
        var bv:BoundingVolume = getWorldBound();
        if (Std.is(bv, BoundingBox))
		{
            attachBoundingBox(cast bv, parent);
        }
    }

    /**
     * used by attachBoundChildren()
     */
    private function attachBoundingBox(bb:BoundingBox, parent:Node):Void
	{
        var wb:WireBox = new WireBox(bb.xExtent, bb.yExtent, bb.zExtent);
        var g:Geometry = new Geometry("debugBox");
        g.setMesh(wb);
        g.setLocalTranslation(bb.getCenter());
        parent.attachChild(g);
    }

    /**
     * Signal if the normal vectors for the terrain need to be recalculated.
     * Does this by looking at the affectedAreaBBox bounding box. If the bbox
     * exists already, then it will grow the box to fit the new changedPoint.
     * If the affectedAreaBBox is null, then it will create one of unit size.
     *
     * @param needToRecalculateNormals if null, will cause needToRecalculateNormals() to return false
     */
    private function setNormalRecalcNeeded(changedPoint:Vector2f):Void
	{
		// set needToRecalculateNormals() to false
        if (changedPoint == null)
		{ 
            affectedAreaBBox = null;
            return;
        }

        if (affectedAreaBBox == null) 
		{
            affectedAreaBBox = new BoundingBox(new Vector3f(changedPoint.x, 0, changedPoint.y), new Vector3f(1, Math.POSITIVE_INFINITY, 1)); // unit length
        }
		else
		{
            // adjust size of box to be larger
            affectedAreaBBox.mergeLocal(new BoundingBox(new Vector3f(changedPoint.x, 0, changedPoint.y), new Vector3f(1, Math.POSITIVE_INFINITY, 1)));
        }
    }

    private function needToRecalculateNormals():Bool 
	{
        if (affectedAreaBBox != null)
            return true;
        if (!lastScale.equals(getWorldScale()))
		{
            affectedAreaBBox = new BoundingBox(getWorldTranslation(), new Vector3f(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY));
            lastScale = getWorldScale();
            return true;
        }
        return false;
    }
    
    /**
     * This will cause all normals for this terrain quad to be recalculated
     */
    private function setNeedToRecalculateNormals():Void 
	{
        affectedAreaBBox = new BoundingBox(getWorldTranslation(), new Vector3f(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY));
    }

    public function getHeightmapHeight(xz:Vector2f):Float 
	{
        // offset
        var halfSize:Float = totalSize / 2;
        var x = Math.round((xz.x / getWorldScale().x) + halfSize);
        var z = Math.round((xz.y / getWorldScale().z) + halfSize);

        if (!isInside(x, z))
            return Math.NaN;
        return getHeightmapHeightXZ(x, z);
    }

    /**
     * This will just get the heightmap value at the supplied point,
     * not an interpolated (actual) height value.
     */
    private function getHeightmapHeightXZ(x:Int, z:Int):Float 
	{
        var quad:Int = findQuadrant(x, z);
        var split:Int = (size + 1) >> 1;
		
		if (children != null)
		{
            var i:Int = children.length;
			while (--i >= 0)
			{
				var spat:Spatial = children[i];
				
				var col:Int = x;
                var row:Int = z;
                var match:Bool = false;

                // get the childs quadrant
                var childQuadrant:Int = 0;
				
				if (Std.is(spat,TerrainQuad))
				{
					childQuadrant = cast(spat, TerrainQuad).getQuadrant();
				} 
				else if (Std.is(spat, TerrainPatch))
				{
                    childQuadrant = cast(spat, TerrainPatch).getQuadrant();
				}
				
				if (childQuadrant == 1 && (quad & 1) != 0)
				{
                    match = true;
                } 
				else if (childQuadrant == 2 && (quad & 2) != 0) 
				{
                    row = z - split + 1;
                    match = true;
                } 
				else if (childQuadrant == 3 && (quad & 4) != 0)
				{
                    col = x - split + 1;
                    match = true;
                }
				else if (childQuadrant == 4 && (quad & 8) != 0)
				{
                    col = x - split + 1;
                    row = z - split + 1;
                    match = true;
                }

                if (match) 
				{
					if (Std.is(spat,TerrainQuad))
					{
						return cast(spat, TerrainQuad).getHeightmapHeightXZ(col, row);
					} 
					else if (Std.is(spat, TerrainPatch))
					{
						return cast(spat, TerrainPatch).getHeightmapHeight(col, row);
					}
                }
            }
        }
		
        return Math.NaN;
    }

    private function getMeshNormal(x:Int, z:Int):Vector3f 
	{
        var quad:Int = findQuadrant(x, z);
        var split:Int = (size + 1) >> 1;
		
		if (children != null)
		{
            var i:Int = children.length;
			while (--i >= 0)
			{
				var spat:Spatial = children[i];
				
				var col:Int = x;
                var row:Int = z;
                var match:Bool = false;

                // get the childs quadrant
                var childQuadrant:Int = 0;
				
				if (Std.is(spat,TerrainQuad))
				{
					childQuadrant = cast(spat, TerrainQuad).getQuadrant();
				} 
				else if (Std.is(spat, TerrainPatch))
				{
                    childQuadrant = cast(spat, TerrainPatch).getQuadrant();
				}
				
				if (childQuadrant == 1 && (quad & 1) != 0)
				{
                    match = true;
                } 
				else if (childQuadrant == 2 && (quad & 2) != 0) 
				{
                    row = z - split + 1;
                    match = true;
                } 
				else if (childQuadrant == 3 && (quad & 4) != 0)
				{
                    col = x - split + 1;
                    match = true;
                }
				else if (childQuadrant == 4 && (quad & 8) != 0)
				{
                    col = x - split + 1;
                    row = z - split + 1;
                    match = true;
                }

                if (match) 
				{
					if (Std.is(spat,TerrainQuad))
					{
						return cast(spat, TerrainQuad).getMeshNormal(col, row);
					} 
					else if (Std.is(spat, TerrainPatch))
					{
						return cast(spat, TerrainPatch).getMeshNormal(col, row);
					}
                }
            }
        }
		
        return null;
    }

    /**
     * is the 2d point inside the terrain?
     * @param x local coordinate
     * @param z local coordinate
     */
    private function isInside(x:Int, z:Int):Bool 
	{
        if (x < 0 || z < 0 || x > totalSize || z > totalSize)
            return false;
        return true;
    }
    
    private function findMatchingChild(x:Int, z:Int):QuadrantChild 
	{
		var quad:Int = findQuadrant(x, z);
        var split:Int = (size + 1) >> 1;
		
		if (children != null)
		{
            var i:Int = children.length;
			while (--i >= 0)
			{
				var spat:Spatial = children[i];
				
				var col:Int = x;
                var row:Int = z;
                var match:Bool = false;

                // get the childs quadrant
                var childQuadrant:Int = 0;
				
				if (Std.is(spat,TerrainQuad))
				{
					childQuadrant = cast(spat, TerrainQuad).getQuadrant();
				} 
				else if (Std.is(spat, TerrainPatch))
				{
                    childQuadrant = cast(spat, TerrainPatch).getQuadrant();
				}
				
				if (childQuadrant == 1 && (quad & 1) != 0)
				{
                    match = true;
                } 
				else if (childQuadrant == 2 && (quad & 2) != 0) 
				{
                    row = z - split + 1;
                    match = true;
                } 
				else if (childQuadrant == 3 && (quad & 4) != 0)
				{
                    col = x - split + 1;
                    match = true;
                }
				else if (childQuadrant == 4 && (quad & 8) != 0)
				{
                    col = x - split + 1;
                    row = z - split + 1;
                    match = true;
                }

                if (match) 
				{
					return new QuadrantChild(col, row, spat);
                }
            }
        }
		
        return null;
    }
    
    /**
     * Get the interpolated height of the terrain at the specified point.
     * @param xz the location to get the height for
     * @return Math.NaN if the value does not exist, or the coordinates are outside of the terrain
     */
    public function getHeight(xz:Vector2f):Float 
	{
        // offset
        var x:Int = Std.int(((xz.x - getWorldTranslation().x) / getWorldScale().x) + (totalSize-1) / 2);
        var z:Int = Std.int(((xz.y - getWorldTranslation().z) / getWorldScale().z) + (totalSize-1) / 2);
        if (!isInside(x, z))
            return Math.NaN;
        var height = getHeightXZM(x, z, (x%1), (z%1));
        height *= getWorldScale().y;
        return height;
    }

    /*
     * gets an interpolated value at the specified point
     */
    private function getHeightXZM(x:Int, z:Int, xm:Float, zm:Float):Float 
	{
        var match:QuadrantChild = findMatchingChild(x,z);
        if (match != null) 
		{
            if (Std.is(match.child, TerrainQuad))
			{
                return cast(match.child,TerrainQuad).getHeightXZM(match.col, match.row, xm, zm);
            } 
			else if (Std.is(match.child,TerrainPatch)) 
			{
                return cast(match.child,TerrainPatch).getHeightXZM(match.col, match.row, xm, zm);
            }
        }
        return Math.NaN;
    }

    public function getNormal(xz:Vector2f):Vector3f 
	{
        // offset
        var x:Float = (((xz.x - getWorldTranslation().x) / getWorldScale().x) + (totalSize-1) / 2);
        var z:Float = (((xz.y - getWorldTranslation().z) / getWorldScale().z) + (totalSize-1) / 2);
        var normal:Vector3f = getNormal2(x, z, xz);
        
        return normal;
    }
    
    private function getNormal2(x:Float, z:Float, xz:Vector2f):Vector3f 
	{
        x -= 0.5;
        z -= 0.5;
        var col:Int = Math.floor(x);
        var row:Int = Math.floor(z);
        var onX:Bool = false;
        if(1 - (x - col)-(z - row) < 0) // what triangle to interpolate on
            onX = true;
        // v1--v2  ^
        // |  / |  |
        // | /  |  |
        // v3--v4  | Z
        //         |
        // <-------Y
        //     X 
        var n1:Vector3f = getMeshNormal(Math.ceil(x), Math.ceil(z));
        var n2:Vector3f = getMeshNormal(Math.floor(x), Math.ceil(z));
        var n3:Vector3f = getMeshNormal(Math.ceil(x), Math.floor(z));
        var n4:Vector3f = getMeshNormal(Math.floor(x), Math.floor(z));
        
        return n1.add(n2).add(n3).add(n4).normalize();
    }
    
    public function setHeight(xz:Vector2f, height:Float):Void
	{
        var coord:Array<Vector2f> = new Array<Vector2f>();
        coord.push(xz);
        var h:Vector<Float> = new Vector<Float>();
        h.push(height);

        setHeights(coord, h);
    }

    public function adjustHeight(xz:Vector2f, delta:Float):Void
	{
        var coord:Array<Vector2f> = new Array<Vector2f>();
        coord.push(xz);
        var h:Vector<Float> = new Vector<Float>();
        h.push(delta);

        adjustHeights(coord, h);
    }

    public function setHeights(xz:Array<Vector2f>, height:Vector<Float>):Void
	{
        setHeight3(xz, height, true);
    }

    public function adjustHeights(xz:Array<Vector2f>, height:Vector<Float>):Void
	{
        setHeight3(xz, height, false);
    }

    private function setHeight3(xz:Array<Vector2f>, height:Vector<Float>, overrideHeight:Bool):Void
	{
        if (xz.length != height.length)
            throw ("Both lists must be the same length!");

        var halfSize:Int = Std.int(totalSize / 2);

        var locations:Array<LocationHeight> = new Array<LocationHeight>();

        // offset
        for (i in 0...xz.length)
		{
            var x:Int = Math.round((xz[i].x / getWorldScale().x) + halfSize);
            var z:Int = Math.round((xz[i].y / getWorldScale().z) + halfSize);
            if (!isInside(x, z))
                continue;
            locations.push(new LocationHeight(x,z,height[i]));
        }

        setHeight4(locations, overrideHeight); // adjust height of the actual mesh

        // signal that the normals need updating
        for (i in 0...xz.length)
            setNormalRecalcNeeded(xz[i] );
    }

    private function setHeight4(locations:Array<LocationHeight>, overrideHeight:Bool):Void
	{
        if (children == null)
            return;

        var quadLH1:Array<LocationHeight> = new Array<LocationHeight>();
        var quadLH2:Array<LocationHeight> = new Array<LocationHeight>();
        var quadLH3:Array<LocationHeight> = new Array<LocationHeight>();
        var quadLH4:Array<LocationHeight> = new Array<LocationHeight>();
        var quad1:Spatial = null;
        var quad2:Spatial = null;
        var quad3:Spatial = null;
        var quad4:Spatial = null;

        // get the child quadrants
		var i:Int = children.length;
        while (--i >= 0)
		{
            var spat:Spatial = children[i];
            var childQuadrant:Int = 0;
            if (Std.is(spat, TerrainQuad))
			{
                childQuadrant = cast(spat,TerrainQuad).getQuadrant();
            } 
			else if (Std.is(spat, TerrainPatch))
			{
                childQuadrant = cast(spat,TerrainPatch).getQuadrant();
            }

            if (childQuadrant == 1)
                quad1 = spat;
            else if (childQuadrant == 2)
                quad2 = spat;
            else if (childQuadrant == 3)
                quad3 = spat;
            else if (childQuadrant == 4)
                quad4 = spat;
        }

        var split:Int = (size + 1) >> 1;

        // distribute each locationHeight into the quadrant it intersects
        for ( lh in locations)
		{
            var quad:Int = findQuadrant(lh.x, lh.z);
            var col:Int = lh.x;
            var row:Int = lh.z;

            if ((quad & 1) != 0)
			{
                quadLH1.push(lh);
            }
            if ((quad & 2) != 0)
			{
                row = lh.z - split + 1;
                quadLH2.push(new LocationHeight(lh.x, row, lh.h));
            }
            if ((quad & 4) != 0)
			{
                col = lh.x - split + 1;
                quadLH3.push(new LocationHeight(col, lh.z, lh.h));
            }
            if ((quad & 8) != 0)
			{
                col = lh.x - split + 1;
                row = lh.z - split + 1;
                quadLH4.push(new LocationHeight(col, row, lh.h));
            }
        }

        // send the locations to the children
        if (quadLH1.length != 0) 
		{
            if (Std.is(quad1, TerrainQuad))
                cast(quad1,TerrainQuad).setHeight4(quadLH1, overrideHeight);
            else if(Std.is(quad1,TerrainPatch))
                cast(quad1,TerrainPatch).setHeight(quadLH1, overrideHeight);
        }

        if (quadLH2.length != 0) 
		{
            if (Std.is(quad2,TerrainQuad))
                cast(quad2,TerrainQuad).setHeight4(quadLH2, overrideHeight);
            else if(Std.is(quad2,TerrainPatch))
                cast(quad2,TerrainPatch).setHeight(quadLH2, overrideHeight);
        }

        if (quadLH3.length != 0) 
		{
            if (Std.is(quad3,TerrainQuad))
                cast(quad3,TerrainQuad).setHeight4(quadLH3, overrideHeight);
            else if(Std.is(quad3,TerrainPatch))
                cast(quad3,TerrainPatch).setHeight(quadLH3, overrideHeight);
        }

        if (quadLH4.length != 0) 
		{
            if (Std.is(quad4,TerrainQuad))
                cast(quad4,TerrainQuad).setHeight4(quadLH4, overrideHeight);
            else if(Std.is(quad4,TerrainPatch))
                cast(quad4,TerrainPatch).setHeight(quadLH4, overrideHeight);
        }
    }

    private function isPointOnTerrain(x:Int, z:Int):Bool 
	{
        return (x >= 0 && x <= totalSize && z >= 0 && z <= totalSize);
    }

    
    public function getTerrainSize():Int 
	{
        return totalSize;
    }


    // a position can be in multiple quadrants, so use a bit anded value.
    private function findQuadrant(x:Int, z:Int):Int 
	{
        var split:Int = (size + 1) >> 1;
        var quads:Int = 0;
        if (x < split && y < split)
            quads |= 1;
        if (x < split && y >= split - 1)
            quads |= 2;
        if (x >= split - 1 && y < split)
            quads |= 4;
        if (x >= split - 1 && y >= split - 1)
            quads |= 8;
        return quads;
    }

    /**
     * lock or unlock the meshes of this terrain.
     * Locked meshes are uneditable but have better performance.
     * @param locked or unlocked
     */
    public function setLocked(locked:Bool):Void
	{
        for (i in 0...this.numChildren)
		{
			var child:Spatial = children[i];
			
            if (Std.is(child, TerrainQuad))
			{
                cast(child,TerrainQuad).setLocked(locked);
            } 
			else if (Std.is(child, TerrainPatch))
			{
                if (locked)
                    cast(child,TerrainPatch).lockMesh();
                else
                    cast(child,TerrainPatch).unlockMesh();
            }
        }
    }


    public function getQuadrant():Int 
	{
        return quadrant;
    }

    public function setQuadrant(quadrant:Int):Void
	{
        this.quadrant = quadrant;
    }


    private function getPatch(quad:Int):TerrainPatch
	{
        if (children != null)
		{
			var i:Int = children.length;
			while (--i >= 0)
			{
				var child:Spatial = children[i];
				if (Std.is(child, TerrainPatch))
				{
					var tb:TerrainPatch = cast child;
                    if (tb.getQuadrant() == quad)
                        return tb;
				} 
			}
		}
        return null;
    }

    private function getQuad(quad:Int):TerrainQuad
	{
        if (quad == 0)
            return this;
        if (children != null)
		{
			var i:Int = children.length;
			while (--i >= 0)
			{
				var child:Spatial = children[i];
				if (Std.is(child, TerrainQuad))
				{
					var tb:TerrainQuad = cast child;
                    if (tb.getQuadrant() == quad)
                        return tb;
				} 
			}
		}
        return null;
    }

    private function findRightPatch(tp:TerrainPatch):TerrainPatch
	{
        if (tp.getQuadrant() == 1)
            return getPatch(3);
        else if (tp.getQuadrant() == 2)
            return getPatch(4);
        else if (tp.getQuadrant() == 3)
		{
            // find the patch to the right and ask it for child 1.
            var quad:TerrainQuad = findRightQuad();
            if (quad != null)
                return quad.getPatch(1);
        } 
		else if (tp.getQuadrant() == 4) 
		{
            // find the patch to the right and ask it for child 2.
            var quad:TerrainQuad = findRightQuad();
            if (quad != null)
                return quad.getPatch(2);
        }

        return null;
    }

    private function findDownPatch(tp:TerrainPatch):TerrainPatch
	{
        if (tp.getQuadrant() == 1)
            return getPatch(2);
        else if (tp.getQuadrant() == 3)
            return getPatch(4);
        else if (tp.getQuadrant() == 2)
		{
            // find the patch below and ask it for child 1.
            var quad:TerrainQuad = findDownQuad();
            if (quad != null)
                return quad.getPatch(1);
        } 
		else if (tp.getQuadrant() == 4)
		{
            var quad:TerrainQuad = findDownQuad();
            if (quad != null)
                return quad.getPatch(3);
        }

        return null;
    }


    private function findTopPatch(tp:TerrainPatch):TerrainPatch
	{
        if (tp.getQuadrant() == 2)
            return getPatch(1);
        else if (tp.getQuadrant() == 4)
            return getPatch(3);
        else if (tp.getQuadrant() == 1)
		{
            // find the patch above and ask it for child 2.
            var quad:TerrainQuad = findTopQuad();
            if (quad != null)
                return quad.getPatch(2);
        } 
		else if (tp.getQuadrant() == 3)
		{
            var quad:TerrainQuad = findTopQuad();
            if (quad != null)
                return quad.getPatch(4);
        }

        return null;
    }

    private function findLeftPatch(tp:TerrainPatch):TerrainPatch
	{
        if (tp.getQuadrant() == 3)
            return getPatch(1);
        else if (tp.getQuadrant() == 4)
            return getPatch(2);
        else if (tp.getQuadrant() == 1)
		{
            // find the patch above and ask it for child 3.
            var quad:TerrainQuad = findLeftQuad();
            if (quad != null)
                return quad.getPatch(3);
        } else if (tp.getQuadrant() == 2)
		{
            var quad:TerrainQuad = findLeftQuad();
            if (quad != null)
                return quad.getPatch(4);
        }

        return null;
    }

    private function findRightQuad():TerrainQuad 
	{
        var useFinder:Bool = false;
        if (getParent() == null || !Std.is(getParent(), TerrainQuad))
		{
            if (neighbourFinder == null)
                return null;
            else
                useFinder = true;
        }

        var pQuad:TerrainQuad = null;
        if (!useFinder)
            pQuad = cast getParent();

        if (quadrant == 1)
            return pQuad.getQuad(3);
        else if (quadrant == 2)
            return pQuad.getQuad(4);
        else if (quadrant == 3)
		{
            var quad:TerrainQuad = pQuad.findRightQuad();
            if (quad != null)
                return quad.getQuad(1);
        } 
		else if (quadrant == 4) 
		{
            var quad:TerrainQuad = pQuad.findRightQuad();
            if (quad != null)
                return quad.getQuad(2);
        } 
		else if (quadrant == 0)
		{
            // at the top quad
            if (useFinder)
			{
                var quad:TerrainQuad = neighbourFinder.getRightQuad(this);
                return quad;
            }
        }

        return null;
    }

    private function findDownQuad():TerrainQuad 
	{
        var useFinder:Bool = false;
        if (getParent() == null || !Std.is(getParent(), TerrainQuad))
		{
            if (neighbourFinder == null)
                return null;
            else
                useFinder = true;
        }

        var pQuad:TerrainQuad = null;
        if (!useFinder)
            pQuad = cast getParent();

        if (quadrant == 1)
            return pQuad.getQuad(2);
        else if (quadrant == 3)
            return pQuad.getQuad(4);
        else if (quadrant == 2) 
		{
            var quad:TerrainQuad = pQuad.findDownQuad();
            if (quad != null)
                return quad.getQuad(1);
        } 
		else if (quadrant == 4)
		{
            var quad:TerrainQuad = pQuad.findDownQuad();
            if (quad != null)
                return quad.getQuad(3);
        } 
		else if (quadrant == 0) 
		{
            // at the top quad
            if (useFinder) 
			{
                var quad:TerrainQuad = neighbourFinder.getDownQuad(this);
                return quad;
            }
        }

        return null;
    }

    private function findTopQuad():TerrainQuad
	{
        var useFinder:Bool = false;
        if (getParent() == null || !Std.is(getParent(), TerrainQuad))
		{
            if (neighbourFinder == null)
                return null;
            else
                useFinder = true;
        }

        var pQuad:TerrainQuad = null;
        if (!useFinder)
            pQuad = cast getParent();

        if (quadrant == 2)
            return pQuad.getQuad(1);
        else if (quadrant == 4)
            return pQuad.getQuad(3);
        else if (quadrant == 1)
		{
            var quad:TerrainQuad = pQuad.findTopQuad();
            if (quad != null)
                return quad.getQuad(2);
        }
		else if (quadrant == 3) 
		{
            var quad:TerrainQuad = pQuad.findTopQuad();
            if (quad != null)
                return quad.getQuad(4);
        } 
		else if (quadrant == 0) 
		{
            // at the top quad
            if (useFinder) 
			{
                var quad:TerrainQuad = neighbourFinder.getTopQuad(this);
                return quad;
            }
        }

        return null;
    }

    private function findLeftQuad():TerrainQuad
	{
        var useFinder:Bool = false;
        if (getParent() == null || !Std.is(getParent(), TerrainQuad))
		{
            if (neighbourFinder == null)
                return null;
            else
                useFinder = true;
        }

        var pQuad:TerrainQuad = null;
        if (!useFinder)
            pQuad = cast getParent();

        if (quadrant == 3)
            return pQuad.getQuad(1);
        else if (quadrant == 4)
            return pQuad.getQuad(2);
        else if (quadrant == 1) 
		{
            var quad:TerrainQuad = pQuad.findLeftQuad();
            if (quad != null)
                return quad.getQuad(3);
        }
		else if (quadrant == 2) 
		{
            var quad:TerrainQuad = pQuad.findLeftQuad();
            if (quad != null)
                return quad.getQuad(4);
        } 
		else if (quadrant == 0)
		{
            // at the top quad
            if (useFinder) {
                var quad:TerrainQuad = neighbourFinder.getLeftQuad(this);
                return quad;
            }
        }

        return null;
    }

    /**
     * Find what terrain patches need normal recalculations and update
     * their normals;
     */
    private function fixNormals(affectedArea:BoundingBox):Void 
	{
        if (children == null)
            return;
			
		// go through the children and see if they collide with the affectedAreaBBox
        // if they do, then update their normals
		var i:Int = children.length;
		while (--i >= 0)
		{
			var child:Spatial = children[i];
			if (Std.is(child, TerrainQuad))
			{
				if (affectedArea != null && affectedArea.intersects(child.getWorldBound()) )
                    cast(child,TerrainQuad).fixNormals(affectedArea);
			} 
			else if (Std.is(child, TerrainPatch))
			{
				if (affectedArea != null && affectedArea.intersects(child.getWorldBound()) )
                    cast(child,TerrainPatch).updateNormals(); // recalculate the patch's normals
			}
		}
    }

    /**
     * fix the normals on the edge of the terrain patches.
     */
    private function fixNormalEdges(affectedArea:BoundingBox):Void
	{
        if (children == null)
            return;
			
		var i:Int = children.length;
		while (--i >= 0)
		{
			var child:Spatial = children[i];
			if (Std.is(child, TerrainQuad))
			{
				if (affectedArea != null && affectedArea.intersects(child.getWorldBound()) )
                    cast(child,TerrainQuad).fixNormalEdges(affectedArea);
			} 
			else if (Std.is(child, TerrainPatch))
			{
				if (affectedArea != null && !affectedArea.intersects(child.getWorldBound()) ) // if doesn't intersect, continue
                    continue;

                var tp:TerrainPatch = cast child;
                var right:TerrainPatch = findRightPatch(tp);
                var bottom:TerrainPatch = findDownPatch(tp);
                var top:TerrainPatch = findTopPatch(tp);
                var left:TerrainPatch = findLeftPatch(tp);
                var topLeft:TerrainPatch = null;
                if (top != null)
                    topLeft = findLeftPatch(top);
                var bottomRight:TerrainPatch = null;
                if (right != null)
                    bottomRight = findDownPatch(right);
                var topRight:TerrainPatch = null;
                if (top != null)
                    topRight = findRightPatch(top);
                var bottomLeft:TerrainPatch = null;
                if (left != null)
                    bottomLeft = findDownPatch(left);

                tp.fixNormalEdges(right, bottom, top, left, bottomRight, bottomLeft, topRight, topLeft);
			}
		}
    }

	override public function collideWith(other:Collidable, results:CollisionResults):Int
	{
		var total:Int = 0;

        if (Std.is(other,Ray))
            return collideWithRay(cast other, results);

        // if it didn't collide with this bbox, return
        if (Std.is(other,BoundingVolume))
            if (!this.getWorldBound().intersects(cast other))
                return total;

        for (child in children)
		{
            total += child.collideWith(other, results);
        }
        return total;
	}

    /**
     * Gather the terrain patches that intersect the given ray (toTest).
     * This only tests the bounding boxes
     * @param toTest
     * @param results
     */
    public function findPick(toTest:Ray, results:Array<TerrainPickData>):Void 
	{
        if (getWorldBound() != null)
		{
            if (getWorldBound().intersectsRay(toTest))
			{
                // further checking needed.
                for (i in 0...this.numChildren)
				{
					var child:Spatial = children[i];
                    if (Std.is(child, TerrainPatch))
					{
                        var tp:TerrainPatch = cast children[i];
                        tp.ensurePositiveVolumeBBox();
                        if (tp.getWorldBound().intersectsRay(toTest)) 
						{
                            var cr:CollisionResults = new CollisionResults();
                            toTest.collideWith(tp.getWorldBound(), cr);
                            if (cr != null && cr.getClosestCollision() != null)
							{
                                cr.getClosestCollision().distance;
                                results.push(new TerrainPickData(tp, cr.getClosestCollision()));
                            }
                        }
                    }
                    else if (Std.is(child, TerrainQuad))
					{
                        cast(children[i],TerrainQuad).findPick(toTest, results);
                    }
                }
            }
        }
    }


    /**
     * Retrieve all Terrain Patches from all children and store them
     * in the 'holder' list
     * @param holder must not be null, will be populated when returns
     */
    public function getAllTerrainPatches(holder:Array<TerrainPatch>):Void
	{
        if (children != null)
		{
			var i:Int = children.length;
			while (--i >= 0)
			{
                var child:Spatial = children[i];
                if (Std.is(child, TerrainQuad))
				{
                    cast(child,TerrainQuad).getAllTerrainPatches(holder);
                } else if (Std.is(child, TerrainPatch)) 
				{
                    holder.push(cast child);
                }
            }
        }
    }

    public function getAllTerrainPatchesWithTranslation(holder:ObjectMap<TerrainPatch,Vector3f>, translation:Vector3f):Void
	{
		if (children != null)
		{
			var i:Int = children.length;
			while (--i >= 0)
			{
                var child:Spatial = children[i];
                if (Std.is(child, TerrainQuad))
				{
                    cast(child,TerrainQuad).getAllTerrainPatchesWithTranslation(holder,translation.clone().add(child.getLocalTranslation()));
                } else if (Std.is(child, TerrainPatch)) 
				{
                    holder.push(cast child, translation.clone().add(child.getLocalTranslation()));
                }
            }
        }
    }
	
	override public function clone(newName:String, cloneMaterial:Bool = true, result:Spatial = null):Spatial
	{
		var quadClone:TerrainQuad = cast super.clone(newName, cloneMaterial, result);
        quadClone.name = name.toString();
        quadClone.size = size;
        quadClone.totalSize = totalSize;
        if (stepScale != null) 
		{
            quadClone.stepScale = stepScale.clone();
        }
        if (offset != null)
		{
            quadClone.offset = offset.clone();
        }
        quadClone.offsetAmount = offsetAmount;
        quadClone.quadrant = quadrant;
        //quadClone.lodCalculatorFactory = lodCalculatorFactory.clone();
        //quadClone.lodCalculator = lodCalculator.clone();
        
        var lodControlCloned:TerrainLodControl = cast this.getControl(TerrainLodControl);
        var lodControl:TerrainLodControl = cast quadClone.getControl(TerrainLodControl);
        
        if (lodControlCloned != null && !Std.is(getParent(), TerrainQuad))
		{
            //lodControlCloned.setLodCalculator(lodControl.getLodCalculator().clone());
        }
        var normalControl:NormalRecalcControl = cast getControl(NormalRecalcControl);
        if (normalControl != null)
            normalControl.setTerrain(this);

        return quadClone;
	}
	
	override function set_parent(value:Node):Node 
	{
		var result = super.set_parent(value);
		if (value == null)
		{
            // if the terrain is being detached
            clearCaches();
        }
		return result;
	}
    
    /**
     * Removes any cached references this terrain is holding, in particular
     * the TerrainPatch's neighbour references.
     * This is called automatically when the root terrainQuad is detached from
     * its parent or if setParent(null) is called.
     */
    public function clearCaches():Void
	{
		if (children != null)
		{
			var i:Int = children.length;
			while (--i >= 0)
			{
                var child:Spatial = children[i];
                if (Std.is(child, TerrainQuad))
				{
                    cast(child,TerrainQuad).clearCaches();
                } 
				else if (Std.is(child, TerrainPatch)) 
				{
                    cast(child,TerrainPatch).clearCaches();
                }
            }
        }
    }
    
    public function getMaxLod():Int 
	{
        if (maxLod < 0)
            maxLod = Std.int(Math.max(1, (Math.log(size-1)/Math.log(2)) -1)); // -1 forces our minimum of 4 triangles wide

        return maxLod;
    }

    public function getPatchSize():Int
	{
        return patchSize;
    }

    public function getTotalSize():Int
	{
        return totalSize;
    }

    public function getHeightMap():Vector<Float>
	{

        var hm:Vector<Float> = null;
        var length:Int = Std.int((size-1) / 2) + 1;
        var area:Int = size*size;
        hm = new Vector<Float>(area);

        if (this.numChildren != 0)
		{
            var ul:Vector<Float> = null, ur:Vector<Float> = null, bl:Vector<Float> = null, br:Vector<Float> = null;
            // get the child heightmaps
            if (Std.is(getChildAt(0), TerrainPatch))
			{
                for (s in children)
				{
                    if ( cast(s,TerrainPatch).getQuadrant() == 1)
                        ul = cast(s,TerrainPatch).getHeightMap();
                    else if(cast(s,TerrainPatch).getQuadrant() == 2)
                        bl = cast(s,TerrainPatch).getHeightMap();
                    else if(cast(s,TerrainPatch).getQuadrant() == 3)
                        ur = cast(s,TerrainPatch).getHeightMap();
                    else if(cast(s,TerrainPatch).getQuadrant() == 4)
                        br = cast(s,TerrainPatch).getHeightMap();
                }
            }
            else 
			{
                ul = getQuad(1).getHeightMap();
                bl = getQuad(2).getHeightMap();
                ur = getQuad(3).getHeightMap();
                br = getQuad(4).getHeightMap();
            }

            // combine them into a single heightmap


            // first upper blocks
            for (y in 0...length) // rows
			{ 
                for (x1 in 0...length)
				{
                    var row:Int = y * size;
                    hm[row + x1] = ul[y * length + x1];
                }
                for (x2 in 1...length)
				{
                    var row:Int = y*size + length;
                    hm[row+x2-1] = ur[y*length + x2];
                }
            }
            // second lower blocks
            var rowOffset:Int = size * length;
            for (y in 1...length)// rows
			{ 
                for (x1 in 0...length) 
				{
                    var row = (y - 1) * size;
                    hm[rowOffset + row + x1] = bl[y * length + x1];
                }
                for (x2 in 1...length)
				{
                    var row = (y - 1) * size + length;
                    hm[rowOffset + row + x2 - 1] = br[y * length + x2];
                }
            }
        }

        return hm;
    }
	
}

/**
 * Used for searching for a child and keeping
 * track of its quadrant
 */
class QuadrantChild
{
	public var col:Int;
	public var row:Int;
	public var child:Spatial;
	
	public function new(col:Int, row:Int, child:Spatial)
	{
		this.col = col;
		this.row = row;
		this.child = child;
	}
}

class LocationHeight 
{
	public var x:Int;
	public var z:Int;
	public var h:Float;

	public function new(x:Int, z:Int, h:Float)
	{
		this.x = x;
		this.z = z;
		this.h = h;
	}
}