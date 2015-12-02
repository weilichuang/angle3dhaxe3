package org.angle3d.material.sgsl.node;

class AgalNode
{
	public var name:String;
	public var dest:LeafNode;
	public var source1:LeafNode;
	public var source2:LeafNode;
	
	public function new() 
	{
		dest = null;
		source1 = null;
		source2 = null;
	}
	
}