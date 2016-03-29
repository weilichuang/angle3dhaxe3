package com.bulletphysics.dynamics;

/**
 * Dynamics world type.
 * @author weilichuang
 */
@:enum abstract DynamicsWorldType(Int) 
{
	var NONE = -1;
    var SIMPLE_DYNAMICS_WORLD = 0;
    var DISCRETE_DYNAMICS_WORLD = 1;
    var CONTINUOUS_DYNAMICS_WORLD = 2;
}
