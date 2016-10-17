package examples.model;

import flash.Vector;
import flash.events.Event;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.asset.FileInfo;
import org.angle3d.asset.FilesLoader;
import org.angle3d.asset.LoaderType;
import org.angle3d.io.parser.obj.MtlParser;
import org.angle3d.io.parser.obj.ObjParser;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.PointLight;
import org.angle3d.material.BlendMode;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.shadow.BasicShadowRenderer;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.MipFilter;
import org.angle3d.texture.TextureFilter;
import org.angle3d.texture.WrapMode;

class HouseTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new HouseTest());
	}
	
	private var baseURL:String;
	public function new()
	{
		super();
		Angle3D.maxAgalVersion = 2;
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		mRenderer.setAntiAlias(0);

		baseURL = "../assets/room/";
		
		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueFile(baseURL + "interior.obj",LoaderType.TEXT);
		assetLoader.queueFile(baseURL + "interior.mtl",LoaderType.TEXT);
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
		
		//TODO single pass光照有问题
		//mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		//mRenderManager.setSinglePassLightBatchSize(4);

		showMsg("模型加载中...","center");
	}

	private var mtlInfos:Vector<MtlInfo>;
	private var _objSource:String;
	private var _textureTotal:Int;
	private var _textureCurrent:Int;
	private var textureLoader:FilesLoader;
	private function _loadComplete(loader:FilesLoader):Void
	{
		_objSource = loader.getAssetByUrl(baseURL + "interior.obj").info.content;
		
		mtlInfos = new MtlParser().parse(loader.getAssetByUrl(baseURL + "interior.mtl").info.content);
		textureLoader = new FilesLoader();
		for (i in 0...mtlInfos.length)
		{
			var info:MtlInfo = mtlInfos[i];
			if (info.diffuseMap != null)
			{
				//info.diffuseMap = StringUtil.changeExtension(info.diffuseMap, "atf");
				textureLoader.queueFile(baseURL + info.diffuseMap,LoaderType.IMAGE);
			}
			
			if (info.ambientMap != null)
			{
				//info.ambientMap = StringUtil.changeExtension(info.ambientMap, "atf");
				if (info.ambientMap != info.diffuseMap)
				{
					textureLoader.queueFile(baseURL + info.ambientMap,LoaderType.IMAGE);
				}
			}
			
			if (info.alphaMap != null)
			{
				//info.alphaMap = StringUtil.changeExtension(info.alphaMap, "atf");
				textureLoader.queueFile(baseURL + info.alphaMap,LoaderType.IMAGE);
			}
			
			
			if (info.bumpMap != null)
			{
				//info.bumpMap = StringUtil.changeExtension(info.bumpMap, "atf");
				textureLoader.queueFile(baseURL + info.bumpMap,LoaderType.IMAGE);
			}
		}
		
		_textureCurrent = 0;
		_textureTotal = textureLoader.getFileCount();
		
		showMsg("加载纹理中，剩余"+_textureCurrent + "/" + _textureTotal + "...", "center");
		
		textureLoader.onFilesLoaded.addOnce(_onTextureLoaded);
		textureLoader.onFileLoaded.add(_onSingleTextureLoaded);
		textureLoader.loadQueuedFiles();
	}
	
	private function _onSingleTextureLoaded(file:FileInfo):Void
	{
		_textureCurrent++;
		showMsg(file.url + "加载完成,剩余" + _textureCurrent + "/" + _textureTotal + "...", "center");
	}
	
	private function getMtlInfo(id:String):MtlInfo
	{
		for (i in 0...mtlInfos.length)
		{
			if (mtlInfos[i].id == id)
				return mtlInfos[i];
		}
		return null;
	}
	
	private var _objParser:ObjParser;
	private var _materials:StringMap<Material>;
	private function _onTextureLoaded(loader:FilesLoader):Void
	{
		var textureMap:StringMap<BitmapTexture> = new StringMap<BitmapTexture>();
		_materials = new StringMap<Material>();
		for (i in 0...mtlInfos.length)
		{
			var info:MtlInfo = mtlInfos[i];
			
			var material:Material = new Material();
			material.load(Angle3D.materialFolder + "material/lighting.mat");
			material.setFloat("u_Shininess", info.shininess);
			material.setBoolean("useMaterialColor", false);
			material.setBoolean("useVertexLighting", false);
			material.setBoolean("useLowQuality", false);
			material.setColor("u_Ambient",  info.ambient);
			material.setColor("u_Diffuse",  info.diffuse);
			material.setColor("u_Specular", info.specular);
			
			var fileInfo:FileInfo = loader.getAssetByUrl(baseURL + info.diffuseMap);
			if (fileInfo != null && fileInfo.info != null)
			{
				var texture:BitmapTexture = textureMap.get(baseURL + info.diffuseMap);
				if (texture == null)
				{
					texture = new BitmapTexture(fileInfo.info.content);
					texture.mipFilter = MipFilter.MIPNONE;
					texture.textureFilter = TextureFilter.LINEAR;
					texture.wrapMode = WrapMode.REPEAT;
					
					textureMap.set(baseURL + info.diffuseMap, texture);
				}
				material.setTexture("u_DiffuseMap", texture);
			}
			
			if (info.ambientMap != null && info.ambientMap != "" && info.ambientMap != info.diffuseMap)
			{
				fileInfo = loader.getAssetByUrl(baseURL + info.ambientMap);
				if (fileInfo != null && fileInfo.info != null)
				{
					var texture:BitmapTexture = textureMap.get(baseURL + info.ambientMap);
					if (texture == null)
					{
						texture = new BitmapTexture(fileInfo.info.content);
						texture.mipFilter = MipFilter.MIPNONE;
						texture.textureFilter = TextureFilter.LINEAR;
						texture.wrapMode = WrapMode.REPEAT;
						
						textureMap.set(baseURL + info.ambientMap, texture);
					}
					material.setTexture("u_LightMap", texture);
				}
			}
			
			if (info.bumpMap != null && info.bumpMap != "")
			{
				fileInfo = loader.getAssetByUrl(baseURL + info.bumpMap);
				if (fileInfo != null && fileInfo.info != null)
				{
					var texture:BitmapTexture = textureMap.get(baseURL + info.bumpMap);
					if (texture == null)
					{
						texture = new BitmapTexture(fileInfo.info.content);
						texture.mipFilter = MipFilter.MIPNONE;
						texture.textureFilter = TextureFilter.LINEAR;
						texture.wrapMode = WrapMode.REPEAT;
						
						textureMap.set(baseURL + info.bumpMap, texture);
					}
					//material.setTexture("u_NormalMap", texture);
				}
			}
			
			if (info.alphaMap != null && info.alphaMap != "")
			{
				fileInfo = loader.getAssetByUrl(baseURL + info.alphaMap);
				if (fileInfo != null && fileInfo.info != null)
				{
					var texture:BitmapTexture = textureMap.get(baseURL + info.alphaMap);
					if (texture == null)
					{
						texture = new BitmapTexture(fileInfo.info.content);
						texture.mipFilter = MipFilter.MIPNONE;
						texture.textureFilter = TextureFilter.LINEAR;
						texture.wrapMode = WrapMode.REPEAT;
						
						textureMap.set(baseURL + info.alphaMap, texture);
					}
					material.setTexture("u_AlphaMap", texture);
					material.getAdditionalRenderState().setBlendMode(BlendMode.Alpha);
					material.setTransparent(true);
				}
			}
			
			_materials.set(info.id, material);
		}
		
		showMsg("解析模型中...", "center");
		
		_objParser = new ObjParser();
		_objParser.addEventListener(Event.COMPLETE, onParseComplete);
		_objParser.asyncParse(_objSource);
	}
	
	private var basicShadowRender:BasicShadowRenderer;
	private function onParseComplete(event:Event):Void
	{
		hideMsg();
		
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(1000);
		
		var am:AmbientLight = new AmbientLight();
		am.color = new Color(0.5, 0.5, 0.5);
		scene.addLight(am);
		
		var pl = new PointLight();
		pl.color = Color.Random();
		pl.radius = 5000;
		pl.position = new Vector3f(0, 500, 0);
		scene.addLight(pl);
		
		//pl = new PointLight();
		//pl.color = Color.Random();
		//pl.radius = 5000;
		//pl.position = new Vector3f(500, 500, 0);
		//scene.addLight(pl);
		//
		//pl = new PointLight();
		//pl.color = Color.Random();
		//pl.radius = 5000;
		//pl.position = new Vector3f(-500, 500, 0);
		//scene.addLight(pl);
		
		var meshes:Vector<Dynamic> = _objParser.getMeshes();
		for (i in 0...meshes.length)
		{
			var meshInfo:Dynamic = meshes[i];
			
			var mesh:Mesh = meshInfo.mesh;
			
			if (getMtlInfo(meshInfo.mtl).bumpMap != null)
			{
				//TangentBinormalGenerator.generateMesh(mesh);
				getMtlInfo(meshInfo.mtl).bumpMap = null;
			}
			
			var geomtry:Geometry = new Geometry(meshInfo.name, mesh);
			
			if(meshInfo.mtl != "floor")
				geomtry.localShadowMode = ShadowMode.CastAndReceive;
			else
				geomtry.localShadowMode = ShadowMode.Receive;
			
			scene.attachChild(geomtry);
			
			var mat:Material = _materials.get(meshInfo.mtl);
			geomtry.setMaterial(mat);
		}
		
		camera.frustumFar = 15000;
		camera.location.setTo(0, 0, 200);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		basicShadowRender= new BasicShadowRenderer(1024);
		basicShadowRender.setShadowInfo(0.008, 0.6, false);
		basicShadowRender.setDirection(new Vector3f(0, -1, 0.1).normalizeLocal());
		//viewPort.addProcessor(basicShadowRender);
		
		
		//var fpp:FilterPostProcessor = new FilterPostProcessor();
		//var blackAndWhiteFilter:BlackAndWhiteFilter = new BlackAndWhiteFilter();
		//fpp.addFilter(blackAndWhiteFilter);
		//viewPort.addProcessor(fpp);
		
		camera.setLocation(new Vector3f(0, 150, 150));
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		start();
	}

	override public function simpleUpdate(tpf:Float):Void
	{
		super.simpleUpdate(tpf);
	}
	
}