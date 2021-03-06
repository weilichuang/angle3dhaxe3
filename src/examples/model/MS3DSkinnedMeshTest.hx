package examples.model;

import examples.skybox.DefaultSkyBox;
import org.angle3d.asset.FilesLoader;
import org.angle3d.asset.FileInfo;
import flash.display.BitmapData;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.animation.Animation;
import org.angle3d.animation.AnimChannel;
import org.angle3d.animation.AnimControl;
import org.angle3d.animation.Bone;
import org.angle3d.animation.Skeleton;
import org.angle3d.animation.SkeletonControl;
import org.angle3d.app.SimpleApplication;
import org.angle3d.cinematic.LoopMode;
import org.angle3d.io.parser.ms3d.MS3DParser;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.texture.WrapMode;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.shadow.BasicShadowRenderer;
import org.angle3d.texture.ATFTexture;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;

class MS3DSkinnedMeshTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new MS3DSkinnedMeshTest());
	}
	
	private var baseURL:String;
	public function new()
	{
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		baseURL = "../assets/ms3d/";

		var assetLoader:FilesLoader = new FilesLoader();
		assetLoader.queueBinary(baseURL + "ninja.ms3d");
		assetLoader.queueBinary(baseURL + "nskinbr.atf");
		assetLoader.queueBinary(baseURL + "wood.atf");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
	}

	private var mat:Material;
	private var meshes:Array<Mesh>;
	private var animation:Animation;
	private var bones:Vector<Bone>;
	private var _center:Vector3f;
	private var texture:ATFTexture;

	private var basicShadowRender:BasicShadowRenderer;

	private function _loadComplete(loader:FilesLoader):Void
	{
		flyCam.setDragToRotate(true);
		
		//mRenderManager.setPreferredLightMode(LightMode.SinglePass);
		//mRenderManager.setSinglePassLightBatchSize(2);
		
		texture = new ATFTexture(loader.getAssetByUrl(baseURL + "nskinbr.atf").info.content);
		
		var sphere:Sphere = new Sphere(2, 10, 10);
		var mat2:Material = new Material();
		mat2.load(Angle3D.materialFolder + "material/unshaded.mat");
		var groundTexture = new ATFTexture(loader.getAssetByUrl(baseURL + "wood.atf").info.content);
		groundTexture.wrapMode = WrapMode.REPEAT;
		mat2.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, groundTexture);
		

		//var sky : DefaultSkyBox = new DefaultSkyBox(500);
		//scene.attachChild(sky);

		var directionLight:DirectionalLight = new DirectionalLight();
		directionLight.color = new Color(0, 1, 0, 1);
		directionLight.direction = new Vector3f(0, 1, 0);
		scene.addLight(directionLight);
		
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.3, 0.3, 0.3, 1);
		scene.addLight(al);

		var parser:MS3DParser = new MS3DParser();
		meshes = parser.parseSkinnedMesh("ninja", loader.getAssetByUrl(baseURL + "ninja.ms3d").info.content);
		var boneAnimation:BoneAnimation = parser.buildSkeleton();
		bones = boneAnimation.bones;
		animation = boneAnimation.animation;
		animation.name = "default";

		var hCount:Int = 10;
		var vCount:Int = 10;
		var halfHCount:Float = (hCount / 2);
		var halfVCount:Float = (vCount / 2);
		var index:Int = 0;
		for (i in 0...hCount)
		{
			for (j in 0...vCount)
			{
				var node:Node = createNinja(index++);
				node.setTranslationXYZ((i - halfHCount) * 15, 0, (j - halfVCount) * 15);
				scene.attachChild(node);
			}
		}
		
		var floor:Box = new Box(100, 0.1, 100);
		floor.scaleTextureCoordinates(new Vector2f(5, 5));
		var floorGeom:Geometry = new Geometry("Floor", floor);
		floorGeom.setMaterial(mat2);
		floorGeom.setLocalTranslation(new Vector3f(0, -0.2, 0));
		floorGeom.localShadowMode = ShadowMode.Receive;
		scene.attachChild(floorGeom);
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(Math.cos(0) * 80, 60, Math.sin(0) * 80);
		camera.lookAt(_center, Vector3f.UNIT_Y);
		
		flyCam.setMoveSpeed(20);
		
		basicShadowRender = new BasicShadowRenderer(2048);
		basicShadowRender.setShadowInfo(0.002, 0.6, true);
		basicShadowRender.setDirection(camera.getDirection().normalizeLocal());
		viewPort.addProcessor(basicShadowRender);
		
		gui.attachChild(basicShadowRender.getDisplayPicture());
		
		reshape(mContextWidth, mContextHeight);
		
		start();
	}
	
	private function createNinja(index:Int):Node
	{
		var speed:Float = Math.random() * 20;
		
		var ninjaNode:Node = new Node("ninja" + index);
		
		for (i in 0...meshes.length)
		{
			var geometry:Geometry = new Geometry("ninjaGeometry" + index + "_part" + i, meshes[i]);
			geometry.useLight = false;
			ninjaNode.attachChild(geometry);
			
			var mat:Material = new Material();
			mat.load(Angle3D.materialFolder + "material/unshaded.mat");
			mat.setTextureParam("u_DiffuseMap", VarType.TEXTURE2D, texture);
			
			geometry.setMaterial(mat);
			
			geometry.localShadowMode = ShadowMode.Cast;
		}
		
		//var q:Quaternion = new Quaternion();
		//q.fromAngles(0, Math.random()*180, 0);
		//ninjaNode.setRotation(q);
		
		var newBones:Vector<Bone> = new Vector<Bone>();
		for (i in 0...bones.length)
		{
			newBones[i] = bones[i].clone();
		}

		var skeleton:Skeleton = new Skeleton(newBones);
		var skeletonControl:SkeletonControl = new SkeletonControl(skeleton);
		var animationControl:AnimControl = new AnimControl(skeleton);
		animationControl.addAnimation(animation);
		
		ninjaNode.addControl(skeletonControl);
		ninjaNode.addControl(animationControl);
		
		//attatchNode
		//var boxNode:Node = new Node(ninjaNode.name + "attachBox");
		//var gm:Geometry = new Geometry("cube", new Box(0.5, 0.5, 5));
		//
		//var boxMat:Material = new Material();
		//boxMat.load(Angle3D.materialFolder + "material/unshaded.mat");
		//boxMat.setColor("u_MaterialColor", new Color(Math.random(), Math.random(), Math.random(), 1));
		//gm.setMaterial(boxMat);
		//boxNode.attachChild(gm);
		//
		//var attachNode:Node = skeletonControl.getAttachmentsNode("Joint29");
		//attachNode.attachChild(boxNode);
		//if (index % 2 == 0)
		//{
			//var skeletonDebugger:SkeletonDebugger = new SkeletonDebugger("skeletonDebugger", skeletonControl.getSkeleton(),
																	//0.2, Std.int(Math.random() * 0xFFFFFF), Std.int(Math.random() * 0xFFFFFF));
			//ninjaNode.attachChild(skeletonDebugger);
		//}

		
		
		var channel:AnimChannel = animationControl.createChannel();
		channel.setAnim("default", 0);
		channel.setLoopMode(LoopMode.Cycle);
		channel.setSpeed(speed);
		

		return ninjaNode;
	}

	override public function simpleUpdate(tpf:Float):Void
	{
		//basicShadowRender.setDirection(camera.getDirection().normalizeLocal());
	}
}
