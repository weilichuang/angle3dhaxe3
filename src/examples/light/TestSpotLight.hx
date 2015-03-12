package examples.light;
import flash.ui.Keyboard;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.PointLight;
import org.angle3d.light.SpotLight;
import org.angle3d.material.LightMode;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Cube;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/wood.jpg") class ROCK_ASSET extends flash.display.BitmapData { }


class TestSpotLight extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestSpotLight());
	}

	private var movingNode:Node;
	private var angle:Float = 0;

	public function new() 
	{
		super();
	}
	
	private var pl:SpotLight;
	private var fillMaterial:Material;

	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		//mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		//mRenderManager.setSinglePassLightBatchSize(2);
		
		var bitmapTexture:Texture2D = new Texture2D(new ROCK_ASSET(0, 0));
		
		var box:Cube = new Cube(3, 3, 1, 5, 5, 5);
		var sphereMesh:Geometry = new Geometry("Sphere Geom", box);
		
		var mat:Material = new Material();
		mat.load("assets/material/lighting.mat");
		mat.setFloat("u_Shininess", 32);
        mat.setBoolean("useMaterialColor", false);
		mat.setBoolean("useVertexLighting", false);
		mat.setBoolean("useLowQuality", false);
        mat.setColor("u_Ambient",  Color.White());
        mat.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
        mat.setColor("u_Specular", Color.White());
		mat.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, bitmapTexture);
		sphereMesh.setMaterial(mat);
		
		scene.attachChild(sphereMesh);
		

		fillMaterial = new Material();
		fillMaterial.load("assets/material/unshaded.mat");
		fillMaterial.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, bitmapTexture);
		
		var sphere:Sphere = new Sphere(0.1, 12, 12);
		
		var lightModel:Geometry = new Geometry("Light", sphere);
		lightModel.setMaterial(fillMaterial);
		
		movingNode = new Node("lightParentNode");
		movingNode.attachChild(lightModel);
		scene.attachChild(movingNode);

		pl = new SpotLight();
		pl.spotRange = 5;
		pl.innerAngle = 10 * FastMath.DEGTORAD();
		pl.outerAngle = 30 * FastMath.DEGTORAD();
		pl.position = new Vector3f(Math.cos(0) * 2, 0, Math.sin(0) * 2);
		pl.direction = new Vector3f().subtract(pl.position);
		pl.color = new Color(1, 0, 0, 1);
		scene.addLight(pl);
		
		var p2 = new PointLight();
		p2.color = new Color(0, 1, 0, 1);
		p2.radius = 2;
		p2.position = new Vector3f(0, 0, 2);
		scene.addLight(p2);

		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.2, 0.2, 0.2, 0);
		scene.addLight(al);
		
		mInputManager.addSingleMapping("reset", new KeyTrigger(Keyboard.R));
		mInputManager.addListener(this, ["reset"]);
		
		Stats.show(stage);
		start();
		
		camera.location.setTo(0, 0, 6);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
	
	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		super.onAction(name, value, tpf);
		
		if (name == "reset")
		{
			angle = 0;
			movingNode.setTranslationXYZ(Math.cos(angle) * 2, 0, Math.sin(angle) * 2);
		}
	}
	
	override public function simpleUpdate(tpf : Float) : Void
	{
		super.simpleUpdate(tpf);
		
		angle += 0.02;

		if (angle > FastMath.TWO_PI())
		{
			pl.color = new Color(Math.random(), Math.random(), Math.random());
			//fillMaterial.color = pl.color.getColor();
		}

		angle %= FastMath.TWO_PI();

		movingNode.setTranslationXYZ(Math.cos(angle) * 2, 0, Math.sin(angle) * 2);
		
		pl.position = movingNode.getLocalTranslation().clone();
		pl.direction = new Vector3f().subtract(pl.position);
	}
}