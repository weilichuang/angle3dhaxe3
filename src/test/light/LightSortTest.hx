package test.light;

import haxe.unit.TestCase;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.LightList;
import org.angle3d.light.PointLight;
import org.angle3d.light.SpotLight;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;

class LightSortTest extends TestCase
{

	public function new() 
	{
		super();
		
	}
	
	public function testSimpleSort():Void
	{
		var g:Geometry = new Geometry("test", new Mesh());
        var list:LightList = new LightList(g);
        
		var sl = new SpotLight();
		sl.position = new Vector3f(0, 0, 0);
		sl.direction = new Vector3f(1, 0, 0);
        list.addLight(sl);
		var pl = new PointLight();
		pl.position = new Vector3f(1, 0, 0);
        list.addLight(pl);
        list.addLight(new DirectionalLight(Vector3f.X_AXIS));
        list.addLight(new AmbientLight());
        
        list.sort(true);
		
        assertTrue(Std.is(list.getLightAt(0), AmbientLight));     // Ambients always first
        assertTrue(Std.is(list.getLightAt(1), DirectionalLight)); // .. then directionals
        assertTrue(Std.is(list.getLightAt(2), SpotLight));        // Spot is 0 units away from geom
        assertTrue(Std.is(list.getLightAt(3), PointLight));       // .. and point is 1 unit away.
	}
	
	public function testSceneGraphSort():Void
	{
		var n:Node = new Node("node");
        var g:Geometry = new Geometry("geom", new Mesh());
        var spot:SpotLight = new SpotLight(Vector3f.ZERO, Vector3f.X_AXIS);
        var point:PointLight = new PointLight(Vector3f.X_AXIS);
        var directional:DirectionalLight = new DirectionalLight(Vector3f.X_AXIS);
        var ambient:AmbientLight = new AmbientLight();
        
        // Some lights are on the node
        n.addLight(spot);
        n.addLight(point);
        
        // .. and some on the geometry.
        g.addLight(directional);
        g.addLight(ambient);
        
        n.attachChild(g);
        n.updateGeometricState();
        
        var list:LightList = g.getWorldLightList();
        
        // check the sorting (when geom is at 0,0,0)
		assertTrue(Std.is(list.getLightAt(0), AmbientLight)); 
        assertTrue(Std.is(list.getLightAt(1), DirectionalLight)); 
        assertTrue(Std.is(list.getLightAt(2), SpotLight));     
        assertTrue(Std.is(list.getLightAt(3), PointLight)); 
        
        // move the geometry closer to the point light
        g.setLocalTranslation(Vector3f.X_AXIS);
        n.updateGeometricState();
		
		assertTrue(Std.is(list.getLightAt(0), AmbientLight)); 
        assertTrue(Std.is(list.getLightAt(1), DirectionalLight)); 
        assertTrue(Std.is(list.getLightAt(2), PointLight));     
        assertTrue(Std.is(list.getLightAt(3), SpotLight)); 
	}
}