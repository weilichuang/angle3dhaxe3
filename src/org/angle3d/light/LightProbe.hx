package org.angle3d.light;

/**
 * A LightProbe is not exactly a light. It holds environment map information used for Image Based Lighting.
 * This is used for indirect lighting in the Physically Based Rendering pipeline.
 *
 * A light probe has a position in world space. This is the position from where the Environment Map are rendered.
 * There are two environment maps held by the LightProbe :
 * - The irradiance map (used for indirect diffuse lighting in the PBR pipeline).
 * - The prefiltered environment map (used for indirect specular lighting and reflection in the PBE pipeline).
 * Note that when instanciating the LightProbe, both those maps are null.
 * To render them see `LightProbeFactory.makeProbe`
 * and {@link EnvironmentCamera}.
 *
 * The light probe has an area of effect that is a bounding volume centered on its position. (for now only Bounding spheres are supported).
 *
 * A LightProbe will only be taken into account when it's marked as ready.
 * A light probe is ready when it has valid environment map data set.
 * Note that you should never call setReady yourself.
 *
 * @see LightProbeFactory
 * @see EnvironmentCamera
 */
class LightProbe extends Light {

	public function new() {
		super();
		this.type = LightType.Probe;
	}

}