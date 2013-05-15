package org.angle3d.scene.debug;

import flash.display3D.Context3DCompareMode;
import flash.Vector;

import org.angle3d.animation.Bone;
import org.angle3d.animation.Skeleton;
import org.angle3d.material.MaterialColorFill;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Cube;

class SkeletonPoints extends Node
{
	private var _size:Float;
	private var _skeleton:Skeleton;

	private var points:Vector<Geometry>;

	private var material:MaterialColorFill;

	public function new(name:String, skeleton:Skeleton, size:Float)
	{
		super(name);

		_skeleton = skeleton;
		_size = size;

		material = new MaterialColorFill(0x00ff00);
		material.technique.renderState.applyDepthTest = true;
		material.technique.renderState.depthTest = true;
		material.technique.renderState.compareMode = Context3DCompareMode.ALWAYS;

		points = new Vector<Geometry>();

		var boneCount:Int = _skeleton.numBones;
		for (i in 0...boneCount)
		{
			var node:Geometry = new Geometry(_skeleton.boneList[i].name, new Cube(_size, _size, _size));
			node.setMaterial(material);
			this.attachChild(node);
			points[i] = node;
		}
	}

	public function updateGeometry():Void
	{
		var boneCount:Int = _skeleton.numBones;
		for (i in 0...boneCount)
		{
			var bone:Bone = _skeleton.getBoneAt(i);
			var node:Geometry = points[i];
			node.translation = bone.getModelSpacePosition();
		}
	}
}
