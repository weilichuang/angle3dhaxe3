package org.angle3d.scene.mesh;

class MorphData {
	public var name:String;
	public var start:Int;
	public var end:Int;

	public function new(name:String, start:Int, end:Int) {
		this.name = name;
		this.start = start;
		this.end = end;
	}
}
