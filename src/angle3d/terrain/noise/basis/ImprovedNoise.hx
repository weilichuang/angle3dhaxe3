package angle3d.terrain.noise.basis ;


import angle3d.terrain.noise.ShaderUtils;

// JAVA REFERENCE IMPLEMENTATION OF IMPROVED NOISE - COPYRIGHT 2002 KEN PERLIN.
/**
 * Perlin's default implementation of Improved Perlin Noise
 * designed to work with Noise base
 */
class ImprovedNoise extends Noise 
{
	public static var p:Array<Int>;// new int[512], 
	public static var permutation:Array<Int>;
	
	private static var GRAD3:Array<Array<Int>>;
	
	static function __init__():Void
	{
		permutation = [ 151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36,
			103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11,
			32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158,
			231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80,
			73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217,
			226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183,
			170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113,
			224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235,
			249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205,
			93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180 ];
		permutation.fixed = true;
		
		for (i in 0...256)
		{
			p[256 + i] = p[i] = permutation[i];
		}
		
		GRAD3 = [[ 1, 1, 0 ], [ -1, 1, 0 ], [ 1, -1, 0 ], [ -1, -1, 0 ], [ 1, 0, 1 ], [ -1, 0, 1 ],
				 [ 1, 0, -1 ], [ -1, 0, -1 ], [ 0, 1, 1 ], [ 0, -1, 1 ], [ 0, 1, -1 ], [ 0, -1, -1 ], [ 1, 0, -1 ], [ -1, 0, -1 ], [ 0, -1, 1 ],
				[ 0, 1, 1 ] ];
	}
	
	static public function noise(x:Float, y:Float, z:Float):Float 
	{
		var X:Int = ShaderUtils.floor(x); // FIND UNIT CUBE THAT
		var Y:Int = ShaderUtils.floor(y); // CONTAINS POINT.
		var Z:Int = ShaderUtils.floor(z);
		x -= X; // FIND RELATIVE X,Y,Z
		y -= Y; // OF POINT IN CUBE.
		z -= Z;
		X = X & 255;
		Y = Y & 255;
		Z = Z & 255;
		var u:Float = fade(x), // COMPUTE FADE CURVES
		v = fade(y), // FOR EACH OF X,Y,Z.
		w = fade(z);
		var A:Int = p[X] + Y;
		var AA:Int = p[A] + Z;
		var AB:Int = p[A + 1] + Z;
		var B:Int = p[X + 1] + Y;
		var BA:Int = p[B] + Z;
		var BB:Int = p[B + 1] + Z;

		return lerp(w,
				lerp(v,
					lerp(u, grad3(p[AA], x, y, z),
							grad3(p[BA], x - 1, y, z)), // BLENDED
					lerp(u, grad3(p[AB], x, y - 1, z), // RESULTS
								grad3(p[BB], x - 1, y - 1, z))),// FROM
				lerp(v,
					lerp(u, grad3(p[AA + 1], x, y, z - 1), // CORNERS
							grad3(p[BA + 1], x - 1, y, z - 1)), // OF
					lerp(u, grad3(p[AB + 1], x, y - 1, z - 1),
							grad3(p[BB + 1], x - 1, y - 1, z - 1))));
	}

	static function fade(t:Float):Float
	{
		return t * t * t * (t * (t * 6 - 15) + 10);
	}

	static function lerp(t:Float, a:Float, b:Float):Float
	{
		return a + t * (b - a);
	}

	static function grad(hash:Int, x:Float, y:Float, z:Float):Float 
	{
		var h:Int = hash & 15; // CONVERT LO 4 BITS OF HASH CODE
		var u:Float = h < 8 ? x : y, // INTO 12 GRADIENT DIRECTIONS.
		v = h < 4 ? y : h == 12 || h == 14 ? x : z;
		return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
	}

	static function grad3(hash:Int, x:Float, y:Float, z:Float):Float 
	{
		var h:Int = hash & 15; // CONVERT LO 4 BITS OF HASH CODE
		return x * GRAD3[h][0] + y * GRAD3[h][1] + z * GRAD3[h][2];
	}
	
	public function new()
	{
		
	}

	override public function value(x:Float, y:Float, z:Float):Float
	{
		return noise(this.scale * x, this.scale * y, this.scale * z);
	}

}
