package org.angle3d.material;


import flash.display3D.Context3DTriangleFace;
import flash.Vector;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.Light;
import org.angle3d.light.LightList;
import org.angle3d.light.LightType;
import org.angle3d.light.PointLight;
import org.angle3d.light.SpotLight;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.Uniform;
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
import de.polygonal.ds.error.Assert;


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
	private static var nullDirLight:Vector<Float>;
	
	private static var additiveLight:RenderState;
	
	private static var depthOnly:RenderState;
	
	/**
	 * 特殊函数，用于执行一些static变量的定义等(有这个函数时，static变量预先赋值必须也放到这里面)
	 */
	static function __init__():Void
	{
		nullDirLight = Vector.ofArray([0.0, -1.0, 0.0, -1.0]);
		
		depthOnly = new RenderState();
		depthOnly.setDepthTest(true);
		depthOnly.setDepthWrite(true);
		depthOnly.setCullMode(CullMode.BACK);
		depthOnly.setColorWrite(false);
		
		additiveLight = new RenderState();
		additiveLight.setBlendMode(BlendMode.AlphaAdditive);
		additiveLight.setDepthWrite(false);
	}
	
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
	
	private var additionalState:RenderState;
    private var mergedRenderState:RenderState;

	public function new()
	{
		mTechniques = new Array<Technique>();

		mEmissiveColor = new Color(0, 0, 0, 1);
		mAmbientColor = new Color(1, 1, 1, 0);
		mDiffuseColor = new Color(1, 1, 1, 1);
		mSpecularColor = new Color(1, 1, 1, 1);

		mCullMode = CullMode.BACK;
		
		additionalState = null;
		mergedRenderState = new RenderState();

		mAlpha = 1.0;
	}
	
	 /**
     * Acquire the additional {@link RenderState render state} to apply
     * for this material.
     *
     * <p>The first call to this method will create an additional render
     * state which can be modified by the user to apply any render
     * states in addition to the ones used by the renderer. Only render
     * states which are modified in the additional render state will be applied.
     *
     * @return The additional render state.
     */
    public function getAdditionalRenderState():RenderState
	{
        if (additionalState == null) 
		{
            additionalState = RenderState.ADDITIONAL.clone();
        }
        return additionalState;
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
	
	//TODO 待实现
	public function contentEquals(mat:Material):Bool
	{
		return mat == this;
	}
	
	public function render(g:Geometry, lights:LightList, rm:RenderManager):Void
	{
		var mesh:Mesh = g.getMesh();
		
		var render:IRenderer = rm.getRenderer();
		
		var numLight:Int = lights.getSize();

		// for each technique in material
		var techniques:Array<Technique> = getTechniques();
		var shader:Shader;
		var technique:Technique;
		var light:Light;
		var size:Int = techniques.length;
		for (i in 0...size)
		{
			technique = techniques[i];
			
			if (technique.requiresLight && numLight == 0)
				continue;
			
			if (rm.forcedRenderState != null)
			{
				render.applyRenderState(rm.forcedRenderState);
			} 
			else
			{
				if (technique.renderState != null) 
				{
					render.applyRenderState(technique.renderState.copyMergedTo(additionalState, mergedRenderState));
				} 
				else 
				{
					render.applyRenderState(RenderState.DEFAULT.copyMergedTo(additionalState, mergedRenderState));
				}
			}
			
			shader = technique.getShader(LightType.None, mesh.type);
			
			if (technique.requiresLight)
			{
				renderMultipassLighting(technique, shader, g, lights, rm);
			}
			else
			{
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
	
	/**
	 * 多重灯光渲染
	 * @param	shader
	 * @param	g
	 * @param	rm
	 */
	private var tmpLightDirection:Vector<Float>;
	private var tmpLightPosition:Vector<Float>;
	private var tmpColors:Vector<Float>;
	private function renderMultipassLighting(technique:Technique, shader:Shader, g:Geometry, lightList:LightList, rm:RenderManager):Void
	{
		var r:IRenderer = rm.getRenderer();

		var numLight:Int = lightList.getSize();
		
		var lightDir:Uniform = shader.getUniform(ShaderType.VERTEX, "u_LightDirection");
		var lightColor:Uniform = shader.getUniform(ShaderType.VERTEX, "u_LightColor");
		var lightPos:Uniform = shader.getUniform(ShaderType.VERTEX, "u_LightPosition");
		var ambientColor:Uniform = shader.getUniform(ShaderType.VERTEX, "u_Ambient");
		
		
		var isFirstLight:Bool = true;
		var isSecondLight:Bool = false;
		
		for (i in 0...numLight)
		{
			var l:Light = lightList.getLightAt(i);
			if (l.type == LightType.Ambient)
			{
				continue;
			}
			
			if (isFirstLight)
			{
				// set ambient color for first light only
				ambientColor.setColor(lightList.getAmbientColor());
				isFirstLight = false;
				isSecondLight = true;
			}
			else if (isSecondLight)
			{
				ambientColor.setColor(Color.Black());
				// apply additive blending for 2nd and future lights
				r.applyRenderState(additiveLight);
				isSecondLight = false;
			}
			
			if(tmpLightDirection == null)
				tmpLightDirection = new Vector<Float>(4, true);
			if(tmpLightPosition == null)
			    tmpLightPosition = new Vector<Float>(4, true);
			if (tmpColors == null)
				tmpColors = new Vector<Float>(4, true);

			l.color.toUniform(tmpColors);
			tmpColors[3] = Type.enumIndex(l.type) - 1;
			lightColor.setVector(tmpColors);
			
			switch(l.type)
			{
				case LightType.Directional:
					
					var dl:DirectionalLight = Std.instance(l, DirectionalLight);
					var dir:Vector3f = dl.direction;
					
					tmpLightPosition[0] = dir.x;
					tmpLightPosition[1] = dir.y;
					tmpLightPosition[2] = dir.z;
					tmpLightPosition[3] = -1;
					lightPos.setVector(tmpLightPosition);
					
					tmpLightDirection[0] = 0;
					tmpLightDirection[1] = 0;
					tmpLightDirection[2] = 0;
					tmpLightDirection[3] = 0;
					lightDir.setVector(tmpLightDirection);
					
				case LightType.Point:
					
					var pl:PointLight = Std.instance(l, PointLight);
					var pos:Vector3f = pl.position;
					tmpLightPosition[0] = pos.x;
					tmpLightPosition[1] = pos.y;
					tmpLightPosition[2] = pos.z;
					tmpLightPosition[3] = pl.invRadius;
					lightPos.setVector(tmpLightPosition);
					
					tmpLightDirection[0] = 0;
					tmpLightDirection[1] = 0;
					tmpLightDirection[2] = 0;
					tmpLightDirection[3] = 0;
					lightDir.setVector(tmpLightDirection);
					
				case LightType.Spot:
					
					var sl:SpotLight = Std.instance(l, SpotLight);
					var pos:Vector3f = sl.position;
					var dir:Vector3f = sl.direction;
					
					tmpLightPosition[0] = pos.x;
					tmpLightPosition[1] = pos.y;
					tmpLightPosition[2] = pos.z;
					tmpLightPosition[3] = sl.invSpotRange;
					lightPos.setVector(tmpLightPosition);
					
					var tmpVec:Vector4f = new Vector4f();
					tmpVec.setTo(dir.x, dir.y, dir.z, 0);
					
					rm.getCamera().getViewMatrix().multVec4(tmpVec, tmpVec);
					
					//We transform the spot directoin in view space here to save 5 varying later in the lighting shader
                    //one vec4 less and a vec4 that becomes a vec3
                    //the downside is that spotAngleCos decoding happen now in the frag shader.
					tmpLightDirection[0] = tmpVec.x;
					tmpLightDirection[1] = tmpVec.y;
					tmpLightDirection[2] = tmpVec.z;
					tmpLightDirection[3] = sl.packedAngleCos;
					
					lightDir.setVector(tmpLightDirection);
					
				default:
					Assert.assert(false, "Unknown type of light: " + l.type);
			}
			
			//需要更新绑定和用户自定义的Uniform，然后上传到GPU
			rm.updateShaderBinding(shader);
			technique.updateShader(shader);

			r.setShader(shader);
			r.renderMesh(g.getMesh());
		}
		
		//只有环境光时会出错，需要修改
		if (isFirstLight && numLight > 0)
		{
			// There are only ambient lights in the scene. Render
            // a dummy "normal light" so we can see the ambient
			ambientColor.setVector(lightList.getAmbientColor().toUniform());
			lightColor.setVector(Color.BlackNoAlpha().toUniform());
			lightPos.setVector(nullDirLight);
			
			r.setShader(shader);
			r.renderMesh(g.getMesh());
		}
	}
	
	public function setBoolean(key:String, value:Bool):Void
	{
		
	}

	public function setInt(key:String, value:Int):Void
	{
	}

	public function setFloat(key:String, value:Float):Void
	{
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

