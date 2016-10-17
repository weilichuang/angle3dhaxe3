package examples.light;
import flash.ui.Keyboard;
import flash.Vector;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.PointLight;
import org.angle3d.material.LightMode;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/wood.jpg") class ROCK_ASSET extends flash.display.BitmapData { }

class TestLightRadius extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestLightRadius());
	}

	public function new() 
	{
		super();
		Angle3D.maxAgalVersion = 2;
	}
	
	private var pl:PointLight;
	private var lightModel:Geometry;
	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(false);
		flyCam.setEnabled(false);
		
		mRenderManager.setPreferredLightMode(LightMode.MultiPass);
		
		var texture:BitmapTexture = new BitmapTexture(new ROCK_ASSET(0, 0));
		
		var sphere:Sphere = new Sphere(1.5, 16, 16, true);
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
		
		var sphere:Sphere = new Sphere(0.1, 10, 10);
		var mat2:Material = new Material();
		mat2.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat2.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, texture);
		
		lightModel = new Geometry("Light", sphere);
		lightModel.setMaterial(mat2);
		scene.attachChild(lightModel);
		
		pl = new PointLight();
		pl.color = new Color(1, 0, 0, 1);
		pl.radius = 16;
		scene.addLight(pl);
		
		pl.position = new Vector3f(1, 0, 2);
		lightModel.setLocalTranslation(pl.position);

		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.1, 0.1, 0.1, 1);
		scene.addLight(al);
		
		mInputManager.addTrigger("up", new KeyTrigger(Keyboard.UP));
		mInputManager.addTrigger("down", new KeyTrigger(Keyboard.DOWN));
		mInputManager.addListener(this, Vector.ofArray(["up","down"]));
		
		
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
				pl.radius += 1;
			}
			else if (name == "down")
			{
				pl.radius -= 1;
			}
			
			pl.radius = FastMath.clamp(pl.radius, 2, 128);
		}
	}
	
	private var pos:Float = 0;
	private var vel:Int = -1;
	override public function simpleUpdate(tpf : Float) : Void
	{
		super.simpleUpdate(tpf);
		
		pos += tpf * vel * 5;
        if (pos > 15)
		{
            vel *= -1;
        }
		else if (pos < -15)
		{
            vel *= -1;
        }
		
		pl.position = new Vector3f(pos, 3, 1);
		lightModel.setLocalTranslation(pl.position);
	}
}