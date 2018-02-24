package angle3d.shadow;
import angle3d.light.PointLight;
import angle3d.light.SpotLight;

/**
 *
 * This Filter does basically the same as a SpotLightShadowRenderer except it
 * renders the post shadow pass as a fulscreen quad pass instead of a geometry
 * pass. It's mostly faster than PssmShadowRenderer as long as you have more
 * than a about ten shadow recieving objects. The expense is the draw back that
 * the shadow Recieve mode set on spatial is ignored. So basically all and only
 * objects that render depth in the scene receive shadows. See this post for
 * more details
 * http://jmonkeyengine.org/groups/general-2/forum/topic/silly-question-about-shadow-rendering/#post-191599
 *
 * API is basically the same as the PssmShadowRenderer;
 *
 */
class PointLightShadowFilter extends AbstractShadowFilter {

	public function new(shadowMapSize:Int) {
		super(shadowMapSize, new PointLightShadowRenderer(shadowMapSize));
	}

	/**
	 * return the light used to cast shadows
	 *
	 * @return the DirectionalLight
	 */
	public function getLight():PointLight {
		return cast(shadowRenderer,PointLightShadowRenderer).getLight();
	}

	/**
	 * Sets the light to use to cast shadows
	 *
	 * @param light a DirectionalLight
	 */
	public function setLight(light:PointLight):Void {
		cast(shadowRenderer,PointLightShadowRenderer).setLight(light);
	}

}