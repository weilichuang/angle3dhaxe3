package angle3d.input;

import angle3d.input.controls.InputListener;
import angle3d.input.controls.Trigger;

class InputMapping
{
	public var name:String;
	public var triggers:Array<Int>;
	public var listeners:Array<InputListener>;

	public inline function new(name:String)
	{
		this.name = name;

		this.triggers = [];
		this.listeners = [];
	}
}


