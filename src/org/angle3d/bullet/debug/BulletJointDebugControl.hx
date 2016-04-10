package org.angle3d.bullet.debug;
import org.angle3d.bullet.joints.PhysicsJoint;
import org.angle3d.math.Transform;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.debug.Arrow;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;

/**
 * ...
 
 */
class BulletJointDebugControl extends AbstractPhysicsDebugControl
{
	private var body:PhysicsJoint;
    private var geomA:Geometry;
    private var arrowA:Arrow;
    private var geomB:Geometry;
    private var arrowB:Arrow;
    private var a:Transform = new Transform();
    private var b:Transform = new Transform();
    private var offA:Vector3f = new Vector3f();
    private var offB:Vector3f = new Vector3f();

	public function new(debugAppState:BulletDebugAppState, body:PhysicsJoint) 
	{
		super(debugAppState);
		this.body = body;
		
        this.geomA = new Geometry("physicsJointA");
        arrowA = new Arrow(Vector3f.ZERO);
        geomA.setMesh(arrowA);
        geomA.setMaterial(debugAppState.DEBUG_GREEN);
		
        this.geomB = new Geometry("physicsJointB");
        arrowB = new Arrow(Vector3f.ZERO);
        geomB.setMesh(arrowB);
        geomB.setMaterial(debugAppState.DEBUG_GREEN);
	}
	
	override public function setSpatial(newSpatial:Spatial):Void 
	{
		if (newSpatial != null && Std.is(newSpatial, Node))
		{
            var node:Node = cast newSpatial;
            node.attachChild(geomA);
            node.attachChild(geomB);
        } 
		else if (newSpatial == null && this.getSpatial() != null) 
		{
            var node:Node = cast this.getSpatial();
            node.detachChild(geomA);
            node.detachChild(geomB);
        }
		super.setSpatial(newSpatial);
	}
	
	override function controlUpdate(tpf:Float):Void 
	{
		body.getBodyA().getPhysicsLocation(a.translation);
        body.getBodyA().getPhysicsRotation(a.rotation);

        body.getBodyB().getPhysicsLocation(b.translation);
        body.getBodyB().getPhysicsRotation(b.rotation);

        geomA.setTransform(a);
        geomB.setTransform(b);

        arrowA.setArrowExtent(body.getPivotA());
        arrowB.setArrowExtent(body.getPivotB());
	}
}