package org.angle3d.pool;
import org.angle3d.math.Vector3f;

class Vector3fPool extends ObjectPool<Vector3f> {
	public static var instance(get, never):Vector3fPool;

	private static var sInstance:Vector3fPool = null;

	private static function get_instance() : Vector3fPool {
		if (sInstance == null) {
			sInstance = new Vector3fPool();
		}
		return sInstance;
	}

	public function new() {
		super(Vector3f);
	}

	public function alloc() : Vector3f {
		var result:Vector3f = cast allocInternal();
		result.x = result.y = result.z = 0;
		return result;
	}

	public function allocEx(x:Float, y:Float, z:Float) : Vector3f {
		var result:Vector3f = cast allocInternal();
		result.x = x;
		result.y = y;
		result.z = z;
		return result;
	}

	public function allocEx2(param1:Vector3f) : Vector3f {
		var result:Vector3f = cast allocInternal();
		result.x = param1.x;
		result.y = param1.y;
		result.z = param1.z;
		return result;
	}
}
