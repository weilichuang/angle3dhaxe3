package org.angle3d.bullet.debug;

import org.angle3d.app.Application;
import org.angle3d.app.state.AbstractAppState;
import org.angle3d.app.state.AppStateManager;
import org.angle3d.bullet.joints.PhysicsJoint;
import org.angle3d.bullet.objects.PhysicsCharacter;
import org.angle3d.bullet.objects.PhysicsGhostObject;
import org.angle3d.bullet.objects.PhysicsRigidBody;
import org.angle3d.bullet.objects.PhysicsVehicle;
import org.angle3d.bullet.PhysicsSpace;
import org.angle3d.material.Material;
import org.angle3d.material.MaterialColorFill;
import org.angle3d.material.MaterialWireframe;
import org.angle3d.math.Color;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.CullHint;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Logger;
import org.angle3d.scene.Node;

/**
 * ...
 * @author weilichuang
 */
class BulletDebugAppState extends AbstractAppState
{
	public var DEBUG_BLUE:Material;
    public var DEBUG_RED:Material;
    public var DEBUG_GREEN:Material;
    public var DEBUG_YELLOW:Material;
    public var DEBUG_MAGENTA:Material;
    public var DEBUG_PINK:Material;
	
	private var bodies:Map<PhysicsRigidBody, Spatial> = new Map<PhysicsRigidBody, Spatial>();
    private var joints:Map<PhysicsJoint, Spatial> = new Map<PhysicsJoint, Spatial>();
    private var ghosts:Map<PhysicsGhostObject, Spatial> = new Map<PhysicsGhostObject, Spatial>();
    private var characters:Map<PhysicsCharacter, Spatial> = new Map<PhysicsCharacter, Spatial>();
    private var vehicles:Map<PhysicsVehicle, Spatial> = new Map<PhysicsVehicle, Spatial>();
	
	//private var filter:DebugAppStateFilter;
    private var app:Application;
    private var space:PhysicsSpace;
    private var physicsDebugRootNode:Node = new Node("Physics Debug Root Node");
    private var viewPort:ViewPort;
    private var rm:RenderManager;

	public function new(space:PhysicsSpace) 
	{
		super();
		this.space = space;
	}
	
	override public function initialize(stateManager:AppStateManager, app:Application):Void 
	{
		super.initialize(stateManager, app);
		
		this.app = app;
        this.rm = app.getRenderManager();
		
		setupMaterials();
		
		physicsDebugRootNode.localCullHint = (CullHint.Never);
        viewPort = rm.createMainView("Physics Debug Overlay", app.camera);
        viewPort.setClearFlags(false, true, false);
        viewPort.attachScene(physicsDebugRootNode);
	}
	
	override public function cleanup():Void 
	{
		rm.removeMainView(viewPort);
		super.cleanup();
	}
	
	override public function update(tpf:Float):Void 
	{
		super.update(tpf);
		
		//update all object links
        updateRigidBodies();
        updateGhosts();
        updateCharacters();
        updateJoints();
        updateVehicles();
        //update our debug root node
        physicsDebugRootNode.updateLogicalState(tpf);
        physicsDebugRootNode.updateGeometricState();
	}
	
	override public function render(rm:RenderManager):Void 
	{
		super.render(rm);
		if (viewPort != null)
		{
			rm.renderScene(physicsDebugRootNode, viewPort);
		}
	}
	
	private function setupMaterials():Void
	{
		//DEBUG_BLUE = new MaterialColorFill(Color.Blue().getColor());
		//DEBUG_GREEN = new MaterialColorFill(Color.Green().getColor());
		//DEBUG_RED = new MaterialColorFill(Color.Red().getColor());
		//DEBUG_YELLOW = new MaterialColorFill(Color.Yellow().getColor());
		//DEBUG_MAGENTA = new MaterialColorFill(Color.Magenta().getColor());
		//DEBUG_PINK = new MaterialColorFill(Color.Pink().getColor());
		
        DEBUG_BLUE = new MaterialWireframe(Color.Blue().getColor());
        DEBUG_GREEN = new MaterialWireframe(Color.Green().getColor());
		DEBUG_RED = new MaterialWireframe(Color.Red().getColor());
		DEBUG_YELLOW = new MaterialWireframe(Color.Yellow().getColor());
		DEBUG_MAGENTA = new MaterialWireframe(Color.Magenta().getColor());
		DEBUG_PINK = new MaterialWireframe(Color.Pink().getColor());
    }
	
	public function updateRigidBodies():Void
	{
		var oldObjects:Map<PhysicsRigidBody,Spatial> = bodies;
		
		bodies = new Map<PhysicsRigidBody,Spatial>();
		
		var current:Array<PhysicsRigidBody> = space.getRigidBodyList();
		for (i in 0...current.length)
		{
			var physicsObject:PhysicsRigidBody = current[i];
			
			//copy existing spatials
            if (oldObjects.exists(physicsObject)) 
			{
                var spat:Spatial = oldObjects.get(physicsObject);
                bodies.set(physicsObject, spat);
                oldObjects.remove(physicsObject);
            } 
			else 
			{
                //if (filter == null || filter.displayObject(physicsObject)) {
                    Logger.log("Create new debug RigidBody");
                    //create new spatial
                    var node:Node = new Node(Std.string(physicsObject));
                    node.addControl(new BulletRigidBodyDebugControl(this, physicsObject));
                    bodies.set(physicsObject, node);
                    physicsDebugRootNode.attachChild(node);
                //}
            }
		}
		
		var keys = oldObjects.keys();
		for (key in keys)
		{
			var spatial:Spatial = oldObjects.get(key);
			spatial.removeFromParent();
		}
	}
	
	public function updateGhosts():Void
	{
		
	}
	
	public function updateCharacters():Void
	{
		
	}
	
	public function updateJoints():Void
	{
		
	}
	
	public function updateVehicles():Void
	{
		
	}
}