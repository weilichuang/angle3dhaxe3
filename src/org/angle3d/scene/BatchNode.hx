package org.angle3d.scene;
import org.angle3d.collision.CollisionResults;

import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import org.angle3d.collision.Collidable;
import haxe.ds.StringMap;
import org.angle3d.material.Material;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.mesh.VertexBuffer;
import org.angle3d.scene.Spatial;
import org.angle3d.error.Assert;
import org.angle3d.utils.Logger;
import org.angle3d.utils.TempVars;

//TODO 效率需要测试,估计得数量够多，才能显示出效果
/**
 * BatchNode holds geometries that are a batched version of all the geometries that are in its sub scenegraph.
 * There is one geometry per different material in the sub tree.
 * The geometries are directly attached to the node in the scene graph.
 * Usage is like any other node except you have to call the `batch()` method once all the geometries have been attached to the sub scene graph and their material set
 * (see todo more automagic for further enhancements)
 * All the geometries that have been batched are set to not be rendered - `CullHint` is left intact.
 * The sub geometries can be transformed as usual, their transforms are used to update the mesh of the geometryBatch.
 * Sub geoms can be removed but it may be slower than the normal spatial removing
 * Sub geoms can be added after the batch() method has been called but won't be batched and will just be rendered as normal geometries.
 * To integrate them in the batch you have to call the batch() method again on the batchNode.
 * 
 * TODO normal or tangents or both looks a bit weird
 * TODO more automagic (batch when needed in the updateLogicalState)
 */
class BatchNode extends GeometryGroupNode
{
	/**
     * the list of geometry holding the batched meshes
     */
	private var batches:Array<Batch> = [];
	
	/**
     * a map for storing the batches by geometry to quickly access the batch when updating
     */
	private var batchesByGeom:ObjectMap<Geometry,Batch> = new ObjectMap<Geometry,Batch>();
	
	/**
     * used to store transformed vectors before proceeding to a bulk put into the FloatBuffer 
     */
    private var tmpFloat:Vector<Float>;
    private var tmpFloatN:Vector<Float>;
    private var tmpFloatT:Vector<Float>;
	
    private var maxVertCount:Int = 0;
    private var useTangents:Bool = false;
    private var needsFullRebatch:Bool = true;

	public function new(name:String) 
	{
		super(name);
		
		tmpFloat = new Vector<Float>();
		tmpFloatN = new Vector<Float>();
		tmpFloatT = new Vector<Float>();
	}
	
	override public function onTransformChange(geom:Geometry):Void 
	{
		updateSubBatch(geom);
	}
	
	override public function onMaterialChange(geom:Geometry):Void 
	{
		Assert.assert(false,"Cannot set the material of a batched geometry, "
                + "change the material of the parent BatchNode.");
	}
	
	override public function onMeshChange(geom:Geometry):Void 
	{
		Assert.assert(false, "Cannot set the mesh of a batched geometry");
	}
	
	override public function onGeometryUnassociated(geom:Geometry):Void 
	{
		setNeedsFullRebatch(true);
	}
	
	private function updateSubBatch(bg:Geometry):Void
	{
		var batch:Batch = batchesByGeom.get(bg);
		if (batch != null)
		{
			var mesh:Mesh = batch.geometry.getMesh();
			var origMesh:Mesh = bg.getMesh();
			
			var pvb:VertexBuffer = mesh.getVertexBuffer(BufferType.POSITION);
			var posBuf:Vector<Float> = pvb.getData();
			var nvb:VertexBuffer = mesh.getVertexBuffer(BufferType.NORMAL);
			var normBuf:Vector<Float> = nvb.getData();
			
			var opvb:VertexBuffer = origMesh.getVertexBuffer(BufferType.POSITION);
			var oposBuf:Vector<Float> = opvb.getData();
			var onvb:VertexBuffer = origMesh.getVertexBuffer(BufferType.NORMAL);
			var onormBuf:Vector<Float> = onvb.getData();
			
			var transformMat:Matrix4f = getTransformMatrix(bg);
			
			if (mesh.getVertexBuffer(BufferType.TANGENT) != null)
			{
				var tvb:VertexBuffer = mesh.getVertexBuffer(BufferType.TANGENT);
				var tanBuf:Vector<Float> = tvb.getData();
				
				var otvb:VertexBuffer = origMesh.getVertexBuffer(BufferType.TANGENT);
				var otanBuf:Vector<Float> = otvb.getData();
				
				doTransformsTangents(oposBuf, onormBuf, otanBuf, posBuf, normBuf, tanBuf, bg.startIndex, bg.startIndex + bg.getVertexCount(), transformMat);
                tvb.updateData(tanBuf);
			}
			else
			{
				doTransforms(oposBuf, onormBuf, posBuf, normBuf, bg.startIndex, bg.startIndex + bg.getVertexCount(), transformMat);
			}
			
			pvb.updateData(posBuf);
            nvb.updateData(normBuf);
			
			batch.geometry.updateModelBound();
		}
	}
	
	/**
     * Batch this batchNode
     * every geometry of the sub scene graph of this node will be batched into a single mesh that will be rendered in one call
     */
	public function batch():Void
	{
		doBatch();
		
		//we set the batch geometries to ignore transforms to avoid transforms of parent nodes to be applied twice   
		for (i in 0...batches.length)
		{
			var batch:Batch = batches[i];
			batch.geometry.setIgnoreTransform(true);
			batch.geometry.setUserData(Spatial.USERDATA_PHYSICSIGNORE, true);
		}
	}
	
	private function doBatch():Void
	{
		var matMap:ObjectMap<Material, Array<Geometry>> = new ObjectMap<Material, Array<Geometry>>();
		
		var nbGeoms:Int = 0;
		gatherGeometries(matMap, this, needsFullRebatch);
		if (needsFullRebatch)
		{
			for (i in 0...batches.length)
			{
				var batch:Batch = batches[i];
				batch.geometry.removeFromParent();
			}
			batches = [];
			batchesByGeom = new ObjectMap<Geometry,Batch>();
		}
		
		//only reset maxVertCount if there is something new to batch
		if (!isMapEmpty(matMap))
		{
			maxVertCount = 0;
		}
		
		var keys = matMap.keys();
		for (key in keys)
		{
			var mesh:Mesh = new Mesh();
			var material:Material = cast key;
			var list:Array<Geometry> = matMap.get(key);
			
			nbGeoms += list.length;
			
			var batchName:String = name + "-batch" + batches.length;
			
			var batch:Batch;
			
			if (!needsFullRebatch)
			{
				batch = findBatchByMaterial(material);
                if (batch != null)
				{
					list.unshift(batch.geometry);
                    batchName = batch.geometry.name;
                    batch.geometry.removeFromParent();
                } 
				else
				{
                    batch = new Batch(this);
                }
			}
			else
			{
				batch = new Batch(this);
			}
			
			mergeGeometries(mesh, list);
			mesh.setDynamic();
			
			batch.updateGeomList(list);
			
			batch.geometry = new Geometry(batchName);
			batch.geometry.setMaterial(material);
			this.attachChild(batch.geometry);
			
			batch.geometry.setMesh(mesh);
			batch.geometry.getMesh().updateCounts();
			batch.geometry.getMesh().updateBound();
			batches.push(batch);
		}
		
		if (batches.length > 0)
		{
			needsFullRebatch = false;
		}
		
		#if debug
		Logger.log('Batched $nbGeoms geometries in ${batches.length} batches.');
		#end
		
		//init the temp arrays if something has been batched only.
		if (!isMapEmpty(matMap))
		{
			//TODO these arrays should be allocated by chunk instead to avoid recreating them each time the batch is changed.
            //init temp float arrays
			tmpFloat = new Vector<Float>(maxVertCount * 3);
			tmpFloatN = new Vector<Float>(maxVertCount * 3);
			if (useTangents)
				tmpFloatT = new Vector<Float>(maxVertCount * 4);
		}
	}
	
	override public function detachChildAt(index:Int):Spatial 
	{
		var s:Spatial = super.detachChildAt(index);
		if (Std.is(s, Node))
		{
			unbatchSubGraph(s);
		}
		return s;
	}
	
	/**
     * recursively visit the subgraph and unbatch geometries
     * @param s 
     */
    private function unbatchSubGraph(s:Spatial):Void
	{
        if (Std.is(s, Node))
		{
			var node:Node = cast s;
			for (i in 0...node.children.length)
			{
				var sp:Spatial = node.children[i];
				unbatchSubGraph(sp);
			}
        }
		else if (Std.is(s, Geometry))
		{
            var g:Geometry = cast s;
            if (g.isGrouped()) 
			{
                g.unassociateFromGroupNode();
            }
        }
    }
	
	private function isMapEmpty(map:ObjectMap<Material, Array<Geometry>>):Bool
	{
		return map.keys().hasNext();
	}
	
	private function gatherGeometries(map:ObjectMap<Material, Array<Geometry>>, n:Spatial, rebatch:Bool):Void
	{
		if (Std.is(n, Geometry))
		{
			var g:Geometry = cast n;
			if (!isBatch(n) && n.batchHint != BatchHint.Never)
			{
				if (!g.isGrouped() || rebatch)
				{
					var gm:Material = g.getMaterial();
					
					#if debug
					Assert.assert(gm != null, "No material is set for Geometry: " + g.name + " please set a material before batching");
					#end
					
					var list:Array<Geometry> = map.get(gm);
					if (list == null)
					{
						//trying to compare materials with the isEqual method 
						var keys = map.keys();
						for (key in keys)
						{
							if (gm.contentEquals(key))
							{
								list = map.get(key);
								break;
							}
						}
					}
					
					if (list == null)
					{
						list = [];
						map.set(gm, list);
					}
					
					g.setTransformRefresh();
					list.push(g);
				}
			}
		}
		else if (Std.is(n, Node))
		{
			var node:Node = cast n;
			for (i in 0...node.children.length)
			{
				var child:Spatial = node.children[i];
				if (Std.is(child, BatchNode))
				{
					continue;
				}
				
				gatherGeometries(map, child, rebatch);
			}
		}
	}
	
	private function findBatchByMaterial(m:Material):Batch
	{
		for (i in 0...batches.length)
		{
			var batch:Batch = batches[i];
			if (batch.geometry.getMaterial().contentEquals(m))
			{
				return batch;
			}
		}
		return null;
	}
	
	public function isBatch(s:Spatial):Bool
	{
		for (i in 0...batches.length)
		{
			var batch:Batch = batches[i];
			if (batch.geometry == s)
			{
				return true;
			}
		}
		return false;
	}
	
	override public function setMaterial(material:Material):Void 
	{
		Assert.assert(false, "Unsupported for now, please set the material on the geoms before batching");
	}
	
	public function getMaterial():Material
	{
		if (batches.length > 0)
		{
			return batches[0].geometry.getMaterial();
		}
		return null;
	}
	
	private function mergeGeometries(outMesh:Mesh, geometries:Array<Geometry>):Void
	{
		var compsForBuf:IntMap<Int> = new IntMap<Int>();
		
		var totalVerts:Int = 0;
		var totalTris:Int = 0;
		var totalLodLevels:Int = -1;
		
		for (i in 0...geometries.length)
		{
			var geom:Geometry = geometries[i];
			totalVerts += geom.getVertexCount();
			totalTris += geom.getTriangleCount();
			if (totalLodLevels == -1)
				totalLodLevels = geom.getMesh().getNumLodLevels();
			else
				totalLodLevels = FastMath.minInt(totalLodLevels, geom.getMesh().getNumLodLevels());
			
			if (maxVertCount < geom.getVertexCount())
			{
				maxVertCount = geom.getVertexCount();
			}
			
			//var components:Int = 3;
			
			var bufferList:Array<VertexBuffer> = geom.getMesh().getBufferList();
			for (buf in bufferList)
			{
				if (buf == null)
					continue;
					
				if (compsForBuf.exists(buf.type) && compsForBuf.get(buf.type) != buf.components)
				{
					throw "The geometry " + geom.name + " buffer " + buf.type
                            + " has different number of components than the rest of the meshes "
                            + "(this: " + buf.components + ", expected: " + compsForBuf.get(buf.type) + ")";
				}
				
				compsForBuf.set(buf.type,buf.components);
			}
			
		}
		
		if (totalVerts >= 65536)
		{
			throw "too much vertices";
		}
		
		var compKeys = compsForBuf.keys();
		for (key in compKeys)
		{
			outMesh.createVertexBuffer(key,compsForBuf.get(key));
		}
		
		var globalVertIndex:Int = 0;
		var globalTriIndex:Int = 0;
		
		var outIndices:Vector<UInt> = new Vector<UInt>();
		outMesh.setIndices(outIndices);
		
		for (i in 0...geometries.length)
		{
			var geom:Geometry = geometries[i];
			var inMesh:Mesh = geom.getMesh();
			if (!isBatch(geom))
			{
				geom.associateWithGroupNode(this, globalVertIndex);
			}
			
			var geomVertCount:Int = inMesh.getVertexCount();
			var geomTriCount:Int = inMesh.getTriangleCount();
			
			//indices
			var inIndices:Vector<UInt> = inMesh.getIndices();
			for (tri in 0...geomTriCount)
			{
				outIndices[(globalTriIndex + tri) * 3 + 0] = inIndices[tri * 3 + 0] + globalVertIndex;
				outIndices[(globalTriIndex + tri) * 3 + 1] = inIndices[tri * 3 + 1] + globalVertIndex;
				outIndices[(globalTriIndex + tri) * 3 + 2] = inIndices[tri * 3 + 2] + globalVertIndex;
			}
			
			//other
			var compKeys = compsForBuf.keys();
			for (bufType in compKeys)
			{
				var inBuff:VertexBuffer = inMesh.getVertexBuffer(bufType);
				var outBuff:VertexBuffer = outMesh.getVertexBuffer(bufType);
				
				if (outBuff == null)
				{
					continue;
				}
				
				var inPos:Vector<Float> = inBuff.getData();
				var outPos:Vector<Float>;
				if (outBuff.getData() == null)
				{
					outPos = new Vector<Float>();
					outBuff.updateData(outPos);
				}
				else
				{
					outPos = outBuff.getData();
				}
				
				doCopyBuffer(inPos, globalVertIndex, outPos, compsForBuf.get(bufType));
				
				if (bufType == BufferType.TANGENT)
				{
					useTangents = true;
				}
				
				outBuff.dirty = true;
			}
			
			globalVertIndex += geomVertCount;
            globalTriIndex += geomTriCount;
		}
	}
	
	private function doTransforms(bindBufPos:Vector<Float>, bindBufNorm:Vector<Float>, 
								bufPos:Vector<Float>, bufNorm:Vector<Float>, 
								start:Int, end:Int, transform:Matrix4f):Void
	{
        var tempVars:TempVars = TempVars.getTempVars();
        var pos:Vector3f = tempVars.vect1;
        var norm:Vector3f = tempVars.vect2;

        var length:Int = (end - start) * 3;

        // offset is given in element units
        // convert to be in component units
        var offset:Int = start * 3;
		
		for (i in 0...length)
		{
			tmpFloat[i] = bindBufPos[i];
			tmpFloatN[i] = bindBufNorm[i];
		}
		
        var index:Int = 0;
        while (index < length)
		{
            pos.x = tmpFloat[index];
            norm.x = tmpFloatN[index++];
			
            pos.y = tmpFloat[index];
            norm.y = tmpFloatN[index++];
			
            pos.z = tmpFloat[index];
            norm.z = tmpFloatN[index];

            transform.multVec(pos, pos);
            transform.multNormal(norm, norm);

            index -= 2;
            tmpFloat[index] = pos.x;
            tmpFloatN[index++] = norm.x;
            tmpFloat[index] = pos.y;
            tmpFloatN[index++] = norm.y;
            tmpFloat[index] = pos.z;
            tmpFloatN[index++] = norm.z;
        }
		
        tempVars.release();
		
		for (i in 0...length)
		{
			bufPos[offset + i] = tmpFloat[i];
			bufNorm[offset + i] = tmpFloatN[i];
		}
    }
	
	private function doTransformsTangents(bindBufPos:Vector<Float>, bindBufNorm:Vector<Float>, bindBufTangents:Vector<Float>,
										bufPos:Vector<Float>, bufNorm:Vector<Float>, bufTangents:Vector<Float>,
										start:Int, end:Int, transform:Matrix4f):Void
	{
		var tempVars:TempVars = TempVars.getTempVars();
        var pos:Vector3f = tempVars.vect1;
        var norm:Vector3f = tempVars.vect2;
		var tan:Vector3f = tempVars.vect3;

        var length:Int = (end - start) * 3;
		var tanLength:Int = (end - start) * 4;

        // offset is given in element units
        // convert to be in component units
        var offset:Int = start * 3;
		var tanOffset:Int = start * 4;
		
		for (i in 0...length)
		{
			tmpFloat[i] = bindBufPos[i];
			tmpFloatN[i] = bindBufNorm[i];
		}
		
		for (i in 0...tanLength)
		{
			tmpFloatT[i] = bindBufTangents[i];
		}
		
        var index:Int = 0;
		var tanIndex:Int = 0;
        while (index < length)
		{
            pos.x = tmpFloat[index];
            norm.x = tmpFloatN[index++];
			
            pos.y = tmpFloat[index];
            norm.y = tmpFloatN[index++];
			
            pos.z = tmpFloat[index];
            norm.z = tmpFloatN[index];
			
			tan.x = tmpFloatT[tanIndex++];
            tan.y = tmpFloatT[tanIndex++];
            tan.z = tmpFloatT[tanIndex++];

            transform.multVec(pos, pos);
            transform.multNormal(norm, norm);
			transform.multNormal(tan, tan);

            index -= 2;
			tanIndex -= 3;
			
            tmpFloat[index] = pos.x;
            tmpFloatN[index++] = norm.x;
            tmpFloat[index] = pos.y;
            tmpFloatN[index++] = norm.y;
            tmpFloat[index] = pos.z;
            tmpFloatN[index++] = norm.z;
			
			tmpFloatT[tanIndex++] = tan.x;
            tmpFloatT[tanIndex++] = tan.y;
            tmpFloatT[tanIndex++] = tan.z;
			
			//Skipping 4th element of tangent buffer (handedness)
            tanIndex++;
        }
		
        tempVars.release();
		
		for (i in 0...length)
		{
			bufPos[offset + i] = tmpFloat[i];
			bufNorm[offset + i] = tmpFloatN[i];
		}
		
		for (i in 0...tanLength)
		{
			bufTangents[tanOffset + i] = tmpFloatT[i];
		}
	}
	
	private function doCopyBuffer<T>(inBuff:Vector<T>, offset:Int, outBuff:Vector<T>, componentSize:Int):Void
	{
		// offset is given in element units
        // convert to be in component units
        offset *= componentSize;
		
		var count:Int = Std.int(inBuff.length / componentSize);
		for (i in 0...count)
		{
			var t:Int = i * componentSize;
			for (j in 0...componentSize)
			{
				outBuff[offset + t + j] = inBuff[t + j];
			}
		}
	}
	
	override public function clone(newName:String, cloneMaterial:Bool = true, result:Spatial = null):Spatial 
	{
		var batchNode:BatchNode;
		if (result == null)
		{
			batchNode = new BatchNode(newName);
		}
		else
		{
			batchNode = Std.instance(result, BatchNode);
		}
		
		batchNode = cast super.clone(newName, cloneMaterial, batchNode);
		
		for (i in 0...batches.length)
		{
			var batch:Batch = batches[i];
			for (j in 0...batchNode.children.length)
			{
				if (batchNode.children[j].name == batch.geometry.name)
				{
					batchNode.children.splice(j, 1);
					break;
				}
			}
		}
		
		batchNode.needsFullRebatch = true;
		batchNode.batches = [];
		batchNode.batchesByGeom = new ObjectMap<Geometry,Batch>();
		batchNode.batch();
		
		return batchNode;
	}
	
	private function setNeedsFullRebatch(needsFullRebatch:Bool):Void
	{
		this.needsFullRebatch = needsFullRebatch;
	}
	
	private function getTransformMatrix(g:Geometry):Matrix4f
	{
		return g.getCachedWorldMatrix();
	}
	
	public function addGeometryToBatch(geom:Geometry,batch:Batch):Void
	{
		batchesByGeom.set(geom, batch);
	}
	
	override public function collideWith(other:Collidable, results:CollisionResults):Int 
	{
		var total:Int = 0;
        for ( child in children)
		{
            if (!isBatch(child)) 
			{
                total += child.collideWith(other, results);
            }
        }
        return total;
	}
}

class Batch 
{
	public var batchNode:BatchNode;
	
	public var geometry:Geometry;
	
	public var needMeshUpdate:Bool = false;
	
	public function new(batchNode:BatchNode)
	{
		this.batchNode = batchNode;
	}
	/**
	 * update the batchesByGeom map for this batch with the given List of geometries
	 * @param list 
	 */
	public function updateGeomList(list:Array<Geometry>):Void
	{
		for (i in 0...list.length)
		{
			var geom:Geometry = list[i];
			if (!batchNode.isBatch(geom))
			{
				batchNode.addGeometryToBatch(geom, this);
			}
		}
	}
}