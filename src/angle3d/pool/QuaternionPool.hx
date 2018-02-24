package angle3d.pool;
import angle3d.math.Quaternion;

class QuaternionPool extends ObjectPool<Quaternion> {
	public static var instance(get, never):QuaternionPool;

	private static var sInstance:QuaternionPool = null;

	private static function get_instance() : QuaternionPool {
		if (sInstance == null) {
			sInstance = new QuaternionPool();
		}
		return sInstance;
	}

	public function new() {
		super(Quaternion);
	}

	public function alloc() : Quaternion {
		var result:Quaternion = cast allocInternal();
		result.x = result.y = result.z = 0;
		return result;
	}

	public function allocEx(x:Float, y:Float, z:Float, w:Float) : Quaternion {
		var result:Quaternion = cast allocInternal();
		result.x = x;
		result.y = y;
		result.z = z;
		result.w = w;
		return result;
	}

	public function allocEx2(param1:Quaternion) : Quaternion {
		var result:Quaternion = cast allocInternal();
		result.x = param1.x;
		result.y = param1.y;
		result.z = param1.z;
		result.w = param1.w;
		return result;
	}
}
