package org.angle3d.material.sgsl.parser;

class Token
{
	public var name:String;
	public var type:String;

	public function new(type:String, name:String)
	{
		this.type = type;
		this.name = name;
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


