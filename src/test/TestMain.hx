package test;
import haxe.unit.TestRunner;
import test.collision.BoundingCollisionTest;
import test.light.LightFilterTest;
import test.light.LightSortTest;

class TestMain 
{
	static function main()
	{
		new TestMain();
	}

	private var tr:TestRunner;
	public function new() 
	{
		tr = new TestRunner();
		tr.add(new BoundingCollisionTest());
		tr.add(new LightSortTest());
		tr.add(new LightFilterTest());
		
		tr.run();
	}
	
}