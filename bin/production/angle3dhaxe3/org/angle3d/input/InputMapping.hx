package org.angle3d.input;

import org.angle3d.input.controls.InputListener;
import org.angle3d.input.controls.Trigger;

class InputMapping
{
	public var name:String;
	public var triggers:Array<Int>;
	public var listeners:Array<InputListener>;

	public function new(name:String)
	{
		this.name = name;

		this.triggers = [];
		this.listeners = [];
	}
}


