package test.collision;

import haxe.unit.TestCase;
import org.angle3d.bounding.BoundingBox;
import org.angle3d.bounding.BoundingSphere;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.collision.Collidable;
import org.angle3d.collision.CollisionResults;
import org.angle3d.math.FastMath;
import org.angle3d.math.Ray;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Quad;

class BoundingCollisionTest extends TestCase
{

	public function new() 
	{
		super();
	}
	
	
	public function testBoxBoxCollision():Void
	{
		var box1:BoundingBox = new BoundingBox(new Vector3f(), new Vector3f(1, 1, 1));
		var box2:BoundingBox = new BoundingBox(new Vector3f(), new Vector3f(1, 1, 1));
		checkCollision(box1, box2, 1);
		
		// Put it at the very edge - should still intersect.
        box2.setCenter(new Vector3f(2, 0, 0));
        checkCollision(box1, box2, 1);
        
        // Put it a wee bit farther - no intersection expected
        box2.setCenter(new Vector3f(2 + FastMath.ZERO_TOLERANCE, 0, 0));
        checkCollision(box1, box2, 0);
        
        // Check the corners.
        box2.setCenter(new Vector3f(2, 2, 2));
        checkCollision(box1, box2, 1);
        
        box2.setCenter(new Vector3f(2, 2, 2 + FastMath.ZERO_TOLERANCE));
        checkCollision(box1, box2, 0);
	}
	
	public function testSphereSphereCollision():Void
	{
		var sphere1:BoundingSphere = new BoundingSphere(1);
        var sphere2:BoundingSphere = new BoundingSphere(1);
        checkCollision(sphere1, sphere2, 1);
        
        // Put it at the very edge - should still intersect.
        sphere2.center = (new Vector3f(2, 0, 0));
        checkCollision(sphere1, sphere2, 1);
        
        // Put it a wee bit farther - no intersection expected
        sphere2.center = (new Vector3f(2 + FastMath.ZERO_TOLERANCE, 0, 0));
        checkCollision(sphere1, sphere2, 0);
	}
	
	public function testBoxSphereCollision():Void
	{
		var box1:BoundingBox = new BoundingBox(Vector3f.ZERO, new Vector3f(1, 1, 1));
        var sphere2:BoundingSphere = new BoundingSphere(1, Vector3f.ZERO);
        checkCollision(box1, sphere2, 1);
        
        // Put it at the very edge - for sphere vs. box, it will not intersect
        sphere2.setCenter(new Vector3f(2, 0, 0));
        checkCollision(box1, sphere2, 0);
        
        // Put it a wee bit closer - should intersect.
        sphere2.setCenter(new Vector3f(2 - FastMath.ZERO_TOLERANCE, 0, 0));
        checkCollision(box1, sphere2, 1);
        
        // Test if the algorithm converts the sphere 
        // to a box before testing the collision (incorrect)
        var sqrt3:Float = FastMath.sqrt(3);
        
        sphere2.setCenter(new Vector3f(2,2,2));
        sphere2.radius = (sqrt3);
        checkCollision(box1, sphere2, 0);
        
        // Make it a wee bit larger.
        sphere2.radius = (sqrt3 + FastMath.ZERO_TOLERANCE);
        checkCollision(box1, sphere2, 1);
	}
	
	public function testBoxRayCollision():Void
	{
		var box:BoundingBox = new BoundingBox(Vector3f.ZERO, new Vector3f(1, 1, 1));
        var ray:Ray = new Ray(Vector3f.ZERO, Vector3f.Z_AXIS);
        
        // XXX: seems incorrect, ray inside box should only generate
        // one result...
        checkCollision(box, ray, 2);
        
        ray.setOrigin(new Vector3f(0, 0, -5));
        checkCollision(box, ray, 2);
        
        // XXX: is this right? the ray origin is on the box's side..
        ray.setOrigin(new Vector3f(0, 0, 2));
        checkCollision(box, ray, 0);
        
        ray.setOrigin(new Vector3f(0, 0, -2));
        checkCollision(box, ray, 2);
        
        // parallel to the edge, touching the side
        ray.setOrigin(new Vector3f(0, 1, -2));
        checkCollision(box, ray, 2);
        
        // still parallel, but not touching the side
        ray.setOrigin(new Vector3f(0, 1 + FastMath.ZERO_TOLERANCE, -2));
        checkCollision(box, ray, 0);
	}
	
	public function testBoxTriangleCollision():Void
	{
		var box:BoundingBox = new BoundingBox(Vector3f.ZERO, new Vector3f(1, 1, 1));
        var geom:Geometry = new Geometry("geom", new Quad(1, 1));
        checkCollision(box, geom, 2); // Both triangles intersect
        
        // The box touches the edges of the triangles.
        box.setCenter(new Vector3f(-1, 0, 0));
        checkCollision(box, geom, 2);
        
        // Move it slightly farther..
        box.setCenter(new Vector3f(-1 - FastMath.ZERO_TOLERANCE, 0, 0));
        checkCollision(box, geom, 0);
        
        // Parallel triangle / box side, touching
        box.setCenter(new Vector3f(0, 0, -1));
        checkCollision(box, geom, 2);
        
        // Not touching
        box.setCenter(new Vector3f(0, 0, -1 - FastMath.ZERO_TOLERANCE));
        checkCollision(box, geom, 0);
        
        // Test collisions only against one of the triangles
        box.setCenter(new Vector3f(-1, 1.5, 0));
        checkCollision(box, geom, 1);
        
        box.setCenter(new Vector3f(1.5, -1, 0));
        checkCollision(box, geom, 1);
	}
	
	public function testSphereTriangleCollision():Void
	{
		var sphere:BoundingSphere = new BoundingSphere(1, Vector3f.ZERO);
        var geom:Geometry = new Geometry("geom", new Quad(1, 1));
        checkCollision(sphere, geom, 2);
        
        // The box touches the edges of the triangles.
        sphere.setCenter(new Vector3f(-1 + FastMath.ZERO_TOLERANCE, 0, 0));
        checkCollision(sphere, geom, 2);
        
        // Move it slightly farther..
        sphere.setCenter(new Vector3f(-1 - FastMath.ZERO_TOLERANCE, 0, 0));
        checkCollision(sphere, geom, 0);
        
        // Parallel triangle / box side, touching
        sphere.setCenter(new Vector3f(0, 0, -1));
        checkCollision(sphere, geom, 2);
        
        // Not touching
        sphere.setCenter(new Vector3f(0, 0, -1 - FastMath.ZERO_TOLERANCE));
        checkCollision(sphere, geom, 0);
        
        // Test collisions only against one of the triangles
        sphere.setCenter(new Vector3f(-0.9, 1.2, 0));
        checkCollision(sphere, geom, 1);
        
        sphere.setCenter(new Vector3f(1.2, -0.9, 0));
        checkCollision(sphere, geom, 1);
	}
	
	private function checkCollisionBase(a:Collidable, b:Collidable, expected:Int):Void
	{
		// Test bounding volume methods
		if (Std.is(a, BoundingVolume) && Std.is(b, BoundingVolume))
		{
			var bv1:BoundingVolume = cast a;
			var bv2:BoundingVolume = cast b;
			assertEquals(expected != 0 , bv1.intersects(bv2));
		}
		
		// Test standard collideWith method
		var results:CollisionResults = new CollisionResults();
		var numCollisions:Int = a.collideWith(b, results);
		
		assertEquals(numCollisions, results.size);
		assertEquals(expected, numCollisions);
		
		results.getClosestCollision();
		
		if (results.size > 0)
		{
			assertEquals(results.getClosestCollision(), results.getCollision(0));
		}
		if (results.size == 1)
		{
			assertEquals(results.getClosestCollision(), results.getFarthestCollision());
		}
	}
	
	private function checkCollision(a:Collidable, b:Collidable, expected:Int):Void
	{
		checkCollisionBase(a, b, expected);
		checkCollisionBase(b, a, expected);
	}
}