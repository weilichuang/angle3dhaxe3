package org.angle3d.terrain.noise ;


interface Filter 
{
	function addPreFilter(filter:Filter):Filter;

	function addPostFilter(filter:Filter):Filter;

	function doFilter(sx:Float, sy:Float, base:Float, data:Array<Float>, size:Int):Array<Float>;

	function getMargin(size:Int, margin:Int):Int;

	function isEnabled():Bool;
}
