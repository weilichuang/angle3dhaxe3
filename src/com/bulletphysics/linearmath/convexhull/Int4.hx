package com.bulletphysics.linearmath.convexhull;

/**
 * ...
 * @author weilichuang
 */
class Int4
{
	public var x:Int;
	public var y:Int;
	public var z:Int;
	public var w:Int;

	public function new(x:Int = 0, y:Int = 0, z:Int = 0, w:Int = 0) 
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
	
	public function setTo(x:Int, y:Int, z:Int, w:Int):Void
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}
	
	public function fromInt4(int4:Int4):Void
	{
		this.x = int4.x;
		this.y = int4.y;
		this.z = int4.z;
		this.w = int4.w;
	}
	
	public function getCoord(coord:Int):Int
	{
        switch (coord) 
		{
            case 0:
                return x;
            case 1:
                return y;
			case 2:
                return z;
            default:
                return w;
        }
    }

    public function setCoord(coord:Int, value:Int):Void
	{
        switch (coord)
		{
            case 0:
                x = value;
            case 1:
                y = value;
            case 2:
                z = value;
			case 3:
				w = value;
        }
    }

    public function equals(i:Int4):Bool
	{
        return (x == i.x && y == i.y && z == i.z && w == i.w);
    }
	
}