package examples.light;
import flash.geom.Point;
import flash.ui.Keyboard;
import flash.Vector;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.PointLight;
import org.angle3d.light.SpotLight;
import org.angle3d.material.Material;
import org.angle3d.material.MaterialColorFill;
import org.angle3d.material.MaterialLight;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.Node;
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
	private var fillMaterial:MaterialColorFill;

	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		var sphere:Sphere = new Sphere(1, 12, 12, true);
		var g:Geometry = new Geometry("Sphere Geom", sphere);
		
		var bitmapTexture:Texture2D = new Texture2D(new ROCK_ASSET(0, 0));

		var mat:MaterialLight = new MaterialLight();
		mat.diffuseColor = Vector.ofArray([1.0, 1.0, 1.0, 1.0]);
		mat.specularColor = Vector.ofArray([1.0, 1.0, 1.0, 32.0]);
		mat.texture = bitmapTexture;
		g.setMaterial(mat);
		
		scene.attachChild(g);
		
		var sphere:Sphere = new Sphere(0.1, 12, 12);
		
		var lightModel:Geometry = new Geometry("Light", sphere);
		fillMaterial = new MaterialColorFill(0xff0000, 1);
		lightModel.setMaterial(fillMaterial);
		
		movingNode = new Node("lightParentNode");
		movingNode.attachChild(lightModel);
		scene.attachChild(movingNode);

		pl = new SpotLight();
		pl.spotRange = 100;
		pl.innerAngle = 5 * FastMath.DEGTORAD();
		pl.outerAngle = 60 * FastMath.DEGTORAD();
		pl.position = new Vector3f(Math.cos(0) * 2, 0, Math.sin(0) * 2);
		pl.direction = new Vector3f().subtract(pl.position);
		pl.color = new Color(1, 0, 0, 1);
		scene.addLight(pl);

		var lightNode:LightNode = new LightNode("pointLight", pl);
		movingNode.attachChild(lightNode);

		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.2, 0.5, 0.2, 0);
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
			fillMaterial.color = pl.color.getColor();
		}

		angle %= FastMath.TWO_PI();

		movingNode.setTranslationXYZ(Math.cos(angle) * 2, 0, Math.sin(angle) * 2);
	}
}