package lecture;
import flash.ui.Keyboard;
import flash.Vector;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.PointLight;
import org.angle3d.light.SpotLight;
import org.angle3d.material.Material;
import org.angle3d.material.sgsl.SgslCompiler;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Cube;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/wood.jpg") class ROCK_ASSET extends flash.display.BitmapData { }


class SpotLightLecture extends BasicLecture
{
	static function main() 
	{
		flash.Lib.current.addChild(new SpotLightLecture());
	}

	private var movingNode:Node;
	private var angle:Float = 0;

	public function new() 
	{
		super();
		
		Angle3D.maxAgalVersion = 2;
	}
	
	private var spotLight:SpotLight;
	private var fillMaterial:Material;

	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		var bitmapTexture:BitmapTexture = new BitmapTexture(new ROCK_ASSET(0, 0));
		
		var box:Cube = new Cube(3, 3, 1, 5, 5, 5);
		var sphereMesh:Geometry = new Geometry("Sphere Geom", box);
		
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
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

		spotLight = new SpotLight();
		spotLight.spotRange = 5;
		spotLight.innerAngle = 10 * FastMath.DEG_TO_RAD;
		spotLight.outerAngle = 30 * FastMath.DEG_TO_RAD;
		spotLight.position = new Vector3f(Math.cos(0) * 2, 0, Math.sin(0) * 2);
		spotLight.direction = new Vector3f().subtract(spotLight.position);
		spotLight.color = new Color(1, 0, 0, 1);
		scene.addLight(spotLight);
		
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.2, 0.2, 0.2, 0);
		scene.addLight(al);
		
		fillMaterial = new Material();
		fillMaterial.load(Angle3D.materialFolder + "material/unshaded.mat");
		fillMaterial.setColor("u_MaterialColor", spotLight.color);
		
		var sphere:Sphere = new Sphere(0.1, 12, 12);
		
		var lightModel:Geometry = new Geometry("Light", sphere);
		lightModel.setMaterial(fillMaterial);
		
		movingNode = new Node("lightParentNode");
		movingNode.attachChild(lightModel);
		scene.attachChild(movingNode);
		
		mInputManager.addTrigger("reset", new KeyTrigger(Keyboard.R));
		mInputManager.addListener(this, Vector.ofArray(["reset"]));
		
		
		start();
		
		camera.location.setTo(0, 0, 6);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
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

		if (angle > FastMath.TWO_PI)
		{
			spotLight.color = new Color(Math.random(), Math.random(), Math.random());
			fillMaterial.setColor("u_MaterialColor", spotLight.color);
		}

		angle %= FastMath.TWO_PI;

		movingNode.setTranslationXYZ(Math.cos(angle) * 2, 0, Math.sin(angle) * 2);
		
		spotLight.position = movingNode.getLocalTranslation().clone();
		spotLight.direction = new Vector3f().subtract(spotLight.position);
	}
}