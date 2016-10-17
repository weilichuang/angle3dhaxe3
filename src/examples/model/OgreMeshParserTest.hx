package examples.model;

import org.angle3d.asset.FilesLoader;
import org.angle3d.asset.FileInfo;
import flash.Vector;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.animation.AnimChannel;
import org.angle3d.animation.AnimControl;
import org.angle3d.animation.Animation;
import org.angle3d.animation.Skeleton;
import org.angle3d.animation.SkeletonControl;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.io.parser.ogre.OgreMeshXmlParser;
import org.angle3d.io.parser.ogre.OgreSkeletonParser;
import org.angle3d.material.Material;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.BitmapTexture;

class OgreMeshParserTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new OgreMeshParserTest());
	}
	
	private var baseURL:String;
	public function new()
	{
		Angle3D.maxAgalVersion = 2;
		super();
	}
	
	private var _loadedCount:Int = 0;
	private var _loadCount:Int = 0;
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "../assets/ogre/sinbad/";

		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueText(baseURL + "sinbad.mesh.xml");
		assetLoader.queueText(baseURL + "Sword.mesh.xml");
		assetLoader.queueText(baseURL + "Sinbad.skeleton.xml");
		assetLoader.queueImage(baseURL + "sinbad_body.jpg");
		assetLoader.queueImage(baseURL + "sinbad_clothes.jpg");
		assetLoader.queueImage(baseURL + "sinbad_sword.jpg");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.onFileLoaded.add(_loadFile);
		assetLoader.loadQueuedFiles();
		
		_loadCount = assetLoader.getFileCount();
		
		showMsg("资源加载中"+_loadedCount+"/"+_loadCount+"...","center");
	}
	
	private function _loadFile(file:FileInfo):Void
	{
		_loadedCount++;
		showMsg("资源加载中" + _loadedCount + "/" + _loadCount + "...", "center");
	}

	private var skeletonParser:OgreSkeletonParser;
	private var sinbadMeshes:Vector<Mesh>;
	private var swordMeshes:Vector<Mesh>;
	
	private var bodyMaterial:Material;
	private var clothesMaterial:Material;
	private var swordMaterial:Material;
	private var swordTexture:BitmapTexture;
	private function _loadComplete(loader:FilesLoader):Void
	{
		bodyMaterial = new Material();
		bodyMaterial.load(Angle3D.materialFolder + "material/unshaded.mat");
		bodyMaterial.setTexture("u_DiffuseMap", new BitmapTexture(loader.getAssetByUrl(baseURL + "sinbad_body.jpg").info.content));
		
		clothesMaterial = new Material();
		clothesMaterial.load(Angle3D.materialFolder + "material/unshaded.mat");
		clothesMaterial.setTexture("u_DiffuseMap", new BitmapTexture(loader.getAssetByUrl(baseURL + "sinbad_clothes.jpg").info.content));
		
		swordTexture = new BitmapTexture(loader.getAssetByUrl(baseURL + "sinbad_sword.jpg").info.content);
		swordMaterial = new Material();
		swordMaterial.load(Angle3D.materialFolder + "material/unshaded.mat");
		swordMaterial.setTexture("u_DiffuseMap", swordTexture);
		
		var parser:OgreMeshXmlParser = new OgreMeshXmlParser();
		sinbadMeshes = parser.parse(loader.getAssetByUrl(baseURL + "sinbad.mesh.xml").info.content);
		swordMeshes = parser.parse(loader.getAssetByUrl(baseURL + "Sword.mesh.xml").info.content);
		
		showMsg("骨骼动画解析中...", "center");
		
		skeletonParser = new OgreSkeletonParser();
		skeletonParser.addEventListener(Event.COMPLETE, onSkeletonParseComplete);
		skeletonParser.parse(loader.getAssetByUrl(baseURL + "Sinbad.skeleton.xml").info.content);
	}
	
	private var channel:AnimChannel;
	private var index:Int = 0;
	private var animations:Vector<Animation>;
	private function onSkeletonParseComplete(event:Event):Void
	{
		hideMsg();
		
		var skeleton:Skeleton = skeletonParser.skeleton;
		animations = skeletonParser.animations;
		
		var node:Node = new Node("sinbad");
		
		for (i in 0...sinbadMeshes.length)
		{
			var mesh:Mesh = sinbadMeshes[i];
			var geometry:Geometry = new Geometry(mesh.id, mesh);
			switch(mesh.id)
			{
				case "Sinbad/Body","Sinbad/Teeth","Sinbad/Eyes":
					geometry.setMaterial(bodyMaterial);
				case "Sinbad/Gold","Sinbad/Clothes","Sinbad/Spikes":
					geometry.setMaterial(clothesMaterial);
				case "Sinbad/Sheaths":
					geometry.setMaterial(swordMaterial);
				default:
					geometry.setMaterial(bodyMaterial);
			}
			node.attachChild(geometry);
		}
		
		var nodeRight:Node = new Node("right_sword");
		var swordMaterial2 = new Material();
		swordMaterial2.load(Angle3D.materialFolder + "material/unshaded.mat");
		swordMaterial2.setTexture("u_DiffuseMap", swordTexture);
		for (i in 0...swordMeshes.length)
		{
			var mesh:Mesh = swordMeshes[i];
			var geometry:Geometry = new Geometry(mesh.id, mesh);
			geometry.setMaterial(swordMaterial2);
			nodeRight.attachChild(geometry);
		}
		
		var nodeLeft:Node = new Node("lefg_sword");
		var swordMaterial3 = new Material();
		swordMaterial3.load(Angle3D.materialFolder + "material/unshaded.mat");
		swordMaterial3.setTexture("u_DiffuseMap", swordTexture);
		for (i in 0...swordMeshes.length)
		{
			var mesh:Mesh = swordMeshes[i];
			var geometry:Geometry = new Geometry(mesh.id, mesh);
			geometry.setMaterial(swordMaterial3);
			nodeLeft.attachChild(geometry);
		}
		
		skeleton.getBoneByName("Handle.R").setAttachmentsNode(nodeRight);
		node.attachChild(nodeRight);
		
		skeleton.getBoneByName("Handle.L").setAttachmentsNode(nodeLeft);
		node.attachChild(nodeLeft);
		
		scene.attachChild(node);
		
		var skeletonControl:SkeletonControl = new SkeletonControl(skeleton);
		
		var animationControl:AnimControl = new AnimControl(skeleton);
		
		for (i in 0...animations.length)
		{
			animationControl.addAnimation(animations[i]);
		}
		
		node.addControl(skeletonControl);
		node.addControl(animationControl);
		
		channel = animationControl.createChannel();
		channel.setLoopMode(LoopMode.Loop);
		channel.setSpeed(1);
		
		camera.location.setTo(0, 0, 20);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		flyCam.setDragToRotate(true);
		reshape(mContextWidth, mContextHeight);
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		
		playAnimation(animations[0].name);
		
		start();
		
	}
	
	private function onKeyDown(event:KeyboardEvent):Void
	{
		if (animations == null)
			return;
			
		if (event.keyCode == Keyboard.TAB)
		{
			index++;
			if (index >= animations.length)
			{
				index = 0;	
			}
			playAnimation(animations[index].name);
		}
	}
	
	private function playAnimation(name:String):Void
	{
		showMsg("按Tab切换动画，当前动画："+name);
		channel.setAnim(name, 0);
	}

	private var angle:Float = -1.5;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.01;
		angle %= FastMath.TWO_PI;
	}
}
