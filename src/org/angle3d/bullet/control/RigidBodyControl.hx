package org.angle3d.bullet.control;
import org.angle3d.bullet.collision.shapes.BoxCollisionShape;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.collision.shapes.SphereCollisionShape;
import org.angle3d.bullet.util.CollisionShapeFactory;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.ViewPort;
import org.angle3d.renderer.RenderManager;
import org.angle3d.scene.control.Control;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.scene.Spatial;
import org.angle3d.bullet.objects.PhysicsRigidBody;
import org.angle3d.bullet.PhysicsSpace;

/**
 * ...
 * @author weilichuang
 */
class RigidBodyControl extends PhysicsRigidBody implements PhysicsControl
{
	private var spatial:Spatial;
	private var enabled:Bool = true;
	private var added:Bool = false;
	private var space:PhysicsSpace;
	private var kinematicSpatial:Bool = true;

	public function new(shape:CollisionShape, mass:Float = 1.0) 
	{
		super(shape, mass);
		
	}
	
	/* INTERFACE org.angle3d.bullet.control.PhysicsControl */
	
	public function setPhysicsSpace(space:PhysicsSpace):Void 
	{
		if (space == null)
		{
            if (this.space != null) 
			{
                this.space.removeCollisionObject(this);
                added = false;
            }
        } 
		else 
		{
            if (this.space == space) 
				return;
            space.addCollisionObject(this);
            added = true;
        }
        this.space = space;
	}
	
	public function getPhysicsSpace():PhysicsSpace 
	{
		return space;
	}
	
	
	public function setSpatial(value:Spatial):Void 
	{
		spatial = value;
		
		setUserObject(value);
		
		if (value != null)
		{
			if (collisionShape == null) 
			{
				createCollisionShape();
				rebuildRigidBody();
			}
			setPhysicsLocation(getSpatialTranslation());
			setPhysicsRotationWithQuaternion(getSpatialRotation());
		}
	}
	
	private function createCollisionShape():Void
	{
        if (spatial == null)
		{
            return;
        }
		
        if (Std.is(spatial,Geometry))
		{
            var geom:Geometry = cast spatial;
            var mesh:Mesh = geom.getMesh();
            if (Std.is(mesh, Sphere))
			{
                collisionShape = new SphereCollisionShape(cast(mesh,Sphere).radius);
                return;
            } 
			else if (Std.is(mesh,Box)) 
			{
				var box:Box = cast mesh;
                collisionShape = new BoxCollisionShape(new Vector3f(box.xExtent, box.yExtent, box.zExtent));
                return;
            }
        }
		
        if (mass > 0)
		{
            collisionShape = CollisionShapeFactory.createDynamicMeshShape(spatial);
        }
		else 
		{
            collisionShape = CollisionShapeFactory.createMeshShape(spatial);
        }
    }
	
	public function isEnabled():Bool 
	{
		return enabled;
	}
	
	public function setEnabled(value:Bool):Void 
	{
		enabled = value;
		
		if (space != null)
		{
            if (enabled && !added)
			{
                if (spatial != null)
				{
                    setPhysicsLocation(getSpatialTranslation());
                    setPhysicsRotationWithQuaternion(getSpatialRotation());
                }
                space.addCollisionObject(this);
                added = true;
            }
			else if (!enabled && added)
			{
                space.removeCollisionObject(this);
                added = false;
            }
        }
	}
	
	public function cloneForSpatial(spatial:Spatial):Control 
	{
		var control:RigidBodyControl = new RigidBodyControl(collisionShape, mass);
        control.setAngularFactor(getAngularFactor());
        control.setAngularSleepingThreshold(getAngularSleepingThreshold());
        control.setCcdMotionThreshold(getCcdMotionThreshold());
        control.setCcdSweptSphereRadius(getCcdSweptSphereRadius());
        control.setCollideWithGroups(getCollideWithGroups());
        control.setCollisionGroup(getCollisionGroup());
        control.setDamping(getLinearDamping(), getAngularDamping());
        control.setFriction(getFriction());
        control.setGravity(getGravity());
        control.setKinematic(isKinematic());
        control.setKinematicSpatial(isKinematicSpatial());
        control.setLinearSleepingThreshold(getLinearSleepingThreshold());
        control.setPhysicsLocation(getPhysicsLocation(null));
        control.setPhysicsRotation(getPhysicsRotationMatrix(null));
        control.setRestitution(getRestitution());

        if (mass > 0)
		{
            control.setAngularVelocity(getAngularVelocity());
            control.setLinearVelocity(getLinearVelocity());
        }
        control.setApplyPhysicsLocal(isApplyPhysicsLocal());
        return control;
	}
	
	/**
     * Checks if this control is in kinematic spatial mode.
     * @return true if the spatial location is applied to this kinematic rigidbody
     */
    public function isKinematicSpatial():Bool 
	{
        return kinematicSpatial;
    }

    /**
     * Sets this control to kinematic spatial mode so that the spatials transform will
     * be applied to the rigidbody in kinematic mode, defaults to true.
     * @param kinematicSpatial
     */
    public function setKinematicSpatial( kinematicSpatial:Bool):Void
	{
        this.kinematicSpatial = kinematicSpatial;
    }

    public function isApplyPhysicsLocal():Bool 
	{
        return motionState.isApplyPhysicsLocal();
    }

    /**
     * When set to true, the physics coordinates will be applied to the local
     * translation of the Spatial instead of the world traslation.
     * @param applyPhysicsLocal
     */
    public function setApplyPhysicsLocal(applyPhysicsLocal:Bool):Void
	{
        motionState.setApplyPhysicsLocal(applyPhysicsLocal);
    }

    private function getSpatialTranslation():Vector3f
	{
        if (motionState.isApplyPhysicsLocal())
		{
            return spatial.getLocalTranslation();
        }
        return spatial.getWorldTranslation();
    }

    private function getSpatialRotation():Quaternion
	{
        if (motionState.isApplyPhysicsLocal())
		{
            return spatial.getLocalRotation();
        }
        return spatial.getWorldRotation();
    }
	
	public function update(tpf:Float):Void 
	{
		if (enabled && spatial != null) 
		{
            if (isKinematic() && kinematicSpatial) 
			{
                super.setPhysicsLocation(getSpatialTranslation());
                super.setPhysicsRotationWithQuaternion(getSpatialRotation());
            } else
			{
                getMotionState().applyTransform(spatial);
            }
        }
	}
	
	public function render(rm:RenderManager, vp:ViewPort):Void 
	{
		
	}
}