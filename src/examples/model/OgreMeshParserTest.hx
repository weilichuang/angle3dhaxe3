package examples.model;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import flash.events.Event;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.animation.Animation;
import org.angle3d.animation.AnimChannel;
import org.angle3d.animation.AnimControl;
import org.angle3d.animation.Skeleton;
import org.angle3d.animation.SkeletonControl;
import org.angle3d.app.SimpleApplication;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.io.parser.ogre.OgreMeshXmlParser;
import org.angle3d.io.parser.ogre.OgreSkeletonParser;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.material.LightMode;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.scene.shape.WireframeShape;
import org.angle3d.scene.shape.WireframeUtil;
import org.angle3d.scene.WireframeGeometry;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;
import org.angle3d.utils.TangentBinormalGenerator;

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
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "../assets/ogre/sinbad/";

		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueText(baseURL + "sinbad.mesh.xml");
		assetLoader.queueText(baseURL + "Sword.mesh.xml");
		assetLoader.queueText(baseURL + "Sinbad.skeleton.xml");
		assetLoader.queueImage(baseURL + "sinbad_body.jpg");
		assetLoader.queueImage(baseURL + "sinbad_clothes.jpg");
		assetLoader.queueImage(baseURL + "sinbad_sword.jpg");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}

	private var skeletonParser:OgreSkeletonParser;
	private var sinbadMeshes:Vector<Mesh>;
	private var swordMeshes:Vector<Mesh>;
	
	private var bodyMaterial:Material;
	private var clothesMaterial:Material;
	private var swordMaterial:Material;
	private var swordTexture:BitmapTexture;
	private function _loadComplete(files:StringMap<FileInfo>):Void
	{
		bodyMaterial = new Material(Angle3D.materialFolder + "material/unshaded.mat");
		bodyMaterial.setTexture("u_DiffuseMap", new BitmapTexture(files.get(baseURL + "sinbad_body.jpg").data));
		
		clothesMaterial = new Material(Angle3D.materialFolder + "material/unshaded.mat");
		clothesMaterial.setTexture("u_DiffuseMap", new BitmapTexture(files.get(baseURL + "sinbad_clothes.jpg").data));
		
		swordTexture = new BitmapTexture(files.get(baseURL + "sinbad_sword.jpg").data);
		swordMaterial = new Material(Angle3D.materialFolder + "material/unshaded.mat");
		swordMaterial.setTexture("u_DiffuseMap", swordTexture);
		
		var parser:OgreMeshXmlParser = new OgreMeshXmlParser();
		sinbadMeshes = parser.parse(files.get(baseURL + "sinbad.mesh.xml").data);
		swordMeshes = parser.parse(files.get(baseURL + "Sword.mesh.xml").data);
		
		skeletonParser = new OgreSkeletonParser();
		skeletonParser.addEventListener(Event.COMPLETE, onSkeletonParseComplete);
		skeletonParser.parse(files.get(baseURL + "Sinbad.skeleton.xml").data);
	}
	
	private function onSkeletonParseComplete(event:Event):Void
	{
		var skeleton:Skeleton = skeletonParser.skeleton;
		var animations:Vector<Animation> = skeletonParser.animations;
		
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
			}
			node.attachChild(geometry);
		}
		
		var node2:Node = new Node("sword");
		var swordMaterial2 = new Material(Angle3D.materialFolder + "material/unshaded.mat");
		swordMaterial2.setTexture("u_DiffuseMap", swordTexture);
		for (i in 0...swordMeshes.length)
		{
			var mesh:Mesh = swordMeshes[i];
			var geometry:Geometry = new Geometry(mesh.id, mesh);
			geometry.setMaterial(swordMaterial2);
			node2.attachChild(geometry);
		}
		
		skeleton.getBoneByName("Hand.R").setAttachmentsNode(node2);
		node.attachChild(node2);
		
		scene.attachChild(node);
		
		var skeletonControl:SkeletonControl = new SkeletonControl(skeleton);
		
		var animationControl:AnimControl = new AnimControl(skeleton);
		
		for (i in 0...animations.length)
		{
			animationControl.addAnimation(animations[i]);
		}
		
		node.addControl(skeletonControl);
		node.addControl(animationControl);
		
		var channel:AnimChannel = animationControl.createChannel();
		channel.setAnim("Dance", 0);
		channel.setLoopMode(LoopMode.Cycle);
		channel.setSpeed(1);
		
		camera.location.setTo(0, 0, 20);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
		
		flyCam.setDragToRotate(true);
		reshape(mContextWidth, mContextHeight);
		
		start();
		Stats.show(stage);
	}

	private var angle:Float = -1.5;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.01;
		angle %= FastMath.TWO_PI;
	}
}
