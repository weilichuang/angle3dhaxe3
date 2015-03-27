package examples.material;
import examples.skybox.DefaultSkyBox;
import flash.display.BitmapData;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.Lib;
import org.angle3d.app.SimpleApplication;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.ui.Picture;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/no-shader.png") class DECALMAP_ASSET extends flash.display.BitmapData { }
@:bitmap("../assets/embed/wood.jpg") class WOOD_ASSET extends flash.display.BitmapData { }

class MaterialLoaderTest extends SimpleApplication
{
	static function main()
	{
		Lib.current.addChild(new MaterialLoaderTest());
	}

	public function new() 
	{
		super();
	}
	
	private var mat:Material;
	private var mat2:Material;
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		mCamera.location = (new Vector3f(3, 3, 3));
        mCamera.lookAt(Vector3f.ZERO, Vector3f.Y_AXIS);
		
		var sky : DefaultSkyBox = new DefaultSkyBox(500);
		scene.attachChild(sky);
		
		var texture:Texture2D = new BitmapTexture(new DECALMAP_ASSET(0, 0), false);
		var texture2:Texture2D = new BitmapTexture(new WOOD_ASSET(0,0), false);

		mat = new Material();
		mat.load("assets/material/unshaded.mat");
		mat.setTexture("u_DiffuseMap",  texture);
		
		mat2 = new Material();
		mat2.load("assets/material/unshaded.mat");
		mat2.setTexture("u_DiffuseMap", texture);
		mat2.setTexture("u_LightMap", texture2);
		
		var image = new Picture("image", false);
		image.move(new Vector3f(0, 0, 0));
		image.setPosition(400, 300);
		image.setSize(256, 256);
		image.setTexture(texture, false);
		
		//mGui.attachChild(image);
		
		//setup main scene
        var quad0:Geometry = new Geometry("box", new Box(0.5, 0.5, 0.5));
        quad0.setMaterial(mat);
        mScene.attachChild(quad0);
		
		//setup main scene
        var quad2:Geometry = new Geometry("box2", new Box(0.5, 0.5, 0.5));
		quad2.getMesh().setVertexBuffer(BufferType.TEXCOORD2, 2, quad2.getMesh().getVertexBuffer(BufferType.TEXCOORD).getData().concat());
		quad2.setTranslationXYZ(1, 0, 0.5);

        quad2.setMaterial(mat2);
        mScene.attachChild(quad2);
		
		var quad3:Geometry = new Geometry("box3", new Box(0.5, 0.5, 0.5));
		quad3.setTranslationXYZ(1, 0, 1.5);
        quad3.setMaterial(mat);
        mScene.attachChild(quad3);

		this.stage.addEventListener(MouseEvent.CLICK, onClick);
		
		Stats.show(stage);
		start();
	}
	
	private function onClick(event:Event):Void
	{
		if(mat != null)
			mat.setColor("u_MaterialColor", new Color(Math.random(), Math.random(), Math.random(), 1));
		if(mat2 != null)
			mat2.setColor("u_MaterialColor", new Color(Math.random(), Math.random(), Math.random(), 1));
	}
	
	override public function simpleUpdate(tpf:Float):Void
	{
	}
}