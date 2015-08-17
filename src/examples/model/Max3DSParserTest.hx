package examples.model;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import assets.manager.misc.FileType;
import examples.skybox.DefaultSkyBox;
import flash.display.BitmapData;
import flash.utils.ByteArray;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.io.parser.max3ds.Max3DSParser;
import org.angle3d.io.parser.ParserOptions;
import org.angle3d.material.CullMode;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.BitmapTexture;
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

		baseURL = "../assets/max3ds/";
		
		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueBinary(baseURL + "ship.3ds");
		assetLoader.queueImage(baseURL + "ship.jpg");
		assetLoader.queueImage(baseURL + "no-shader.png");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();

		Stats.show(this.stage);
	}
	
	private function _loadComplete(files:StringMap<FileInfo>):Void
	{
		flyCam.setDragToRotate(true);
		
		var texture = new BitmapTexture(files.get(baseURL + "ship.jpg").data);
		
		var mat2:Material = new Material();
		mat2.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat2.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, texture);
		mat2.setTextureParam("u_LightMap", VarType.TEXTURE2D, new BitmapTexture(files.get(baseURL + "no-shader.png").data));
		mat2.getAdditionalRenderState().setCullMode(CullMode.NONE);
		
		var sky:DefaultSkyBox = new DefaultSkyBox(500);
		scene.attachChild(sky);

		var parser:Max3DSParser = new Max3DSParser();
		parser.parse(files.get(baseURL + "ship.3ds").data, new ParserOptions());

		var meshes:Array<Mesh> = parser.meshes;
		
		for (i in 0...meshes.length)
		{
			var geom:Geometry = new Geometry("ship" + i, meshes[i]);
			
			geom.setMaterial(mat2);

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

