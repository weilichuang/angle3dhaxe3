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
import org.angle3d.math.Color;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.CullHint;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Logger;

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
		
		DEBUG_BLUE = new Material();
		DEBUG_BLUE.load("assets/material/wireframe.mat");
		DEBUG_BLUE.setColor("u_color", Color.Blue());
		
		DEBUG_GREEN = new Material();
		DEBUG_GREEN.load("assets/material/wireframe.mat");
		DEBUG_GREEN.setColor("u_color", Color.Green());
		
		DEBUG_RED = new Material();
		DEBUG_RED.load("assets/material/wireframe.mat");
		DEBUG_RED.setColor("u_color", Color.Red());
		
		DEBUG_YELLOW = new Material();
		DEBUG_YELLOW.load("assets/material/wireframe.mat");
		DEBUG_YELLOW.setColor("u_color", Color.Yellow());
		
		DEBUG_MAGENTA = new Material();
		DEBUG_MAGENTA.load("assets/material/wireframe.mat");
		DEBUG_MAGENTA.setColor("u_color", Color.Magenta());
		
		DEBUG_PINK = new Material();
		DEBUG_PINK.load("assets/material/wireframe.mat");
		DEBUG_PINK.setColor("u_color",Color.Pink());
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
                //if (filter == null || filter.displayObject(physicsObject)) 
				if (physicsObject.showDebug)
				{
                    Logger.log("Create new debug RigidBody");
                    //create new spatial
                    var node:Node = new Node(Std.string(physicsObject));
                    node.addControl(new BulletRigidBodyDebugControl(this, physicsObject));
                    bodies.set(physicsObject, node);
                    physicsDebugRootNode.attachChild(node);
                }
            }
		}
		
		for (spatial in oldObjects)
		{
			spatial.removeFromParent();
		}
	}
	
	public function updateGhosts():Void
	{
		var oldObjects:Map<PhysicsGhostObject,Spatial> = ghosts;
		
		ghosts = new Map<PhysicsGhostObject,Spatial>();
		
		var current:Array<PhysicsGhostObject> = space.getGhostObjectList();
		for (i in 0...current.length)
		{
			var physicsObject:PhysicsGhostObject = current[i];
			
			//copy existing spatials
            if (oldObjects.exists(physicsObject)) 
			{
                var spat:Spatial = oldObjects.get(physicsObject);
                ghosts.set(physicsObject, spat);
                oldObjects.remove(physicsObject);
            } 
			else 
			{
                //if (filter == null || filter.displayObject(physicsObject)) {
                    Logger.log("Create new debug GhostObject");
                    //create new spatial
                    var node:Node = new Node(Std.string(physicsObject));
                    node.addControl(new BulletGhostObjectDebugControl(this, physicsObject));
                    ghosts.set(physicsObject, node);
                    physicsDebugRootNode.attachChild(node);
                //}
            }
		}
		
		for (spatial in oldObjects)
		{
			spatial.removeFromParent();
		}
	}
	
	public function updateCharacters():Void
	{
		var oldObjects:Map<PhysicsCharacter,Spatial> = characters;
		
		characters = new Map<PhysicsCharacter,Spatial>();
		
		var current:Array<PhysicsCharacter> = space.getCharacterList();
		for (i in 0...current.length)
		{
			var physicsObject:PhysicsCharacter = current[i];
			
			//copy existing spatials
            if (oldObjects.exists(physicsObject)) 
			{
                var spat:Spatial = oldObjects.get(physicsObject);
                characters.set(physicsObject, spat);
                oldObjects.remove(physicsObject);
            } 
			else 
			{
                //if (filter == null || filter.displayObject(physicsObject)) {
                    Logger.log("Create new debug Character");
                    //create new spatial
                    var node:Node = new Node(Std.string(physicsObject));
                    node.addControl(new BulletCharacterDebugControl(this, physicsObject));
                    characters.set(physicsObject, node);
                    physicsDebugRootNode.attachChild(node);
                //}
            }
		}
		
		for (spatial in oldObjects)
		{
			spatial.removeFromParent();
		}
	}
	
	public function updateJoints():Void
	{
		var oldObjects:Map<PhysicsJoint,Spatial> = joints;
		
		joints = new Map<PhysicsJoint,Spatial>();
		
		var current:Array<PhysicsJoint> = space.getJointList();
		for (i in 0...current.length)
		{
			var physicsObject:PhysicsJoint = current[i];
			
			//copy existing spatials
            if (oldObjects.exists(physicsObject)) 
			{
                var spat:Spatial = oldObjects.get(physicsObject);
                joints.set(physicsObject, spat);
                oldObjects.remove(physicsObject);
            } 
			else 
			{
                //if (filter == null || filter.displayObject(physicsObject)) {
                    Logger.log("Create new debug Joint");
                    //create new spatial
                    var node:Node = new Node(Std.string(physicsObject));
                    node.addControl(new BulletJointDebugControl(this, physicsObject));
                    joints.set(physicsObject, node);
                    physicsDebugRootNode.attachChild(node);
                //}
            }
		}
		
		for (spatial in oldObjects)
		{
			spatial.removeFromParent();
		}
	}
	
	public function updateVehicles():Void
	{
		var oldObjects:Map<PhysicsVehicle,Spatial> = vehicles;
		
		vehicles = new Map<PhysicsVehicle,Spatial>();
		
		var current:Array<PhysicsVehicle> = space.getVehicleList();
		for (i in 0...current.length)
		{
			var physicsObject:PhysicsVehicle = current[i];
			
			//copy existing spatials
            if (oldObjects.exists(physicsObject)) 
			{
                var spat:Spatial = oldObjects.get(physicsObject);
                vehicles.set(physicsObject, spat);
                oldObjects.remove(physicsObject);
            } 
			else 
			{
                //if (filter == null || filter.displayObject(physicsObject)) {
                    Logger.log("Create new debug Vehicle");
                    //create new spatial
                    var node:Node = new Node(Std.string(physicsObject));
                    node.addControl(new BulletVehicleDebugControl(this, physicsObject));
                    vehicles.set(physicsObject, node);
                    physicsDebugRootNode.attachChild(node);
                //}
            }
		}
		
		for (spatial in oldObjects)
		{
			spatial.removeFromParent();
		}
	}
}