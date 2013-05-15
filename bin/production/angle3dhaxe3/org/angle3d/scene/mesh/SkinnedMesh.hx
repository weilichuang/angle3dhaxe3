package org.angle3d.scene.mesh;

/**
 * 骨骼动画
 */
class SkinnedMesh extends Mesh
{
	public function new()
	{
		super();

		mType = MeshType.SKINNING;
	}
}

