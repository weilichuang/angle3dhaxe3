package org.angle3d.bullet.debug;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.objects.PhysicsCharacter;
import org.angle3d.bullet.util.DebugShapeFactory;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;

/**
 * ...
 
 */
class BulletCharacterDebugControl extends AbstractPhysicsDebugControl
{
	private var body:PhysicsCharacter;
    private var location:Vector3f = new Vector3f();
    private var rotation:Quaternion = new Quaternion();
    private var myShape:CollisionShape;
    private var geom:Spatial;

	public function new(debugAppState:BulletDebugAppState,body:PhysicsCharacter) 
	{
		super(debugAppState);
		
		this.body = body;
        myShape = body.getCollisionShape();
        this.geom = DebugShapeFactory.getDebugShape(body.getCollisionShape());
        geom.setMaterial(debugAppState.DEBUG_PINK);
	}
	
	override public function setSpatial(spatial:Spatial):Void 
	{
		if (spatial != null && Std.is(spatial,Node))
		{
            var node:Node = cast spatial;
            node.attachChild(geom);
        } 
		else if (spatial == null && this.spatial != null)
		{
            var node:Node = cast this.spatial;
            node.detachChild(geom);
        }
		super.setSpatial(spatial);
	}
	
	override function controlUpdate(tpf:Float):Void 
	{
		if (myShape != body.getCollisionShape())
		{
            var node:Node = cast this.spatial;
            node.detachChild(geom);
            geom = DebugShapeFactory.getDebugShape(body.getCollisionShape());
            geom.setMaterial(debugAppState.DEBUG_PINK);
            node.attachChild(geom);
        }
        applyPhysicsTransform(body.getPhysicsLocation(location), Quaternion.IDENTITY);
        geom.setLocalScale(body.getCollisionShape().getScale());
	}
	
}