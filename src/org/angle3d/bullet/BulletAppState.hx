package org.angle3d.bullet;
import org.angle3d.bullet.debug.BulletDebugAppState;
import org.angle3d.bullet.PhysicsSpace;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.RenderManager;

import org.angle3d.app.Application;
import org.angle3d.app.state.AppState;
import org.angle3d.app.state.AppStateManager;

/**
 * ...
 * @author weilichuang
 */
class BulletAppState implements AppState implements PhysicsTickListener
{
	public var isInitialized(get,null):Bool;

	/**
	 * Enable or disable the functionality of the <code>AppState</code>.
	 * The effect of this call depends on implementation. An
	 * <code>AppState</code> starts as being enabled by default.
	 *
	 * @param value active the AppState or not.
	 */
	public var enabled(get, set):Bool;
	
	private var initialized:Bool = false;
    private var app:Application;
    private var stateManager:AppStateManager;
    private var pSpace:PhysicsSpace;
    private var broadphaseType:BroadphaseType = BroadphaseType.DBVT;
    private var worldMin:Vector3f = new Vector3f(-5000, -5000, -5000);
    private var worldMax:Vector3f = new Vector3f(5000, 5000, 5000);
    private var speed:Float = 1;
    private var active:Bool = true;
    private var debugEnabled:Bool = false;
    private var debugAppState:BulletDebugAppState;
    private var tpf:Float;

	public function new(debug:Bool = false,worldMin:Vector3f = null, worldMax:Vector3f = null, broadphaseType:BroadphaseType = null)
	{
		this.debugEnabled = debug;
		if (worldMin != null)
			this.worldMin.copyFrom(worldMin);
		if (worldMax != null)
			this.worldMax.copyFrom(worldMax);
		if (broadphaseType != null)
			this.broadphaseType = broadphaseType;
	}
	
	public function setDebugEnabled(value:Bool):Void
	{
		debugEnabled = value;
	}
	
	public function getPhysicsSpace():PhysicsSpace
	{
		return pSpace;
	}
	
	/**
     * The physics system is started automatically on attaching, if you want to
     * start it before for some reason, you can use this method.
     */
    public function startPhysics():Void
	{
        if (initialized)
		{
            return;
        }

        pSpace = new PhysicsSpace(worldMin, worldMax, broadphaseType);
        pSpace.addTickListener(this);
        initialized = true;
    }
    
    public function stopPhysics():Void
	{
        if (!initialized)
		{
            return;
        }

        pSpace.removeTickListener(this);
        pSpace.destroy();
        initialized = false;
    }
	
	/* INTERFACE org.angle3d.bullet.PhysicsTickListener */
	
	public function prePhysicsTick(space:PhysicsSpace, tpf:Float):Void 
	{
		
	}
	
	public function physicsTick(space:PhysicsSpace, tpf:Float):Void 
	{
		
	}

	/* INTERFACE org.angle3d.app.state.AppState */
	
	function get_isInitialized():Bool 
	{
		return initialized;
	}
	
	function set_isInitialized(value:Bool):Bool 
	{
		return initialized = value;
	}
	
	function get_enabled():Bool 
	{
		return active;
	}
	
	function set_enabled(value:Bool):Bool 
	{
		return active = value;
	}
	
	public function initialize(stateManager:AppStateManager, app:Application):Void 
	{
		this.app = app;
		this.stateManager = stateManager;
	}
	
	public function isDebugEnabled():Bool
	{
        return debugEnabled;
    }
	
	public function stateAttached(stateManager:AppStateManager):Void 
	{
		if (!initialized) 
		{
			initialize(stateManager, stateManager.getApplication());
            startPhysics();
        }

        if (debugEnabled)
		{
            debugAppState = new BulletDebugAppState(pSpace);
            stateManager.attach(debugAppState);
        }
	}
	
	public function stateDetached(stateManager:AppStateManager):Void 
	{
		
	}
	
	public function update(tpf:Float):Void 
	{
		if (debugEnabled && debugAppState == null && pSpace != null) 
		{
            debugAppState = new BulletDebugAppState(pSpace);
            stateManager.attach(debugAppState);
        } 
		else if (!debugEnabled && debugAppState != null) 
		{
            stateManager.detach(debugAppState);
            debugAppState = null;
        }

        if (!active)
		{
            return;
        }
		
        pSpace.distributeEvents();
        this.tpf = tpf;
	}
	
	public function render(rm:RenderManager):Void 
	{
		if (!active)
		{
            return;
        }

		pSpace.update(active ? tpf * speed : 0);
	}
	
	public function postRender():Void 
	{
		
	}
	
	public function cleanup():Void 
	{
		if (debugAppState != null) 
		{
            stateManager.detach(debugAppState);
            debugAppState = null;
        }
        stopPhysics();
	}
	
	/**
     * Use before attaching state
     */
    public function setBroadphaseType(broadphaseType:BroadphaseType):Void
	{
        this.broadphaseType = broadphaseType;
    }

    /**
     * Use before attaching state
     */
    public function setWorldMin(worldMin:Vector3f):Void
	{
        this.worldMin = worldMin;
    }

    /**
     * Use before attaching state
     */
    public function setWorldMax(worldMax:Vector3f):Void
	{
        this.worldMax = worldMax;
    }

    public function getSpeed():Float 
	{
        return speed;
    }

    public function setSpeed(speed:Float):Void
	{
        this.speed = speed;
    }
	
}