package org.angle3d.bullet.collision.shapes;
import com.bulletphysics.collision.shapes.CompoundShape;
import com.bulletphysics.linearmath.Transform;
import org.angle3d.bullet.collision.shapes.infos.ChildCollisionShape;
import org.angle3d.bullet.util.Converter;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Vector3f;
import org.angle3d.utils.Logger;

/**
 * A CompoundCollisionShape allows combining multiple base shapes
 * to generate a more sophisticated shape.
 * @author weilichuang
 */
class CompoundCollisionShape extends CollisionShape
{
	private var children:Array<ChildCollisionShape> = [];

	public function new() 
	{
		super();
		cShape = new CompoundShape();
	}
	
	public function addChildShape(shape:CollisionShape, location:Vector3f, rotation:Matrix3f = null):Void
	{
		var transA:Transform = new Transform();
		
		if (rotation == null)
			rotation = new Matrix3f();
		
		transA.fromMatrix3f(rotation);
		
		transA.origin.copyFrom(location);
		transA.basis.copyFrom(rotation);
		
		children.push(new ChildCollisionShape(location.clone(), rotation.clone(), shape));
		
		cast(cShape, CompoundShape).addChildShape(transA, shape.getCShape());
	}
	
	//private function addChildShapeDirect(shape:CollisionShape, location:Vector3f, rotation:Matrix3f = null):Void
	//{
		//var transA:Transform = new Transform();
		//
		//if (rotation == null)
			//rotation = new Matrix3f();
		//
		//transA.fromMatrix3f(Converter.a2vMatrix3f(rotation));
		//
		//Converter.a2vVector3f(location, transA.origin);
		//Converter.a2vMatrix3f(rotation, transA.basis);
	//
		//cast(cShape, CompoundShape).addChildShape(transA, shape.getCShape());
	//}
	
	public function removeChildShape(shape:CollisionShape):Void
	{
		cast(cShape, CompoundShape).removeChildShape(shape.getCShape());
		
		children.remove(cast shape);
	}
	
	public function getChildren():Array<ChildCollisionShape>
	{
		return children;
	}
	
	override public function setScale(scale:Vector3f):Void 
	{
		Logger.warn("CompoundCollisionShape cannot be scaled");
	}
}