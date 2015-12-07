package examples.model;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.animation.Animation;
import org.angle3d.animation.AnimChannel;
import org.angle3d.animation.AnimControl;
import org.angle3d.animation.Skeleton;
import org.angle3d.animation.SkeletonControl;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.io.parser.ogre.OgreMeshXmlParser;
import org.angle3d.io.parser.ogre.OgreSkeletonParser;
import org.angle3d.material.Material;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;

class OgreMeshParserTest2 extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new OgreMeshParserTest2());
	}
	
	private var baseURL:String;
	public function new()
	{
		//Angle3D.maxAgalVersion = 2;
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "../assets/ogre/Oto/";

		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueText(baseURL + "Oto.mesh.xml");
		assetLoader.queueText(baseURL + "Oto.skeleton.xml");
		assetLoader.queueImage(baseURL + "Oto.jpg");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}

	private var skeletonParser:OgreSkeletonParser;
	private var meshes:Vector<Mesh>;

	private var material:Material;
	private function _loadComplete(files:StringMap<FileInfo>):Void
	{
		material = new Material(Angle3D.materialFolder + "material/unshaded.mat");
		material.setTexture("u_DiffuseMap", new BitmapTexture(files.get(baseURL + "Oto.jpg").data));
		
		var parser:OgreMeshXmlParser = new OgreMeshXmlParser();
		meshes = parser.parse(files.get(baseURL + "Oto.mesh.xml").data);

		skeletonParser = new OgreSkeletonParser();
		skeletonParser.addEventListener(Event.COMPLETE, onSkeletonParseComplete);
		skeletonParser.parse(files.get(baseURL + "Oto.skeleton.xml").data);
	}
	
	private var channel:AnimChannel;
	private var index:Int = 0;
	private var animations:Vector<Animation>;
	private function onSkeletonParseComplete(event:Event):Void
	{
		var skeleton:Skeleton = skeletonParser.skeleton;
		animations = skeletonParser.animations;
		
		var node:Node = new Node("Oto");
		
		for (i in 0...meshes.length)
		{
			var mesh:Mesh = meshes[i];
			var geometry:Geometry = new Geometry(mesh.id, mesh);
			geometry.setMaterial(material);
			node.attachChild(geometry);
		}

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
		channel.setLoopMode(LoopMode.Cycle);
		channel.setSpeed(1);
		
		camera.location.setTo(0, 0, 20);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
		
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
		showMsg("当前动画："+name);
		channel.setAnim(name, 0);
	}

	private var angle:Float = -1.5;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.01;
		angle %= FastMath.TWO_PI;
	}
}
