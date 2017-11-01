package examples.light;

import flash.ui.Keyboard;
import org.angle3d.Angle3D;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.PointLight;
import org.angle3d.material.LightMode;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Sphere;

class TestLightNode extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestLightNode());
	}

	private var pointLightNode:Node;
	private var directionLightNode:Node;
	private var angle:Float = 0;
	private var angle2:Float = 0;
	
	private var pl:PointLight;
	private var directionLight:DirectionalLight;
	
	private var isSinglePass:Bool = true;
	
	public function new() 
	{
		super();
		Angle3D.maxAgalVersion = 2;
	}
	
	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		mRenderManager.setSinglePassLightBatchSize(2);
		
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
		
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.1, 0.1, 0.1, 1);
		scene.addLight(al);
		
		pl = new PointLight();
		pl.color = new Color(1, 0, 0, 1);
		pl.radius = 160;
		scene.addLight(pl);
		
		var p2 = new PointLight();
		p2.color = new Color(0, 0, 1, 1);
		p2.radius = 16;
		p2.position = new Vector3f(0, 0, 3);
		scene.addLight(p2);
		
		directionLight = new DirectionalLight();
		directionLight.color = new Color(0, 1, 0, 1);
		directionLight.direction = new Vector3f(0, 0, 0);
		scene.addLight(directionLight);
		
		pointLightNode = createLightNode(pl, 0.1);
		scene.attachChild(pointLightNode);
		
		directionLightNode = createLightNode(directionLight, 0.1);
		scene.attachChild(directionLightNode);
		
		mInputManager.addTrigger("reset", new KeyTrigger(Keyboard.R));
		mInputManager.addTrigger("space", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addListener(this, ["reset","space"]);
		
		camera.location.setTo(0, 0, 7);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		start();
	}
	
	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		super.onAction(name, value, tpf);
		
		if (name == "reset")
		{
			angle = 0;
			angle2 = 0;
			pointLightNode.setTranslationXYZ(Math.cos(angle) * 2, 0.5, Math.sin(angle) * 2);
			directionLightNode.setTranslationXYZ(Math.cos(angle2) * 3, 1, Math.sin(angle2) * 3);
		}
		else if (name == "space")
		{
			if (value)
			{
				if (isSinglePass)
				{
					mRenderManager.setPreferredLightMode(LightMode.MultiPass);
					isSinglePass = false;
				}
				else
				{
					isSinglePass = true;
					mRenderManager.setPreferredLightMode(LightMode.SinglePass);
					mRenderManager.setSinglePassLightBatchSize(4);
				}
			}
		}
	}
	
	override public function simpleUpdate(tpf : Float) : Void
	{
		super.simpleUpdate(tpf);
		
		angle += 0.02;
		angle2 += 0.01;
		
		if (angle > FastMath.TWO_PI)
		{
			pl.color = Color.Random();
			cast(pointLightNode.getChildByName("debugNode"),Geometry).getMaterial().setColor("u_MaterialColor", pl.color);
		}
		
		if (angle2 > FastMath.TWO_PI)
		{
			directionLight.color = Color.Random();
			cast(directionLightNode.getChildByName("debugNode"),Geometry).getMaterial().setColor("u_MaterialColor", directionLight.color);
		}
		
		angle %= FastMath.TWO_PI;
		angle2 %= FastMath.TWO_PI;
		
		pointLightNode.setTranslationXYZ(Math.cos(angle) * 2, 0.5, Math.sin(angle) * 2);
		directionLightNode.setTranslationXYZ(Math.cos(angle2) * 3, 1, Math.sin(angle2) * 3);
	}
}