package org.angle3d.scene.debug;

import flash.Vector;
import org.angle3d.animation.Bone;
import org.angle3d.animation.Skeleton;
import org.angle3d.material.Material;
import org.angle3d.material.TestFunction;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Cube;
import org.angle3d.scene.shape.WireframeLineSet;
import org.angle3d.scene.shape.WireframeShape;
import org.angle3d.scene.WireframeGeometry;


/**
 * 用来显示骨骼框架
 */
class SkeletonDebugger extends Node
{
	private var _lines:SkeletonLines;
	private var _points:SkeletonPoints;
	private var _skeleton:Skeleton;

	public function new(name:String, skeleton:Skeleton, radius:Float = 1, lineColor:UInt = 0, pointColor:UInt = 0)
	{
		super(name);

		this._skeleton = skeleton;
		
		_lines = new SkeletonLines(this.name + "_lines", skeleton, lineColor);
		_points = new SkeletonPoints(this.name + "_points", skeleton, radius, pointColor);

		attachChild(_lines);
		attachChild(_points);
	}

	override public function runControlUpdate(tpf:Float):Void
	{
		super.runControlUpdate(tpf);

		_lines.updateGeometry(false);
		_points.updateGeometry();
	}
}

class SkeletonLines extends WireframeGeometry
{
	private var _lines:WireframeShape;

	private var _skeleton:Skeleton;

	public function new(name:String,skeleton:Skeleton, color:UInt = 0xFFFFFF)
	{
		_lines = new WireframeShape();
		
		super(name, _lines);
		
		localQueueBucket = QueueBucket.Opaque;

		_skeleton = skeleton;
		
		var mat:Material = new Material();
		mat.load("assets/material/wireframe.mat");
		mat.setParam("u_color", VarType.COLOR, Color.fromColor(color));
		mat.setParam("u_thickness", VarType.FLOAT, 0.001);
		
		mat.getAdditionalRenderState().applyDepthTest = false;
		mat.getAdditionalRenderState().depthTest = false;
		mat.getAdditionalRenderState().depthFunc = TestFunction.ALWAYS;
		
		this.setMaterial(mat);

		updateGeometry();
	}

	public function updateGeometry(updateIndices:Bool = true):Void
	{
		_lines.clearSegment();

		var rootBones:Vector<Bone> = _skeleton.rootBones;
		for (i in 0...rootBones.length)
		{
			buildBoneLines(rootBones[i]);
		}

		_lines.build(updateIndices);
	}

	private function buildBoneLines(bone:Bone):Void
	{
		var parentPos:Vector3f = bone.getModelSpacePosition();

		var children:Vector<Bone> = bone.children;
		for (i in 0...children.length)
		{
			var child:Bone = children[i];
			var childPos:Vector3f = child.getModelSpacePosition();
			_lines.addSegment(new WireframeLineSet(parentPos.x, parentPos.y, parentPos.z, childPos.x, childPos.y, childPos.z));

			buildBoneLines(child);
		}
	}
}

class SkeletonPoints extends Node
{
	private var _size:Float;
	private var _skeleton:Skeleton;

	private var points:Vector<Geometry>;

	private var material:Material;

	public function new(name:String, skeleton:Skeleton, size:Float, color:UInt = 0xFFFFFF)
	{
		super(name);

		_skeleton = skeleton;
		_size = size;

		material = new Material();
		material.load("assets/material/unshaded.mat");
		material.setBoolean("useMaterialColor", true);
		material.setColor("u_MaterialColor", Color.fromColor(color));
		material.getAdditionalRenderState().applyDepthTest = false;
		material.getAdditionalRenderState().depthTest = false;
		material.getAdditionalRenderState().depthFunc = TestFunction.ALWAYS;
		
		this.setMaterial(material);
		
		localQueueBucket = QueueBucket.Opaque;

		points = new Vector<Geometry>();

		var boneCount:Int = _skeleton.numBones;
		for (i in 0...boneCount)
		{
			var node:Geometry = new Geometry(_skeleton.boneList[i].name + "_point", new Cube(_size, _size, _size));
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