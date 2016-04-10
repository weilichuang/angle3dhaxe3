package org.angle3d.shadow;
import org.angle3d.light.DirectionalLight;

/**
 *
 * This Filter does basically the same as a DirectionalLightShadowRenderer
 * except it renders the post shadow pass as a fulscreen quad pass instead of a
 * geometry pass. It's mostly faster than PssmShadowRenderer as long as you have
 * more than a about ten shadow recieving objects. The expense is the draw back
 * that the shadow Recieve mode set on spatial is ignored. So basically all and
 * only objects that render depth in the scene receive shadows. See this post
 * for more details
 * http://jmonkeyengine.org/groups/general-2/forum/topic/silly-question-about-shadow-rendering/#post-191599
 *
 * API is basically the same as the PssmShadowRenderer;
 *
 */
class DirectionalLightShadowFilter extends AbstractShadowFilter
{
	public function new(shadowMapSize:Int,nbSplits:Int) 
	{
		super(shadowMapSize, new DirectionalLightShadowRenderer(shadowMapSize, nbSplits));
	}
	
	/**
     * return the light used to cast shadows
     *
     * @return the DirectionalLight
     */
    public function getLight():DirectionalLight
	{
		return cast(shadowRenderer,DirectionalLightShadowRenderer).getLight();
    }

    /**
     * Sets the light to use to cast shadows
     *
     * @param light a DirectionalLight
     */
    public function setLight(light:DirectionalLight):Void 
	{
        cast(shadowRenderer,DirectionalLightShadowRenderer).setLight(light);
    }

    /**
     * returns the labda parameter
     *
     * @see setLambda(float lambda)
     * @return lambda
     */
    public function getLambda():Float
	{
        return cast(shadowRenderer,DirectionalLightShadowRenderer).getLambda();
    }

    /**
     * Adjust the repartition of the different shadow maps in the shadow extend
     * usualy goes from 0.0 to 1.0 a low value give a more linear repartition
     * resulting in a constant quality in the shadow over the extends, but near
     * shadows could look very jagged a high value give a more logarithmic
     * repartition resulting in a high quality for near shadows, but the quality
     * quickly decrease over the extend. the default value is set to 0.65f
     * (theoric optimal value).
     *
     * @param lambda the lambda value.
     */
    public function setLambda(lambda:Float):Void 
	{
        cast(shadowRenderer,DirectionalLightShadowRenderer).setLambda(lambda);
    }

    /**
     * retruns true if stabilization is enabled
     * @return 
     */
    public function isEnabledStabilization():Bool
	{
        return cast(shadowRenderer,DirectionalLightShadowRenderer).isEnabledStabilization();
    }
    
    /**
     * Enables the stabilization of the shadows's edges. (default is true)
     * This prevents shadows' edges to flicker when the camera moves
     * However it can lead to some shadow quality loss in some particular scenes.
     * @param stabilize 
     */
    public function setEnabledStabilization(stabilize:Bool):Void
	{
        cast(shadowRenderer,DirectionalLightShadowRenderer).setEnabledStabilization(stabilize);        
    }   
}