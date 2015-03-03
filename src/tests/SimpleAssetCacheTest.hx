package tests;
import flash.Lib;
import haxe.unit.TestCase;
import org.angle3d.asset.cache.SimpleAssetCache;
import org.angle3d.material.shader.DefineList;
import org.angle3d.material.shader.ShaderKey;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;

/**
 * ...
 * @author weilichuang
 */
class SimpleAssetCacheTest extends TestCase
{

	public function new() 
	{
		super();
	}
	
	public function testGetFromCache():Void
	{
		var cache:SimpleAssetCache<Int> = new SimpleAssetCache<Int>();
		
		var defineList:DefineList = new DefineList();
		defineList.set("color", VarType.COLOR, new Color(1, 1, 1, 1));
		var shaderKey:ShaderKey = new ShaderKey(defineList, "vertTest", "fragTest");
		
		cache.addToCache(shaderKey, 1);
		
		assertEquals(1, cache.getFromCache(shaderKey));
		
		var defineList1:DefineList = new DefineList();
		defineList1.set("color", VarType.COLOR, new Color(1, 0.2, 0.3, 1));
		var newShaderKey:ShaderKey = new ShaderKey(defineList1, "vertTest", "fragTest");
		
		assertEquals(1, cache.getFromCache(newShaderKey));
		
		cache.addToCache(newShaderKey, 2);
		
		assertEquals(2, cache.getFromCache(shaderKey));
		assertEquals(2, cache.getFromCache(newShaderKey));
		
		defineList1.set("color1", VarType.COLOR, new Color());

		Lib.trace(cache.getFromCache(shaderKey));
		Lib.trace(cache.getFromCache(newShaderKey));
		assertTrue(cache.getFromCache(shaderKey) == 2);
		assertEquals(0, cache.getFromCache(newShaderKey));
		
		cache.addToCache(newShaderKey, 3);
		
		assertEquals(2, cache.getFromCache(shaderKey));
		assertEquals(3, cache.getFromCache(newShaderKey));
	}
	
}