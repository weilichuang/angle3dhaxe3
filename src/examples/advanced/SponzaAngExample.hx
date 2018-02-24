package examples.advanced;


import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.net.FileReference;
import flash.ui.Keyboard;
import flash.utils.ByteArray;
import haxe.Timer;
import haxe.ds.StringMap;
import angle3d.Angle3D;
import angle3d.asset.FileInfo;
import angle3d.asset.FilesLoader;
import angle3d.asset.LoaderType;
import angle3d.cinematic.LoopMode;
import angle3d.cinematic.MotionPath;
import angle3d.cinematic.events.DirectionType;
import angle3d.cinematic.events.MotionEvent;
import angle3d.input.controls.KeyTrigger;
import angle3d.io.parser.ang.AngReader;
import angle3d.io.parser.obj.MtlParser;
import angle3d.io.parser.obj.ObjParser;
import angle3d.light.AmbientLight;
import angle3d.light.DirectionalLight;
import angle3d.light.PointLight;
import angle3d.light.SpotLight;
import angle3d.material.BlendMode;
import angle3d.material.LightMode;
import angle3d.material.Material;
import angle3d.math.Color;
import angle3d.math.FastMath;
import angle3d.math.Quaternion;
import angle3d.math.SplineType;
import angle3d.math.Vector3f;
import angle3d.renderer.queue.ShadowMode;
import angle3d.scene.Geometry;
import angle3d.scene.LightNode;
import angle3d.scene.Node;
import angle3d.scene.mesh.Mesh;
import angle3d.scene.shape.Sphere;
import angle3d.shadow.BasicShadowRenderer;
import angle3d.texture.ATFTexture;
import angle3d.texture.MipFilter;
import angle3d.texture.TextureFilter;
import angle3d.texture.WrapMode;
import angle3d.utils.Logger;
import angle3d.utils.StringUtil;
import angle3d.utils.TangentBinormalGenerator;
import angle3d.io.parser.ang.AngWriter;

class SponzaAngExample extends BasicExample
{

	static function main() 
	{
		flash.Lib.current.addChild(new SponzaAngExample());
	}
	
	private var baseURL:String;
	private var mtlInfos:Array<MtlInfo>;
	private var _textureTotal:Int;
	private var _textureCurrent:Int;
	private var textureLoader:FilesLoader;
	private var _materials:StringMap<Material>;
	
	private var _angSource:ByteArray;
	private var _angReader:AngReader;
	
	private var path:MotionPath;
	private var motionNode:Node;
	private var motionControl:MotionEvent;
	private var motionSphere:Geometry;
	
	private var dirLight:DirectionalLight;
	private var pointLight:PointLight;
	private var pointLight2:PointLight;
	private var pointLight3:PointLight;
	private var basicShadowRender:BasicShadowRenderer;
	
	public function new()
	{
		super();
		Angle3D.maxAgalVersion = 2;
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
				
		mRenderer.setAntiAlias(0);

		baseURL = "../assets/sponza/";
		
		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueFile(baseURL + "sponza.ang",LoaderType.BINARY);
		assetLoader.queueFile(baseURL + "sponza.mtl",LoaderType.TEXT);
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
		
		mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		mRenderManager.setSinglePassLightBatchSize(4);

		showMsg("模型加载中...","center");
	}

	
	private function _loadComplete(loader:FilesLoader):Void
	{
		_angSource = loader.getAssetByUrl(baseURL + "sponza.ang").info.content;
		
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
			var useLight:Bool = true;
			
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
					useLight = false;
				}
			}
			
			if (useLight && info.bumpMap != null && info.bumpMap != "")
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
			
			if (useLight)
			{
				material.load(Angle3D.materialFolder + "material/lighting.mat");
				material.setFloat("u_Shininess", info.shininess);
				material.setBoolean("useVertexLighting", false);
				material.setBoolean("useLowQuality", false);
				material.setBoolean("useMaterialColor", false);
				material.setColor("u_Ambient",  info.ambient);
				material.setColor("u_Diffuse",  info.diffuse);
				material.setColor("u_Specular", info.specular);
			}
			else
			{
				material.load(Angle3D.materialFolder + "material/unshaded.mat");
			}
			
			_materials.set(info.id, material);
		}
		
		hideMsg();
		
		_angReader = new AngReader();
		var meshes:Array<Mesh> = _angReader.readMeshes(_angSource);
		for (i in 0...meshes.length)
		{
			var mesh:Mesh = meshes[i];

			//先屏蔽竖幅
			if (mesh.id == "sponza_04")
				continue;

			var geomtry:Geometry = new Geometry(mesh.id, mesh);
			
			if(mesh.extra != "floor")
				geomtry.localShadowMode = ShadowMode.CastAndReceive;
			else
				geomtry.localShadowMode = ShadowMode.Receive;

			var mat:Material = _materials.get(mesh.extra);
			geomtry.setMaterial(mat);
			
			scene.attachChild(geomtry);
		}
		
		beginRender();
	}
	
	private function beginRender():Void
	{
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(1000);
		
		var am:AmbientLight = new AmbientLight();
		am.color = new Color(0.2, 0.2, 0.2);
		scene.addLight(am);
		
		dirLight = new DirectionalLight();
		dirLight.color = new Color(0.5, 0.5, 0.5);
		dirLight.direction = new Vector3f(0.2, -1, 0.1).normalizeLocal();
		scene.addLight(dirLight);
		
		pointLight = new PointLight();
		pointLight.color = new Color(1, 0, 0);
		pointLight.radius = 500;
		scene.addLight(pointLight);
		
		pointLight2 = new PointLight();
		pointLight2.color = new Color(0, 1, 0);
		pointLight2.radius = 500;
		scene.addLight(pointLight2);
		
		pointLight3 = new PointLight();
		pointLight3.color = new Color(0, 0, 1);
		pointLight3.radius = 500;
		scene.addLight(pointLight3);
		
		camera.frustumFar = 3000;
		camera.location.setTo(957,250,-33);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		basicShadowRender= new BasicShadowRenderer(1024);
		basicShadowRender.setShadowInfo(0.005, 0.6, true);
		basicShadowRender.setDirection(dirLight.direction);
		basicShadowRender.setCheckCasterCulling(false);
		//viewPort.addProcessor(basicShadowRender);
		
		addRedMotion();
		addBlueMotion();
		addGreenMotion();
		
		start();

		mInputManager.addTrigger("motion", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addListener(this, ["motion"]);
	}
	
	private function addRedMotion():Void
	{
		path = new MotionPath();
		path.setCycle(true);

		path.addWayPoint(new Vector3f(979,150,-451));
		path.addWayPoint(new Vector3f(-1198,150,-412));
		path.addWayPoint(new Vector3f(-1174,150,391));
		path.addWayPoint(new Vector3f(1129,150,400));

		path.splineType = SplineType.CatmullRom;
		path.setCurveTension(0.2);
		//path.enableDebugShape(scene);
		
		path.onWayPointReach.add(onWayPointReach);
		
		var lightNode:LightNode = createLightNode(pointLight);
		
		scene.attachChild(lightNode);

		motionControl = new MotionEvent(lightNode, path, 100, LoopMode.Loop);
		motionControl.directionType = DirectionType.PathAndRotation;
		var rot : Quaternion = new Quaternion();
		rot.fromAngleAxis(-FastMath.HALF_PI, Vector3f.UNIT_Y);
		motionControl.setRotation(rot);
		motionControl.setSpeed(6);
		motionControl.play();
	}
	
	private function addBlueMotion():Void
	{
		var motionPath = new MotionPath();
		motionPath.setCycle(true);

		motionPath.addWayPoint(new Vector3f(-1198,150,-412));
		motionPath.addWayPoint(new Vector3f(-1174,150,391));
		motionPath.addWayPoint(new Vector3f(1129, 150, 400));
		motionPath.addWayPoint(new Vector3f(979,150,-451));

		motionPath.splineType = SplineType.CatmullRom;
		motionPath.setCurveTension(0.2);

		var lightNode:LightNode = createLightNode(pointLight2);
		
		scene.attachChild(lightNode);

		var motionControl = new MotionEvent(lightNode, motionPath, 100, LoopMode.Loop);
		motionControl.directionType = DirectionType.PathAndRotation;
		var rot : Quaternion = new Quaternion();
		rot.fromAngleAxis(-FastMath.HALF_PI, Vector3f.UNIT_Y);
		motionControl.setRotation(rot);
		motionControl.setSpeed(7);
		motionControl.play();
	}
	
	private function addGreenMotion():Void
	{
		var motionPath = new MotionPath();
		motionPath.setCycle(true);

		motionPath.addWayPoint(new Vector3f(-1174,150,391));
		motionPath.addWayPoint(new Vector3f(1129, 150, 400));
		motionPath.addWayPoint(new Vector3f(979, 150, -451));
		motionPath.addWayPoint(new Vector3f(-1198,150,-412));

		motionPath.splineType = SplineType.CatmullRom;
		motionPath.setCurveTension(0.2);
		
		var lightNode:LightNode = createLightNode(pointLight3);
		
		scene.attachChild(lightNode);

		var motionControl = new MotionEvent(lightNode, motionPath, 100, LoopMode.Loop);
		motionControl.directionType = DirectionType.PathAndRotation;
		var rot : Quaternion = new Quaternion();
		rot.fromAngleAxis(-FastMath.HALF_PI, Vector3f.UNIT_Y);
		motionControl.setRotation(rot);
		motionControl.setSpeed(8);
		motionControl.play();
	}
	
	private function onWayPointReach(control:MotionEvent, wayPointIndex:Int) : Void
	{
		//Logger.log("currentPointIndex is " + wayPointIndex);
	}
	
	override public function onAction(name:String, isPressed:Bool, tpf:Float):Void
	{
		super.onAction(name, isPressed, tpf);
		
		if (name == "motion" && isPressed)
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
	}
	
}