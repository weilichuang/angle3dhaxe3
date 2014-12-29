package org.angle3d.material.sgsl.node;
import org.angle3d.material.sgsl.node.agal.FlatInfo;

/**
 * ...
 * @author weilichuang
 */
class OpNode extends LeafNode
{
	public var leftNode:LeafNode;
	public var rightNode:LeafNode;

	public function new(name:String) 
	{
		super(name);
	}
	
	override public function flat(result:Array<FlatInfo>):Void
	{
		leftNode = leftNode.flat(result);
	}
	
	override public function calDepth(depth:Int):Void
	{
		this.depth = depth + 1;
		
		leftNode.calDepth(this.depth);
		rightNode.calDepth(this.depth);
	}
	
	override public function getDataType():String
	{
		switch(this.name)
		{
			case "+", "-", "/":
				return leftNode.getDataType();
			case "*":
				if (leftNode.getDataType() == "vec3")
					return "vec3";
				else if (leftNode.getDataType() == "vec2")
					return "vec2";
				else if (leftNode.getDataType() == "vec4")
					return "vec4";
				else 
					return "float";
			default:
				return "";
		}
	}
	
	override public function toString(level:Int = 0):String
	{
		var result:String = getSpace(level) + leftNode.toString(0) + this.name + rightNode.toString(0);

		return result;
	}
}