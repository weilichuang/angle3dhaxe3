package examples.io;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.Lib;
import flash.utils.ByteArray;
import hu.vpmedia.assets.AssetLoader;
import hu.vpmedia.assets.AssetLoaderVO;
import hu.vpmedia.assets.loaders.AssetLoaderType;
import hu.vpmedia.assets.parsers.AssetParserType;
import org.angle3d.app.SimpleApplication;
import org.angle3d.io.parser.material.MaterialParser;
import org.angle3d.material.Material;
import org.angle3d.material.MaterialDef;
import org.angle3d.material.shader.DefineList;
import org.angle3d.material.VarType;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/no-shader.png") class DECALMAP_ASSET extends flash.display.BitmapData { }

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
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		mCamera.location = (new Vector3f(3, 3, 3));
        mCamera.lookAt(Vector3f.ZERO, Vector3f.Y_AXIS);

		var mat:Material = new Material();
		mat.load("assets/material/unshaded.mat", onMaterialLoaded);
	}
	
	private function onMaterialLoaded(material:Material):Void
	{
		var texture:Texture2D = new Texture2D(new BitmapData(512, 512, false, 0xff0000), false);
		var texture2:Texture2D = new Texture2D(new BitmapData(512, 512, false, 0x00ff00), false);
		
		material.setTextureParam("s_texture", VarType.TEXTURE2D, texture);
		material.setTextureParam("s_lightmap", VarType.TEXTURE2D, texture2);
		
		
		//setup main scene
        var quad:Geometry = new Geometry("box", new Box(1, 1, 1));

        quad.setMaterial(material);
        mScene.attachChild(quad);

		Stats.show(stage);
		start();
	}
	
	override public function simpleUpdate(tpf:Float):Void
	{
	}
}