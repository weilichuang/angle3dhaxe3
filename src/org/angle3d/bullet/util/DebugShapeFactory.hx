package org.angle3d.bullet.util;
import com.bulletphysics.collision.shapes.ConcaveShape;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.collision.shapes.ShapeHull;
import com.bulletphysics.collision.shapes.TriangleCallback;
import com.bulletphysics.util.IntArrayList;
import com.bulletphysics.util.ObjectArrayList;
import flash.Vector;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.collision.shapes.CompoundCollisionShape;
import org.angle3d.bullet.collision.shapes.infos.ChildCollisionShape;
import org.angle3d.bullet.collision.shapes.MeshCollisionShape;
import org.angle3d.math.Matrix3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.WireframeUtil;
import org.angle3d.scene.Spatial;
import de.polygonal.ds.error.Assert;
import org.angle3d.utils.TempVars;
import org.angle3d.math.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class DebugShapeFactory
{

	/** The maximum corner for the aabb used for triangles to include in ConcaveShape processing.*/
    private static var aabbMax:Vector3f = new Vector3f(1e30, 1e30, 1e30);
    /** The minimum corner for the aabb used for triangles to include in ConcaveShape processing.*/
    private static var aabbMin:Vector3f = new Vector3f( -1e30, -1e30, -1e30);
	
	private static var tmpMatrix3:Matrix3f = new Matrix3f();

    /**
     * Creates a debug shape from the given collision shape. This is mostly used internally.<br>
     * To attach a debug shape to a physics object, call <code>attachDebugShape(AssetManager manager);</code> on it.
     * @param collisionShape
     * @return
     */
    public static function getDebugShape(collisionShape:CollisionShape):Spatial
	{
        if (collisionShape == null)
		{
            return null;
        }
		
        var debugShape:Spatial;
        if (Std.is(collisionShape, CompoundCollisionShape))
		{
            var shape:CompoundCollisionShape = cast collisionShape;
            var children:Array<ChildCollisionShape> = shape.getChildren();
            var node:Node = new Node("DebugShapeNode");
            for (i in 0...children.length)
			{
                var childCollisionShape:ChildCollisionShape = children[i];
                var ccollisionShape:CollisionShape = childCollisionShape.shape;
                var geometry:Geometry = createDebugShape(ccollisionShape);

                // apply translation
                geometry.setLocalTranslation(childCollisionShape.location);

                // apply rotation
                tmpMatrix3.fromQuaternion(geometry.getLocalRotation());
                childCollisionShape.rotation.mult(tmpMatrix3, tmpMatrix3);
                geometry.setLocalRotationByMatrix3f(tmpMatrix3);

                node.attachChild(geometry);
            }
            debugShape = node;
        }
		else
		{
            debugShape = createDebugShape(collisionShape);
        }
		
        if (debugShape == null) 
		{
            return null;
        }
        debugShape.updateGeometricState();
        return debugShape;
    }

    private static function createDebugShape(shape:CollisionShape):Geometry
	{
        var geom:Geometry = new Geometry("debugShape");
        geom.setMesh(getDebugMesh(shape));
//        geom.setLocalScale(shape.getScale());
        geom.updateModelBound();
        return geom;
    }

	//TODO 优化
    public static function getDebugMesh(shape:CollisionShape):Mesh
	{
        var mesh:Mesh = null;

		if (Std.is(shape.getCShape(), ConvexShape))
		{
			mesh = new Mesh();
			mesh.setVertexBuffer(BufferType.POSITION, 3, getConvexShapeVertices(cast shape.getCShape()));
		} 
		else if (Std.is(shape.getCShape(), ConcaveShape)) 
		{
			mesh = new Mesh();
			mesh.setVertexBuffer(BufferType.POSITION, 3, getConcaveShapeVertices(cast shape.getCShape()));
		}
		
		//如果没有indices数据，则根据POSITION创建
		if (mesh != null && mesh.getIndices() == null)
		{
			var vertices:Vector<Float> = mesh.getVertexBuffer(BufferType.POSITION).getData();
			
			var indices:Vector<UInt> = new Vector<UInt>(Std.int(vertices.length / 3));
			for (i in 0...indices.length)
			{
				indices[i] = i;
			}
			mesh.setIndices(indices);
			
			mesh.validate();
		}
		
        return WireframeUtil.generateWireframe(mesh);
    }

    /**
     *  Constructs the buffer for the vertices of the concave shape.
     *
     * @param concaveShape the shape to get the vertices for / from.
     * @return the shape as stored by the given broadphase rigid body.
     */
    private static function getConcaveShapeVertices(concaveShape:ConcaveShape):Vector<Float>
	{
        // Create the call back that'll create the vertex buffer
        var triangleProcessor:BufferedTriangleCallback = new BufferedTriangleCallback();
        concaveShape.processAllTriangles(triangleProcessor, aabbMin, aabbMax);

        // Retrieve the vextex and index buffers
        return triangleProcessor.getVertices();
    }

    /**
     *  Processes the given convex shape to retrieve a correctly ordered FloatBuffer to
     *  construct the shape from with a TriMesh.
     *
     * @param convexShape the shape to retreieve the vertices from.
     * @return the vertices as a FloatBuffer, ordered as Triangles.
     */
    private static function getConvexShapeVertices(convexShape:ConvexShape):Vector<Float>
	{
        // Check there is a hull shape to render
        if (convexShape.getUserPointer() == null) 
		{
            // create a hull approximation
            var hull:ShapeHull = new ShapeHull(convexShape);
            var margin:Float = convexShape.getMargin();
            hull.buildHull(margin);
            convexShape.setUserPointer(hull);
        }

        // Assert state - should have a pointer to a hull (shape) that'll be drawn
        Assert.assert( convexShape.getUserPointer() != null, "Should have a shape for the userPointer, instead got null");
		
        var hull:ShapeHull = cast convexShape.getUserPointer();

        // Assert we actually have a shape to render
        Assert.assert(hull.numTriangles() > 0 , "Expecting the Hull shape to have triangles");
        var numberOfTriangles:Int = hull.numTriangles();

        // The number of bytes needed is: (floats in a vertex) * (vertices in a triangle) * (# of triangles) * (size of float in bytes)
        var numberOfFloats:Int = 3 * 3 * numberOfTriangles;
		
        var vertices:Vector<Float> = new Vector<Float>(numberOfFloats); 

        // Loop variables
        var hullIndicies:IntArrayList = hull.getIndexPointer();
        var hullVertices:ObjectArrayList<Vector3f> = hull.getVertexPointer();
        var vertexA:Vector3f, vertexB:Vector3f, vertexC:Vector3f;
        var index:Int = 0;
        for (i in 0...numberOfTriangles)
		{
            // Grab the data for this triangle from the hull
            vertexA = hullVertices.get(hullIndicies.get(index++));
            vertexB = hullVertices.get(hullIndicies.get(index++));
            vertexC = hullVertices.get(hullIndicies.get(index++));
			
			vertices[i * 9 + 0] = vertexA.x;
			vertices[i * 9 + 1] = vertexA.y;
			vertices[i * 9 + 2] = vertexA.z;
			
			vertices[i * 9 + 3] = vertexB.x;
			vertices[i * 9 + 4] = vertexB.y;
			vertices[i * 9 + 5] = vertexB.z;
			
			vertices[i * 9 + 6] = vertexC.x;
			vertices[i * 9 + 7] = vertexC.y;
			vertices[i * 9 + 8] = vertexC.z;
        }

        return vertices;
    }
}

/**
 *  A callback is used to process the triangles of the shape as there is no direct access to a concave shapes, shape.
 *  <p/>
 *  The triangles are simply put into a list (which in extreme condition will cause memory problems) then put into a direct buffer.
 *
 * @author CJ Hare
 */
class BufferedTriangleCallback implements TriangleCallback 
{

    private var vertices:Array<Vector3f>;

    public function new()
	{
        vertices = new Array<Vector3f>();
    }

	public function processTriangle(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void 
	{
		// Three sets of individual lines
        // The new Vector is needed as the given triangle reference is from a pool
        vertices.push(triangle[0].clone());
        vertices.push(triangle[1].clone());
        vertices.push(triangle[2].clone());
	}
	
    /**
     *  Retrieves the vertices from the Triangle buffer.
     */
    public function getVertices():Vector<Float>
	{
        // There are 3 floats needed for each vertex (x,y,z)
        var numberOfFloats:Int = vertices.length * 3;
		
		var result:Vector<Float> = new Vector<Float>(numberOfFloats);
		
		for (i in 0...vertices.length)
		{
			var vertex:Vector3f = vertices[i];
			result[i * 3 + 0] = vertex.x;
			result[i * 3 + 1] = vertex.y;
			result[i * 3 + 2] = vertex.z;
		}

        return result;
    }
}


