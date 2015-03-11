package examples.model;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import assets.manager.misc.FileType;
import examples.skybox.DefaultSkyBox;
import flash.display.BitmapData;
import flash.utils.ByteArray;
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

		baseURL = "max3ds/";
		
		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueBinary(baseURL + "ship.3ds");
		assetLoader.queueImage(baseURL + "ship.jpg");
		assetLoader.queueImage(baseURL + "no-shader.png");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();

		Stats.show(this.stage);
	}
	
	private function _loadComplete(files:Array<FileInfo>):Void
	{
		flyCam.setDragToRotate(true);
		
		var byteArray:ByteArray = null;
		var bitmapData:BitmapData = null;
		var lightmapData:BitmapData = null;
		for (i in 0...files.length)
		{
			if (files[i].type == FileType.BINARY)
			{
				byteArray = files[i].data;
			}
			else if (files[i].type == FileType.IMAGE)
			{
				if (files[i].id == baseURL + "ship.jpg")
				{
					bitmapData = files[i].data;
				}
				else
				{
					lightmapData = files[i].data;
				}
			}
		}
		
		var texture = new Texture2D(bitmapData);
		
		var mat2:Material = new Material();
		mat2.load("assets/material/unshaded.mat");
		mat2.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, texture);
		mat2.setTextureParam("u_LightMap", VarType.TEXTURE2D, new Texture2D(lightmapData));
		mat2.getAdditionalRenderState().setCullMode(CullMode.NONE);
		
		var sky:DefaultSkyBox = new DefaultSkyBox(500);
		scene.attachChild(sky);

		var parser:Max3DSParser = new Max3DSParser();
		parser.parse(byteArray, new ParserOptions());

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

