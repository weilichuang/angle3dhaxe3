package org.angle3d.material;


import flash.display3D.Context3DTriangleFace;
import flash.Vector;
import org.angle3d.light.Light;
import org.angle3d.light.LightList;
import org.angle3d.light.LightType;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.technique.Technique;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;
import org.angle3d.renderer.IRenderer;
import org.angle3d.renderer.RenderManager;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.texture.TextureMapBase;


/**
 * <code>Material</code> describes the rendering style for a given <code>Geometry</code>.
 * <p>A material is essentially a list of {@link MatParam parameters},
 * those parameters map to uniforms which are defined in a shader.
 * Setting the parameters can modify the behavior of a
 * shader.
 * <p/>
 * 
 */
class Material
{
	public var skinningMatrices(null, set):Vector<Float>;
	public var influence(null, set):Float;
	public var cullMode(get, set):CullMode;
	public var doubleSide(get, set):Bool;
	public var alpha(get, set):Float;
	
	private var mCullMode:CullMode;

	private var mEmissiveColor:Color;
	private var mAmbientColor:Color;
	private var mDiffuseColor:Color;
	private var mSpecularColor:Color;

	private var mAlpha:Float;

	private var sortingId:Int = -1;

	private var mTechniques:Array<Technique>;

	public function new()
	{
		mTechniques = new Array<Technique>();

		mEmissiveColor = new Color(0, 0, 0, 1);
		mAmbientColor = new Color(1, 1, 1, 0);
		mDiffuseColor = new Color(1, 1, 1, 1);
		mSpecularColor = new Color(1, 1, 1, 1);

		mCullMode = CullMode.FRONT;

		mAlpha = 1.0;
	}

	
	private function set_skinningMatrices(data:Vector<Float>):Vector<Float>
	{
		return data;
	}

	
	private function set_influence(value:Float):Float
	{
		return value;
	}
	
	private function get_cullMode():CullMode
	{
		return mCullMode;
	}
	
	private function set_cullMode(mode:CullMode):CullMode
	{
		if (mCullMode == mode)
			return mCullMode;

		mCullMode = mode;

		var size:Int = mTechniques.length;
		for (i in 0...size)
		{
			mTechniques[i].renderState.cullMode = mode;
		}
		
		return mCullMode;
	}

	private function get_doubleSide():Bool
	{
		return mCullMode == CullMode.NONE;
	}
	
	private function set_doubleSide(value:Bool):Bool
	{
		if (value)
		{
			mCullMode = CullMode.NONE;
		}

		var size:Int = mTechniques.length;
		for (i in 0...size)
		{
			mTechniques[i].renderState.cullMode = mCullMode;
		}
		
		return value;
	}

	public function getTechniques():Array<Technique>
	{
		return mTechniques;
	}

	public function getTechniqueAt(i:Int):Technique
	{
		return mTechniques[i];
	}

	public function addTechnique(t:Technique):Void
	{
		mTechniques.push(t);
	}

	private function set_alpha(alpha:Float):Float
	{
		return mAlpha = FastMath.clamp(alpha, 0.0, 1.0);
	}
	private function get_alpha():Float
	{
		return mAlpha;
	}

	public function getSortId():Int
	{
		return sortingId;
	}

	public function clone():Material
	{
		var mat:Material = new Material();
		return mat;
	}
	
	public function render(g:Geometry, rm:RenderManager):Void
	{
		var mesh:Mesh = g.getMesh();
		
		var render:IRenderer = rm.getRenderer();
		
		var lightList:LightList = g.getWorldLightList();
		var lightSize:Int = lightList.getSize();

		// for each technique in material
		var techniques:Array<Technique> = getTechniques();
		var shader:Shader;
		var technique:Technique;
		var light:Light;
		var size:Int = techniques.length;
		for (i in 0...size)
		{
			technique = techniques[i];

			render.applyRenderState(technique.renderState);

			//如何使用灯光的话
			if (technique.requiresLight && lightSize > 0)
			{
				for (j in 0...lightSize)
				{
					light = lightList.getLightAt(j);

					shader = technique.getShader(light.type, mesh.type);

					//需要更新绑定和用户自定义的Uniform，然后上传到GPU
					rm.updateShaderBinding(shader);
					technique.updateShader(shader);

					render.setShader(shader);
					render.renderMesh(mesh);
				}
			}
			else
			{
				shader = technique.getShader(LightType.None, mesh.type);

				//需要更新绑定和用户自定义的Uniform，然后上传到GPU
				rm.updateShaderBinding(shader);
				technique.updateShader(shader);

				//设置Shader
				render.setShader(shader);

				//渲染模型
				render.renderMesh(mesh);
			}
		}
	}
	
	public function setBoolean(key:String, value:Bool):Void
	{
		
	}

	public function setInt(key:String, value:Int):Void
	{
		// TODO Auto Generated method stub

	}

	public function setFloat(key:String, value:Float):Void
	{
		// TODO Auto Generated method stub

	}

	public function setColor(key:String, color:Color):Void
	{

	}

	public function setTexture(key:String, texture:TextureMapBase):Void
	{

	}
	
	public function setMatrix4(key:String, matrix4:Matrix4f):Void
	{
		
	}
	
	public function setVector4(key:String, vec:Vector4f):Void
	{
		
	}
	
	public function setVector3(key:String, vec:Vector3f):Void
	{
		
	}
}

