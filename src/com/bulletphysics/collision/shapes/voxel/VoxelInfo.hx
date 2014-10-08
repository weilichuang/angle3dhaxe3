package com.bulletphysics.collision.shapes.voxel;
import com.vecmath.Vector3f;

/**
 * The collision data for a single Voxel.
 * @author weilichuang
 */
interface VoxelInfo
{
	/**
     * @return Whether the voxel can be collided with at all.
     */
    function isColliding():Bool;

    /**
     * @return The user data associated with this voxel. I would suggest at least the position of the voxel.
     */
    function getUserData():Dynamic;

    /**
     * @return The collision shape for the voxel. Reuse these as much as possible.
     */
    function getCollisionShape():CollisionShape;

    /**
     * @return The offset of the collision shape from the center of the voxel.
     */
    function getCollisionOffset():Vector3f;

    /**
     * @return Does this voxel block rigid bodies
     */
    function isBlocking():Bool;
}