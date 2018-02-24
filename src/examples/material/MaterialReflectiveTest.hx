package examples.material;

import examples.skybox.DefaultSkyBox;
import angle3d.Angle3D;
import angle3d.app.SimpleApplication;
import angle3d.material.Material;
import angle3d.math.FastMath;
import angle3d.math.Vector3f;
import angle3d.scene.Geometry;
import angle3d.scene.shape.Sphere;
import angle3d.scene.shape.WireframeShape;
import angle3d.scene.shape.WireframeUtil;
import angle3d.scene.WireframeGeometry;
import angle3d.texture.BitmapTexture;
import angle3d.utils.Stats;

/**
 * Reflection mapping http://en.wikipedia.org/wiki/Reflection_mapping
 * http://developer.nvidia.com/book/export/html/86
 */
class MaterialReflectiveTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new MaterialReflectiveTest());
	}
	
	private var reflectiveSphere : Geometry;

	public function new()
	{
		super();
	}

	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);

		flyCam.setDragToRotate(false);

		var sky : DefaultSkyBox = new DefaultSkyBox(500);
		scene.attachChild(sky);

		var decalMap : BitmapTexture = new BitmapTexture(new DECALMAP_ASSET(0, 0));
		
		var material : Material = new Material();
		material.load(Angle3D.materialFolder + "material/unshaded.mat");
		material.setTexture("u_DiffuseMap",  decalMap);
		material.setTexture("u_ReflectMap",  sky.cubeMap);
		material.setFloat("u_Reflectivity", 0.8);

		var sphere : Sphere = new Sphere(50, 30, 30); //Sphere = new Sphere(50, 30, 30);
		reflectiveSphere = new Geometry("sphere", sphere);
		reflectiveSphere.setMaterial(material);
		scene.attachChild(reflectiveSphere);

		camera.location.setTo(0, 0, -200);
		camera.lookAt(new Vector3f(0, 0, 0), Vector3f.UNIT_Y);
		
		
		
		start();
	}

	private var angle : Float = 0;

	override public function simpleUpdate(tpf : Float) : Void
	{
		super.simpleUpdate(tpf);
		
		angle += 0.02;
		angle %= FastMath.TWO_PI;


		camera.location.setTo(Math.cos(angle) * 200, 0, Math.sin(angle) * 200);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
	}
}

@:bitmap("../assets/embed/water.png") class DECALMAP_ASSET extends flash.display.BitmapData { }