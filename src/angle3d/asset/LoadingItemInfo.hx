package angle3d.asset;

class LoadingItemInfo {
	public var ref : Dynamic;
	public var data : Dynamic;
	public var openHandler : Dynamic;
	public var completeHandler : Dynamic;
	public var progressHandler : Dynamic;
	public var errorHandler : Dynamic;

	public function new() {

	}

	public function dispose() :Void {
		ref = null;
		data = null;
		openHandler = null;
		completeHandler = null;
		progressHandler = null;
		errorHandler = null;
	}
}
