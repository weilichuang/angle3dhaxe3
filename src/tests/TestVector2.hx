package tests;

import haxe.unit.TestCase;
import org.angle3d.math.Vector2f;

/**
 * andy
 * @author 
 */
class TestVector2 extends TestCase
{

	public function new() 
	{
		super();
	}
	
	public function testClone():Void
	{
		var a:Vector2f = new Vector2f();
		var b:Vector2f = a.clone();
		assertFalse(a == b);
	}
	
}