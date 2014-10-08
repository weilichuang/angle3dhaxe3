package com.bulletphysics.linearmath;
import com.bulletphysics.linearmath.Transform;

/**
 * DefaultMotionState provides a common implementation to synchronize world transforms
 * with offsets.
 * @author weilichuang
 */
class DefaultMotionState extends MotionState
{
	/**
     * Current interpolated world transform, used to draw object.
     */
	public var graphicsWorldTrans:Transform = new Transform();
	
	/**
     * Center of mass offset transform, used to adjust graphics world transform.
     */
	public var centerOfMassOffset:Transform = new Transform();
	
	/**
     * Initial world transform.
     */
	public var startWorldTrans:Transform = new Transform();

	
	/**
     * Creates a new DefaultMotionState with initial world transform and center
     * of mass offset transform.
     */
	public function new(startTrans:Transform,centerOfMassOffset:Transform = null) 
	{
		super();
		this.graphicsWorldTrans.fromTransform(startTrans);
		this.startWorldTrans.fromTransform(startTrans);
		
		if(centerOfMassOffset != null)
			this.centerOfMassOffset.fromTransform(centerOfMassOffset);
		else
			this.centerOfMassOffset.setIdentity();
	}
	
	override public function getWorldTransform(out:Transform):Transform 
	{
		out.inverse(centerOfMassOffset);
		out.mul(graphicsWorldTrans);
		return out;
	}
	
	override public function setWorldTransform(worldTrans:Transform):Void 
	{
		graphicsWorldTrans.fromTransform(worldTrans);
		graphicsWorldTrans.mul(centerOfMassOffset);
	}
	
}