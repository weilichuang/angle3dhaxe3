package org.angle3d.scene;

import flash.Vector;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.collision.Collidable;
import org.angle3d.collision.CollisionResults;
import org.angle3d.material.Material;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.FrustumIntersect;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.scene.DFSMode;
import org.angle3d.scene.SceneGraphVisitor;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import de.polygonal.ds.error.Assert;
import org.angle3d.utils.Logger;
import org.angle3d.utils.TempVars;

/**
 * Geometry defines a leaf node of the scene graph. The leaf node
 * contains the geometric data for rendering objects. It manages all rendering
 * information such as a Material object to define how the surface
 * should be shaded and the Mesh data to contain the actual geometry.
 *
 */
class Geometry extends Spatial
{
	private var mMesh:Mesh;
	
	private var lodLevel:Int = 0;

	private var mMaterial:Material;

	/**
	* When true, the geometry's transform will not be applied.
	*/
	private var mIgnoreTransform:Bool = false;

	private var mCachedWorldMat:Matrix4f = new Matrix4f();
	
	public var groupNode:GeometryGroupNode;
	public var startIndex:Int = -1;

	public function new(name:String, mesh:Mesh = null)
	{
		super(name);
		
		// For backwards compatibility, only clear the "requires
        // update" flag if we are not a subclass of Node.
        // This prevents subclass from silently failing to receive
        // updates when they upgrade.
		setRequiresUpdates(Geometry != Type.getClass(this)); 

		setMesh(mesh);
	}
	
	public function getCachedWorldMatrix():Matrix4f
	{
		return mCachedWorldMat;
	}
	
	override public function checkCulling(cam:Camera):Bool 
	{
		if (isGrouped())
		{
			lastFrustumIntersection = FrustumIntersect.Outside;
			return false;
		}
		return super.checkCulling(cam);
	}

	/**
	 * 渲染时只使用本地坐标
	 * @return If ignoreTransform mode is set.
	 *
	 * @see Geometry#setIgnoreTransform(Bool)
	 */
	public inline function isIgnoreTransform():Bool
	{
		return mIgnoreTransform;
	}

	/**
	 * @param ignoreTransform If true, the geometry's transform will not be applied.
	 */
	public function setIgnoreTransform(value:Bool):Void
	{
		mIgnoreTransform = value;
	}
	
	override public function setLodLevel(lod:Int):Void 
	{
		#if debug
		if (mMesh.getNumLodLevels() == 0)
		{
			throw "LOD levels are not set on this mesh";
		}
		
		if (lod < 0 || lod >= mMesh.getNumLodLevels())
		{
            throw ("LOD level is out of range: " + lod);
        }
		#end

        lodLevel = lod;
        
        if (isGrouped())
		{
            groupNode.onMeshChange(this);
        }
	}

	public inline function getLodLevel():Int
	{
		return lodLevel;
	}
	
	override public function getVertexCount():Int 
	{
		return mMesh.getVertexCount();
	}
	
	override public function getTriangleCount():Int 
	{
		return mMesh.getTriangleCount(this.lodLevel);
	}
	
	/**
	 * Sets the mesh to use for this geometry when rendering.
	 *
	 * @param mesh the mesh to use for this geometry
	 *
	 */
	public function setMesh(mesh:Mesh):Void
	{
		if (mesh == null)
		{
			return;
		}

		this.mMesh = mesh;
		setBoundRefresh();
		
		if (isGrouped())
		{
            groupNode.onMeshChange(this);
        }
	}

	/**
	 * Returns the mseh to use for this geometry
	 *
	 * @return the mseh to use for this geometry
	 *
	 * @see setMesh(org.angle3d.scene.Mesh)
	 */
	public inline function getMesh():Mesh
	{
		return mMesh;
	}

	/**
	 * Sets the material to use for this geometry.
	 *
	 * @param material the material to use for this geometry
	 */
	override public function setMaterial(material:Material):Void
	{
		this.mMaterial = material;
		
		if (mMaterial.isTransparent())
		{
			localQueueBucket = QueueBucket.Transparent;
		}
		
		if (isGrouped())
		{
            groupNode.onMaterialChange(this);
        }
	}

	/**
	 * Returns the material that is used for this geometry.
	 *
	 * @return the material that is used for this geometry
	 *
	 * @see setMaterial(org.angle3d.material.Material)
	 */
	public inline function getMaterial():Material
	{
		return mMaterial;
	}

	/**
	 * @return The bounding volume of the mesh, in model space.
	 */
	public function getModelBound():BoundingVolume
	{
		return mMesh.getBound();
	}

	/**
	 * Updates the bounding volume of the mesh. Should be called when the
	 * mesh has been modified.
	 */
	override public function updateModelBound():Void
	{
		mMesh.updateBound();
		setBoundRefresh();
	}

	/**
	 * `updateWorldBound` updates the bounding volume that contains
	 * this geometry. The location of the geometry is based on the location of
	 * all this node's parents.
	 *
	 * @see org.angle3d.scene.Spatial#updateWorldBound()
	 */
	override public function updateWorldBound():Void
	{
		super.updateWorldBound();

		if (mMesh == null)
		{
			return;
		}

		var bound:BoundingVolume = mMesh.getBound();
		if (bound != null)
		{
			if (mIgnoreTransform)
			{
				// we do not transform the model bound by the world transform,
				// just use the model bound as-is
				mWorldBound = bound.clone(mWorldBound);
			}
			else
			{
				mWorldBound = bound.transform(mWorldTransform, mWorldBound);
			}
		}
	}

	override private function updateWorldTransforms():Void
	{
		super.updateWorldTransforms();

		computeWorldMatrix();
		
		if (isGrouped())
		{
            groupNode.onTransformChange(this);   
        }

		// geometry requires lights to be sorted
		//排序比较耗时，需要优化
		mWorldLights.sort(true);
	}
	
	public function associateWithGroupNode(node:GeometryGroupNode, startIndex:Int):Void
	{
		if (isGrouped())
		{
			unassociateFromGroupNode();
		}
		
		this.groupNode = node;
		this.startIndex = startIndex;
	}
	
	public function unassociateFromGroupNode():Void
	{
		if (groupNode != null) 
		{
            // Once the geometry is removed 
            // from the parent, the group node needs to be updated.
            groupNode.onGeoemtryUnassociated(this);
            groupNode = null;
            
            // change the default to -1 to make error detection easier
            startIndex = -1; 
        }
	}
	
	override private function set_parent(value:Node):Node 
	{
		// If the geometry is managed by group node we need to unassociate.
        if (value == null && isGrouped()) 
		{
            unassociateFromGroupNode();
        }
		
		return super.set_parent(value);
	}

	/**
	 * Recomputes the matrix returned by {Geometry#getWorldMatrix() }.
	 * This will require a localized transform update for this geometry.
	 */
	public function computeWorldMatrix():Void
	{
		// Force a local update of the geometry's transform
		checkDoTransformUpdate();
		
		// Compute the cached world matrix
		//mCachedWorldMat.loadIdentity();//没必要loadIdentity了，setQuaternion会全部覆盖掉
		mCachedWorldMat.setQuaternion(mWorldTransform.rotation);
		mCachedWorldMat.setTranslation(mWorldTransform.translation);

		var s:Vector3f = mWorldTransform.scale;
		if (s.x != 1 || s.y != 1 || s.z != 1)
		{
			mCachedWorldMat.scaleVecLocal(s);
			
			//var tempVars:TempVars = TempVars.getTempVars();
			//var scaleMat:Matrix4f = tempVars.tempMat4;
			//scaleMat.loadIdentity();
			////scaleMat.scaleVecLocal(mWorldTransform.scale);
			//scaleMat.m00 = s.x;
			//scaleMat.m11 = s.y;
			//scaleMat.m22 = s.z;
			//mCachedWorldMat.multLocal(scaleMat);
			//tempVars.release();
		}
	}

	/**
	 * @return A {Matrix4f matrix} that transforms the {Geometry#getMesh() mesh}
	 * from model space to world space. This matrix is computed based on the
	 * {Geometry#getWorldTransform() world transform} of this geometry.
	 * In order to receive updated values, you must call {Geometry#computeWorldMatrix() }
	 * before using this method.
	 */
    public inline function getWorldMatrix():Matrix4f
	{
		return mCachedWorldMat;
	}

	/**
	 * Sets the model bound to use for this geometry.
	 * This alters the bound used on the mesh as well via
	 * `org.angle3d.scene.mesh.Mesh.setBound` and
	 * forces the world bounding volume to be recomputed.
	 *
	 * @param modelBound The model bound to set
	 */
	override public function setModelBound(bound:BoundingVolume):Void
	{
		mWorldBound = null;
		mMesh.setBound(bound);
		setBoundRefresh();
	}

	override public function collideWith(other:Collidable, results:CollisionResults):Int
	{
		// Force bound to update
		checkDoBoundUpdate();
		// Update transform, and compute cached world matrix
		computeWorldMatrix();

		Assert.assert(!refreshFlags.contains(RefreshFlag.RF_BOUND.add(RefreshFlag.RF_TRANSFORM)), "");

		if (mMesh != null)
		{
			// NOTE: BIHTree in mesh already checks collision with the
			// mesh's bound
			var prevSize:Int = results.size;
			var added:Int = mMesh.collideWith(other, mCachedWorldMat, mWorldBound, results);
			var newSize:Int = results.size;
			for (i in prevSize...newSize)
			{
				results.getCollisionDirect(i).geometry = this;
			}
			return added;
		}
		return 0;
	}

	override private function depthFirstTraversalInternal(visitor:SceneGraphVisitor, mode:DFSMode):Void 
	{
		visitor.visit(this);
	}

	override private function breadthFirstTraversalInternal(visitor:SceneGraphVisitor,queue:Vector<Spatial>):Void
	{
	
	}
	
	public inline function isGrouped():Bool
	{
		return groupNode != null;
	}

	override public function clone(newName:String, cloneMaterial:Bool = true, result:Spatial = null):Spatial
	{
		var geom:Geometry;
		if (result == null)
		{
			geom = new Geometry(newName);
		}
		else
		{
			geom = Std.instance(result, Geometry);
		}

		geom = cast super.clone(newName, cloneMaterial, geom);
		
		// This geometry is managed,
        // but the cloned one is not attached to anything, hence not managed.
        if (geom.isGrouped())
		{
            geom.groupNode = null;
            geom.startIndex = -1;
        }

		geom.mCachedWorldMat.copyFrom(mCachedWorldMat);
		if (mMaterial != null)
		{
			if (cloneMaterial)
			{
				geom.mMaterial = mMaterial.clone();
			}
			else
			{
				geom.mMaterial = mMaterial;
			}
		}
		
		geom.lodLevel = this.lodLevel;
		geom.mIgnoreTransform = mIgnoreTransform;
		geom.mMesh = this.mMesh;

		return geom;
	}
}

