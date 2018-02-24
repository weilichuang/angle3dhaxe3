package angle3d.asset.parsers;
import angle3d.asset.AssetInfo;

class BaseParser {
	private var _complete : AssetInfo->Bool->Void;
	private var _error : String->String->Void;
	private var _isCache : Bool;

	private var _data : Dynamic;
	private var _url : String;
	private var _type : String;

	public function new() {
	}

	public function setType( type : String ) : BaseParser {
		_type = type;
		return this;
	}

	public function initialize( complete : AssetInfo->Bool->Void, error : String->String->Void, isCache : Bool ) : Void {
		_complete = complete;
		_error = error;
		_isCache = isCache;
	}

	public function parse( url : String, data : Dynamic ) : Void {
		_url = url;
		_data = data;
	}

	private function notifyComplete( info : AssetInfo ) : Void {
		if ( _complete != null ) {
			_complete( info, _isCache );
		}
		dispose();
	}

	private function notifyError() : Void {
		_error( _url,"error" );
		dispose();
	}

	public function dispose() : Void {
		_complete = null;
		_error = null;
		_data = null;
		_url = null;
	}
}
