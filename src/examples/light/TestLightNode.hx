package examples.light;
import flash.ui.Keyboard;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/wood.jpg") class ROCK_ASSET extends flash.display.BitmapData { }


class TestLightNode extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestLightNode());
	}

	private var pointLightNode:Node;
	private var directionLightNode:Node;
	private var angle:Float = 0;
	private var angle2:Float = 0;
	
	public function new() 
	{
		super();
	}
	
	private var pl:PointLight;
	private var directionLight:DirectionalLight;
	private var sphereMesh:Geometry;
	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		//mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		//mRenderManager.setSinglePassLightBatchSize(2);
		
		var texture:BitmapTexture = new BitmapTexture(new ROCK_ASSET(0, 0));
		
		var sphere:Sphere = new Sphere(1.5, 16, 16, true);
		sphereMesh = new Geometry("Sphere Geom", sphere);
		
		var mat:Material = new Material();
		mat.load("assets/material/lighting.mat");
		mat.setFloat("u_Shininess", 32);
        mat.setBoolean("useMaterialColor", false);
		mat.setBoolean("useVertexLighting", false);
		mat.setBoolean("useLowQuality", false);
        mat.setColor("u_Ambient",  Color.White());
        mat.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
        mat.setColor("u_Specular", Color.White());
		//mat.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, texture);
		sphereMesh.setMaterial(mat);
		
		scene.attachChild(sphereMesh);
		
		var sphere:Sphere = new Sphere(0.1, 10, 10);
		var mat2:Material = new Material();
		mat2.load("assets/material/unshaded.mat");
		mat2.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, texture);
		
		var lightModel:Geometry = new Geometry("Light", sphere);
		lightModel.setMaterial(mat2);
		
		pointLightNode = new Node("lightParentNode");
		pointLightNode.attachChild(lightModel);
		scene.attachChild(pointLightNode);
		
		var lightModel2:Geometry = new Geometry("sphere2", sphere);
		lightModel2.setMaterial(mat2);
		
		directionLightNode = new Node("lightParentNode2");
		directionLightNode.attachChild(lightModel2);
		
		scene.attachChild(directionLightNode);
		
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
		
		var lightNode:LightNode = new LightNode("pointLight", pl);
		pointLightNode.attachChild(lightNode);
		
		var lightNode2:LightNode = new LightNode("directionLight", directionLight);
		directionLightNode.attachChild(lightNode2);
		
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.1, 0.1, 0.1, 1);
		scene.addLight(al);
		
		mInputManager.addSingleMapping("reset", new KeyTrigger(Keyboard.R));
		mInputManager.addListener(this, ["reset"]);
		
		Stats.show(stage);
		start();
		
		camera.location.setTo(0, 0, 7);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
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
	}
	
	override public function simpleUpdate(tpf : Float) : Void
	{
		super.simpleUpdate(tpf);
		
		angle += 0.02;
		angle2 += 0.01;
		
		if (angle > FastMath.TWO_PI())
		{
			//pl.color = new Color(Math.random(), Math.random(), Math.random());
			//fillMaterial.color = pl.color.getColor();
		}
		
		if (angle2 > FastMath.TWO_PI())
		{
			directionLight.color = new Color(Math.random(), Math.random(), Math.random());
			//fillMaterial2.color = pl2.color.getColor();
		}
		
		angle %= FastMath.TWO_PI();
		angle2 %= FastMath.TWO_PI();
		
		pointLightNode.setTranslationXYZ(Math.cos(angle) * 2, 0.5, Math.sin(angle) * 2);
		directionLightNode.setTranslationXYZ(Math.cos(angle2) * 3, 1, Math.sin(angle2) * 3);
	}
}