package examples.bullet;

import flash.display.BitmapData;
import org.angle3d.bullet.collision.PhysicsCollisionEvent;
import org.angle3d.bullet.collision.PhysicsCollisionGroupListener;
import org.angle3d.bullet.collision.PhysicsCollisionListener;
import org.angle3d.bullet.collision.PhysicsCollisionObject;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.collision.shapes.SphereCollisionShape;
import org.angle3d.bullet.control.RigidBodyControl;
import org.angle3d.bullet.objects.PhysicsGhostObject;
import org.angle3d.bullet.objects.PhysicsRigidBody;
import org.angle3d.bullet.PhysicsSpace;
import org.angle3d.bullet.PhysicsTickListener;
import org.angle3d.effect.cpu.ParticleEmitter;
import org.angle3d.effect.cpu.shape.EmitterSphereShape;
import org.angle3d.material.MaterialCPUParticle;
import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;
import org.angle3d.texture.Texture2D;

@:bitmap("embed/particle/explosion/flame.png") class EMBED_FLAME extends flash.display.BitmapData { }
/**
 * ...
 * @author weilichuang
 */
class BombControl extends RigidBodyControl implements PhysicsCollisionListener implements PhysicsTickListener
{
	private var explosionRadius:Float = 10;
    private var ghostObject:PhysicsGhostObject;
    private var vector:Vector3f = new Vector3f();
    private var vector2:Vector3f = new Vector3f();
    private var forceFactor:Float = 1;
	
	private var effect:ParticleEmitter;

    private var fxTime:Float = 0.5;
    private var maxTime:Float = 4;
    private var curTime:Float = -1.0;
    private var timer:Float;

	public function new(shape:CollisionShape, mass:Float=1.0) 
	{
		super(shape, mass);
		
		createGhostObject();
        prepareEffect();
	}
	
	override public function setPhysicsSpace(space:PhysicsSpace):Void
	{
        super.setPhysicsSpace(space);
        if (space != null) 
		{
            space.addCollisionListener(this);
        }
    }

    private function prepareEffect():Void
	{
		var COUNT_FACTOR:Int = 1;
        var COUNT_FACTOR_F:Float = 1;
        effect = new ParticleEmitter("Flame", 32 * COUNT_FACTOR);
        effect.randomImage = (true);
        effect.setStartColor(new Color(1, 0.4, 0.05, (1 / COUNT_FACTOR_F)));
        effect.setEndColor(new Color(.4, .22, .12, 0));
        effect.setStartSize(1.3);
        effect.setEndSize(2);
        effect.setShape(new EmitterSphereShape(Vector3f.ZERO, 1));
        effect.setParticlesPerSec(0);
        effect.setGravity(new Vector3f(0, -5, 0));
        effect.setLowLife(.4);
        effect.setHighLife(.5);
        effect.setInitialVelocity(new Vector3f(0, 7, 0));
        effect.setVelocityVariation(1);
        effect.setImagesX(2);
        effect.setImagesY(2);
		
        var mat:MaterialCPUParticle = createMat(EMBED_FLAME);
        effect.setMaterial(mat);
    }
	
	private function createMat(cls:Class<Dynamic>):MaterialCPUParticle
	{
		var bitmapData:BitmapData = Type.createInstance(cls,[0,0]);
		var texture:Texture2D = new Texture2D(bitmapData, false);

		return new MaterialCPUParticle(texture);
	}

    private function createGhostObject():Void
	{
        ghostObject = new PhysicsGhostObject(new SphereCollisionShape(explosionRadius));
    }

    public function collision(event:PhysicsCollisionEvent):Void
	{
        if (space == null)
		{
            return;
        }
        if (event.getObjectA() == this || event.getObjectB() == this)
		{
            space.add(ghostObject);
            ghostObject.setPhysicsLocation(getPhysicsLocation(vector));
            space.addTickListener(this);
			
            if (effect != null && spatial.parent != null) 
			{
                curTime = 0;
                effect.setLocalTranslation(spatial.getLocalTranslation());
                spatial.parent.attachChild(effect);
                effect.emitAllParticles();
            }
            space.remove(this);
            spatial.removeFromParent();
        }
    }
    
    public function prePhysicsTick(space:PhysicsSpace, f:Float):Void
	{
        space.removeCollisionListener(this);
    }

    public function physicsTick(space:PhysicsSpace, f:Float):Void
	{
        //get all overlapping objects and apply impulse to them
		var objects:Array<PhysicsCollisionObject> = ghostObject.getOverlappingObjects();
        for (i in 0...objects.length)
		{            
            var physicsCollisionObject:PhysicsCollisionObject = objects[i];
            if (Std.is(physicsCollisionObject,PhysicsRigidBody))
			{
                var rBody:PhysicsRigidBody = cast physicsCollisionObject;
                rBody.getPhysicsLocation(vector2);
                vector2.subtractLocal(vector);
                var force:Float = explosionRadius - vector2.length;
                force *= forceFactor;
                force = force > 0 ? force : 0;
                vector2.normalizeLocal();
                vector2.scaleLocal(force);
                cast(physicsCollisionObject,PhysicsRigidBody).applyImpulse(vector2, new Vector3f(1,1,1));
            }
        }
        space.removeTickListener(this);
        space.remove(ghostObject);
    }
	
	override public function update(tpf:Float):Void 
	{
		super.update(tpf);
		
		if (enabled)
		{
            timer+=tpf;
            if (timer > maxTime)
			{
                if (spatial.parent != null)
				{
                    space.removeCollisionListener(this);
                    space.remove(this);
                    spatial.removeFromParent();
                }
            }
        }
		
        if (enabled && curTime >= 0)
		{
            curTime += tpf;
            if (curTime > fxTime)
			{
                curTime = -1;
                effect.removeFromParent();
            }
        }
	}

    /**
     * @return the explosionRadius
     */
    public function getExplosionRadius():Float
	{
        return explosionRadius;
    }

    /**
     * @param explosionRadius the explosionRadius to set
     */
    public function setExplosionRadius(explosionRadius:Float):Void
	{
        this.explosionRadius = explosionRadius;
        createGhostObject();
    }

    public function getForceFactor():Float
	{
        return forceFactor;
    }

    public function setForceFactor(forceFactor:Float):Void
	{
        this.forceFactor = forceFactor;
    }
	
}