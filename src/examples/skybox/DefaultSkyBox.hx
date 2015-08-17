package examples.skybox;

import flash.display.Bitmap;
import flash.display.BitmapData;
import org.angle3d.Angle3D;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Vector3f;

import org.angle3d.scene.SkyBox;
import org.angle3d.texture.CubeTextureMap;

class DefaultSkyBox extends SkyBox
{
	private var _cubeMap : CubeTextureMap;

	public function new(size : Float)
	{
		super(size);
		
		var px : BitmapData = new EmbedPositiveX(0,0);
		var nx : BitmapData = new EmbedNegativeX(0,0);
		var py : BitmapData = new EmbedPositiveY(0,0);
		var ny : BitmapData = new EmbedNegativeY(0,0);
		var pz : BitmapData = new EmbedPositiveZ(0,0);
		var nz : BitmapData = new EmbedNegativeZ(0,0);

		_cubeMap = new CubeTextureMap(px, nx, py, ny, pz, nz);
		
		var material:Material = new Material();
		material.load(Angle3D.materialFolder + "material/skybox.mat");
		material.setTexture("t_cubeTexture", _cubeMap);
		material.setParam("u_NormalScale", VarType.VECTOR3, new Vector3f(1, 1, 1));
		this.setMaterial(material);
	}

	public var cubeMap(get, null):CubeTextureMap;
	private function get_cubeMap() : CubeTextureMap
	{
		return _cubeMap;
	}
}

@:bitmap("../assets/embed/sky/negativeX.png") class EmbedNegativeX extends flash.display.BitmapData { }
@:bitmap("../assets/embed/sky/negativeY.png") class EmbedNegativeY extends flash.display.BitmapData { }
@:bitmap("../assets/embed/sky/negativeZ.png") class EmbedNegativeZ extends flash.display.BitmapData { }
@:bitmap("../assets/embed/sky/positiveX.png") class EmbedPositiveX extends flash.display.BitmapData { }
@:bitmap("../assets/embed/sky/positiveY.png") class EmbedPositiveY extends flash.display.BitmapData { }
@:bitmap("../assets/embed/sky/positiveZ.png") class EmbedPositiveZ extends flash.display.BitmapData { }
