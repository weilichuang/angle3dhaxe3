package com.bulletphysics.dynamics.constraintsolver;

/**
 * Solver flags.
 */
@:enum abstract SolverMode(Int)   
{
	var SOLVER_RANDMIZE_ORDER = 1;
    var SOLVER_FRICTION_SEPARATE = 2;
    var SOLVER_USE_WARMSTARTING = 4;
    var SOLVER_CACHE_FRIENDLY = 8;
	
	public inline function new(v:Int)
        this = v;

    public inline function toInt():Int
    	return this;
	
	inline public function remove(mask:SolverMode):SolverMode
	{
		return new SolverMode(this & ~mask.toInt());
	}
    
	inline public function add(mask:SolverMode):SolverMode
	{
		return new SolverMode(this | mask.toInt());
	}
    
	inline public function contains(mask:SolverMode):Bool
	{
		return this & mask.toInt() != 0;
	}
}