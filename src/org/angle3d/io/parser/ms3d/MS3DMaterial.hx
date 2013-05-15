package org.angle3d.io.parser.ms3d;

import org.angle3d.math.Color;

class MS3DMaterial
{
	public var name:String;
	public var ambient:Color;
	public var diffuse:Color;
	public var specular:Color;
	public var emissive:Color;
	public var shininess:Float; //0.0-128
	public var transparency:Float; //0.0-1.0
	public var texture:String;
	public var alphaMap:String;

	public function new()
	{
		ambient = new Color();
		diffuse = new Color();
		specular = new Color();
		emissive = new Color();
	}
}
