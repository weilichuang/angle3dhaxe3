package examples.effect.gpu;

import examples.skybox.DefaultSkyBox;
import flash.display.BitmapData;
import flash.display3D.Context3DMipFilter;
import flash.display3D.Context3DTextureFilter;
import flash.display3D.Context3DWrapMode;
import flash.events.MouseEvent;
import org.angle3d.app.SimpleApplication;
import org.angle3d.effect.gpu.influencers.birth.PerSecondBirthInfluencer;
import org.angle3d.effect.gpu.influencers.life.SameLifeInfluencer;
import org.angle3d.effect.gpu.influencers.position.CirclePositionInfluencer;
import org.angle3d.effect.gpu.influencers.scale.DefaultScaleInfluencer;
import org.angle3d.effect.gpu.influencers.velocity.DefaultVelocityInfluencer;
import org.angle3d.effect.gpu.ParticleShape;
import org.angle3d.effect.gpu.ParticleShapeGenerator;
import org.angle3d.effect.gpu.ParticleSystem;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;


@:bitmap("../assets/embed/particle/sword.jpg") class EMBED_SWORD extends BitmapData { }

/**
 * 飞剑雨
 */
class SwordTest extends SimpleApplication
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
		texture.wrapMode = Context3DWrapMode.CLAMP;
		texture.textureFilter = Context3DTextureFilter.LINEAR;
		texture.mipFilter = Context3DMipFilter.MIPNONE;

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
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);

		this.stage.doubleClickEnabled = true;
		this.stage.addEventListener(MouseEvent.DOUBLE_CLICK, _doubleClickHandler);
		
		Stats.show(stage);
		start();
	}

	private function _doubleClickHandler(e:MouseEvent):Void
	{
		particleSystem.playOrPause();
	}


	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.03;
		angle %= FastMath.TWO_PI;

		//cam.location.setTo(Math.cos(angle) * 20, 10, Math.sin(angle) * 20);
		//cam.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}
