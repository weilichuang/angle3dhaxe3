package org.angle3d.material.sgsl.node;
import org.angle3d.material.sgsl.node.agal.AgalLine;
import org.angle3d.material.sgsl.node.agal.FlatInfo;

/**
 * ...
 * @author weilichuang
 */
class AssignNode extends LeafNode
{
	public var destNode:AtomNode;
	
	public var sourceNode:LeafNode;

	public function new() 
	{
		super("=");
		destNode = null;
		sourceNode = null;
	}
	
	
	public function needFlat():Bool
	{
		return sourceNode.needFlat();
	}
	
	//执行此操作的前提是，所有自定义函数已替换
	//主要是要把右侧的复杂表达式提取出来
	//如果是函数调用，则查看参数是否需要提取
	//如果是OpNode，则和函数调用一样
	//常数则不需要修改
	override public function flat(result:Array<LeafNode>):Void
	{
		sourceNode.flat(result);
	}
	
	override public function calDepth(depth:Int):Void
	{
		this.depth = depth + 1;
		
		destNode.calDepth(this.depth);
		sourceNode.calDepth(this.depth);
	}
	
	override public function toString(level:Int = 0):String
	{
		var result:String = getSpace(level) + destNode.toString(0) +" = " + sourceNode.toString(0) + ";\n";

		return result;
	}
}