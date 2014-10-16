package tests.util;

import vecmath.Vector3f;
import haxe.unit.TestCase;
import com.bulletphysics.util.ObjectPool;
/**
 * ...
 * @author weilichuang
 */
class ObjectPoolTestCase extends TestCase
{

	public function new() 
	{
		super();
		
	}
	
	public function testGet():Void
	{
		var pool0:ObjectPool<Vector3f> = ObjectPool.getPool(Vector3f);
		var pool1:ObjectPool<Vector3f> = ObjectPool.getPool(Vector3f);
		
		assertEquals(pool0, pool1);
		
		ObjectPool.cleanPools();
		
		var pool3:ObjectPool<Vector3f> = ObjectPool.getPool(Vector3f);
		
		assertFalse(pool0 == pool3);
	}
	
}