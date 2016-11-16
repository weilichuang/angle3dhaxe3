package examples.material;

import examples.skybox.DefaultSkyBox;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.ChaseCamera;
import org.angle3d.material.Material;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Cube;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;

/**
 * Reflection mapping http://en.wikipedia.org/wiki/Reflection_mapping
 * http://developer.nvidia.com/book/export/html/86
 */
class MaterialRefractionTest extends BasicExample
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

		var sky : DefaultSkyBox = new DefaultSkyBox(500);
		scene.attachChild(sky);

		var decalMap : BitmapTexture = new BitmapTexture(new DECALMAP_ASSET(0, 0));

		//Vacuum 1.0
		//Air 1.0003
		//Water 1.3333
		//Glass 1.5
		//Plastic 1.5
		//Diamond	 2.417
		
		var eta:Float = 2.417;

		var material : Material = new Material();
		material.load(Angle3D.materialFolder + "material/unshaded.mat");
		material.setTexture("u_DiffuseMap",  decalMap);
		material.setTexture("u_RefractMap",  sky.cubeMap);
		material.setFloat("u_Transmittance", 0.6);
		//_etaRatios[0] = value;
		//_etaRatios[1] = value * value;
		//_etaRatios[2] = 1.0 - _etaRatios[1];
		material.setVector3("u_EtaRatio", new Vector3f(eta, eta * eta, 1.0 - eta * eta));

		var cube:Cube = new Cube(5, 5, 5);
		reflectiveSphere = new Geometry("sphere", cube);
		reflectiveSphere.setMaterial(material);
		scene.attachChild(reflectiveSphere);

		camera.location.setTo(0, 0, 800);
		camera.lookAt(new Vector3f(0, 0, 0), Vector3f.UNIT_Y);
		
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(2.0);
		flyCam.setEnabled(false);
		
		var cc : ChaseCamera = new ChaseCamera(this.camera, reflectiveSphere, mInputManager);
		cc.setSmoothMotion(true);
		cc.setEnabled(true);
		cc.setDragToRotate(true);
		cc.setRotationSpeed(5);
		cc.setMinVerticalRotation( -FastMath.HALF_PI);
		
		start();
	}

	override public function simpleUpdate(tpf : Float) : Void
	{
		super.simpleUpdate(tpf);
	}
}

@:bitmap("../assets/textures/water.jpg") class DECALMAP_ASSET extends flash.display.BitmapData { }