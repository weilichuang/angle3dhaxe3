package org.angle3d.material.sgsl.parser;

class Token
{
	public var name:String;
	public var type:String;
	
	public var line:Int = 0;
	public var position:Int = 0;

	public function new(type:String, name:String, line:Int = 0, position:Int = 0)
	{
		this.type = type;
		this.name = name;
		this.line = line;
		this.position = position;
	}

	public function equals(type:String, name:String):Bool
	{
		return (this.type == type && this.name == name);
	}

	public function equalsToken(token:Token):Bool
	{
		return (type == token.type && name == token.name);
	}
}


