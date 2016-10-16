package org.angle3d.asset;

import flash.Lib;

class AssetInfo {
	
	public var type : String;
	public var url : String;
	public var content : Dynamic;
	public var noUseTime : Int;
	
	public var numOwners(get, never):Int;

	private var _owners : HashSet = new HashSet( true );

	public function new( url : String, type : String, content : Dynamic ) 
	{
		this.url = url;
		this.type = type;
		this.content = content;
	}

	public function dispose() : Void 
	{
		content = null;
		_owners = null;
	}

	private function get_numOwners() : Int
	{
		return _owners.length;
	}

	public function addOwner( o : Dynamic ) : Void 
	{
		_owners.add( o );
		noUseTime = Std.int(Math.POSITIVE_INFINITY);
	}

	public function removeOwner( o : Dynamic ) : Void
	{
		if ( _owners == null )
			return;
		_owners.remove( o );
		if ( _owners.length == 0 ) 
		{
			noUseTime = Lib.getTimer();
		}
	}
}
