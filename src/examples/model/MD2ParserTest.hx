package examples.model;

import assets.manager.FileLoader;
import assets.manager.misc.FileInfo;
import examples.skybox.DefaultSkyBox;
import flash.events.KeyboardEvent;
import flash.text.TextField;
import flash.ui.Keyboard;
import haxe.ds.StringMap;
import org.angle3d.Angle3D;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.FastStringMap;
import org.angle3d.app.SimpleApplication;
import org.angle3d.io.parser.md2.MD2Parser;
import org.angle3d.material.Material;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.MorphMesh;
import org.angle3d.scene.MorphGeometry;
import org.angle3d.scene.Node;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;

class MD2ParserTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new MD2ParserTest());
	}
	
	private var angle:Float;

	private var monster:MorphGeometry;
	private var weapon:MorphGeometry;
	private var animations:Array<String>;

	private var animationIndex:Int;
	private var speed:Float;

	private var baseURL:String;
	public function new()
	{
		super();
	}

	private function playNextAnimation():Void
	{
		if (animationIndex > animations.length - 1)
		{
			animationIndex = 0;
		}
		playAnimation(animations[animationIndex++], true);
	}

	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		angle = 0;
		animationIndex = 0;
		speed = 2;
		animations = ["stand", "run", "attack", 
						"pain", "jump", "flip", "salute", 
						"taunt", "wave", "point", "crwalk", 
						"crpain", "crdeath", "death"];
		
		flyCam.setDragToRotate(true);

		baseURL = "../assets/md2/";
		
		var assetLoader:FileLoader = new FileLoader();
		assetLoader.queueBinary(baseURL + "ratamahatta.md2");
		assetLoader.queueBinary(baseURL + "w_rlauncher.md2");
		assetLoader.queueImage(baseURL + "ctf_r.png");
		assetLoader.queueImage(baseURL + "w_rlauncher.png");
		assetLoader.onFilesLoaded.addOnce(_loadComplete);
		assetLoader.loadQueuedFiles();
		
		var textField:TextField = new TextField();
		textField.width = 150;
		textField.text = "Press Tab to change animation";
		this.addChild(textField);
		
		Stats.show(stage);
	}

	private function _loadComplete(files:StringMap<FileInfo>):Void
	{
		var texture1:Texture2D = new BitmapTexture(files.get(baseURL + "ctf_r.png").data);
		var texture2:Texture2D = new BitmapTexture(files.get(baseURL + "w_rlauncher.png").data);
		
		var monsterMaterial:Material = new Material();
		monsterMaterial.load(Angle3D.materialFolder + "material/unshaded.mat");
		monsterMaterial.setTexture("u_DiffuseMap", texture1);
		monsterMaterial.setBoolean("useKeyFrame", true);
		
		var weaponMaterial:Material = new Material();
		weaponMaterial.load(Angle3D.materialFolder + "material/unshaded.mat");
		weaponMaterial.setTexture("u_DiffuseMap", texture2);
		weaponMaterial.setBoolean("useKeyFrame", true);
		
		var skybox:DefaultSkyBox = new DefaultSkyBox(500);
		scene.attachChild(skybox);
		
		var parser:MD2Parser = new MD2Parser();
		var monsterMesh:MorphMesh = parser.parse(files.get(baseURL + "ratamahatta.md2").data);
		monsterMesh.useNormal = false;

		var weaponMesh:MorphMesh = parser.parse(files.get(baseURL + "w_rlauncher.md2").data);
		weaponMesh.useNormal = false;

		var team:Node = new Node("team");

		monster = new MorphGeometry("monster", monsterMesh);
		monster.setMaterial(monsterMaterial);
		team.attachChild(monster);

		weapon = new MorphGeometry("weapon", weaponMesh);
		weapon.setMaterial(weaponMaterial);
		team.attachChild(weapon);
		team.rotateAngles(0, -45 / Math.PI, 0);

		scene.attachChild(team);

		setAnimationSpeed(5);
		playNextAnimation();

		camera.location = new Vector3f(0, 0, 80);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
		
		this.stage.addEventListener(KeyboardEvent.KEY_DOWN, _onKeyDownHandler);
		
		start();
	}
	
	private function _onKeyDownHandler(e:KeyboardEvent):Void
	{
		if (e.keyCode == Keyboard.TAB)
		{
			playNextAnimation();
		}
	}

	private function playAnimation(name:String, loop:Bool):Void
	{
		monster.playAnimation(name, loop);
		weapon.playAnimation(name, loop);
	}

	private function setAnimationSpeed(speed:Float):Void
	{
		monster.setAnimationSpeed(speed);
		weapon.setAnimationSpeed(speed);
	}

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.02;
		angle %= FastMath.TWO_PI;

//			camera.setLocation(new Vector3f(Math.cos(angle) * 80, 0, Math.sin(angle) * 80));
//			camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}

