package org.angle3d.scene.debug;

import flash.display3D.Context3DCompareMode;

import org.angle3d.animation.Skeleton;
import org.angle3d.material.MaterialWireframe;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.scene.Node;
import org.angle3d.scene.WireframeGeometry;

/**
 * 用来显示骨骼框架
 */
class SkeletonDebugger extends Node
{
	private var _lines:SkeletonLines;
	private var _points:SkeletonPoints;
	private var _skeleton:Skeleton;

	public function new(name:String, skeleton:Skeleton, radius:Float = 1)
	{
		super(name);

		this._skeleton = skeleton;
		_lines = new SkeletonLines(skeleton);
		_points = new SkeletonPoints(name + "_points", skeleton, radius);

		var lineGM:WireframeGeometry = new WireframeGeometry(name + "_lines", _lines);
		var mat:MaterialWireframe = cast lineGM.getMaterial();
		mat.technique.thickness = 1;
		mat.technique.renderState.applyDepthTest = true;
		mat.technique.renderState.depthTest = true;
		mat.technique.renderState.compareMode = Context3DCompareMode.ALWAYS;

		//TODO 
		//Opaque还得再加个层级

		lineGM.localQueueBucket = QueueBucket.Opaque;

		_points.localQueueBucket = QueueBucket.Opaque;

		attachChild(lineGM);
		//attachChild(_points);
	}

	override public function updateControls(tpf:Float):Void
	{
		super.updateControls(tpf);

		_lines.updateGeometry(false);
		//_points.updateGeometry();
	}
}