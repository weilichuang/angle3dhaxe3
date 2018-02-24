package angle3d.scene.shape;

class Cylinder extends Cone {
	public function new(axisSamples:Int, radialSamples:Int, radius:Float, height:Float, closed:Bool=true,
						inverted:Bool = false ) {
		super(axisSamples, radialSamples, radius, radius, height, closed, inverted);
	}
}

