package org.angle3d.asset.parsers;
import org.angle3d.asset.AssetInfo;

class BytesParser extends BaseParser
{
	public function new()
	{
		super();
	}

	override public function parse( url : String, data : Dynamic ) : Void
	{
		super.parse( url, data );
		notifyComplete( new AssetInfo( url, _type, data ));
	}
}
