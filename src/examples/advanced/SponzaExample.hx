package examples.advanced;

import flash.Vector;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.net.FileReference;
import flash.ui.Keyboard;
import flash.utils.ByteArray;
import haxe.Timer;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.asset.FileInfo;
import org.angle3d.asset.FilesLoader;
import org.angle3d.asset.LoaderType;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.cinematic.MotionPath;
import org.angle3d.cinematic.events.DirectionType;
import org.angle3d.cinematic.events.MotionEvent;
import org.angle3d.io.parser.ang.AngReader;
import org.angle3d.io.parser.obj.MtlParser;
import org.angle3d.io.parser.obj.ObjParser;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.SpotLight;
import org.angle3d.material.BlendMode;
import org.angle3d.material.LightMode;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Quaternion;
import org.angle3d.math.SplineType;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.shadow.BasicShadowRenderer;
import org.angle3d.texture.ATFTexture;
import org.angle3d.texture.MipFilter;
import org.angle3d.texture.TextureFilter;
import org.angle3d.texture.WrapMode;
import org.angle3d.utils.Logger;
import org.angle3d.utils.StringUtil;
import org.angle3d.utils.TangentBinormalGenerator;
import org.angle3d.io.parser.ang.AngWriter;

class SponzaExample extends BasicExample
{

	static function main() 
	{
		flash.Lib.current.addChild(new SponzaExample());
	}
	
	private var baseURL:String;
	private var mtlInfos:Vector<MtlInfo>;
	private var _objSource:String;
	private var _textureTotal:Int;
	private var _textureCurrent:Int;
	private var textureLoader:FilesLoader;
	private var _objParser:ObjParser;
	private var _materials:StringMap<Material>;
	
	private var path:MotionPath;
	private var motionNode:Node;
	private var motionControl:MotionEvent;
	private var target:Vector3f;
	
	private var needTangentMeshes:Vector<Geometry>;
	private var exportMeshes:Vector<Mesh>;
	
	private var pl:DirectionalLight;
	private var basicShadowRender:BasicShadowRenderer;
	
	public function new()
	{
		super();
		Angle3D.maxAgalVersion = 2;
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		mRenderer.setAntiAlias(2);

		baseURL = "../assets/sponza/";
		
		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueFile(baseURL + "sponza.obj",LoaderType.TEXT);
		assetLoader.queueFile(baseURL + "sponza.mtl",LoaderType.TEXT);
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
		
		//TODO single pass光照有问题
		mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		mRenderManager.setSinglePassLightBatchSize(4);

		showMsg("模型加载中...","center");
	}

	
	private function _loadComplete(loader:FilesLoader):Void
	{
		_objSource = loader.getAssetByUrl(baseURL + "sponza.obj").info.content;
		
		mtlInfos = new MtlParser().parse(loader.getAssetByUrl(baseURL + "sponza.mtl").info.content);
		textureLoader = new FilesLoader();
		for (i in 0...mtlInfos.length)
		{
			var info:MtlInfo = mtlInfos[i];
			if (info.diffuseMap != null)
			{
				info.diffuseMap = StringUtil.changeExtension(info.diffuseMap, "atf");
				textureLoader.queueFile(baseURL + info.diffuseMap,LoaderType.BINARY);
			}
			
			if (info.ambientMap != null)
			{
				info.ambientMap = StringUtil.changeExtension(info.ambientMap, "atf");
				if (info.ambientMap != info.diffuseMap)
				{
					textureLoader.queueFile(baseURL + info.ambientMap,LoaderType.BINARY);
				}
			}
			
			if (info.alphaMap != null)
			{
				info.alphaMap = StringUtil.changeExtension(info.alphaMap, "atf");
				textureLoader.queueFile(baseURL + info.alphaMap,LoaderType.BINARY);
			}
			
			
			if (info.bumpMap != null)
			{
				info.bumpMap = StringUtil.changeExtension(info.bumpMap, "atf");
				textureLoader.queueFile(baseURL + info.bumpMap,LoaderType.BINARY);
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

	private function _onTextureLoaded(loader:FilesLoader):Void
	{
		var textureMap:StringMap<ATFTexture> = new StringMap<ATFTexture>();
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
				var texture:ATFTexture = textureMap.get(baseURL + info.diffuseMap);
				if (texture == null)
				{
					texture = new ATFTexture(fileInfo.info.content);
					texture.mipFilter = MipFilter.MIPLINEAR;
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
					var texture:ATFTexture = textureMap.get(baseURL + info.ambientMap);
					if (texture == null)
					{
						texture = new ATFTexture(fileInfo.info.content);
						texture.mipFilter = MipFilter.MIPLINEAR;
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
					var texture:ATFTexture = textureMap.get(baseURL + info.bumpMap);
					if (texture == null)
					{
						texture = new ATFTexture(fileInfo.info.content);
						texture.mipFilter = MipFilter.MIPLINEAR;
						texture.textureFilter = TextureFilter.LINEAR;
						texture.wrapMode = WrapMode.REPEAT;
						
						textureMap.set(baseURL + info.bumpMap, texture);
					}
					material.setTexture("u_NormalMap", texture);
				}
			}
			
			if (info.alphaMap != null && info.alphaMap != "")
			{
				fileInfo = loader.getAssetByUrl(baseURL + info.alphaMap);
				if (fileInfo != null && fileInfo.info != null)
				{
					var texture:ATFTexture = textureMap.get(baseURL + info.alphaMap);
					if (texture == null)
					{
						texture = new ATFTexture(fileInfo.info.content);
						texture.mipFilter = MipFilter.MIPLINEAR;
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
	
	private function onParseComplete(event:Event):Void
	{
		hideMsg();
		
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(1000);
		
		var am:AmbientLight = new AmbientLight();
		am.color = new Color(0.5, 0.5, 0.5);
		scene.addLight(am);
		
		pl = new DirectionalLight();
		pl.color = Color.White();
		pl.direction = new Vector3f(0.2, -1, 0.1).normalizeLocal();
		scene.addLight(pl);
		
		needTangentMeshes = new Vector<Geometry>();
		exportMeshes = new Vector<Mesh>();
		
		var meshes:Vector<Dynamic> = _objParser.getMeshes();
		for (i in 0...meshes.length)
		{
			var meshInfo:Dynamic = meshes[i];
			
			var mesh:Mesh = meshInfo.mesh;
			
			//先屏蔽竖幅
			if (meshInfo.name == "sponza_04")
				continue;
				
			exportMeshes.push(mesh);
				
			var geomtry:Geometry = new Geometry(meshInfo.name, mesh);
			
			if(meshInfo.mtl != "floor")
				geomtry.localShadowMode = ShadowMode.CastAndReceive;
			else
				geomtry.localShadowMode = ShadowMode.Receive;

			var mat:Material = _materials.get(meshInfo.mtl);
			geomtry.setMaterial(mat);
			
			if (getMtlInfo(meshInfo.mtl).bumpMap != null)
			{
				needTangentMeshes.push(geomtry);
			}
			else
			{
				scene.attachChild(geomtry);
			}
		}
		
		if (needTangentMeshes.length > 0)
		{
			var totalCount:Int = needTangentMeshes.length;
			showMsg("生成Tangent中0/"+totalCount+"...", "center");
			
			var timer:Timer = new Timer(100);
			timer.run = function():Void
			{
				var g:Geometry = needTangentMeshes.pop();
				TangentBinormalGenerator.generateMesh(g.getMesh());
				scene.attachChild(g);
				
				if (needTangentMeshes.length == 0)
				{
					hideMsg();
					timer.stop();
					beginRender();
				}
				else
				{
					showMsg("生成Tangent中" + (totalCount - needTangentMeshes.length) + "/" + totalCount + "...", "center");
				}
			}
		}
		else
		{
			beginRender();
		}
	}
	
	private function beginRender():Void
	{
		camera.frustumFar = 3000;
		camera.location.setTo(0, 0, 200);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		basicShadowRender= new BasicShadowRenderer(2048);
		basicShadowRender.setShadowInfo(0.005, 0.6, true);
		basicShadowRender.setDirection(pl.direction);
		basicShadowRender.setCheckCasterCulling(false);
		viewPort.addProcessor(basicShadowRender);
		
		addMotion();
		
		start();
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}
	
	private function addMotion():Void
	{
		path = new MotionPath();
		path.setCycle(true);

		path.addWayPoint(new Vector3f(979,150,-451));
		path.addWayPoint(new Vector3f(-1198,150,-412));
		path.addWayPoint(new Vector3f(-1174,150,391));
		path.addWayPoint(new Vector3f(1129,150,400));

		path.splineType = SplineType.CatmullRom;
		path.setCurveTension(0.2);
		path.onWayPointReach.add(onWayPointReach);
		
		motionNode = new Node("motionNOde");
		scene.attachChild(motionNode);
		
		target = path.getWayPoint(1);

		motionControl = new MotionEvent(motionNode, path, 10, LoopMode.Loop);
		motionControl.directionType = DirectionType.PathAndRotation;
		var rot : Quaternion = new Quaternion();
		rot.fromAngleAxis(-FastMath.HALF_PI, Vector3f.UNIT_Y);
		motionControl.setRotation(rot);
		motionControl.setInitialDuration(100);
		motionControl.setSpeed(2);
		motionControl.play();
	}
	
	private function onWayPointReach(control:MotionEvent, wayPointIndex:Int) : Void
	{
		//Logger.log("currentPointIndex is " + wayPointIndex);
		var index:Int = wayPointIndex >= path.numWayPoints - 1 ? 0 : wayPointIndex + 1;
		target = path.getWayPoint(index);
	}
	
	private function onKeyDown(event:KeyboardEvent):Void
	{
		if (event.keyCode == Keyboard.SPACE)
		{
			if (motionControl == null)
				return;
			if (motionControl.isEnabled())
			{
				motionControl.pause();
			}
			else
			{
				motionControl.play();
			}
		}
	}

	override public function simpleUpdate(tpf:Float):Void
	{
		super.simpleUpdate(tpf);
		
		if (motionNode != null && motionControl.isEnabled())
		{
			camera.setLocation(motionNode.getLocalTranslation());
			camera.lookAt(target, Vector3f.UNIT_Y);
		}
	}
	
}