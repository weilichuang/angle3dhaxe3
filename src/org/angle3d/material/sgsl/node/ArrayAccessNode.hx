package org.angle3d.material.sgsl.node;
import haxe.ds.UnsafeStringMap;
import org.angle3d.material.sgsl.node.reg.RegNode;

class ArrayAccessNode extends SgslNode
{
	public var offset:Int = 0;

	public function new(name:String)
	{
		super(NodeType.ARRAYACCESS, name);
	}
	
	override public function replaceParamNode(paramMap:UnsafeStringMap<LeafNode>):Void
	{
		var node:LeafNode = paramMap.get(this.name);
		if (node != null)
		{
			this.name = node.name;
			if (node.mask.length > 0)
			{
				this.mask = node.mask;
			}
		}
		
		super.replaceParamNode(paramMap);
	}
	
	override public function checkDataType(programNode:ProgramNode, paramMap:UnsafeStringMap<String> = null):Void
	{
		for (i in 0...mChildren.length)
		{
			mChildren[i].checkDataType(programNode, paramMap);
		}
		
		var node:RegNode = programNode.getRegNode(this.name);
		
		var newType:String;
		if (node != null)
			newType = node.dataType;
		else if (paramMap != null && paramMap.exists(this.name))
		{
			newType = paramMap.get(this.name);
		}
		else
		{
			throw 'this node $name does not define';
		}
		
		if (newType == "mat33")
		{
			this._dataType = "vec3";
		}
		else if (newType == "mat34")
		{
			this._dataType = "vec4";
		}
		else if (newType == "mat44")
		{
			this._dataType = "vec4";
		}
		else
		{
			this._dataType = newType;
		}

		if (this.mask != null && this.mask.length > 0)
		{
			switch(mask.length)
			{
				case 1:
					_dataType = "float";
				case 2:
					_dataType = "vec2";
				case 3:
					_dataType = "vec3";
				case 4:
					_dataType = "vec4";
			}
		}
	}
	
	override private function get_dataType():String
	{
		return _dataType;
	}
	
	override public function renameLeafNode(map:UnsafeStringMap<String>):Void
	{
		if (map.exists(this.name))
		{
			this.name = map.get(this.name);
		}
		
		super.renameLeafNode(map);
	}
	
	override public function flat(programNode:ProgramNode, functionNode:FunctionNode, result:Array<LeafNode>):Void
	{
		super.flat(programNode, functionNode, result);
	}

	override public function isRelative():Bool
	{
		return mChildren[0] != null;
	}
	
	override public function clone(result:LeafNode = null):LeafNode
	{
		if (result == null)
			result = new ArrayAccessNode(name);
			
		var node:ArrayAccessNode = cast super.clone(result);
		node.offset = offset;
		return node;
	}

	override public function toString(level:Int = 0):String
	{
		var out:String = this.name + "[";

		if (mChildren[0] != null)
		{
			out += mChildren[0].toString(level);
		}

		if (offset >= 0)
		{
			if (mChildren[0] != null)
			{
				out += " + ";
			}
			out += offset + "";
		}

		out += "]";

		if (mask != "")
		{
			out += "." + mask;
		}

		return out;
	}
}

