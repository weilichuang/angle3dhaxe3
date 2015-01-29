package org.angle3d.material.sgsl.node;

class OpNode extends SgslNode
{
	public function new(type:NodeType,name:String) 
	{
		super(type, name);
	}
	
	private function getOpDataType():String
	{
		var dataType0:String = mChildren[0].dataType;
		var dataType1:String = mChildren[1].dataType;
		switch(this.name)
		{
			case "+", "-", "/":
				if (dataType0 != dataType1)
					throw '$dataType0 should equal to $dataType1';
				return dataType0;
			case "*":
				if (dataType0 == null || dataType1 == null)
				{
					throw 'OpNode Children`s datType cant be null: $dataType0 , $dataType1';
				}
				else if (dataType0 != "mat4" && dataType0 != "mat3" && dataType0 != "mat34" && dataType0 == dataType1)
				{
					return dataType0;
				}
				else if(dataType0 == "vec4" && dataType1 == "mat4")
				{
					return "vec4";
				}
				else if(dataType0 == "vec3" && dataType1 == "mat3")
				{
					return "vec3";
				}
				else if(dataType0 == "vec3" && dataType1 == "mat4")
				{
					return "vec3";
				}
				else if(dataType0 == "vec3" && dataType1 == "mat34")
				{
					return "vec3";
				}
				else if(dataType0 == "vec2" && dataType1 == "float")
				{
					return dataType0;
				}
				else if(dataType0 == "vec3" && dataType1 == "float")
				{
					return dataType0;
				}
				else if(dataType0 == "vec4" && dataType1 == "float")
				{
					return dataType0;
				}
				else if(dataType0 == "float" && dataType1 == "vec2")
				{
					return dataType1;
				}
				else if(dataType0 == "float" && dataType1 == "vec3")
				{
					return dataType1;
				}
				else if(dataType0 == "float" && dataType1 == "vec4")
				{
					return dataType1;
				}
				else
				{
					throw "Cant find return type by : " + dataType0 + " * " + dataType1;
				}
				
			default:
				throw 'OpNode name shoule only be [+,-,*,/]';
		}
		return null;
	}
	
	override private function get_dataType():String
	{
		var opDataType:String = getOpDataType();

		this._dataType = opDataType;
		
		return this._dataType;
	}
	
	public function toFunctionCallNode():FunctionCallNode
	{
		var functionName:String = "";
		switch(this.name)
		{
			case "+":
				functionName = "add";
			case "-":
				functionName = "sub";
			case "/":
				functionName = "div";
			case "*":
				var dataType0:String = mChildren[0].dataType;
				var dataType1:String = mChildren[1].dataType;
				
				if (dataType0 == dataType1)
				{
					functionName = "mul";
				}
				else if(dataType0 == "vec4" && dataType1 == "mat4")
				{
					functionName = "m44";
				}
				else if(dataType0 == "vec3" && dataType1 == "mat3")
				{
					functionName = "m33";
				}
				else if(dataType0 == "vec3" && dataType1 == "mat4")
				{
					functionName = "m33";
				}
				else if(dataType0 == "vec3" && dataType1 == "mat34")
				{
					functionName = "m33";
				}
				else if(dataType0 == "vec2" && dataType1 == "float")
				{
					functionName = "mul";
				}
				else if(dataType0 == "vec3" && dataType1 == "float")
				{
					functionName = "mul";
				}
				else if(dataType0 == "vec4" && dataType1 == "float")
				{
					functionName = "mul";
				}
				else if(dataType0 == "float" && dataType1 == "vec2")
				{
					functionName = "mul";
				}
				else if(dataType0 == "float" && dataType1 == "vec3")
				{
					functionName = "mul";
				}
				else if(dataType0 == "float" && dataType1 == "vec4")
				{
					functionName = "mul";
				}
				else
				{
					throw "Cant find function: " + dataType0 + " * " + dataType1;
				}
		}

		var callNode:FunctionCallNode = new FunctionCallNode(functionName);
		cloneChildren(callNode);
		callNode.mask = this.mask;
		return callNode;
	}
	
	override public function clone():LeafNode
	{
		var node:OpNode = new OpNode(this.type,this.name);
		cloneChildren(node);
		node.mask = mask;
		return node;
	}
	
	override public function toString(level:Int = 0):String
	{
		var result:String = getSpace(level) + mChildren[0].toString(0) + this.name + mChildren[1].toString(0);

		return result;
	}
}