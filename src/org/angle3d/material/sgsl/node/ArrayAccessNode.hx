package org.angle3d.material.sgsl.node;

class ArrayAccessNode extends AtomNode
{
	public var access:AtomNode;
	public var offset:Int;

	public function new(name:String)
	{
		super(name);
		access = null;
		offset= 0;
	}

	override public function isRelative():Bool
	{
		return access != null;
	}

	override public function clone():LeafNode
	{
		var node:ArrayAccessNode = new ArrayAccessNode(name);
		if (access != null)
		{
			node.access = Std.instance(access.clone(), ArrayAccessNode);
		}
		node.offset= offset;
		node.mask = mask;
		return node;
	}

	override public function toString(level:Int = 0):String
	{
		var out:String = this.name + "[";

		if (access != null)
		{
			out += access.toString(level);
		}

		if (offset>= 0)
		{
			if (access != null)
			{
				out += " + ";
			}
			out += offset+ "";
		}

		out += "]";

		if (mask != "")
		{
			out += "." + mask;
		}

		return out;
	}
}

