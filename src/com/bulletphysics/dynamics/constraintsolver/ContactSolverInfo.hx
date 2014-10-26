package com.bulletphysics.dynamics.constraintsolver;

/**
 * Current state of contact solver.
 * @author weilichuang
 */
class ContactSolverInfo
{

	public var tau:Float = 0.6;
    public var damping:Float = 1;
    public var friction:Float = 0.3;
    public var timeStep:Float;
    public var restitution:Float = 0;
    public var numIterations:Int = 10;
    public var maxErrorReduction:Float = 20;
    public var sor:Float = 1.3;
    public var erp:Float = 0.2; // used as Baumgarte factor
    public var erp2:Float = 0.1; // used in Split Impulse
    public var splitImpulse:Bool = false;
    public var splitImpulsePenetrationThreshold:Float = -0.02;
    public var linearSlop:Float = 0;
    public var warmstartingFactor:Float = 0.85;

    public var solverMode:Int = SolverMode.SOLVER_RANDMIZE_ORDER | SolverMode.SOLVER_CACHE_FRIENDLY | SolverMode.SOLVER_USE_WARMSTARTING;

    public function new()
	{
	}
	
	public inline function copyFrom(g:ContactSolverInfo)
	{
		tau = g.tau;
		damping = g.damping;
		friction = g.friction;
		timeStep = g.timeStep;
		restitution = g.restitution;
		numIterations = g.numIterations;
		maxErrorReduction = g.maxErrorReduction;
		sor = g.sor;
		erp = g.erp;
	}
}