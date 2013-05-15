package examples.material;

import examples.skybox.DefaultSkyBox;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import org.angle3d.app.SimpleApplication;
import org.angle3d.material.MaterialRefraction;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;

class MaterialRefractionTest extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new MaterialRefractionTest());
	}
	
	private var reflectiveSphere : Geometry;

	public function new()
	{
		super();
	}

	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);

		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;

		flyCam.setDragToRotate(true);

		var sky : DefaultSkyBox = new DefaultSkyBox(500);

		scene.attachChild(sky);

		var decalMap : Texture2D = new Texture2D(new DECALMAP_ASSET(0, 0));

		//Vacuum 1.0
		//Air 1.0003
		//Water 1.3333
		//Glass 1.5
		//Plastic 1.5
		//Diamond	 2.417
		var material : MaterialRefraction = new MaterialRefraction(decalMap, sky.cubeMap, 2.417, 0.6);

		var sphere : Sphere = new Sphere(50, 30, 30);
		reflectiveSphere = new Geometry("sphere", sphere);
		reflectiveSphere.setMaterial(material);
		scene.attachChild(reflectiveSphere);


		//var cube : Cone = new Cone(50, 50, 20);
		//var cubeG : Geometry = new Geometry("cube", cube);
		//cubeG.setMaterial(material);
		//scene.attachChild(cubeG);
		//cubeG.setTranslationTo(-100, 0, 0);

		camera.location.setTo(0, 0, -200);
		camera.lookAt(new Vector3f(0, 0, 0), Vector3f.Y_AXIS);
		
		Stats.show(stage);
		start();
	}

	private var angle : Float = 0;

	override public function simpleUpdate(tpf : Float) : Void
	{
		super.simpleUpdate(tpf);
		
		angle += 0.01;
		angle %= FastMath.TWO_PI();


		camera.location.setTo(Math.cos(angle) * 200, 50, Math.sin(angle) * 200);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}

@:bitmap("embed/rock.jpg") class DECALMAP_ASSET extends flash.display.BitmapData { }