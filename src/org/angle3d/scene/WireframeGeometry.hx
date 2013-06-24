package org.angle3d.scene;


import org.angle3d.material.Material;
import org.angle3d.material.MaterialWireframe;
import org.angle3d.scene.shape.WireframeShape;
import org.angle3d.utils.Assert;

class WireframeGeometry extends Geometry
{
	public var materialWireframe(get, null):MaterialWireframe;

	public function new(name:String, mesh:WireframeShape)
	{
		super(name, mesh);

		this.mMaterial = new MaterialWireframe();
	}

	override public function setMaterial(material:Material):Void
	{
		Assert.assert(Std.is(material, MaterialWireframe), "material should be WireframeMaterial");

		super.setMaterial(material);
	}
	
	private function get_materialWireframe():MaterialWireframe
	{
		return Std.instance(this.mMaterial, MaterialWireframe);
	}
}

