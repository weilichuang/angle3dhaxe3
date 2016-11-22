package lecture;
import flash.Vector;
import flash.ui.Keyboard;
import org.angle3d.Angle3D;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.DirectionalLight;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.shape.Sphere;

class DirectionLightLecture extends BasicLecture
{
	static function main() 
	{
		flash.Lib.current.addChild(new DirectionLightLecture());
	}

	private var directionLight:DirectionalLight;
	private var angle:Float = 0;
	private var mat:Material;
	private var useVertexLighting:Bool = false;
	private var directionLightNode:LightNode;
	
	public function new() 
	{
		super();
		Angle3D.maxAgalVersion = 2;
	}
	
	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);

		var sphere:Sphere = new Sphere(1, 24, 24, true);
		var sphereMesh = new Geometry("Sphere Geom", sphere);
		
		mat = new Material();
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
		mat.setFloat("u_Shininess", 4);
        mat.setBoolean("useMaterialColor", false);
		mat.setBoolean("useVertexLighting", useVertexLighting);
		mat.setBoolean("useLowQuality", false);
        mat.setColor("u_Ambient",  Color.White());
        mat.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
        mat.setColor("u_Specular", Color.White());
		sphereMesh.setMaterial(mat);
		sphereMesh.setTranslationXYZ(1.5, 0, 0);
		
		var mat2 = new Material();
		mat2.load(Angle3D.materialFolder + "material/lighting.mat");
		mat2.setFloat("u_Shininess", 32);
        mat2.setBoolean("useMaterialColor", false);
		mat2.setBoolean("useVertexLighting", useVertexLighting);
		mat2.setBoolean("useLowQuality", false);
        mat2.setColor("u_Ambient",  Color.White());
        mat2.setColor("u_Diffuse",  Color.White());
        mat2.setColor("u_Specular", Color.White());
		
		var sphereMesh2 = new Geometry("Sphere Geom2", sphere);
		sphereMesh2.setTranslationXYZ(-1.5, 0, 0);
		sphereMesh2.setMaterial(mat2);
		
		scene.attachChild(sphereMesh);
		scene.attachChild(sphereMesh2);
		
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.1, 0.1, 0.1, 1);
		scene.addLight(al);
		
		directionLight = new DirectionalLight();
		directionLight.color = new Color(0, 1, 0, 1);
		directionLight.direction = new Vector3f(0, 0, 0);
		scene.addLight(directionLight);
		
		directionLightNode = createLightNode(directionLight, 0.1);
		scene.attachChild(directionLightNode);

		mInputManager.addTrigger("space", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addListener(this, Vector.ofArray(["space"]));
		
		updateMsg();
		
		camera.location.setTo(0, 0, 7);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		start();
	}
	
	private function updateMsg():Void
	{
		showMsg('Press SPACE to change useVertexLighting,cur useVertexLighting ${useVertexLighting}');
	}
	
	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		super.onAction(name, value, tpf);
		
		if (name == "space")
		{
			if (value)
			{
				useVertexLighting = !useVertexLighting;
				mat.setBoolean("useVertexLighting", useVertexLighting);
				updateMsg();
			}
		}
	}
	
	override public function simpleUpdate(tpf : Float) : Void
	{
		super.simpleUpdate(tpf);
		
		angle += 0.02;
		if (angle > FastMath.TWO_PI)
		{
			directionLight.color = Color.Random();
			cast(directionLightNode.getChildByName("debugNode"),Geometry).getMaterial().setColor("u_MaterialColor", directionLight.color);
		}
		
		angle %= FastMath.TWO_PI;
		directionLightNode.setTranslationXYZ(Math.cos(angle) * 3, 1, Math.sin(angle) * 3);
	}
}