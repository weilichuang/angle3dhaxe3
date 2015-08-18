package examples.skybox;

import examples.skybox.DefaultSkyBox;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Cube;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;

class SkyBoxTest extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new SkyBoxTest());
	}
	
	public function new()
	{
		super();
	}

	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		mViewPort.backgroundColor.setColor(0x0);

		flyCam.setDragToRotate(true);

		var sky:DefaultSkyBox = new DefaultSkyBox(500);
		scene.attachChild(sky);
		
		var texture:BitmapTexture = new BitmapTexture(new DECALMAP_ASSET(0, 0), false);

		var mat = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat.setTextureParam("s_texture", VarType.TEXTURE2D, texture);

		var solidCube : Cube = new Cube(10, 10, 10, 1, 1, 1);
		var cubeGeometry : Geometry = new Geometry("cube", solidCube);
		cubeGeometry.setMaterial(mat);
		cubeGeometry.rotateAngles(45 / 180 * Math.PI, 45 / 180 * Math.PI, 45 / 180 * Math.PI);
		scene.attachChild(cubeGeometry);

		camera.location.setTo(0, 0, -30);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);

		Stats.show(stage);
		start();
	}

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.03;
		angle %= FastMath.TWO_PI();

		//camera.location.setTo(Math.cos(angle) * 5, 0, Math.sin(angle) * 5);
		//camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}

@:bitmap("../assets/embed/no-shader.png") class DECALMAP_ASSET extends flash.display.BitmapData { }