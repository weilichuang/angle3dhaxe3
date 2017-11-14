package org.angle3d.terrain.geomipmap ;
import org.angle3d.bounding.BoundingBox;
import org.angle3d.bounding.BoundingSphere;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.collision.CollisionResults;

import org.angle3d.scene.RefreshFlag;
import haxe.ds.StringMap;
import org.angle3d.collision.Collidable;
import org.angle3d.math.Ray;
import org.angle3d.math.Triangle;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.BatchHint;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.utils.BufferUtils;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.mesh.VertexBuffer;
import org.angle3d.scene.Spatial;
import org.angle3d.terrain.geomipmap.lodcalc.util.EntropyComputeUtil;
import org.angle3d.terrain.geomipmap.TerrainQuad.LocationHeight;

/**
 * A terrain patch is a leaf in the terrain quad tree. It has a mesh that can change levels of detail (LOD)
 * whenever the view point, or camera, changes. The actual terrain mesh is created by the LODGeomap class.
 * That uses a geo-mipmapping algorithm to change the index buffer of the mesh.
 * The mesh is a triangle strip. In wireframe mode you might notice some strange lines, these are degenerate
 * triangles generated by the geoMipMap algorithm and can be ignored. The video card removes them at almost no cost.
 * 
 * Each patch needs to know its neighbour's LOD so it can seam its edges with them, in case the neighbour has a different
 * LOD. If this doesn't happen, you will see gaps.
 * 
 * The LOD value is most detailed at zero. It gets less detailed the higher the LOD value until you reach maxLod, which
 * is a mathematical limit on the number of times the 'size' of the patch can be divided by two. However there is a -1 to that
 * for now until I add in a custom index buffer calculation for that max level, the current algorithm does not go that far.
 * 
 * You can supply a LodThresholdCalculator for use in determining when the LOD should change. It's API will no doubt change 
 * in the near future. Right now it defaults to just changing LOD every two patch sizes. So if a patch has a size of 65, 
 * then the LOD changes every 130 units away.
 * 
 */
class TerrainPatch extends Geometry
{

	public var geomap:LODGeomap;
    public var lod:Int = 0; // this terrain patch's LOD
    private var maxLod:Int = -1;
    private var previousLod:Int = -1;
    private var lodLeft:Int;
	private var lodTop:Int;
	private var lodRight:Int;
	private var lodBottom:Int; // it's neighbour's LODs

    private var size:Int;

    private var totalSize:Int;

    private var quadrant:Int = 1;

    // x/z step
    private var stepScale:Vector3f;

    // center of the patch in relation to (0,0,0)
    private var offset:Vector2f;

    // amount the patch has been shifted.
    private var offsetAmount:Float;

    //private LodCalculator lodCalculator;
    //private LodCalculatorFactory lodCalculatorFactory;

    public var leftNeighbour:TerrainPatch;
	public var topNeighbour:TerrainPatch;
	public var rightNeighbour:TerrainPatch;
	public var bottomNeighbour:TerrainPatch;
    public var searchedForNeighboursAlready:Bool = false;

    // these two vectors are calculated on the GL thread, but used in the outside LOD thread
    private var worldTranslationCached:Vector3f;
    private var worldScaleCached:Vector3f;

    private var lodEntropy:Array<Float>;

    /**
     * Constructor instantiates a new `TerrainPatch` object. The
     * parameters and heightmap data are then processed to generate a
     * `TriMesh` object for renderering.
     *
     * @param name
     *			the name of the terrain patch.
     * @param size
     *			the size of the patch.
     * @param stepScale
     *			the scale for the axes.
     * @param heightMap
     *			the height data.
     * @param origin
     *			the origin offset of the patch.
     * @param totalSize
     *			the total size of the terrain. (Higher if the patch is part of
     *			a `TerrainQuad` tree.
     * @param offset
     *			the offset for texture coordinates.
     * @param offsetAmount
     *			the total offset amount. Used for texture coordinates.
     */
    public function new(name:String, size:Int, stepScale:Vector3f,
                    heightMap:Array<Float>, origin:Vector3f, totalSize:Int,
                    offset:Vector2f = null, offsetAmount:Float = 0)
	{
        super(name);
		
        setBatchHint(BatchHint.Never);
        this.size = size;
        this.stepScale = stepScale;
        this.totalSize = totalSize;
        this.offsetAmount = offsetAmount;
        this.offset = offset != null ? offset.clone() : new Vector2f(0, 0);

        setLocalTranslation(origin);

        geomap = new LODGeomap(heightMap, size, size);
        var m:Mesh = geomap.createLodMesh(stepScale, new Vector2f(1,1), offset, offsetAmount, totalSize, false);
        setMesh(m);

    }

    /**
     * This calculation is slow, so don't use it often.
     */
    public function generateLodEntropies():Void
	{
        var entropies:Array<Float> = new Array<Float>(getMaxLod() + 1);
        for (i in 0...(getMaxLod() + 1))
		{
            var curLod:Int = Std.int(Math.pow(2, i));
            var idxB:Array<UInt> = geomap.writeIndexArrayLodDiff(curLod, false, false, false, false, totalSize);
            entropies[i] = EntropyComputeUtil.computeLodEntropy(mMesh, idxB);
        }

        lodEntropy = entropies;
    }

    public function getLodEntropies():Array<Float>
	{
        if (lodEntropy == null)
		{
            generateLodEntropies();
        }
        return lodEntropy;
    }

    public function getHeightMap():Array<Float>
	{
        return geomap.getHeightArray();
    }

    /**
     * The maximum lod supported by this terrain patch.
     * If the patch size is 32 then the returned value would be log2(32)-2 = 3
     * You can then use that value, 3, to see how many times you can divide 32 by 2
     * before the terrain gets too un-detailed (can't stitch it any further).
     * @return the maximum LOD
     */
    public function getMaxLod():Int
	{
        if (maxLod < 0)
            maxLod = Std.int(Math.max(1, (Math.log(size-1) / Math.log(2)) -1)); // -1 forces our minimum of 4 triangles wide

        return maxLod;
    }

    public function reIndexGeometry(updated:StringMap<UpdatedTerrainPatch>, useVariableLod:Bool):Void
	{

        var utp:UpdatedTerrainPatch = updated.get(this.name);

        if (utp != null && utp.isReIndexNeeded() )
		{
            var pow:Int = Std.int(Math.pow(2, utp.getNewLod()));
            var left:Bool = utp.getLeftLod() > utp.getNewLod();
            var top:Bool = utp.getTopLod() > utp.getNewLod();
            var right:Bool = utp.getRightLod() > utp.getNewLod();
            var bottom:Bool = utp.getBottomLod() > utp.getNewLod();

            var idxB:Array<UInt>;
            if (useVariableLod)
                idxB = geomap.writeIndexArrayLodVariable(pow, Std.int(Math.pow(2, utp.getRightLod())), Std.int(Math.pow(2, utp.getTopLod())), Std.int( Math.pow(2, utp.getLeftLod())), Std.int(Math.pow(2, utp.getBottomLod())), totalSize);
            else
                idxB = geomap.writeIndexArrayLodDiff(pow, right, top, left, bottom, totalSize);
            
            utp.setNewIndexBuffer(idxB);
        }

    }


    public function getTex(x:Float, z:Float, store:Vector2f):Vector2f 
	{
        if (x < 0 || z < 0 || x >= size || z >= size) 
		{
            store.setTo(0, 0);
            return store;
        }
		var texCoords:Array<Float> = getMesh().getVertexBuffer(BufferType.TEXCOORD).getData();
		
        var idx:Int = Std.int(z * size + x);
        return store.setTo(texCoords[idx * 2], texCoords[idx * 2 + 1]);
    }
    
    public function getHeightmapHeight(x:Float, z:Float):Float
	{
        if (x < 0 || z < 0 || x >= size || z >= size)
            return 0;
		
		var positions:Array<Float> = getMesh().getVertexBuffer(BufferType.POSITION).getData();
			
        var idx:Int = Std.int(z * size + x);
        return positions[idx * 3 + 1];// 3 floats per entry (x,y,z), the +1 is to get the Y
    }
    
    /**
     * Get the triangle of this geometry at the specified local coordinate.
     * @param x local to the terrain patch
     * @param z local to the terrain patch
     * @return the triangle in world coordinates, or null if the point does intersect this patch on the XZ axis
     */
    public function getTriangle(x:Float, z:Float):Triangle
	{
        return geomap.getTriangleAtPointScaleAndTranslation(x, z, getWorldScale() , getWorldTranslation());
    }

    /**
     * Get the triangles at the specified grid point. Probably only 2 triangles
     * @param x local to the terrain patch
     * @param z local to the terrain patch
     * @return the triangles in world coordinates, or null if the point does intersect this patch on the XZ axis
     */
    public function getGridTriangles(x:Float, z:Float):Array<Triangle>
	{
        return geomap.getGridTrianglesAtPointScaleAndTranslation(x, z, getWorldScale() , getWorldTranslation());
    }

    public function setHeight(locationHeights:Array<LocationHeight>, overrideHeight:Bool):Void
	{
        for (lh in locationHeights) 
		{
            if (lh.x < 0 || lh.z < 0 || lh.x >= size || lh.z >= size)
                continue;
				
            var idx:Int = lh.z * size + lh.x;
            if (overrideHeight)
			{
                geomap.getHeightArray()[idx] = lh.h;
            } 
			else 
			{
                var h:Float = getMesh().getVertexBuffer(BufferType.POSITION).getData()[idx * 3 + 1];
                geomap.getHeightArray()[idx] = h + lh.h;
            }
            
        }

        var newVertexBuffer:Array<Float> = geomap.writeVertexArray(null, stepScale, false);
		//getMesh().clearBuffer(BufferType.POSITION);
        getMesh().setVertexBuffer(BufferType.POSITION, 3, newVertexBuffer);
    }

    /**
     * recalculate all of the normal vectors in this terrain patch
     */
    public function updateNormals():Void
	{
        var newNormalBuffer:Array<Float> = geomap.writeNormalArray(null, getWorldScale());
        getMesh().getVertexBuffer(BufferType.NORMAL).updateData(newNormalBuffer);
        var newTangentBuffer:Array<Float> = null;
        var newBinormalBuffer:Array<Float> = null;
        var tb:Array<Array<Float>> = geomap.writeTangentArray(newNormalBuffer, newTangentBuffer, newBinormalBuffer, getMesh().getVertexBuffer(BufferType.TEXCOORD).getData(), getWorldScale());
        newTangentBuffer = tb[0];
        newBinormalBuffer = tb[1];
        getMesh().getVertexBuffer(BufferType.TANGENT).updateData(newTangentBuffer);
        getMesh().getVertexBuffer(BufferType.BINORMAL).updateData(newBinormalBuffer);
    }

    private function setInBuffer(mesh:Mesh, index:Int, normal:Vector3f, tangent:Vector3f, binormal:Vector3f):Void
	{
        var NB:VertexBuffer = mesh.getVertexBuffer(BufferType.NORMAL);
        var TB:VertexBuffer = mesh.getVertexBuffer(BufferType.TANGENT);
        var BB:VertexBuffer = mesh.getVertexBuffer(BufferType.BINORMAL);
        BufferUtils.setInBuffer(normal, NB.getData(), index);
        BufferUtils.setInBuffer(tangent, TB.getData(), index);
        BufferUtils.setInBuffer(binormal, BB.getData(), index);
        NB.dirty = true;
        TB.dirty = true;
        BB.dirty = true;
    }
    
    /**
     * Matches the normals along the edge of the patch with the neighbours.
     * Computes the normals for the right, bottom, left, and top edges of the
     * patch, and saves those normals in the neighbour's edges too.
     *
     * Takes 4 points (if has neighbour on that side) for each
     * point on the edge of the patch:
     *              *
     *              |
     *          *---x---*
     *              |
     *              *
     * It works across the right side of the patch, from the top down to 
     * the bottom. Then it works on the bottom side of the patch, from the
     * left to the right.
     */
    public function fixNormalEdges(right:TerrainPatch,
									bottom:TerrainPatch,
									 top:TerrainPatch,
									 left:TerrainPatch,
									 bottomRight:TerrainPatch,
									 bottomLeft:TerrainPatch,
									 topRight:TerrainPatch,
									 topLeft:TerrainPatch):Void
    {
        var rootPoint:Vector3f = new Vector3f();
        var rightPoint:Vector3f = new Vector3f();
        var leftPoint:Vector3f = new Vector3f();
        var topPoint:Vector3f = new Vector3f();

        var bottomPoint:Vector3f = new Vector3f();

        var tangent:Vector3f = new Vector3f();
        var binormal:Vector3f = new Vector3f();
        var normal:Vector3f = new Vector3f();

        
        var s:Int = this.getSize() - 1;
        
        if (right != null) // right side,    works its way down
		{ 
            for (i in 0...(s + 1))
			{
                rootPoint.setTo(0, this.getHeightmapHeight(s,i), 0);
                leftPoint.setTo(-1, this.getHeightmapHeight(s-1,i), 0);
                rightPoint.setTo(1, right.getHeightmapHeight(1,i), 0);

                if (i == 0)  // top point
				{
                    bottomPoint.setTo(0, this.getHeightmapHeight(s,i+1), 1);
                    
                    if (top == null) 
					{
                        averageNormalsTangents(null, rootPoint, leftPoint, bottomPoint, rightPoint,  normal, tangent, binormal);
                        setInBuffer(this.getMesh(), s, normal, tangent, binormal);
                        setInBuffer(right.getMesh(), 0, normal, tangent, binormal);
                    } 
					else 
					{
                        topPoint.setTo(0, top.getHeightmapHeight(s,s-1), -1);
                        
                        averageNormalsTangents(topPoint, rootPoint, leftPoint, bottomPoint, rightPoint,normal, tangent, binormal);
                        setInBuffer(this.getMesh(), s, normal, tangent, binormal);
                        setInBuffer(right.getMesh(), 0, normal, tangent, binormal);
                        setInBuffer(top.getMesh(), (s+1)*(s+1)-1, normal, tangent, binormal);
                        
                        if (topRight != null)
						{
                    //        setInBuffer(topRight.getMesh(), (s+1)*s, normal, tangent, binormal);
                        }
                    }
                } 
				else if (i == s) // bottom point
				{ 
                    topPoint.setTo(0, this.getHeightmapHeight(s,s-1), -1);
                    
                    if (bottom == null) 
					{
                        averageNormalsTangents(topPoint, rootPoint, leftPoint, null, rightPoint, normal, tangent, binormal);
                        setInBuffer(this.getMesh(), (s+1)*(s+1)-1, normal, tangent, binormal);
                        setInBuffer(right.getMesh(), (s+1)*(s), normal, tangent, binormal);
                    } 
					else
					{
                        bottomPoint.setTo(0, bottom.getHeightmapHeight(s,1), 1);
                        averageNormalsTangents(topPoint, rootPoint, leftPoint, bottomPoint, rightPoint, normal, tangent, binormal);
                        setInBuffer(this.getMesh(), (s+1)*(s+1)-1, normal, tangent, binormal);
                        setInBuffer(right.getMesh(), (s+1)*s, normal, tangent, binormal);
                        setInBuffer(bottom.getMesh(), s, normal, tangent, binormal);
                        
                        if (bottomRight != null) 
						{
                   //         setInBuffer(bottomRight.getMesh(), 0, normal, tangent, binormal);
                        }
                    }
                } 
				else  // all in the middle
				{
                    topPoint.setTo(0, this.getHeightmapHeight(s,i-1), -1);
                    bottomPoint.setTo(0, this.getHeightmapHeight(s,i+1), 1);
                    averageNormalsTangents(topPoint, rootPoint, leftPoint, bottomPoint, rightPoint, normal, tangent, binormal);
                    setInBuffer(this.getMesh(), (s+1)*(i+1)-1, normal, tangent, binormal);
                    setInBuffer(right.getMesh(), (s+1)*(i), normal, tangent, binormal);
                }
            }
        }

        if (left != null) // left side,    works its way down
		{ 
            for (i in 0...(s + 1)) 
			{
                rootPoint.setTo(0, this.getHeightmapHeight(0,i), 0);
                leftPoint.setTo(-1, left.getHeightmapHeight(s-1,i), 0);
                rightPoint.setTo(1, this.getHeightmapHeight(1,i), 0);
                
                if (i == 0) // top point
				{ 
                    bottomPoint.setTo(0, this.getHeightmapHeight(0,i+1), 1);
                    
                    if (top == null)
					{
                        averageNormalsTangents(null, rootPoint, leftPoint, bottomPoint, rightPoint, normal, tangent, binormal);
                        setInBuffer(this.getMesh(), 0, normal, tangent, binormal);
                        setInBuffer(left.getMesh(), s, normal, tangent, binormal);
                    } 
					else
					{
                        topPoint.setTo(0, top.getHeightmapHeight(0,s-1), -1);
                        
                        averageNormalsTangents(topPoint, rootPoint, leftPoint, bottomPoint, rightPoint, normal, tangent, binormal);
                        setInBuffer(this.getMesh(), 0, normal, tangent, binormal);
                        setInBuffer(left.getMesh(), s, normal, tangent, binormal);
                        setInBuffer(top.getMesh(), (s+1)*s, normal, tangent, binormal);
                        
                        if (topLeft != null) {
                     //       setInBuffer(topLeft.getMesh(), (s+1)*(s+1)-1, normal, tangent, binormal);
                        }
                    }
                } 
				else if (i == s) // bottom point
				{ 
                    topPoint.setTo(0, this.getHeightmapHeight(0,i-1), -1);
                    
                    if (bottom == null)
					{
                        averageNormalsTangents(topPoint, rootPoint, leftPoint, null, rightPoint, normal, tangent, binormal);
                        setInBuffer(this.getMesh(), (s+1)*(s), normal, tangent, binormal);
                        setInBuffer(left.getMesh(), (s+1)*(s+1)-1, normal, tangent, binormal);
                    } 
					else
					{
                        bottomPoint.setTo(0, bottom.getHeightmapHeight(0,1), 1);
                        
                        averageNormalsTangents(topPoint, rootPoint, leftPoint, bottomPoint, rightPoint, normal, tangent, binormal);
                        setInBuffer(this.getMesh(), (s+1)*(s), normal, tangent, binormal);
                        setInBuffer(left.getMesh(), (s+1)*(s+1)-1, normal, tangent, binormal);
                        setInBuffer(bottom.getMesh(), 0, normal, tangent, binormal);
                        
                        if (bottomLeft != null) {
                     //       setInBuffer(bottomLeft.getMesh(), s, normal, tangent, binormal);
                        }
                    }
                }
				else // all in the middle
				{ 
                    topPoint.setTo(0, this.getHeightmapHeight(0,i-1), -1);
                    bottomPoint.setTo(0, this.getHeightmapHeight(0,i+1), 1);
                    
                    averageNormalsTangents(topPoint, rootPoint, leftPoint, bottomPoint, rightPoint, normal, tangent, binormal);
                    setInBuffer(this.getMesh(), (s+1)*(i), normal, tangent, binormal);
                    setInBuffer(left.getMesh(), (s+1)*(i+1)-1, normal, tangent, binormal);
                }
            }
        }

        if (top != null) // top side,    works its way right
		{ 
            for (i in 0...(s + 1))
			{
                rootPoint.setTo(0, this.getHeightmapHeight(i,0), 0);
                topPoint.setTo(0, top.getHeightmapHeight(i,s-1), -1);
                bottomPoint.setTo(0, this.getHeightmapHeight(i,1), 1);
                
                if (i == 0) // left corner
				{ 
                    // handled by left side pass
                    
                } else if (i == s) // right corner
				{ 
                    
                    // handled by this patch when it does its right side
                    
                }
				else // all in the middle
				{ 
                    leftPoint.setTo(-1, this.getHeightmapHeight(i-1,0), 0);
                    rightPoint.setTo(1, this.getHeightmapHeight(i+1,0), 0);
                    averageNormalsTangents(topPoint, rootPoint, leftPoint, bottomPoint, rightPoint, normal, tangent, binormal);
                    setInBuffer(this.getMesh(), i, normal, tangent, binormal);
                    setInBuffer(top.getMesh(), (s+1)*(s)+i, normal, tangent, binormal);
                }
            }
            
        }
        
        if (bottom != null) // bottom side,    works its way right
		{ 
            for (i in 0...(s + 1))
			{
                rootPoint.setTo(0, this.getHeightmapHeight(i,s), 0);
                topPoint.setTo(0, this.getHeightmapHeight(i,s-1), -1);
                bottomPoint.setTo(0, bottom.getHeightmapHeight(i,1), 1);

                if (i == 0) // left
				{ 
                    // handled by the left side pass
                    
                } 
				else if (i == s) // right
				{ 
                    
                    // handled by the right side pass
                    
                }
				else  // all in the middle
				{
                    leftPoint.setTo(-1, this.getHeightmapHeight(i-1,s), 0);
                    rightPoint.setTo(1, this.getHeightmapHeight(i+1,s), 0);
                    averageNormalsTangents(topPoint, rootPoint, leftPoint, bottomPoint, rightPoint, normal, tangent, binormal);
                    setInBuffer(this.getMesh(), (s+1)*(s)+i, normal, tangent, binormal);
                    setInBuffer(bottom.getMesh(), i, normal, tangent, binormal);
                }
            }
            
        }
    }

    public function averageNormalsTangents(
											 topPoint:Vector3f,
											 rootPoint:Vector3f,
											 leftPoint:Vector3f, 
											 bottomPoint:Vector3f, 
											 rightPoint:Vector3f,
											 normal:Vector3f,
											 tangent:Vector3f,
											 binormal:Vector3f):Void
    {
        var scale:Vector3f = getWorldScale();
        
        var n1:Vector3f = new Vector3f(0,0,0);
        if (topPoint != null && leftPoint != null)
		{
            n1.copyFrom(calculateNormal(topPoint.mult(scale), rootPoint.mult(scale), leftPoint.mult(scale)));
        }
        var n2:Vector3f = new Vector3f(0,0,0);
        if (leftPoint != null && bottomPoint != null) 
		{
            n2.copyFrom(calculateNormal(leftPoint.mult(scale), rootPoint.mult(scale), bottomPoint.mult(scale)));
        }
        var n3:Vector3f = new Vector3f(0,0,0);
        if (rightPoint != null && bottomPoint != null)
		{
            n3.copyFrom(calculateNormal(bottomPoint.mult(scale), rootPoint.mult(scale), rightPoint.mult(scale)));
        }
        var n4:Vector3f = new Vector3f(0,0,0);
        if (rightPoint != null && topPoint != null)
		{
            n4.copyFrom(calculateNormal(rightPoint.mult(scale), rootPoint.mult(scale), topPoint.mult(scale)));
        }
        
        //if (bottomPoint != null && rightPoint != null && rootTex != null && rightTex != null && bottomTex != null)
        //    LODGeomap.calculateTangent(new Vector3f[]{rootPoint.mult(scale),rightPoint.mult(scale),bottomPoint.mult(scale)}, new Vector2f[]{rootTex,rightTex,bottomTex}, tangent, binormal);

        normal.copyFrom(n1.add(n2).add(n3).add(n4).normalize());
        
        tangent.copyFrom(normal.cross(new Vector3f(0,0,1)).normalize());
        binormal.copyFrom(new Vector3f(1,0,0).cross(normal).normalize());
    }

    public function calculateNormal(firstPoint:Vector3f, rootPoint:Vector3f, secondPoint:Vector3f):Vector3f
	{
        var normal:Vector3f = new Vector3f();
        normal.copyFrom(firstPoint).subtractLocal(rootPoint)
                  .crossLocal(secondPoint.subtract(rootPoint)).normalizeLocal();
        return normal;
    }
    
    public function getMeshNormal(x:Int, z:Int):Vector3f
	{
        if (x >= size || z >= size)
            return null; // out of range
        
        var index:Int = (z*size+x)*3;
        var nb:Array<Float> = this.getMesh().getVertexBuffer(BufferType.NORMAL).getData();
        var normal:Vector3f = new Vector3f();
        normal.x = nb[index];
        normal.y = nb[index+1];
        normal.z = nb[index+2];
        return normal;
    }

    public function getHeightXZM(x:Int, z:Int, xm:Float, zm:Float):Float
	{
        return geomap.getHeightXZ(x, z, xm, zm);
    }
    
    /**
     * Locks the mesh (sets it static) to improve performance.
     * But it it not editable then. Set unlock to make it editable.
     */
    public function lockMesh():Void
	{
        getMesh().setStatic();
    }

    /**
     * Unlocks the mesh (sets it dynamic) to make it editable.
     * It will be editable but performance will be reduced.
     * Call lockMesh to improve performance.
     */
    public function unlockMesh():Void
	{
        getMesh().setDynamic();
    }
	
    /**
     * Returns the offset amount this terrain patch uses for textures.
     *
     * @return The current offset amount.
     */
    public function getOffsetAmount():Float
	{
        return offsetAmount;
    }

    /**
     * Returns the step scale that stretches the height map.
     *
     * @return The current step scale.
     */
    public function getStepScale():Vector3f 
	{
        return stepScale;
    }

    /**
     * Returns the total size of the terrain.
     *
     * @return The terrain's total size.
     */
    public function getTotalSize():Int
	{
        return totalSize;
    }

    /**
     * Returns the size of this terrain patch.
     *
     * @return The current patch size.
     */
    public function getSize():Int
	{
        return size;
    }

    /**
     * Returns the current offset amount. This is used when building texture
     * coordinates.
     *
     * @return The current offset amount.
     */
    public function getOffset():Vector2f
	{
        return offset;
    }

    /**
     * Sets the value for the current offset amount to use when building texture
     * coordinates. Note that this does <b>NOT </b> rebuild the terrain at all.
     * This is mostly used for outside constructors of terrain patches.
     *
     * @param offset
     *			The new texture offset.
     */
    public function setOffset(offset:Vector2f):Void
	{
        this.offset = offset;
    }

    /**
     * Sets the size of this terrain patch. Note that this does <b>NOT </b>
     * rebuild the terrain at all. This is mostly used for outside constructors
     * of terrain patches.
     *
     * @param size
     *			The new size.
     */
    public function setSize(size:Int):Void
	{
        this.size = size;

        maxLod = -1; // reset it
    }

    /**
     * Sets the total size of the terrain . Note that this does <b>NOT </b>
     * rebuild the terrain at all. This is mostly used for outside constructors
     * of terrain patches.
     *
     * @param totalSize
     *			The new total size.
     */
    public function setTotalSize(totalSize:Int):Void
	{
        this.totalSize = totalSize;
    }

    /**
     * Sets the step scale of this terrain patch's height map. Note that this
     * does <b>NOT </b> rebuild the terrain at all. This is mostly used for
     * outside constructors of terrain patches.
     *
     * @param stepScale
     *			The new step scale.
     */
    public function setStepScale(stepScale:Vector3f):Void 
	{
        this.stepScale = stepScale;
    }

    /**
     * Sets the offset of this terrain texture map. Note that this does <b>NOT
     * </b> rebuild the terrain at all. This is mostly used for outside
     * constructors of terrain patches.
     *
     * @param offsetAmount
     *			The new texture offset.
     */
    public function setOffsetAmount(offsetAmount:Float):Void 
	{
        this.offsetAmount = offsetAmount;
    }

    /**
     * @return Returns the quadrant.
     */
    public function getQuadrant():Int
	{
        return quadrant;
    }

    /**
     * @param quadrant
     *			The quadrant to set.
     */
    public function setQuadrant(quadrant:Int):Void 
	{
        this.quadrant = quadrant;
    }

    public function getLod():Int
	{
        return lod;
    }

    public function setLod(lod:Int):Void
	{
        this.lod = lod;
    }

    public function getPreviousLod():Int
	{
        return previousLod;
    }

    public function setPreviousLod(previousLod:Int):Void
	{
        this.previousLod = previousLod;
    }

    public function getLodLeft():Int
	{
        return lodLeft;
    }

    public function setLodLeft(lodLeft:Int):Void 
	{
        this.lodLeft = lodLeft;
    }

    public function getLodTop():Int
	{
        return lodTop;
    }

    public function setLodTop(lodTop:Int):Void 
	{
        this.lodTop = lodTop;
    }

    public function getLodRight():Int
	{
        return lodRight;
    }

    public function setLodRight(lodRight:Int):Void
	{
        this.lodRight = lodRight;
    }

    public function getLodBottom():Int
	{
        return lodBottom;
    }

    public function setLodBottom(lodBottom:Int):Void
	{
        this.lodBottom = lodBottom;
    }
    
    /*public void setLodCalculator(LodCalculatorFactory lodCalculatorFactory) {
        this.lodCalculatorFactory = lodCalculatorFactory;
        setLodCalculator(lodCalculatorFactory.createCalculator(this));
    }*/
	
	override public function collideWith(other:Collidable, results:CollisionResults):Int 
	{
		if (refreshFlags != RefreshFlag.NONE)
            throw "Scene graph must be updated" +
                                            " before checking collision";

        if (Std.is(other,BoundingVolume))
            if (!getWorldBound().intersects(cast other))
                return 0;
        
        if(Std.is(other,Ray))
            return collideWithRay(cast other, results);
        else if (Std.is(other,BoundingVolume))
            return collideWithBoundingVolume(cast other, results);
        else 
		{
            throw "TerrainPatch cannnot collide with " + Std.string(other);
        }
	}


    private function collideWithRay(ray:Ray, results:CollisionResults):Int
	{
        // This should be handled in the root terrain quad
        return 0;
    }

    private function collideWithBoundingVolume(boundingVolume:BoundingVolume, results:CollisionResults):Int 
	{
        if (Std.is(boundingVolume,BoundingBox))
            return collideWithBoundingBox(cast boundingVolume, results);
        else if (Std.is(boundingVolume, BoundingSphere))
		{
            var sphere:BoundingSphere = cast boundingVolume;
            var bbox:BoundingBox = new BoundingBox(boundingVolume.getCenter().clone(), new Vector3f(sphere.radius,
                                                           sphere.radius,
                                                           sphere.radius));
            return collideWithBoundingBox(bbox, results);
        }
        return 0;
    }

    private function worldCoordinateToLocal(loc:Vector3f):Vector3f
	{
        var translated:Vector3f = new Vector3f();
        translated.x = loc.x/getWorldScale().x - getWorldTranslation().x;
        translated.y = loc.y/getWorldScale().y - getWorldTranslation().y;
        translated.z = loc.z/getWorldScale().z - getWorldTranslation().z;
        return translated;
    }

    /**
     * This most definitely is not optimized.
     */
    private function collideWithBoundingBox(bbox:BoundingBox, results:CollisionResults):Int 
	{
        
        // test the four corners, for cases where the bbox dimensions are less than the terrain grid size, which is probably most of the time
        var topLeft:Vector3f = worldCoordinateToLocal(new Vector3f(bbox.getCenter().x-bbox.xExtent, 0, bbox.getCenter().z-bbox.zExtent));
        var topRight:Vector3f = worldCoordinateToLocal(new Vector3f(bbox.getCenter().x+bbox.xExtent, 0, bbox.getCenter().z-bbox.zExtent));
        var bottomLeft:Vector3f = worldCoordinateToLocal(new Vector3f(bbox.getCenter().x-bbox.xExtent, 0, bbox.getCenter().z+bbox.zExtent));
        var bottomRight:Vector3f = worldCoordinateToLocal(new Vector3f(bbox.getCenter().x+bbox.xExtent, 0, bbox.getCenter().z+bbox.zExtent));

        var t:Triangle = getTriangle(topLeft.x, topLeft.z);
        if (t != null && bbox.collideWith(t, results) > 0)
            return 1;
        t = getTriangle(topRight.x, topRight.z);
        if (t != null && bbox.collideWith(t, results) > 0)
            return 1;
        t = getTriangle(bottomLeft.x, bottomLeft.z);
        if (t != null && bbox.collideWith(t, results) > 0)
            return 1;
        t = getTriangle(bottomRight.x, bottomRight.z);
        if (t != null && bbox.collideWith(t, results) > 0)
            return 1;
        
        // box is larger than the points on the terrain, so test against the points
		var z:Float = topLeft.z;
        while (z < bottomLeft.z)
		{
			var x:Float = topLeft.x;
            while ( x < topRight.x)
			{
                
                if (x < 0 || z < 0 || x >= size || z >= size)
				{
					x += 1;
                    continue;
				}
				
                t = getTriangle(x,z);
                if (t != null && bbox.collideWith(t, results) > 0)
                    return 1;
					
				x += 1;
            }
			
			z += 1;
        }

        return 0;
    }
	
	override public function clone(newName:String, cloneMaterial:Bool = true, result:Spatial = null):Spatial 
	{
		return super.clone(newName, cloneMaterial, result);
		
		//var clone:TerrainPatch = new TerrainPatch();
        //clone.name = name.toString();
        //clone.size = size;
        //clone.totalSize = totalSize;
        //clone.quadrant = quadrant;
        //clone.stepScale = stepScale.clone();
        //clone.offset = offset.clone();
        //clone.offsetAmount = offsetAmount;
        ////clone.lodCalculator = lodCalculator.clone();
        ////clone.lodCalculator.setTerrainPatch(clone);
        ////clone.setLodCalculator(lodCalculatorFactory.clone());
        //clone.geomap = new LODGeomap(size, geomap.getHeightArray());
        //clone.setLocalTranslation(getLocalTranslation().clone());
        //var m:Mesh = clone.geomap.createMesh(clone.stepScale, Vector2f.UNIT_XY, clone.offset, clone.offsetAmount, clone.totalSize, false);
        //clone.setMesh(m);
        //clone.setMaterial(material.clone());
        //return clone;
	}
	
    public function ensurePositiveVolumeBBox():Void 
	{
        if (Std.is(getModelBound(),BoundingBox))
		{
			var box:BoundingBox = cast getModelBound();
			
            if (box.yExtent < 0.001) 
			{
                // a correction so the box always has a volume
                box.yExtent = 0.001;
                updateWorldBound();
            }
        }
    }

    /**
     * Caches the transforms (except rotation) so the LOD calculator,
     * which runs on a separate thread, can access them safely.
     */
    public function cacheTerrainTransforms():Void
	{
        this.worldScaleCached = getWorldScale().clone();
        this.worldTranslationCached = getWorldTranslation().clone();
    }

    public function getWorldScaleCached():Vector3f
	{
        return worldScaleCached;
    }

    public function getWorldTranslationCached():Vector3f
	{
        return worldTranslationCached;
    }

    /**
     * Removes any references when the terrain is being removed.
     */
    public function clearCaches():Void
	{
        if (leftNeighbour != null)
		{
            leftNeighbour.rightNeighbour = null;
            leftNeighbour = null;
        }
        if (rightNeighbour != null)
		{
            rightNeighbour.leftNeighbour = null;
            rightNeighbour = null;
        }
        if (topNeighbour != null)
		{
            topNeighbour.bottomNeighbour = null;
            topNeighbour = null;
        }
        if (bottomNeighbour != null)
		{
            bottomNeighbour.topNeighbour = null;
            bottomNeighbour = null;
        }
    }
}