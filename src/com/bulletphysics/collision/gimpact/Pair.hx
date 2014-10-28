package com.bulletphysics.collision.gimpact ;

/**
 * Overlapping pair.
 *
 * @author weilichuang
 */
class Pair 
{

    public var index1:Int;
    public var index2:Int;

    public function new()
	{
        
    }
	
	public function init(index1:Int, index2:Int):Void
	{
		this.index1 = index1;
        this.index2 = index2;
	}

    public function copyFrom(p:Pair):Void
	{
        index1 = p.index1;
        index2 = p.index2;
    }

}
