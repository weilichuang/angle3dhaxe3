package examples.material;
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
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/no-shader.png") class DECALMAP_ASSET extends flash.display.BitmapData { }
@:bitmap("../assets/embed/wood.jpg") class DECALMAP_ASSET2 extends flash.display.BitmapData { }

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
		
		var texture:Texture2D = new Texture2D(new DECALMAP_ASSET(0, 0), false);
		var texture2:Texture2D = new Texture2D(new DECALMAP_ASSET2(0,0), false);

		mat = new Material();
		mat.load("assets/material/unshaded.mat");
		
		mat2 = new Material();
		mat2.load("assets/material/unshaded.mat");
		
		mat.setTextureParam("s_texture", VarType.TEXTURE2D, texture);
		mat.setTextureParam("s_lightmap", VarType.TEXTURE2D, null);
		
		mat2.setTextureParam("s_texture", VarType.TEXTURE2D, texture);
		mat2.setTextureParam("s_lightmap", VarType.TEXTURE2D, texture2);
		
		//setup main scene
        var quad0:Geometry = new Geometry("box", new Box(0.5, 0.5, 0.5));
        quad0.setMaterial(mat);
        mScene.attachChild(quad0);
		
		//setup main scene
        var quad2:Geometry = new Geometry("box", new Box(0.5, 0.5, 0.5));
		quad2.getMesh().setVertexBuffer(BufferType.TEXCOORD2, 2, quad2.getMesh().getVertexBuffer(BufferType.TEXCOORD).getData().concat());
		quad2.setTranslationXYZ(1, 0, 0);

        quad2.setMaterial(mat2);
        mScene.attachChild(quad2);

		this.stage.addEventListener(MouseEvent.CLICK, onClick);
		
		Stats.show(stage);
		start();
	}
	
	private function onClick(event:Event):Void
	{
		if(mat != null)
			mat.setColor("u_ambientColor", new Color(Math.random(), Math.random(), Math.random(), 1));
		if(mat2 != null)
			mat2.setColor("u_ambientColor", new Color(Math.random(), Math.random(), Math.random(), 1));
	}
	
	override public function simpleUpdate(tpf:Float):Void
	{
	}
}