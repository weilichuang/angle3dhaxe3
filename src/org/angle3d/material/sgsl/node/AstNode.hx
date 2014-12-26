package org.angle3d.material.sgsl.node;

/**
 * ...
 * @author weilichuang
 */
class AstNode
{
	public var type:AstNodeType;
	public var text:String;
	public var children:Array<AstNode>;

	public function new(type:AstNodeType,text:String) 
	{
		this.type = type;
		this.text = text;
		children = [];
	}
	
	public function addChild(node:AstNode):Void
	{
		children.push(node);
	}
	
}