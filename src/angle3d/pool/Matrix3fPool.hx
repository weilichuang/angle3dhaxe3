package angle3d.pool;
import angle3d.math.Matrix3f;

class Matrix3fPool extends ObjectPool<Matrix3f> {
	public static var instance(get, never):Matrix3fPool;

	private static var sInstance:Matrix3fPool = null;

	private static function get_instance() : Matrix3fPool {
		if (sInstance == null) {
			sInstance = new Matrix3fPool();
		}
		return sInstance;
	}

	public function new() {
		super(Matrix3f);
	}

	public function alloc() : Matrix3f {
		var result:Matrix3f = cast allocInternal();
		result.loadIdentity();
		return result;
	}

	public function allocEx(param1:Matrix3f) : Matrix3f {
		var result:Matrix3f = cast allocInternal();
		result.copyFrom(param1);
		return result;
	}
}
