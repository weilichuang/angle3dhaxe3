package org.angle3d.bullet.control;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.ViewPort;
import org.angle3d.renderer.RenderManager;
import org.angle3d.scene.Spatial;
import org.angle3d.scene.control.Control;

import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.objects.PhysicsGhostObject;
import org.angle3d.bullet.PhysicsSpace;

/**
 * ...
 
 */
class GhostControl extends PhysicsGhostObject implements PhysicsControl
{
	private var spatial:Spatial;
    private var enabled:Bool = true;
    private var added:Bool = false;
    private var space:PhysicsSpace = null;
    private var applyLocal:Bool = false;

	public function new(shape:CollisionShape) 
	{
		super(shape);
		
	}
	
	public function dispose():Void
	{
		spatial = null;
		space = null;
	}
	
	public function isApplyPhysicsLocal():Bool
	{
		return applyLocal;
	}
	
	/**
     * When set to true, the physics coordinates will be applied to the local
     * translation of the Spatial
     *
     * @param applyPhysicsLocal
     */
    public function setApplyPhysicsLocal(applyPhysicsLocal:Bool):Void
	{
        applyLocal = applyPhysicsLocal;
    }
	
	private function getSpatialTranslation():Vector3f
	{
        if (applyLocal) 
		{
            return spatial.getLocalTranslation();
        }
        return spatial.getWorldTranslation();
    }

    private function getSpatialRotation():Quaternion
	{
        if (applyLocal)
		{
            return spatial.getLocalRotation();
        }
        return spatial.getWorldRotation();
    }
	
	public function cloneForSpatial(spatial:Spatial):Control 
	{
		var control:GhostControl = new GhostControl(collisionShape);
        control.setCcdMotionThreshold(getCcdMotionThreshold());
        control.setCcdSweptSphereRadius(getCcdSweptSphereRadius());
        control.setCollideWithGroups(getCollideWithGroups());
        control.setCollisionGroup(getCollisionGroup());
        control.setPhysicsLocation(getPhysicsLocation());
        control.setPhysicsRotationMatrix3f(getPhysicsRotationMatrix());
        control.setApplyPhysicsLocal(isApplyPhysicsLocal());
		control.setSpatial(spatial);
        return control;
	}
	
	public function setSpatial(spatial:Spatial):Void 
	{
		this.spatial = spatial;
        setUserObject(spatial);
        if (spatial == null) {
            return;
        }
        setPhysicsLocation(getSpatialTranslation());
        setPhysicsRotation(getSpatialRotation());
	}
	
	public function isEnabled():Bool 
	{
		return enabled;
	}
	
	public function setEnabled(enabled:Bool):Void 
	{
		this.enabled = enabled;
        if (space != null) 
		{
            if (enabled && !added) 
			{
                if (spatial != null)
				{
                    setPhysicsLocation(getSpatialTranslation());
                    setPhysicsRotation(getSpatialRotation());
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
	
	public function update(tpf:Float):Void 
	{
		if (!enabled) {
            return;
        }
        setPhysicsLocation(getSpatialTranslation());
        setPhysicsRotation(getSpatialRotation());
	}
	
	public function render(rm:RenderManager, vp:ViewPort):Void 
	{
		
	}
	
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
			{
                return;
            }
            space.addCollisionObject(this);
            added = true;
        }
        this.space = space;
	}
	
	public function getPhysicsSpace():PhysicsSpace 
	{
		return space;
	}
	
}