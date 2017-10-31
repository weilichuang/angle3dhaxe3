package org.angle3d.bullet.util;
import org.angle3d.scene.Node;

import org.angle3d.bounding.BoundingBox;
import org.angle3d.bullet.collision.shapes.BoxCollisionShape;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.collision.shapes.CompoundCollisionShape;
import org.angle3d.bullet.collision.shapes.HeightfieldCollisionShape;
import org.angle3d.bullet.collision.shapes.HullCollisionShape;
import org.angle3d.bullet.collision.shapes.infos.ChildCollisionShape;
import org.angle3d.bullet.collision.shapes.MeshCollisionShape;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Transform;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Spatial;
import org.angle3d.terrain.geomipmap.TerrainPatch;
import org.angle3d.terrain.geomipmap.TerrainQuad;

/**
 * ...
 
 */
class CollisionShapeFactory
{

	/**
     * returns the correct transform for a collisionshape in relation
     * to the ancestor for which the collisionshape is generated
     * @param spat
     * @param parent
     * @return
     */
    private static function getTransform(spat:Spatial, parent:Spatial):Transform
	{
        var shapeTransform:Transform = new Transform();
        var parentNode:Spatial = spat.parent != null ? spat.parent : spat;
        var currentSpatial:Spatial = spat;
        //if we have parents combine their transforms
        while (parentNode != null) 
		{
            if (parent == currentSpatial) 
			{
                //real parent -> only apply scale, not transform
                var trans:Transform = new Transform();
                trans.setScale(currentSpatial.getLocalScale());
                shapeTransform.combineWithParent(trans);
                parentNode = null;
            } 
			else
			{
                shapeTransform.combineWithParent(currentSpatial.getTransform());
                parentNode = currentSpatial.parent;
                currentSpatial = parentNode;
            }
        }
        return shapeTransform;
    }

    private static function createCompoundShape(realRootNode:Node,
												rootNode:Node,
												shape:CompoundCollisionShape, 
												meshAccurate:Bool, 
												isDynamic:Bool = false):CompoundCollisionShape
	{
		var children:Vector<Spatial> = rootNode.children;
		for (i in 0...children.length)
		{
			var spatial:Spatial = children[i];
			
			if (Std.is(spatial,TerrainQuad))
			{
				if (spatial.hasUserData(Spatial.USERDATA_PHYSICSIGNORE) &&
					spatial.getUserData(Spatial.USERDATA_PHYSICSIGNORE) == true)
				{
                    continue; // go to the next child in the loop
                }
				
                var terrain:TerrainQuad = cast spatial;
                var trans:Transform = getTransform(spatial, realRootNode);
                shape.addChildShape(new HeightfieldCollisionShape(terrain.getHeightMap(), trans.scale),
                        trans.translation,
                        trans.rotation.toMatrix3f());
            } 
			else if (Std.is(spatial,Node))
			{
                createCompoundShape(realRootNode, cast spatial, shape, meshAccurate, isDynamic);
            }
			else if (Std.is(spatial,TerrainPatch))
			{
                if (spatial.hasUserData(Spatial.USERDATA_PHYSICSIGNORE) &&
					spatial.getUserData(Spatial.USERDATA_PHYSICSIGNORE) == true)
				{
                    continue; // go to the next child in the loop
                }
				
                var terrain:TerrainPatch = cast spatial;
                var trans:Transform = getTransform(spatial, realRootNode);
                shape.addChildShape(new HeightfieldCollisionShape(terrain.getHeightMap(), terrain.getLocalScale()),
                        trans.translation,
                        trans.rotation.toMatrix3f());
            } 
			else if (Std.is(spatial,Geometry)) 
			{
                if (spatial.hasUserData(Spatial.USERDATA_PHYSICSIGNORE) &&
					spatial.getUserData(Spatial.USERDATA_PHYSICSIGNORE) == true)
				{
                    continue; // go to the next child in the loop
                }

                if (meshAccurate)
				{
                    var childShape:CollisionShape = isDynamic
                            ? createSingleDynamicMeshShape(cast spatial, realRootNode)
                            : createSingleMeshShape(cast spatial, realRootNode);
                    if (childShape != null)
					{
                        var trans:Transform = getTransform(spatial, realRootNode);
                        shape.addChildShape(childShape,
                                trans.translation,
                                trans.rotation.toMatrix3f());
                    }
                } 
				else 
				{
                    var trans:Transform = getTransform(spatial, realRootNode);
                    shape.addChildShape(createSingleBoxShape(spatial, realRootNode),
                            trans.translation,
                            trans.rotation.toMatrix3f());
                }
            }
		}

        return shape;
    }
	
    /**
     * This type of collision shape is mesh-accurate and meant for immovable "world objects".
     * Examples include terrain, houses or whole shooter levels.<br>
     * Objects with "mesh" type collision shape will not collide with each other.
     */
    private static function createMeshCompoundShape(rootNode:Node):CompoundCollisionShape
	{
        return createCompoundShape(rootNode, rootNode, new CompoundCollisionShape(), true);
    }

    /**
     * This type of collision shape creates a CompoundShape made out of boxes that
     * are based on the bounds of the Geometries  in the tree.
     * @param rootNode
     * @return
     */
    private static function createBoxCompoundShape(rootNode:Node):CompoundCollisionShape
	{
        return createCompoundShape(rootNode, rootNode, new CompoundCollisionShape(), false);
    }

    /**
     * This type of collision shape is mesh-accurate and meant for immovable "world objects".
     * Examples include terrain, houses or whole shooter levels.<br/>
     * Objects with "mesh" type collision shape will not collide with each other.<br/>
     * Creates a HeightfieldCollisionShape if the supplied spatial is a TerrainQuad.
     * @return A MeshCollisionShape or a CompoundCollisionShape with MeshCollisionShapes as children if the supplied spatial is a Node. A HeightieldCollisionShape if a TerrainQuad was supplied.
     */
    public static function createMeshShape(spatial:Spatial):CollisionShape 
	{
        if (Std.is(spatial,TerrainQuad))
		{
            var terrain:TerrainQuad = cast spatial;
            return new HeightfieldCollisionShape(terrain.getHeightMap(), terrain.getLocalScale());
        } 
		else if (Std.is(spatial,TerrainPatch))
		{
            var terrain:TerrainPatch = cast spatial;
            return new HeightfieldCollisionShape(terrain.getHeightMap(), terrain.getLocalScale());
        } 
		else if (Std.is(spatial,Geometry))
		{
            return createSingleMeshShape(cast spatial, spatial);
        } 
		else if (Std.is(spatial,Node))
		{
            return createMeshCompoundShape(cast spatial);
        } 
		else 
		{
            throw ("Supplied spatial must either be Node or Geometry!");
        }
    }

    /**
     * This method creates a hull shape for the given Spatial.<br>
     * If you want to have mesh-accurate dynamic shapes (CPU intense!!!) use GImpact shapes, its probably best to do so with a low-poly version of your model.
     * @return A HullCollisionShape or a CompoundCollisionShape with HullCollisionShapes as children if the supplied spatial is a Node.
     */
    public static function createDynamicMeshShape(spatial:Spatial):CollisionShape
	{
        if (Std.is(spatial,Geometry)) 
		{
            return createSingleDynamicMeshShape(cast spatial, spatial);
        } 
		else if (Std.is(spatial,Node))
		{
            return createCompoundShape(cast spatial, cast spatial, new CompoundCollisionShape(), true, true);
        } 
		else 
		{
            throw ("Supplied spatial must either be Node or Geometry!");
        }
		return null;
    }

    public static function createBoxShape(spatial:Spatial):CollisionShape
	{
        if (Std.is(spatial,Geometry)) 
		{
            return createSingleBoxShape(cast spatial, spatial);
        }
		else if (Std.is(spatial,Node))
		{
            return createBoxCompoundShape(cast spatial);
        } 
		else
		{
            throw ("Supplied spatial must either be Node or Geometry!");
        }
		return null;
    }

    /**
     * This type of collision shape is mesh-accurate and meant for immovable "world objects".
     * Examples include terrain, houses or whole shooter levels.<br>
     * Objects with "mesh" type collision shape will not collide with each other.
     */
    private static function createSingleMeshShape(geom:Geometry, parent:Spatial):MeshCollisionShape
	{
        var mesh:Mesh = geom.getMesh();
        var trans:Transform = getTransform(geom, parent);
        if (mesh != null) 
		{
            var mColl:MeshCollisionShape = new MeshCollisionShape(mesh);
            mColl.setScale(trans.scale);
            return mColl;
        } 
		else
		{
            return null;
        }
    }

    /**
     * Uses the bounding box of the supplied spatial to create a BoxCollisionShape
     * @param spatial
     * @return BoxCollisionShape with the size of the spatials BoundingBox
     */
    private static function createSingleBoxShape(spatial:Spatial, parent:Spatial):BoxCollisionShape
	{
        //TODO: using world bound here instead of "local world" bound...
        var shape:BoxCollisionShape = new BoxCollisionShape(
                cast(spatial.worldBound,BoundingBox).getExtent(new Vector3f()));
        return shape;
    }

    /**
     * This method creates a hull collision shape for the given mesh.<br>
     */
    private static function createSingleDynamicMeshShape(geom:Geometry, parent:Spatial):HullCollisionShape
	{
        var mesh:Mesh = geom.getMesh();
        var trans:Transform = getTransform(geom, parent);
        if (mesh != null) 
		{
            var dynamicShape:HullCollisionShape = new HullCollisionShape();
			dynamicShape.fromMesh(mesh);
            dynamicShape.setScale(trans.scale);
            return dynamicShape;
        } 
		else
		{
            return null;
        }
    }

    /**
     * This method moves each child shape of a compound shape by the given vector
     * @param vector
     */
    public static function shiftCompoundShapeContents(compoundShape:CompoundCollisionShape, vector:Vector3f):Void
	{
		var children:Array<ChildCollisionShape> = compoundShape.getChildren();
		for (i in 0...children.length)
        {
            var childCollisionShape:ChildCollisionShape = children[i];
            var child:CollisionShape = childCollisionShape.shape;
            var location:Vector3f = childCollisionShape.location;
            var rotation:Matrix3f = childCollisionShape.rotation;
            compoundShape.removeChildShape(child);
            compoundShape.addChildShape(child, location.add(vector), rotation);
        }
    }
	
}