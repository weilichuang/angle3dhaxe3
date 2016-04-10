package com.bulletphysics.dynamics.constraintsolver;

/**
 * Typed constraint type.
 
 */
@:enum abstract TypedConstraintType(Int)   
{
	var POINT2POINT_CONSTRAINT_TYPE = 0;
    var HINGE_CONSTRAINT_TYPE = 1;
    var CONETWIST_CONSTRAINT_TYPE = 2;
    var D6_CONSTRAINT_TYPE = 3;
    var VEHICLE_CONSTRAINT_TYPE = 4;
    var SLIDER_CONSTRAINT_TYPE = 5;
	var D6_SPRING_CONSTRAINT_TYPE = 6;
}