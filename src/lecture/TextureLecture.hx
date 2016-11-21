package lecture;
import flash.ui.Keyboard;
import flash.Vector;
import lecture.BasicLecture;
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
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Cube;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.WrapMode;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/wood.jpg") class ROCK_ASSET extends flash.display.BitmapData { }


class TextureLecture extends BasicLecture
{
	static function main() 
	{
		flash.Lib.current.addChild(new TextureLecture());
	}

	private var box:Cube;
	private var bitmapTexture:BitmapTexture;
	private var scaleTexture:Bool = false;
	public function new() 
	{
		super();
		
		Angle3D.maxAgalVersion = 2;
	}
	
	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		bitmapTexture = new BitmapTexture(new ROCK_ASSET(0, 0));
		
		box = new Cube(3, 3, 1, 5, 5, 5);
		
		var boxMesh:Geometry = new Geometry("Sphere Geom", box);
		
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, bitmapTexture);
		boxMesh.setMaterial(mat);
		
		scene.attachChild(boxMesh);
		
		mInputManager.addTrigger("scaleTexture", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addListener(this, Vector.ofArray(["scaleTexture"]));
		
		start();
		
		camera.location.setTo(0, 0, 6);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		showMsg("Press Space to change wrapMode");
	}
	
	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		super.onAction(name, value, tpf);
		
		if (name == "scaleTexture" && value)
		{
			scaleTexture = !scaleTexture;
			if (scaleTexture)
			{
				box.scaleTextureCoordinates(new Vector2f(10, 10));
				bitmapTexture.wrapMode = WrapMode.REPEAT;
			}
			else
			{
				box.scaleTextureCoordinates(new Vector2f(0.1, 0.1));
				bitmapTexture.wrapMode = WrapMode.CLAMP;
			}
		}
	}
	
	override public function simpleUpdate(tpf : Float) : Void
	{
		super.simpleUpdate(tpf);
	}
}