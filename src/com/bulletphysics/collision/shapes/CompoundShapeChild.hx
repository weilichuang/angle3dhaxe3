package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.linearmath.Transform;

/**
 * Compound shape child.
 * @author weilichuang
 */
class CompoundShapeChild
{
	public var transform:Transform = new Transform();
	public var childShape:CollisionShape;
	public var childShapeType:BroadphaseNativeType;
	public var childMargin:Float;

	public function new() 
	{
		
	}
	
	public function equals(obj:CompoundShapeChild):Bool
	{
		if (obj == null)
			return false;
			
		return transform.equals(obj.transform) && childShape == obj.childShape &&
				childShapeType  == obj.childShapeType && childMargin == obj.childMargin;
	}
	
}