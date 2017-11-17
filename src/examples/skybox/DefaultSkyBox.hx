package examples.skybox;

import org.angle3d.Angle3D;
import org.angle3d.material.Material;
import org.angle3d.shader.VarType;
import org.angle3d.math.Vector3f;

import org.angle3d.scene.SkyBox;
import org.angle3d.texture.CubeTextureMap;

class DefaultSkyBox extends SkyBox
{
	private var _cubeMap : CubeTextureMap;

	public function new(size : Float)
	{
		super(size);
		
		//var px : BitmapData = new Left(0,0);
		//var nx : BitmapData = new Right(0,0);
		//var py : BitmapData = new Top(0,0);
		//var ny : BitmapData = new Bottom(0,0);
		//var pz : BitmapData = new Front(0,0);
		//var nz : BitmapData = new Back(0,0);
//
		//_cubeMap = new CubeTextureMap(px, nx, py, ny, pz, nz);
		//
		//var material:Material = new Material();
		//material.load(Angle3D.materialFolder + "material/skybox.mat");
		//material.setTexture("u_cubeTexture", _cubeMap);
		//material.setParam("u_NormalScale", VarType.VECTOR3, new Vector3f(1, 1, 1));
		//this.setMaterial(material);
	}

	public var cubeMap(get, null):CubeTextureMap;
	private function get_cubeMap() : CubeTextureMap
	{
		return _cubeMap;
	}
}

//@:bitmap("../assets/sky/right.jpg") class Right extends flash.display.BitmapData { }
//@:bitmap("../assets/sky/left.jpg") class Left extends flash.display.BitmapData { }
//@:bitmap("../assets/sky/top.jpg") class Top extends flash.display.BitmapData { }
//@:bitmap("../assets/sky/bottom.jpg") class Bottom extends flash.display.BitmapData { }
//@:bitmap("../assets/sky/front.jpg") class Front extends flash.display.BitmapData { }
//@:bitmap("../assets/sky/back.jpg") class Back extends flash.display.BitmapData { }
