package examples.model;

import examples.skybox.DefaultSkyBox;
import flash.utils.ByteArray;
import hu.vpmedia.assets.AssetLoader;
import org.angle3d.app.SimpleApplication;
import org.angle3d.io.parser.max3ds.Max3DSParser;
import org.angle3d.io.parser.ParserOptions;
import org.angle3d.material.MaterialTexture;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;


class Max3DSParserTest extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new Max3DSParserTest());
	}
	
	private var angle:Float;

	private var baseURL:String;

	public function new()
	{
		super();

		angle = 0;
	}

	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		//flyCam.setDragToRotate(true);
		
		baseURL = "max3ds/";
		var assetLoader:AssetLoader = new AssetLoader();
		assetLoader.add(baseURL + "ship.3ds");
		assetLoader.add(baseURL + "ship.jpg");
		assetLoader.signalSet.completed.add(_loadComplete);
		assetLoader.execute();

		Stats.show(this.stage);
	}

	private function _loadComplete(assetLoader:AssetLoader):Void
	{
		var bitmapTexture:Texture2D = new Texture2D(assetLoader.get(baseURL + "ship.jpg").data.bitmapData);

		var material:MaterialTexture = new MaterialTexture(bitmapTexture);
		material.doubleSide = true;

		var sky:DefaultSkyBox = new DefaultSkyBox(500);
		scene.attachChild(sky);

		var data:ByteArray = assetLoader.get(baseURL + "ship.3ds").data;
		var parser:Max3DSParser = new Max3DSParser();
		parser.parse(data, new ParserOptions());

		var meshes:Array<Mesh> = parser.meshes;
		
		for (i in 0...meshes.length)
		{
			var geom:Geometry = new Geometry("ship" + i, meshes[i]);
			
			trace(geom.name);

			geom.setMaterial(material);

			scene.attachChild(geom);
		}

		
		start();
	}

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.02;
		angle %= FastMath.TWO_PI();


		camera.location.setTo(Math.cos(angle) * 800, 200, Math.sin(angle) * 800);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}

