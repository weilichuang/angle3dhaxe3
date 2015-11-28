package examples.effect.gpu;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.MouseEvent;

import org.angle3d.app.SimpleApplication;
import org.angle3d.effect.gpu.ParticleShape;
import org.angle3d.effect.gpu.ParticleShapeGenerator;
import org.angle3d.effect.gpu.ParticleSystem;
import org.angle3d.effect.gpu.influencers.life.DefaultLifeInfluencer;
import org.angle3d.effect.gpu.influencers.position.CylinderPositionInfluencer;
import org.angle3d.effect.gpu.influencers.position.DefaultPositionInfluencer;
import org.angle3d.effect.gpu.influencers.scale.DefaultScaleInfluencer;
import org.angle3d.effect.gpu.influencers.velocity.DefaultVelocityInfluencer;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/particle/smoke.png") class EMBED_SMOKE extends BitmapData { }


//TODO 是否添加可用多个颜色
class FireTest extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new FireTest());
	}
	
	private var particleSystem:ParticleSystem;
	private var fireShape:ParticleShape;

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

		var particleGenerator:ParticleShapeGenerator = new ParticleShapeGenerator(500, 2);
		particleGenerator.setPositionInfluencer(new DefaultPositionInfluencer(new Vector3f(0, 0, 0)));
		particleGenerator.setVelocityInfluencer(new DefaultVelocityInfluencer(new Vector3f(0, 1.5, 0), 0.2));
		particleGenerator.setScaleInfluencer(new DefaultScaleInfluencer(0.5, 0.2));
		particleGenerator.setLifeInfluencer(new DefaultLifeInfluencer(1, 2));

		fireShape = particleGenerator.createParticleShape("Fire", texture);
		fireShape.setColor(0x99ffff00, 0x00ff0000);
		fireShape.setAcceleration(new Vector3f(0, .3, 0));
		fireShape.setSize(1, 3);

		var smokeGenerator:ParticleShapeGenerator = new ParticleShapeGenerator(200, 2);
		smokeGenerator.setPositionInfluencer(new CylinderPositionInfluencer(0, new Vector3f(0, 1, 0), 0.3, true));
		smokeGenerator.setVelocityInfluencer(new DefaultVelocityInfluencer(new Vector3f(0, 1.5, 0), 0.2));
		smokeGenerator.setScaleInfluencer(new DefaultScaleInfluencer(1, 0.2));
		smokeGenerator.setLifeInfluencer(new DefaultLifeInfluencer(1, 2));

		var smoke:ParticleShape = smokeGenerator.createParticleShape("Smoke", texture);
		smoke.setColor(0x00111111, 0x88111111);
		smoke.setAcceleration(new Vector3f(0, 0.3, 0));
		smoke.setSize(1, 3);
		smoke.startTime = 1;

		particleSystem = new ParticleSystem("FireSystem");
		particleSystem.addShape(fireShape);
		particleSystem.addShape(smoke);
		scene.attachChild(particleSystem);
		particleSystem.play();

		camera.location.setTo(0, 5, 10);
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

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.03;
		angle %= FastMath.TWO_PI;

//			var fx:Number = Math.cos(angle) * 5;
//			var fy:Number = Math.sin(angle) * 5;
//			fireShape.setTranslationXYZ(fx, 0, fy);

//			cam.location.setTo(Math.cos(angle) * 20, 10, Math.sin(angle) * 20);
//			cam.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}
