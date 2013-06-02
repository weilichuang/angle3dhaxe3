package examples.effect.gpu;

import flash.display.BitmapData;
import flash.events.MouseEvent;

import org.angle3d.app.SimpleApplication;
import org.angle3d.effect.gpu.ParticleShape;
import org.angle3d.effect.gpu.ParticleShapeGenerator;
import org.angle3d.effect.gpu.ParticleSystem;
import org.angle3d.effect.gpu.influencers.angle.DefaultAngleInfluencer;
import org.angle3d.effect.gpu.influencers.color.RandomColorInfluencer;
import org.angle3d.effect.gpu.influencers.life.DefaultLifeInfluencer;
import org.angle3d.effect.gpu.influencers.position.PlanePositionInfluencer;
import org.angle3d.effect.gpu.influencers.scale.DefaultScaleInfluencer;
import org.angle3d.effect.gpu.influencers.spin.DefaultSpinInfluencer;
import org.angle3d.effect.gpu.influencers.velocity.DefaultVelocityInfluencer;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;

@:bitmap("embed/particle/snow.png") class EMBED_SNOW extends BitmapData { }

/**
 * 下雪测试
 */
class SnowTest extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new SnowTest());
	}
	
	private var particleSystem:ParticleSystem;
	private var snowShape:ParticleShape;
	private var angle:Float = 0;

	public function new()
	{
		super();
	}

	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		flyCam.setDragToRotate(true);

		var bitmapData:BitmapData = Type.createInstance(EMBED_SNOW, [0, 0]);
		var texture:Texture2D = new Texture2D(bitmapData, false);

		var particleGenerator:ParticleShapeGenerator = new ParticleShapeGenerator(1000, 8);
		particleGenerator.setPositionInfluencer(new PlanePositionInfluencer(new Vector3f(0, 10, 0), 20, 20));
		particleGenerator.setScaleInfluencer(new DefaultScaleInfluencer(0.5, 0.3));
		particleGenerator.setVelocityInfluencer(new DefaultVelocityInfluencer(new Vector3f(0, -4, 0), 0.3));
		particleGenerator.setLifeInfluencer(new DefaultLifeInfluencer(4, 8));
		particleGenerator.setAngleInfluencer(new DefaultAngleInfluencer());
		particleGenerator.setSpinInfluencer(new DefaultSpinInfluencer(3, 0.7));
		//使用自定义粒子颜色
		particleGenerator.setColorInfluencer(new RandomColorInfluencer());
		//particleGenerator.setAlphaInfluencer(new RandomAlphaInfluencer());

		snowShape = particleGenerator.createParticleShape("Snow", texture);
		snowShape.useSpin = true;
		snowShape.loop = true;
		snowShape.setAlpha(0.9, 0.0);
//			snowShape.setColor(0xffffff, 0xffffff);
		snowShape.setAcceleration(new Vector3f(0, -1.5, 0));
		snowShape.setSize(1, 1);

		var snowShape2:ParticleShape = particleGenerator.createParticleShape("Snow2", texture);
		snowShape2.startTime = 1;
		snowShape2.useSpin = true;
		snowShape2.loop = true;
		snowShape2.setAlpha(0.9, 0);
		snowShape2.setColor(0xff0000, 0xffff00);
		snowShape2.setAcceleration(new Vector3f(0, 0, 0));
		snowShape2.setSize(1, 1);

		particleSystem = new ParticleSystem("SnowSystem");
		particleSystem.addShape(snowShape);
		particleSystem.addShape(snowShape2);
		scene.attachChild(particleSystem);

		particleSystem.play();

		camera.location.setTo(0, 8, 10);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);

		this.stage.doubleClickEnabled = true;
		this.stage.addEventListener(MouseEvent.DOUBLE_CLICK, _doubleClickHandler);
		
		Stats.show(stage);
		start();
	}

	private function _doubleClickHandler(e:MouseEvent):Void
	{
		particleSystem.playOrPause();

		//snowShape.reset();
	}


	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.03;
		angle %= FastMath.TWO_PI();

//			camera.location.setTo(Math.cos(angle) * 10, 10, Math.sin(angle) * 10);
//			camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}
