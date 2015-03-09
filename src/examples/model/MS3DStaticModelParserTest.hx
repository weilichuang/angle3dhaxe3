package examples.model;

import hu.vpmedia.assets.AssetLoader;
import hu.vpmedia.assets.AssetLoaderVO;
import org.angle3d.app.SimpleApplication;
import org.angle3d.io.parser.ms3d.MS3DParser;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;


class MS3DStaticModelParserTest extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new MS3DStaticModelParserTest());
	}
	
	private var baseURL:String;
	public function new()
	{
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "ms3d/";
		var assetLoader:AssetLoader = new AssetLoader();
		assetLoader.signalSet.completed.add(_loadComplete);
		assetLoader.add(baseURL + "ninja.ms3d");
		assetLoader.add(baseURL + "nskinbr.jpg");

		assetLoader.execute();

		Stats.show(stage);
	}

	private function _loadComplete(loader:AssetLoader):Void
	{
		var assetLoaderVO1:AssetLoaderVO = loader.get(baseURL + "ninja.ms3d");
		var assetLoaderVO2:AssetLoaderVO = loader.get(baseURL + "nskinbr.jpg");
		
		flyCam.setDragToRotate(true);
		
		var material:Material = new Material();
		material.load("assets/material/unshaded.mat");
		material.setTextureParam("s_texture", VarType.TEXTURE2D, new Texture2D(assetLoaderVO2.data.bitmapData));


		var parser:MS3DParser = new MS3DParser();
		
		var meshes:Array<Mesh> = parser.parseStaticMesh(assetLoaderVO1.data);
		
		for (i in 0...meshes.length)
		{
			var geomtry:Geometry = new Geometry("ninja" + i, meshes[i]);
			geomtry.setMaterial(material);
			scene.attachChild(geomtry);
			
			trace(geomtry.name);

			geomtry.setTranslationXYZ(0, -5, 0);
		}

		
		camera.location.setTo(0, 5, -20);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
		
		start();
	}

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.02;
		angle %= FastMath.TWO_PI();


		camera.location.setTo(Math.cos(angle) * 20, 0, Math.sin(angle) * 20);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}
