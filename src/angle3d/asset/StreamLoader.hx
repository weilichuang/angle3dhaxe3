package angle3d.asset;
import flash.net.URLRequest;
import flash.net.URLStream;
import haxe.Timer;

class StreamLoader extends URLStream {
	private var _timetOutId:Timer;
	private var _priority : Int;
	private var _url : String;
	private var _urlRequest : URLRequest;

	public var url(get, never):String;
	public var timeoutId(get, set):Timer;
	public var priority(get, never):Int;

	public function new() {
		super();
		_urlRequest = new URLRequest();
	}

	private function get_url() : String {
		return _url;
	}

	private function get_timeoutId() : Timer {
		return _timetOutId;
	}

	private function set_timeoutId( value : Timer ) : Timer {
		return _timetOutId = value;
	}

	public function clearTimeout() : Void {
		if ( _timetOutId != null) {
			_timetOutId.stop();
			_timetOutId = null;
		}
	}

	private function get_priority() : Int {
		return _priority;
	}

	public function doLoad( info : WaitInfo ) : Void {
		_url = info.url;
		_priority = info.priority;
		_urlRequest.url = _url;
		load( _urlRequest );
	}

	override public function close() : Void {
		clearTimeout();
		if ( connected ) {
			super.close();
		}
	}
}
