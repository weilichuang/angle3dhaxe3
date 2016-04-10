package org.angle3d.math;

/**
 * 非均匀有理B类样条曲线
 
 */
@:enum abstract SplineType(Int)  
{
	var Linear = 0;
	var CatmullRom = 1;
	var Bezier = 2;
	var Nurb = 3;
}


