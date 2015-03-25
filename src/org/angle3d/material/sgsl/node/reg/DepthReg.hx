package org.angle3d.material.sgsl.node.reg;

import org.angle3d.material.sgsl.DataType;
import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.node.LeafNode;

/**
 * Fragment depth output
 * It’s a new register “fd” in pixel shader. Note that it’s write-only and used to re-write z-value (or depth value) written in vertex shader.
 * Note that only its x component (fd.x) is available as it’s a scalar. Also, re-writing z-value is often considered as a costly operation. 
 * Hence, use it only if it’s really needed.
 * @see http://blogs.adobe.com/flashplayer/2014/09/stage3d-standard-profile.html
 * @author weilichuang
 */
class DepthReg extends RegNode
{
	public function new()
	{
		super(RegType.DEPTH, DataType.FLOAT, "");
		this.name = "depth";
		this.index = 0;
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new DepthReg();
			
		return super.clone(result);
	}
}


