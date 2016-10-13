package test.light;

import haxe.unit.TestCase;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.DefaultLightFilter;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.LightList;
import org.angle3d.light.PointLight;
import org.angle3d.light.SpotLight;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;
import org.angle3d.utils.TempVars;

class LightFilterTest extends TestCase
{
	private var filter:DefaultLightFilter;
	private var cam:Camera;
	private var geom:Geometry;
	private var list:LightList;

	public function new() 
	{
		super();
		
	}
	
	override public function setup():Void 
	{
		super.setup();
		
		filter = new DefaultLightFilter();
		
		cam = new Camera(512, 512);
		cam.setFrustumPerspective(45, 1, 1, 1000);
		cam.setLocation(new Vector3f(0, 0, 0));
		cam.lookAtDirection(new Vector3f(0, 0, 1), new Vector3f(0, 1, 0));
		
		var box:Box = new Box(1, 1, 1);
		geom = new Geometry("geom", box);
		geom.setLocalTranslation(new Vector3f(0, 0, 10));
		geom.updateGeometricState();
		
		list = new LightList(geom);
	}
	
	private function checkFilteredLights(expected:Int):Void
	{
		geom.updateGeometricState();
		filter.setCamera(cam);
		list.clear();
		filter.filterLights(geom, list);
		assertEquals(expected, list.getSize());
	}
	
	public function testAmbientFiltering():Void
	{
		geom.addLight(new AmbientLight());
		checkFilteredLights(1);// Ambient lights must never be filtered
	}
	
	public function testDirectionalFiltering():Void
	{
		geom.addLight(new DirectionalLight(Vector3f.Y_AXIS));
		checkFilteredLights(1);// Directional lights must never be filtered
	}
	
	public function testPointFiltering():Void
	{
		var pl:PointLight = new PointLight();
        geom.addLight(pl);
        checkFilteredLights(1); // Infinite point lights must never be filtered
        
        // Light at origin does not intersect geom which is at Z=10
        pl.radius = (1);
        checkFilteredLights(0);
        
        // Put it closer to geom, the very edge of the sphere touches the box.
        // Still not considered an intersection though.
        pl.position = (new Vector3f(0, 0, 8));
        checkFilteredLights(0);
        
        // And more close - now its an intersection.
        pl.position = (new Vector3f(0, 0, 8 + FastMath.ZERO_TOLERANCE));
        checkFilteredLights(1);
        
        // Move the geometry away
        geom.move(0, 0, FastMath.ZERO_TOLERANCE);
        checkFilteredLights(0);
        
        // Test if the algorithm converts the sphere 
        // to a box before testing the collision (incorrect)
        var sqrt3:Float = FastMath.sqrt(3);
        
        pl.position = (new Vector3f(2, 2, 8));
        pl.radius = (sqrt3);
        checkFilteredLights(0);
        
        // Make it a wee bit larger.
        pl.radius = (sqrt3 + FastMath.ZERO_TOLERANCE);
        checkFilteredLights(1);
        
        // Rotate the camera so it is up, light is outside frustum.
        cam.lookAtDirection(Vector3f.Y_AXIS, Vector3f.Y_AXIS);
        checkFilteredLights(0);
	}
	
	public function testSpotFiltering():Void
	{
		var sl:SpotLight = new SpotLight();
		sl.direction = new Vector3f(0, 0, 1);
        sl.spotRange = (0);
        geom.addLight(sl);
        checkFilteredLights(1); // Infinite spot lights are only filtered
                                // if the geometry is outside the infinite cone.
        
		// The spot is not touching the near plane of the camera yet, 
		// should still be culled.
		sl.spotRange = (1 - FastMath.ZERO_TOLERANCE);
		
		assertFalse(sl.intersectsFrustum(cam));

		// should be culled from the geometry's PoV
		checkFilteredLights(0);
		
		// Now it touches the near plane.
		sl.spotRange = (1);
		// still culled from the geometry's PoV
		checkFilteredLights(0);
		assertTrue(sl.intersectsFrustum(cam));


        // make it barely reach the geometry
        sl.spotRange = (9);
        checkFilteredLights(0);
        
        // make it reach the geometry (touching its bound)
        sl.spotRange = (9 + FastMath.ZERO_TOLERANCE);
        checkFilteredLights(1);
        
        // rotate the cone a bit so it no longer faces the geom
        sl.direction = (new Vector3f(0.316, 0, 0.948).normalizeLocal());
        checkFilteredLights(0);
        
        // extent the range much farther
        sl.spotRange = (20);
        checkFilteredLights(0);
        
        // Create box of size X=10 (double the extent)
        // now, the spot will touch the box.
        geom.setMesh(new Box(5, 1, 1));
        checkFilteredLights(1);
	}
}