package org.angle3d.material.sgsl.parser;

class Token
{
	public var text:String;
	public var type:String;
	
	public var line:Int = 0;
	public var position:Int = 0;

	public function new(type:String, text:String, line:Int = 0, position:Int = 0)
	{
		this.type = type;
		this.text = text;
		this.line = line;
		this.position = position;
	}

	public function equals(type:String, text:String):Bool
	{
		return (this.type == type && this.text == text);
	}

	public function equalsToken(token:Token):Bool
	{
		return (type == token.type && text == token.text);
	}
}


