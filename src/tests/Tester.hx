package tests;
import haxe.unit.TestRunner;
class Tester
{
	static function main()
	{
        var runner:TestRunner = new TestRunner();
		
		runner.add(new TestVector2());
		runner.add(new ArrayUtilTest());
		runner.add(new DefineListTest());
		runner.add(new SimpleAssetCacheTest());
		
        runner.run();
    }
}