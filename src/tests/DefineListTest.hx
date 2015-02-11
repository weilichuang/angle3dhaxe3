package tests;

import haxe.unit.TestCase;
import org.angle3d.material.shader.DefineList;
import org.angle3d.material.VarType;
using org.angle3d.utils.ArrayUtil;
/**
 * andy
 * @author 
 */
class DefineListTest extends TestCase
{

	public function new() 
	{
		super();
	}
	
	public function testDefineSet():Void
	{
		var defineList:DefineList = new DefineList();
		defineList.set("USE_TEXCOORD_1", VarType.BOOL, true);
		defineList.set("USE_TEXCOORD_2", VarType.BOOL, false);
		
		defineList.set("NUM_BONES", VarType.FLOAT, 3);
		
		assertEquals(2, defineList.getDefines().length);
	}
	
	public function testDefineAddFrom():Void
	{
		var defineList:DefineList = new DefineList();
		defineList.set("USE_TEXCOORD_1", VarType.BOOL, true);
		defineList.set("USE_TEXCOORD_2", VarType.BOOL, false);
		
		defineList.set("NUM_BONES", VarType.FLOAT, 3);
		
		var defineList2:DefineList = new DefineList();
		defineList2.set("USE_DIFFUSE_MAP", VarType.BOOL, true);
		defineList2.set("USE_LIGHTING", VarType.BOOL, true);
		
		defineList2.addFrom(defineList);

		assertEquals(4, defineList2.getDefines().length);
	}
	
}