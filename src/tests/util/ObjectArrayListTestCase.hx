package tests.util;

import com.bulletphysics.util.ObjectArrayList;
import vecmath.Vector2f;
import haxe.unit.TestCase;

/**
 * ...
 * @author weilichuang
 */
class ObjectArrayListTestCase extends TestCase
{

	public function new() 
	{
		super();
		
	}
	
	public function testSize():Void
	{
		var list:ObjectArrayList<Vector2f> = new ObjectArrayList<Vector2f>(16);
		
		assertEquals(list.size(), 0);
		assertEquals(list.capacity(), 16);
		
		list.add(new Vector2f(100, 10));
		assertEquals(list.size(), 1);
		assertEquals(list.get(0).x, 100);
		
		for (i in 0...16)
		{
			list.add(new Vector2f(100*(i+1), 10*(i+1)));
		}
		
		assertEquals(list.size(), 17);
		assertEquals(list.capacity(), 32);
		
		list.remove(10);
		assertEquals(list.size(), 16);
	}
	
	public function testOperation():Void
	{
		var list:ObjectArrayList<Vector2f> = new ObjectArrayList<Vector2f>(16);
		
		for (i in 0...16)
		{
			list.add(new Vector2f(100*(i+1), 10*(i+1)));
		}
		
		list.insert(12, new Vector2f(121.2, 12.12));
		assertEquals(list.get(12).x, 121.2);
		assertEquals(list.get(12).y, 12.12);
		assertEquals(list.get(13).x, 100*(12+1));
		assertEquals(list.get(13).y, 10 * (12 + 1));
		
		assertEquals(list.indexOf(list.getQuick(10)), 10);
		
		list.clear();
		assertEquals(list.size(), 0);
	}
	
}