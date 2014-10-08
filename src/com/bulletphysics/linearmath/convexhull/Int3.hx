package com.bulletphysics.linearmath.convexhull;

/**
 * ...
 * @author weilichuang
 */
class Int3
{
	public var x:Int;
	public var y:Int;
	public var z:Int;

	public function new(x:Int = 0, y:Int = 0, z:Int = 0) 
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	public function setTo(x:Int, y:Int, z:Int):Void
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	public function fromInt3(int3:Int3):Void
	{
		this.x = int3.x;
		this.y = int3.y;
		this.z = int3.z;
	}
	
	public function getCoord(coord:Int):Int
	{
        switch (coord) 
		{
            case 0:
                return x;
            case 1:
                return y;
            default:
                return z;
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
        }
    }

    public function equals(i:Int3):Bool
	{
        return (x == i.x && y == i.y && z == i.z);
    }
	
	public function getRef(coord:Int):IntRef
	{
		return new Int3IntRef(this, coord);
    }
}

class Int3IntRef extends IntRef
{
	private var int3:Int3;
	private var coord:Int;
	public function new(int3:Int3,coord:Int) 
	{
		super();
		this.int3 = int3;
		this.coord = coord;
	}
	
	override public function get():Int
	{
		return int3.getCoord(coord);
	}
	
	override public function set(value:Int):Void
	{
		int3.setCoord(coord, value);
	}
}