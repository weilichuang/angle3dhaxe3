package examples.effect.gpu;

import flash.display.BitmapData;
import flash.events.MouseEvent;
import org.angle3d.app.SimpleApplication;
import org.angle3d.effect.gpu.influencers.acceleration.ExplosionAccelerationInfluencer;
import org.angle3d.effect.gpu.influencers.angle.DefaultAngleInfluencer;
import org.angle3d.effect.gpu.influencers.birth.EmptyBirthInfluencer;
import org.angle3d.effect.gpu.influencers.life.SameLifeInfluencer;
import org.angle3d.effect.gpu.influencers.position.DefaultPositionInfluencer;
import org.angle3d.effect.gpu.influencers.scale.DefaultScaleInfluencer;
import org.angle3d.effect.gpu.influencers.spin.DefaultSpinInfluencer;
import org.angle3d.effect.gpu.influencers.spritesheet.DefaultSpriteSheetInfluencer;
import org.angle3d.effect.gpu.influencers.velocity.RandomVelocityInfluencer;
import org.angle3d.effect.gpu.ParticleShape;
import org.angle3d.effect.gpu.ParticleShapeGenerator;
import org.angle3d.effect.gpu.ParticleSystem;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;



@:bitmap("../assets/embed/particle/explosion/Debris.png") class EMBED_SMOKE extends BitmapData { }

/**
 * 爆炸效果
 */
class ExplosionTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new ExplosionTest());
	}
	
	private var particleSystem:ParticleSystem;

	public function new()
	{
		super();
	}

	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		flyCam.setDragToRotate(true);

		var bitmapData:BitmapData = new EMBED_SMOKE(0, 0);
		var texture:BitmapTexture = new BitmapTexture(bitmapData, false);

		var particleGenerator:ParticleShapeGenerator = new ParticleShapeGenerator(500, 2);
		particleGenerator.setPositionInfluencer(new DefaultPositionInfluencer(new Vector3f(0, 0, 0)));
		particleGenerator.setScaleInfluencer(new DefaultScaleInfluencer(0.5, 0));
		particleGenerator.setVelocityInfluencer(new RandomVelocityInfluencer(10, 0));
		particleGenerator.setBirthInfluencer(new EmptyBirthInfluencer());
		particleGenerator.setLifeInfluencer(new SameLifeInfluencer(2));
		particleGenerator.setAccelerationInfluencer(new ExplosionAccelerationInfluencer(3));
		particleGenerator.setSpriteSheetInfluencer(new DefaultSpriteSheetInfluencer(9));
		particleGenerator.setAngleInfluencer(new DefaultAngleInfluencer());
		particleGenerator.setSpinInfluencer(new DefaultSpinInfluencer(3, 0.7));

		var explosionShape:ParticleShape = particleGenerator.createParticleShape("Explosion", texture);
		explosionShape.setAlpha(0.8, 0);
		explosionShape.setColor(0xffffff, 0xffffff);
//			explosionShape.setAcceleration(new Vector3f(0, -15, 0));
		explosionShape.setSpriteSheet(0.1, 3, 3);
		explosionShape.setSize(1, 1);
		explosionShape.loop = true;

		particleSystem = new ParticleSystem("Explosion");
		particleSystem.addShape(explosionShape);
		scene.attachChild(particleSystem);
		particleSystem.play();

		camera.location.setTo(0, 8, 10);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);

		this.stage.doubleClickEnabled = true;
		this.stage.addEventListener(MouseEvent.DOUBLE_CLICK, _doubleClickHandler);

		Stats.show(stage);
		start();
	}
	
	private function compareTo(a:Int, b:Int):Int
	{
		if (a < b)
			return -1;
		else if (a > b)
			return 1;
		else
			return 0;
	}

	private function _doubleClickHandler(e:MouseEvent):Void
	{
		particleSystem.playOrPause();
	}

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.03;

		angle %= FastMath.TWO_PI;
	}
}
