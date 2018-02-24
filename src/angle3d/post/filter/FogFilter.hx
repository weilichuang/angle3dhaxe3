package angle3d.post.filter;

import angle3d.material.Material;
import angle3d.math.Color;
import angle3d.math.Vector4f;
import angle3d.post.Filter;
import angle3d.renderer.RenderManager;
import angle3d.renderer.ViewPort;

/*
 A filter to render a fog effect
 We implement here a GL_EXP2 type fog. Let's explain quickly the code. The used equation is:
	fogFactor = exp(-(density * z)2)
The exponential function can be written by a power of 2 :
	exp(x) = 2(x/log(2))
	1/log(2) = 1.442695
	exp(x) = 2(1.442695 * x)
At GLSL level, there exists a function which permits to raise 2 to any x power: exp2. So our equation becomes :
	exp(x) = exp2(1.442695 * x)
	avec x = -(density * z)2
The final equation is:
	fogFactor = exp2(density2 * z2 * 1.442695)
 */
class FogFilter extends Filter {
	private var fogColor:Color;
	private var fogInfo:Vector4f;
	private var near:Float;

	private static inline var LOG2:Float = 1.442695;

	public function new(fogColor:Color, fogDensity:Float = 0.7, fogDistance:Float = 1000, near:Float = 1.0) {
		super("FogFilter");
		this.fogColor = fogColor;
		this.fogInfo = new Vector4f();
		this.fogInfo.x = -fogDensity * fogDensity * LOG2;
		this.fogInfo.y = fogDistance + near;
		this.fogInfo.z = fogDistance - near;
		this.fogInfo.w = 2 * near;
		this.near = near;
	}

	override public function isRequiresDepthTexture():Bool {
		return true;
	}

	override private function initFilter(renderManager:RenderManager, vp:ViewPort, w:Int, h:Int):Void {
		material = new Material();
		material.load(Angle3D.materialFolder + "material/fog.mat");
		material.setColor("u_FogColor", fogColor);
		material.setVector4("u_FogInfo", this.fogInfo);
	}

	override public function getMaterial():Material {
		return material;
	}

	/**
	 * returns the fog color
	 * @return
	 */
	public function getFogColor():Color {
		return fogColor;
	}

	/**
	 * Sets the color of the fog
	 * @param fogColor
	 */
	public function setFogColor(fogColor:Color):Void {
		if (material != null) {
			material.setColor("u_FogColor", fogColor);
		}
		this.fogColor = fogColor;
	}

	/**
	 * returns the fog density
	 * @return
	 */
	public function getFogDensity():Float {
		return Math.sqrt(-this.fogInfo.x / LOG2);
	}

	/**
	 * Sets the density of the fog, a high value gives a thick fog
	 * @param fogDensity
	 */
	public function setFogDensity(fogDensity:Float):Void {
		this.fogInfo.x = -fogDensity * fogDensity * LOG2;
		if (material != null) {
			material.setVector4("u_FogInfo", this.fogInfo);
		}
	}

	/**
	 * returns the fog distance
	 * @return
	 */
	public function getFogDistance():Float {
		return this.fogInfo.y - near;
	}

	/**
	 * the distance of the fog. the higer the value the distant the fog looks
	 * @param fogDistance
	 */
	public function setFogDistance(fogDistance:Float):Void {
		this.fogInfo.y = fogDistance + near;
		this.fogInfo.z = fogDistance - near;
		if (material != null) {
			material.setVector4("u_FogInfo", this.fogInfo);
		}
	}
}
