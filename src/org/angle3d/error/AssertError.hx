package org.angle3d.error;

/**
	Thrown to indicate that an assertion failed
**/
class AssertError
{
	public var message:String;
	
	public function new(?message:String, ?info:haxe.PosInfos)
	{
		if (message == null) message = "";
		this.message = message;
		
		var stack = haxe.CallStack.toString(haxe.CallStack.callStack());
		stack = ~/\nCalled from de\.polygonal\.ds\.error\.AssertError.*$/m.replace(stack, "");
		
		this.message = 'Assertation $message failed in file ${info.fileName}, line ${info.lineNumber}, ${info.className}:: ${info.methodName}\nCall stack:${stack}';
	}
	
	public function toString():String return message;
}