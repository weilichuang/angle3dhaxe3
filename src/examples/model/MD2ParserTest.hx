package examples.model;

import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.text.TextField;
import flash.ui.Keyboard;
import flash.utils.Dictionary;
import hu.vpmedia.assets.AssetLoader;
import org.angle3d.app.SimpleApplication;
import examples.skybox.DefaultSkyBox;
import org.angle3d.io.AssetManager;
import org.angle3d.io.parser.md2.MD2Parser;
import org.angle3d.material.MaterialColorFill;
import org.angle3d.material.MaterialNormalColor;
import org.angle3d.material.MaterialReflective;
import org.angle3d.material.MaterialTexture;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.MorphMesh;
import org.angle3d.scene.MorphGeometry;
import org.angle3d.scene.Node;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;

class MD2ParserTest extends SimpleApplication
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

		baseURL = "md2/";
		var assetLoader:AssetLoader = new AssetLoader();
		assetLoader.add(baseURL + "ratamahatta.md2");
		assetLoader.add(baseURL + "w_rlauncher.md2");
		assetLoader.add(baseURL + "ctf_r.png");
		assetLoader.add(baseURL + "w_rlauncher.png");
		assetLoader.signalSet.completed.add(_loadComplete);
		assetLoader.execute();
		
		var textField:TextField = new TextField();
		textField.width = 150;
		textField.text = "Press Tab to change animation";
		this.addChild(textField);
		
		Stats.show(stage);
	}


	private function _loadComplete(assetLoader:AssetLoader):Void
	{
		var texture1:Texture2D = new Texture2D(assetLoader.get(baseURL + "ctf_r.png").data.bitmapData);
		var texture2:Texture2D = new Texture2D(assetLoader.get(baseURL + "w_rlauncher.png").data.bitmapData);
		var monsterMaterial:MaterialTexture = new MaterialTexture(texture1);
		var weaponMaterial:MaterialTexture = new MaterialTexture(texture2);

		var fillMaterial:MaterialColorFill = new MaterialColorFill(0x008822);
		var normalMaterial:MaterialNormalColor = new MaterialNormalColor();

		var skybox:DefaultSkyBox = new DefaultSkyBox(500);
		scene.attachChild(skybox);

		var reflectiveMat:MaterialReflective = new MaterialReflective(texture1, skybox.cubeMap, 0.9);

		var parser:MD2Parser = new MD2Parser();
		var monsterMesh:MorphMesh = parser.parse(assetLoader.get(baseURL + "ratamahatta.md2").data);
		monsterMesh.useNormal = false;

		var weaponMesh:MorphMesh = parser.parse(assetLoader.get(baseURL + "w_rlauncher.md2").data);
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
		angle %= FastMath.TWO_PI();

//			camera.setLocation(new Vector3f(Math.cos(angle) * 80, 0, Math.sin(angle) * 80));
//			camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}

