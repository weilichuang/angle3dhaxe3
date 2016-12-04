package org.angle3d.pool;
import org.angle3d.math.Matrix4f;

class Matrix4fPool extends ObjectPool<Matrix4f>
{
	public static var instance(get, never):Matrix4fPool;

	private static var sInstance:Matrix4fPool = null;

	private static function get_instance() : Matrix4fPool
	{
		if (sInstance == null)
		{
			sInstance = new Matrix4fPool();
		}
		return sInstance;
	}

	public function new()
	{
		super(Matrix4f);
	}

	public function alloc() : Matrix4f
	{
		var result:Matrix4f = cast allocInternal();
		result.loadIdentity();
		return result;
	}

	public function allocEx(param1:Matrix4f) : Matrix4f
	{
		var result:Matrix4f = cast allocInternal();
		result.copyFrom(param1);
		return result;
	}
}
