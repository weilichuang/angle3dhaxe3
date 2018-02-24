package examples.light;

import flash.ui.Keyboard;
import angle3d.Angle3D;
import angle3d.input.controls.KeyTrigger;
import angle3d.light.AmbientLight;
import angle3d.light.PointLight;
import angle3d.material.LightMode;
import angle3d.material.Material;
import angle3d.math.Color;
import angle3d.math.FastMath;
import angle3d.math.Vector3f;
import angle3d.scene.Geometry;
import angle3d.scene.LightNode;
import angle3d.scene.shape.Sphere;
import angle3d.texture.BitmapTexture;

class TestLightRadius extends BasicExample
{
	static function main()
	{
		flash.Lib.current.addChild(new TestLightRadius());
	}

	private var pl:PointLight;
	private var lightNode:LightNode;

	public function new()
	{
		super();
		Angle3D.maxAgalVersion = 2;
	}

	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);

		flyCam.setDragToRotate(false);
		flyCam.setEnabled(false);

		mRenderManager.setPreferredLightMode(LightMode.MultiPass);

		var sphere:Sphere = new Sphere(1.5, 24, 24, true);
		var sphereMesh = new Geometry("Sphere Geom", sphere);

		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
		mat.setFloat("u_Shininess", 32);
		mat.setBoolean("useMaterialColor", false);
		mat.setBoolean("useVertexLighting", false);
		mat.setBoolean("useLowQuality", false);
		mat.setColor("u_Ambient",  Color.White());
		mat.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
		mat.setColor("u_Specular", Color.White());
		sphereMesh.setMaterial(mat);

		scene.attachChild(sphereMesh);

		pl = new PointLight();
		pl.color = new Color(1, 0, 0, 1);
		pl.position = new Vector3f(1, 0, 2);
		pl.radius = 2;
		scene.addLight(pl);

		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.1, 0.1, 0.1, 1);
		scene.addLight(al);

		lightNode = createLightNode(pl, 0.1);
		lightNode.setTranslationXYZ(Math.cos(Math.PI/3) * 3, 0, Math.sin(Math.PI/3) * 3);
		scene.attachChild(lightNode);
		
		updateMsg();

		mInputManager.addTrigger("up", new KeyTrigger(Keyboard.UP));
		mInputManager.addTrigger("down", new KeyTrigger(Keyboard.DOWN));
		mInputManager.addListener(this, ["up","down"]);

		start();

		camera.location.setTo(0, 0, 7);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
	}

	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		super.onAction(name, value, tpf);

		if (value)
		{
			if (name == "up")
			{
				pl.radius += 0.1;
				pl.radius = FastMath.clamp(pl.radius, 1, 5);
				updateMsg();
			}
			else if (name == "down")
			{
				pl.radius -= 0.1;
				pl.radius = FastMath.clamp(pl.radius, 1, 5);
				updateMsg();
			}
		}
	}
	
	private function updateMsg():Void
	{
		showMsg('Press UP or DOWN to change radius,cur radius ${pl.radius}');
	}

	override public function simpleUpdate(tpf : Float) : Void
	{
		super.simpleUpdate(tpf);
	}
}