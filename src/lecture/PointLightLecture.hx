package lecture;
import flash.Vector;
import flash.ui.Keyboard;
import org.angle3d.Angle3D;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.PointLight;
import org.angle3d.material.LightMode;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Sphere;

class PointLightLecture extends BasicLecture
{
	static function main() 
	{
		flash.Lib.current.addChild(new PointLightLecture());
	}

	private var pointLightNode:Node;
	private var angle:Float = 0;
	private var pl:PointLight;
	private var mat:Material;
	private var useVertexLighting:Bool = false;
	
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
		mat.setFloat("u_Shininess", 32);
        mat.setBoolean("useMaterialColor", false);
		mat.setBoolean("useVertexLighting", useVertexLighting);
		mat.setBoolean("useLowQuality", false);
        mat.setColor("u_Ambient",  Color.White());
        mat.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
        mat.setColor("u_Specular", Color.White());
		sphereMesh.setMaterial(mat);
		sphereMesh.setTranslationXYZ(1.5, 0, 0);
		
		var sphereMesh2 = new Geometry("Sphere Geom2", sphere);
		sphereMesh2.setTranslationXYZ(-1.5, 0, 0);
		sphereMesh2.setMaterial(mat);
		
		scene.attachChild(sphereMesh);
		scene.attachChild(sphereMesh2);
		
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.1, 0.1, 0.1, 1);
		scene.addLight(al);
		
		pl = new PointLight();
		pl.color = new Color(1, 0, 0, 1);
		pl.radius = 4;
		scene.addLight(pl);
		
		pointLightNode = createLightNode(pl, 0.1);
		scene.attachChild(pointLightNode);

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
			angle = angle % FastMath.TWO_PI;
			pl.color = Color.Random();
			cast(pointLightNode.getChildByName("debugNode"),Geometry).getMaterial().setColor("u_MaterialColor", pl.color);
		}
		pointLightNode.setTranslationXYZ(Math.cos(angle) * 3, 0.5, Math.sin(angle) * 3);
	}
}