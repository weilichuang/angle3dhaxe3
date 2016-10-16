package org.angle3d.bullet.collision.shapes;
import flash.Vector;
import org.angle3d.math.Vector3f;

/**
 * ...
 
 */
class HeightfieldCollisionShape extends CollisionShape
{
	private var heightStickWidth:Int;
	private var heightStickLength:Int;
	private var heightfieldData:Vector<Float>;
	private var heightScale:Float;
	private var minHeight:Float;
	private var maxHeight:Float;
	private var upAxis:Int;
	private var flipQuadEdges:Bool;

	public function new(heightmap:Vector<Float>, scale:Vector3f = null) 
	{
		super();
		createCollisionHeightfield(heightmap, scale);
	}
	
	public function createCollisionHeightfield(heightmap:Vector<Float>, scale:Vector3f = null):Void
	{
		if (scale != null)
			this.scale = scale;
			
		this.heightScale = 1;//don't change away from 1, we use worldScale instead to scale
		this.heightfieldData = heightmap;
		
		var min:Float = heightfieldData[0];
		var max:Float = heightfieldData[0];
		
		// calculate min and max height
		for (i in 0...heightfieldData.length) 
		{
			if (heightfieldData[i] < min)
				min = heightfieldData[i];
			if (heightfieldData[i] > max)
				max = heightfieldData[i];
		}
		// we need to center the terrain collision box at 0,0,0 for BulletPhysics. And to do that we need to set the
		// min and max height to be equal on either side of the y axis, otherwise it gets shifted and collision is incorrect.
		if (max < 0)
			max = -min;
		else 
		{
			if (Math.abs(max) > Math.abs(min))
				min = -max;
			else
				max = -min;
		}
		this.minHeight = min;
		this.maxHeight = max;

		this.upAxis = 1;// HeightfieldTerrainShape.YAXIS;
		this.flipQuadEdges = false;

		heightStickWidth = Std.int(Math.sqrt(heightfieldData.length));
		heightStickLength = heightStickWidth;


		createShape();
	}
	
	private function createShape():Void
	{
		//var shape:HeightfieldTerrainShape = new HeightfieldTerrainShape(heightStickWidth, heightStickLength, heightfieldData, heightScale, minHeight, maxHeight, upAxis, flipQuadEdges);
		//shape.setLocalScaling(new vecmath.Vector3f(scale.x, scale.y, scale.z));
		//cShape = shape;
		//cShape.setLocalScaling(Converter.a2vVector3f(getScale()));
		//cShape.setMargin(margin);
	}
}