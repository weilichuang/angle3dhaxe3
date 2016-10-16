package com.bulletphysics.linearmath.convexhull;
import org.angle3d.error.Assert;

/**
 * ...
 
 */
class Tri extends Int3
{
	private static var erRef:TriIntRef = new TriIntRef();
	
	public var n:Int3 = new Int3();
	public var id:Int;
	public var vmax:Int;
	public var rise:Float;

	public function new(x:Int, y:Int, z:Int) 
	{
		super(x, y, z);
		n.setTo( -1, -1, -1);
		vmax = -1;
		rise = 0;
	}
	
	
	public function neib(a:Int, b:Int):IntRef 
	{
        for (i in 0...3) 
		{
            var i1:Int = (i + 1) % 3;
            var i2:Int = (i + 2) % 3;

            if (getCoord(i) == a && getCoord(i1) == b)
			{
                return n.getRef(i2);
            }
            if (getCoord(i) == b && getCoord(i1) == a)
			{
                return n.getRef(i2);
            }
        }
        //Assert.assert (false);
        return erRef;
    }
}

class TriIntRef extends IntRef
{
	private static var er:Int = -1;
	public function new() 
	{
		super();
	}
	
	override public function get():Int
	{
		return er;
	}
	
	override public function set(value:Int):Void
	{
		er = value;
	}
}