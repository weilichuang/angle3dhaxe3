package org.angle3d.scene.shape;
/**
 * ...
 * @author weilichuang
 */

class WireframeCube extends WireframeShape
{
	private var _width:Float;
	private var _height:Float;
	private var _depth:Float;

	public function new(width:Float, height:Float, depth:Float)
	{
		super();

		this._width = width;
		this._height = height;
		this._depth = depth;

		setupGeometry();
		build();
	}

	private function setupGeometry():Void
	{
		var hw:Float = _width * 0.5;
		var hh:Float = _height * 0.5;
		var hd:Float = _depth * 0.5;

		addSegment(new WireframeLineSet(-hw, hh, -hd, -hw, -hh, -hd));
		addSegment(new WireframeLineSet(-hw, hh, hd, -hw, -hh, hd));
		addSegment(new WireframeLineSet(hw, hh, hd, hw, -hh, hd));
		addSegment(new WireframeLineSet(hw, hh, -hd, hw, -hh, -hd));

		addSegment(new WireframeLineSet(-hw, -hh, -hd, hw, -hh, -hd));
		addSegment(new WireframeLineSet(-hw, hh, -hd, hw, hh, -hd));
		addSegment(new WireframeLineSet(-hw, hh, hd, hw, hh, hd));
		addSegment(new WireframeLineSet(-hw, -hh, hd, hw, -hh, hd));

		addSegment(new WireframeLineSet(-hw, -hh, -hd, -hw, -hh, hd));
		addSegment(new WireframeLineSet(-hw, hh, -hd, -hw, hh, hd));
		addSegment(new WireframeLineSet(hw, hh, -hd, hw, hh, hd));
		addSegment(new WireframeLineSet(hw, -hh, -hd, hw, -hh, hd));
	}
}

