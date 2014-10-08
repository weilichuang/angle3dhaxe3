package com.bulletphysics.collision.shapes.voxel;

/**
 * Interface for the provider of Voxel physics information. 
 * Primarily it has to provide what collider is present in each grid cell.
 * @author weilichuang
 */

interface VoxelPhysicsWorld 
{
    function getCollisionShapeAt(x:Int, y:Int, z:Int):VoxelInfo;
}