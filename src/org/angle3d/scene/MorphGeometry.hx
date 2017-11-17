package org.angle3d.scene;

import org.angle3d.scene.control.MorphControl;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.mesh.MorphMesh;

class MorphGeometry extends Geometry {
	public var morphMesh(get, null):MorphMesh;
	public var morphControl(get, null):MorphControl;

	private var mMorphMesh:MorphMesh;

	private var mControl:MorphControl;

	public function new(name:String, mesh:MorphMesh = null) {
		super(name, mesh);

		mControl = new MorphControl();
		addControl(mControl);
	}

	public function setAnimationSpeed(speed:Float):Void {
		mControl.setAnimationSpeed(speed);
	}

	public function playAnimation(animationName:String, loop:Bool = true):Void {
		mControl.playAnimation(animationName, loop);
	}

	public function stop():Void {
		mControl.stop();
	}

	override public function setMesh(mesh:Mesh):Void {
		mMorphMesh = Std.instance(mesh,MorphMesh);
		super.setMesh(mesh);
	}

	private inline function get_morphMesh():MorphMesh {
		return mMorphMesh;
	}

	private inline function get_morphControl():MorphControl {
		return mControl;
	}
}
