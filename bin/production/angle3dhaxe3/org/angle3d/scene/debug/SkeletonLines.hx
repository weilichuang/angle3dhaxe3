package org.angle3d.scene.debug;

import flash.Vector;
import org.angle3d.animation.Bone;
import org.angle3d.animation.Skeleton;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.shape.WireframeLineSet;
import org.angle3d.scene.shape.WireframeShape;

//TODO 优化，不必每次都创建VertexBuffer
class SkeletonLines extends WireframeShape
{
	private var _skeleton:Skeleton;

	public function new(skeleton:Skeleton)
	{
		super();

		_skeleton = skeleton;

		updateGeometry();
	}

	public function updateGeometry(updateIndices:Bool = true):Void
	{
		clearSegment();

		var rootBones:Vector<Bone> = _skeleton.rootBones;
		for (i in 0...rootBones.length)
		{
			buildBoneLines(_skeleton.rootBones[i]);
		}

		build(updateIndices);
	}

	private function buildBoneLines(bone:Bone):Void
	{
		var parentPos:Vector3f = bone.getModelSpacePosition();

		var children:Vector<Bone> = bone.children;
		for (i in 0...children.length)
		{
			var child:Bone = children[i];
			var childPos:Vector3f = child.getModelSpacePosition();
			addSegment(new WireframeLineSet(parentPos.x, parentPos.y, parentPos.z, childPos.x, childPos.y, childPos.z));

			buildBoneLines(child);
		}
	}
}
