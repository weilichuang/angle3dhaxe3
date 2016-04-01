package examples.effect.gpu;

import flash.display.BitmapData;
import flash.events.MouseEvent;
import org.angle3d.app.SimpleApplication;
import org.angle3d.effect.gpu.influencers.life.SameLifeInfluencer;
import org.angle3d.effect.gpu.influencers.position.DefaultPositionInfluencer;
import org.angle3d.effect.gpu.influencers.scale.DefaultScaleInfluencer;
import org.angle3d.effect.gpu.influencers.velocity.ConeVelocityInfluencer;
import org.angle3d.effect.gpu.ParticleShape;
import org.angle3d.effect.gpu.ParticleShapeGenerator;
import org.angle3d.effect.gpu.ParticleSystem;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;


@:bitmap("../assets/embed/particle/smoke.png") class EMBED_SMOKE extends BitmapData { }


/**
 * 喷泉
 */
class FountainTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new FountainTest());
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


		var bitmapData:BitmapData = Type.createInstance(EMBED_SMOKE, [0, 0]);
		var texture:BitmapTexture = new BitmapTexture(bitmapData, false);

		var particleGenerator:ParticleShapeGenerator = new ParticleShapeGenerator(2000, 5);
		particleGenerator.setPositionInfluencer(new DefaultPositionInfluencer(new Vector3f(0, 0, 0)));
		particleGenerator.setScaleInfluencer(new DefaultScaleInfluencer(0.5, 0));
		particleGenerator.setVelocityInfluencer(new ConeVelocityInfluencer(20));
		particleGenerator.setLifeInfluencer(new SameLifeInfluencer(5));

		var fountainShape:ParticleShape = particleGenerator.createParticleShape("Fountain", texture);
		fountainShape.setAlpha(0.8, 0.2);
		fountainShape.setColor(0x44ccff, 0xccffff);
		fountainShape.setAcceleration(new Vector3f(0, -4, 0));
		fountainShape.setSize(0.5, 0.3);

		particleSystem = new ParticleSystem("FountainSystem");
		particleSystem.addShape(fountainShape);
		scene.attachChild(particleSystem);
		particleSystem.play();

		camera.location.setTo(0, 8, 10);
		camera.lookAt(new Vector3f(0, 3, 0), Vector3f.Y_AXIS);

		this.stage.doubleClickEnabled = true;
		this.stage.addEventListener(MouseEvent.DOUBLE_CLICK, _doubleClickHandler);
		
		
		start();
	}

	private function _doubleClickHandler(e:MouseEvent):Void
	{
		particleSystem.playOrPause();
	}

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		super.simpleUpdate(tpf);
		
		angle += 0.03;
		angle %= FastMath.TWO_PI;

//			camera.location.setTo(Math.cos(angle) * 20, 10, Math.sin(angle) * 20);
//			camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}
