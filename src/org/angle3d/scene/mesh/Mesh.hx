package org.angle3d.scene.mesh;

import flash.Vector;
import org.angle3d.bounding.BoundingBox;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.collision.Collidable;
import org.angle3d.collision.CollisionResults;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Triangle;

using org.angle3d.utils.VectorUtil;


class Mesh implements IMesh
{
	public var type(get, null):MeshType;
	public var subMeshList(get, set):Vector<SubMesh>;
	/**
	 * The bounding volume that contains the mesh entirely.
	 * By default a BoundingBox (AABB).
	 */
	private var mBound:BoundingVolume;

	private var mBoundDirty:Bool;

	private var mSubMeshList:Vector<SubMesh>;

	private var mType:MeshType;

	public function new()
	{
		mType = MeshType.STATIC;

		mBound = new BoundingBox();

		mSubMeshList = new Vector<SubMesh>();
	}

	public function getTriangle(index:Int, store:Triangle):Void
	{

	}

	public function addSubMesh(subMesh:SubMesh):Void
	{
		mSubMeshList.push(subMesh);
		subMesh.mesh = this;

		mBoundDirty = true;
	}

	public function removeSubMesh(subMesh:SubMesh):Bool
	{
		if (mSubMeshList.remove(subMesh))
		{
			mBoundDirty = true;
			return true;
		}
		return false;
	}

	public function validate():Void
	{
		updateBound();
	}

	/**
	 * Updates the bounding volume of this mesh.
	 * The method does nothing if the mesh has no Position buffer.
	 * It is expected that the position buffer is a float buffer with 3 components.
	 */
	public function updateBound():Void
	{
		if (!mBoundDirty)
			return;

		var length:Int = mSubMeshList.length;
		for (i in 0...length)
		{
			var subMesh:SubMesh = mSubMeshList[i];
			mBound.mergeLocal(subMesh.getBound());
		}

		mBoundDirty = false;
	}

	/**
	 * Sets the {@link BoundingVolume} for this Mesh.
	 * The bounding volume is recomputed by calling {@link #updateBound() }.
	 *
	 * @param modelBound The model bound to set
	 */
	public function setBound(bound:BoundingVolume):Void
	{
		mBound = bound;
		mBoundDirty = false;
	}

	/**
	 * Returns the {@link BoundingVolume} of this Mesh.
	 * By default the bounding volume is a {@link BoundingBox}.
	 *
	 * @return the bounding volume of this mesh
	 */
	public function getBound():BoundingVolume
	{
		return mBound;
	}
	
	/**
     * Clears any previously generated collision data.  Use this if
     * the mesh has changed in some way that invalidates any previously
     * generated BIHTree.
     */
    public function clearCollisionData():Void 
	{
		for (i in 0...subMeshList.length)
		{
			subMeshList[i].clearCollisionData();
		}
    }

	public function collideWith(other:Collidable, worldMatrix:Matrix4f, worldBound:BoundingVolume, results:CollisionResults):Int
	{
		var size:Int = 0;
		for (i in 0...subMeshList.length)
		{
			size += subMeshList[i].collideWith(other, worldMatrix, worldBound, results);
		}
		return size;
	}
	
	private function get_type():MeshType
	{
		return mType;
	}

	private function get_subMeshList():Vector<SubMesh>
	{
		return mSubMeshList;
	}
	
	private function set_subMeshList(subMeshs:Vector<SubMesh>):Vector<SubMesh>
	{
		mSubMeshList = subMeshs;
		mBoundDirty = true;
		
		return mSubMeshList;
	}
}

