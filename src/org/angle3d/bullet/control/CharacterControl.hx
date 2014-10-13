package org.angle3d.bullet.control;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.ViewPort;
import org.angle3d.renderer.RenderManager;
import org.angle3d.scene.Spatial;
import org.angle3d.scene.control.Control;

import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.objects.PhysicsCharacter;
import org.angle3d.bullet.PhysicsSpace;

/**
 * ...
 * @author weilichuang
 */
class CharacterControl extends PhysicsCharacter implements PhysicsControl
{
	private var spatial:Spatial;
    private var enabled:Bool = true;
    private var added:Bool = false;
    private var space:PhysicsSpace = null;
    private var viewDirection:Vector3f = new Vector3f(0,0,1);
    private var useViewDirection:Bool = true;
    private var applyLocal:Bool = false;

	public function new(shape:CollisionShape, stepHeight:Float) 
	{
		super(shape, stepHeight);
		
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
	
	public function cloneForSpatial(spatial:Spatial):Control 
	{
		var control:CharacterControl = new CharacterControl(collisionShape, stepHeight);
        control.setCcdMotionThreshold(getCcdMotionThreshold());
        control.setCcdSweptSphereRadius(getCcdSweptSphereRadius());
        control.setCollideWithGroups(getCollideWithGroups());
        control.setCollisionGroup(getCollisionGroup());
        control.setFallSpeed(getFallSpeed());
        control.setGravity(getGravity());
        control.setJumpSpeed(getJumpSpeed());
        control.setMaxSlope(getMaxSlope());
        control.setPhysicsLocation(getPhysicsLocation());
        control.setUpAxis(getUpAxis());
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
                    warp(getSpatialTranslation());
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
	
	public function setViewDirection(vec:Vector3f):Void
	{
        viewDirection.copyFrom(vec);
    }

    public function getViewDirection():Vector3f
	{
        return viewDirection;
    }

    public function isUseViewDirection():Bool
	{
        return useViewDirection;
    }

    public function setUseViewDirection(viewDirectionEnabled:Bool):Void
	{
        this.useViewDirection = viewDirectionEnabled;
    }
	
	public function update(tpf:Float):Void 
	{
		if (enabled && spatial != null)
		{
            var localRotationQuat:Quaternion = spatial.getLocalRotation();
            var localLocation:Vector3f = spatial.getLocalTranslation();
            if (!applyLocal && spatial.parent != null)
			{
                getPhysicsLocation(localLocation);
                localLocation.subtractLocal(spatial.parent.getWorldTranslation());
                localLocation.divideLocal(spatial.parent.getWorldScale());
                tmp_inverseWorldRotation.copyFrom(spatial.parent.getWorldRotation()).inverseLocal().multVecLocal(localLocation);
                spatial.setLocalTranslation(localLocation);

                if (useViewDirection)
				{
                    localRotationQuat.lookAt(viewDirection, Vector3f.Y_AXIS);
                    spatial.setLocalRotation(localRotationQuat);
                }
            } 
			else 
			{
                spatial.setLocalTranslation(getPhysicsLocation());
                localRotationQuat.lookAt(viewDirection, new Vector3f(0, 1, 0));
                spatial.setLocalRotation(localRotationQuat);
            }
        }
	}
	
	public function render(rm:RenderManager, vp:ViewPort):Void 
	{
		
	}
	
}