package org.angle3d.bullet.debug;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.objects.PhysicsRigidBody;
import org.angle3d.bullet.util.DebugShapeFactory;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;

/**
 * ...
 
 */
class BulletRigidBodyDebugControl extends AbstractPhysicsDebugControl
{
	private var body:PhysicsRigidBody;
    private var location:Vector3f = new Vector3f();
    private var rotation:Quaternion = new Quaternion();
    private var myShape:CollisionShape;
    private var geom:Spatial;

	public function new(debugAppState:BulletDebugAppState,body:PhysicsRigidBody) 
	{
		super(debugAppState);
		
		this.body = body;
        myShape = body.getCollisionShape();
        this.geom = DebugShapeFactory.getDebugShape(body.getCollisionShape());
        this.geom.name = Std.string(body);
        geom.setMaterial(debugAppState.DEBUG_BLUE);
	}
	
	override public function setSpatial(spatial:Spatial):Void 
	{
		if (spatial != null && Std.is(spatial,Node))
		{
            var node:Node = cast spatial;
            node.attachChild(geom);
        } 
		else if (spatial == null && this.getSpatial() != null)
		{
            var node:Node = cast this.getSpatial();
            node.detachChild(geom);
        }
		super.setSpatial(spatial);
	}
	
	override function controlUpdate(tpf:Float):Void 
	{
		if (myShape != body.getCollisionShape())
		{
            var node:Node = cast this.getSpatial();
            node.detachChild(geom);
            geom = DebugShapeFactory.getDebugShape(body.getCollisionShape());
            node.attachChild(geom);
        }
        if (body.isActive())
		{
            geom.setMaterial(debugAppState.DEBUG_MAGENTA);
        }
		else
		{
            geom.setMaterial(debugAppState.DEBUG_BLUE);
        }
        applyPhysicsTransform(body.getPhysicsLocation(location), body.getPhysicsRotation(rotation),this.getSpatial());
        geom.setLocalScale(body.getCollisionShape().getScale());
	}
	
}