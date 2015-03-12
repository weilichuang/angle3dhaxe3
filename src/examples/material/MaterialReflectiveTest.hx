package examples.material;

import examples.skybox.DefaultSkyBox;
import org.angle3d.app.SimpleApplication;
import org.angle3d.material.Material;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.scene.shape.WireframeShape;
import org.angle3d.scene.shape.WireframeUtil;
import org.angle3d.scene.WireframeGeometry;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;

/**
 * Reflection mapping http://en.wikipedia.org/wiki/Reflection_mapping
 * http://developer.nvidia.com/book/export/html/86
 */
class MaterialReflectiveTest extends SimpleApplication
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

		var decalMap : Texture2D = new Texture2D(new DECALMAP_ASSET(0, 0));
		
		var material : Material = new Material();
		material.load("assets/material/unshaded.mat");
		material.setTexture("u_DiffuseMap",  decalMap);
		material.setTexture("u_ReflectMap",  sky.cubeMap);
		material.setFloat("u_Reflectivity", 0.8);

		var sphere : Sphere = new Sphere(50, 30, 30); //Sphere = new Sphere(50, 30, 30);
		reflectiveSphere = new Geometry("sphere", sphere);
		reflectiveSphere.setMaterial(material);
		scene.attachChild(reflectiveSphere);

		camera.location.setTo(0, 0, -200);
		camera.lookAt(new Vector3f(0, 0, 0), Vector3f.Y_AXIS);
		
		Stats.show(stage);
		
		start();
	}

	private var angle : Float = 0;

	override public function simpleUpdate(tpf : Float) : Void
	{
		super.simpleUpdate(tpf);
		
		angle += 0.02;
		angle %= FastMath.TWO_PI();


		camera.location.setTo(Math.cos(angle) * 200, 0, Math.sin(angle) * 200);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}

@:bitmap("../assets/embed/water.png") class DECALMAP_ASSET extends flash.display.BitmapData { }