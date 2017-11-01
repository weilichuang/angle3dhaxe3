package org.angle3d.core;

class Stage {
	
	static var inst : Stage = null;
	public static function getInstance() : Stage {
		if( inst == null ) inst = new Stage();
		return inst;
	}
	
	public var width(get, never) : Int;
	public var height(get, never) : Int;
	public var mouseX(get, never) : Int;
	public var mouseY(get, never) : Int;
	public var mouseLock(get, set) : Bool;
	public var vsync(get, set) : Bool;

	function new() : Void {
	}

	public dynamic function onClose() : Bool {
		return true;
	}

	public function resize( width : Int, height : Int ) : Void 
	{
	}

	public function setFullScreen( v : Bool ) : Void 
	{
	}

	function get_mouseX() : Int 
	{
		return 0;
	}

	function get_mouseY() : Int 
	{
		return 0;
	}

	function get_width() : Int 
	{
		return 0;
	}

	function get_height() : Int 
	{
		return 0;
	}

	function get_mouseLock() : Bool 
	{
		return false;
	}

	function set_mouseLock( v : Bool ) : Bool
	{
		if( v ) throw "Not implemented";
		return false;
	}

	function get_vsync() : Bool 
	{
		return true;
	}

	function set_vsync( b : Bool ) : Bool
	{
		if ( !b ) 
			throw "Can't disable vsync on this platform";
		return true;
	}

}
