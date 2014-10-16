package tests;
import haxe.unit.TestRunner;
import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;
import tests.util.ObjectArrayListTestCase;
import tests.util.ObjectPoolTestCase;

/**
 * ...
 * @author weilichuang
 */
class BulletTestMain extends Sprite
{
	private var testRunner:TestRunner;

	public function new() 
	{
		super();
		addEventListener(Event.ADDED_TO_STAGE, added);
	}
	
	function added(e) 
	{
		removeEventListener(Event.ADDED_TO_STAGE, added);
		
		testRunner = new TestRunner();
		testRunner.add(new ObjectArrayListTestCase());
		testRunner.add(new ObjectPoolTestCase());
		
		testRunner.run();
	}
	
	public static function main() 
	{
		Lib.current.addChild(new BulletTestMain());
	}
	
}