package angle3d.scene.debug;

import angle3d.scene.Geometry;
import angle3d.scene.shape.Sphere;

class SphereNode extends Geometry {
	public function new(name:String, radius:Float, segmentsW:Int = 15, segmentsH:Int = 15, yUp:Bool = true) {
		super(name, new Sphere(radius, segmentsW, segmentsH, yUp));
	}
}
