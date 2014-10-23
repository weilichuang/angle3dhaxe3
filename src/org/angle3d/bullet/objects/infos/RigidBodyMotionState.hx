package org.angle3d.bullet.objects.infos;

import com.bulletphysics.linearmath.MotionState;
import com.bulletphysics.linearmath.Transform;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;

/**
 * stores transform info of a PhysicsNode in a threadsafe manner to
 * allow multithreaded access from the jme scenegraph and the bullet physicsspace
 * @author normenhansen
 */
class RigidBodyMotionState extends MotionState
{
	private var motionStateTrans:Transform = new Transform();
	private var worldLocation:Vector3f = new Vector3f();
    private var worldRotation:Matrix3f = new Matrix3f();
    private var worldRotationQuat:Quaternion = new Quaternion();
    private var localLocation:Vector3f = new Vector3f();
    private var localRotationQuat:Quaternion = new Quaternion();
    //keep track of transform changes
    private var physicsLocationDirty:Bool = false;
    private var jmeLocationDirty:Bool = false;
    //temp variable for conversion
    private var tmp_inverseWorldRotation:Quaternion = new Quaternion();
    private var vehicle:PhysicsVehicle;
    private var applyPhysicsLocal:Bool = false;

	public function new() 
	{
		super();
		
	}
	
	override public function getWorldTransform(t:Transform):Transform
	{
		t.fromTransform(motionStateTrans);
		return t;
	}
	
	override public function setWorldTransform(worldTrans:Transform):Void
	{
		if (jmeLocationDirty)
		{
			return;
		}
		
		motionStateTrans.fromTransform(worldTrans);
		
		Converter.v2aVector3f(worldTrans.origin, worldLocation);
		Converter.v2aMatrix3f(worldTrans.basis, worldRotation);
		
		worldRotationQuat.fromMatrix3f(worldRotation);
		
		physicsLocationDirty = true;
		if (vehicle != null)
		{
			vehicle.updateWheels();
		}
	}
	
	public function applyTransform(spatial:Spatial):Bool
	{
		if (!physicsLocationDirty)
		{
			return false;
		}
		
		var parent:Node = spatial.parent;
		if (!applyPhysicsLocal && parent != null) 
		{
            localLocation.copyFrom(worldLocation).subtractLocal(parent.getWorldTranslation());
            localLocation.divideLocal(parent.getWorldScale());
            tmp_inverseWorldRotation.copyFrom(parent.getWorldRotation()).inverseLocal().multVecLocal(localLocation);
			
            localRotationQuat.copyFrom(worldRotationQuat);
            tmp_inverseWorldRotation.copyFrom(parent.getWorldRotation()).inverseLocal().multiply(localRotationQuat, localRotationQuat);

            spatial.setLocalTranslation(localLocation);
            spatial.setLocalRotation(localRotationQuat);
        } 
		else 
		{
            spatial.setLocalTranslation(worldLocation);
            spatial.setLocalRotation(worldRotationQuat);
        }
        physicsLocationDirty = false;
        return true;
	}
	
	public function getWorldLocation():Vector3f
	{
		return worldLocation;
	}
	
	public function getWorldRotation():Matrix3f
	{
		return worldRotation;
	}
	
	public function getWorldRotationQuat():Quaternion
	{
		return worldRotationQuat;
	}
	
	public function setVehicle(vehicle:PhysicsVehicle):Void 
	{
        this.vehicle = vehicle;
    }

    public function isApplyPhysicsLocal():Bool
	{
        return applyPhysicsLocal;
    }

    public function setApplyPhysicsLocal(applyPhysicsLocal:Bool):Void
	{
        this.applyPhysicsLocal = applyPhysicsLocal;
    }
}