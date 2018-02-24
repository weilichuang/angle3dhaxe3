package examples.effect.gpu;

import examples.skybox.DefaultSkyBox;
import flash.display.BitmapData;
import flash.events.MouseEvent;
import angle3d.app.SimpleApplication;
import angle3d.effect.gpu.influencers.birth.PerSecondBirthInfluencer;
import angle3d.effect.gpu.influencers.life.SameLifeInfluencer;
import angle3d.effect.gpu.influencers.position.CirclePositionInfluencer;
import angle3d.effect.gpu.influencers.scale.DefaultScaleInfluencer;
import angle3d.effect.gpu.influencers.velocity.DefaultVelocityInfluencer;
import angle3d.effect.gpu.ParticleShape;
import angle3d.effect.gpu.ParticleShapeGenerator;
import angle3d.effect.gpu.ParticleSystem;
import angle3d.texture.WrapMode;
import angle3d.math.FastMath;
import angle3d.math.Vector3f;
import angle3d.texture.BitmapTexture;
import angle3d.texture.MipFilter;
import angle3d.texture.TextureFilter;
import angle3d.utils.Stats;


@:bitmap("../assets/embed/particle/sword.jpg") class EMBED_SWORD extends BitmapData { }

/**
 * 飞剑雨
 */
class SwordTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new SwordTest());
	}
	
	private var particleSystem:ParticleSystem;
	private var swordShape:ParticleShape;
	private var angle:Float;

	public function new()
	{
		super();
	}

	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		angle = 0;

		flyCam.setDragToRotate(true);

		var bitmapData:BitmapData = Type.createInstance(EMBED_SWORD, [0, 0]);
		var texture:BitmapTexture = new BitmapTexture(bitmapData, false);
		texture.wrapMode = WrapMode.CLAMP;
		texture.textureFilter = angle3d.texture.TextureFilter.LINEAR;
		texture.mipFilter = angle3d.texture.MipFilter.MIPNONE;

		var particleGenerator:ParticleShapeGenerator = new ParticleShapeGenerator(90, 3);
		particleGenerator.setPositionInfluencer(new CirclePositionInfluencer(new Vector3f(0, 10, 0), 3, 0));
		particleGenerator.setScaleInfluencer(new DefaultScaleInfluencer(1, 0));
		particleGenerator.setVelocityInfluencer(new DefaultVelocityInfluencer(new Vector3f(0, -1, 0), 0));
		particleGenerator.setBirthInfluencer(new PerSecondBirthInfluencer(0.7));
		particleGenerator.setLifeInfluencer(new SameLifeInfluencer(3));
		//particleGenerator.setAngleInfluencer(new EmptyAngleInfluencer());
		//particleGenerator.setSpinInfluencer(new DefaultSpinInfluencer(3, 2.1));


		swordShape = particleGenerator.createParticleShape("sword", texture);
		swordShape.useSpin = false;
		swordShape.loop = true;
		swordShape.setAlpha(0.7, 0);
		swordShape.setColor(0xff0000, 0xffff00);
		swordShape.setAcceleration(new Vector3f(0, -1.5, 0));
		swordShape.setSize(3, 1);

		particleSystem = new ParticleSystem("swordSystem");
		particleSystem.addShape(swordShape);
		scene.attachChild(particleSystem);
		particleSystem.play();
		
		var sky:DefaultSkyBox = new DefaultSkyBox(10);
		scene.attachChild(sky);

		camera.location.setTo(0, 3, 10);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);

		this.stage.doubleClickEnabled = true;
		this.stage.addEventListener(MouseEvent.DOUBLE_CLICK, _doubleClickHandler);
		
		
		start();
	}

	private function _doubleClickHandler(e:MouseEvent):Void
	{
		particleSystem.playOrPause();
	}


	override public function simpleUpdate(tpf:Float):Void
	{
		super.simpleUpdate(tpf);
		
		angle += 0.03;
		angle %= FastMath.TWO_PI;

		//cam.location.setTo(Math.cos(angle) * 20, 10, Math.sin(angle) * 20);
		//cam.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}
