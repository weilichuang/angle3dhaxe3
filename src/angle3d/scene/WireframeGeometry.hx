package angle3d.scene;

import angle3d.material.Material;
import angle3d.scene.shape.WireframeShape;

class WireframeGeometry extends Geometry {
	public function new(name:String, mesh:WireframeShape) {
		super(name, mesh);
		this.useLight = false;
	}

	override public function setMaterial(material:Material):Void {
		super.setMaterial(material);
	}
}

