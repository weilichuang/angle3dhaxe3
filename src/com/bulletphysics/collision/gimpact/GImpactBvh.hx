package com.bulletphysics.collision.gimpact ;
import com.bulletphysics.collision.gimpact.BoxCollision.AABB;
import com.bulletphysics.collision.gimpact.BoxCollision.BoxBoxTransformCache;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.util.IntArrayList;
import org.angle3d.math.Vector3f;

/**
 * ...
 
 */
class GImpactBvh
{
	private var box_tree:BvhTree = new BvhTree();
    private var primitive_manager:PrimitiveManagerBase;

    /**
     * This constructor doesn't build the tree. you must call buildSet.
     */
    public function new(primitive_manager:PrimitiveManagerBase = null)
	{
        this.primitive_manager = primitive_manager;
    }

    public function getGlobalBox(out:AABB):AABB
	{
        getNodeBound(0, out);
        return out;
    }

    public function setPrimitiveManager( primitive_manager:PrimitiveManagerBase):Void
	{
        this.primitive_manager = primitive_manager;
    }

    public function getPrimitiveManager():PrimitiveManagerBase
	{
        return primitive_manager;
    }

    // stackless refit
    private function refit():Void
	{
        var leafbox:AABB = new AABB();
        var bound:AABB = new AABB();
        var temp_box:AABB = new AABB();

        var nodecount:Int = getNodeCount();
        while ((nodecount--) != 0)
		{
            if (isLeafNode(nodecount))
			{
                primitive_manager.get_primitive_box(getNodeData(nodecount), leafbox);
                setNodeBound(nodecount, leafbox);
            } 
			else
			{
                //const BT_BVH_TREE_NODE * nodepointer = get_node_pointer(nodecount);
                //get left bound
                bound.invalidate();

                var child_node:Int = getLeftNode(nodecount);
                if (child_node != 0) 
				{
                    getNodeBound(child_node, temp_box);
                    bound.merge(temp_box);
                }

                child_node = getRightNode(nodecount);
                if (child_node != 0) 
				{
                    getNodeBound(child_node, temp_box);
                    bound.merge(temp_box);
                }

                setNodeBound(nodecount, bound);
            }
        }
    }

    /**
     * This attemps to refit the box set.
     */
    public function update():Void
	{
        refit();
    }

    /**
     * This rebuild the entire set.
     */
    public function buildSet():Void
	{
        // obtain primitive boxes
        var primitive_boxes:BvhDataArray = new BvhDataArray();
        primitive_boxes.resize(primitive_manager.get_primitive_count());

        var tmpAABB:AABB = new AABB();

        for (i in 0...primitive_boxes.size()) 
		{
            //primitive_manager.get_primitive_box(i,primitive_boxes[i].bound);
            primitive_manager.get_primitive_box(i, tmpAABB);
            primitive_boxes.setBound(i, tmpAABB);

            primitive_boxes.setData(i, i);
        }

        box_tree.build_tree(primitive_boxes);
    }

    /**
     * Returns the indices of the primitives in the primitive_manager field.
     */
    public function boxQuery(box:AABB, collided_results:IntArrayList):Bool
	{
        var curIndex:Int = 0;
        var numNodes:Int = getNodeCount();

        var bound:AABB = new AABB();

        while (curIndex < numNodes)
		{
            getNodeBound(curIndex, bound);

            // catch bugs in tree data

            var aabbOverlap:Bool = bound.has_collision(box);
            var isleafnode:Bool = isLeafNode(curIndex);

            if (isleafnode && aabbOverlap)
			{
                collided_results.add(getNodeData(curIndex));
            }

            if (aabbOverlap || isleafnode) 
			{
                // next subnode
                curIndex++;
            }
			else 
			{
                // skip node
                curIndex += getEscapeNodeIndex(curIndex);
            }
        }
        if (collided_results.size() > 0)
		{
            return true;
        }
        return false;
    }

    /**
     * Returns the indices of the primitives in the primitive_manager field.
     */
    public function boxQueryTrans(box:AABB, transform:Transform, collided_results:IntArrayList):Bool
	{
        var transbox:AABB = box.clone();
        transbox.appy_transform(transform);
        return boxQuery(transbox, collided_results);
    }

    /**
     * Returns the indices of the primitives in the primitive_manager field.
     */
    public function rayQuery(ray_dir:Vector3f, ray_origin:Vector3f, collided_results:IntArrayList):Bool
	{
        var curIndex:Int = 0;
        var numNodes:Int = getNodeCount();

        var bound:AABB = new AABB();

        while (curIndex < numNodes)
		{
            getNodeBound(curIndex, bound);

            // catch bugs in tree data

            var aabbOverlap:Bool = bound.collide_ray(ray_origin, ray_dir);
            var isleafnode:Bool = isLeafNode(curIndex);

            if (isleafnode && aabbOverlap)
			{
                collided_results.add(getNodeData(curIndex));
            }

            if (aabbOverlap || isleafnode)
			{
                // next subnode
                curIndex++;
            }
			else
			{
                // skip node
                curIndex += getEscapeNodeIndex(curIndex);
            }
        }
        if (collided_results.size() > 0) 
		{
            return true;
        }
        return false;
    }

    /**
     * Tells if this set has hierarchy.
     */
    public function hasHierarchy():Bool
	{
        return true;
    }

    /**
     * Tells if this set is a trimesh.
     */
    public function isTrimesh():Bool
	{
        return primitive_manager.is_trimesh();
    }

    public function getNodeCount():Int 
	{
        return box_tree.getNodeCount();
    }

    /**
     * Tells if the node is a leaf.
     */
    public function isLeafNode(nodeindex:Int):Bool
	{
        return box_tree.isLeafNode(nodeindex);
    }

    public function getNodeData(nodeindex:Int):Int
	{
        return box_tree.getNodeData(nodeindex);
    }

    public function getNodeBound( nodeindex:Int, bound:AABB):Void
	{
        box_tree.getNodeBound(nodeindex, bound);
    }

    public function setNodeBound( nodeindex:Int, bound:AABB):Void
	{
        box_tree.setNodeBound(nodeindex, bound);
    }

    public function getLeftNode( nodeindex:Int):Int 
	{
        return box_tree.getLeftNode(nodeindex);
    }

    public function getRightNode(nodeindex:Int):Int 
	{
        return box_tree.getRightNode(nodeindex);
    }

    public function getEscapeNodeIndex(nodeindex:Int):Int 
	{
        return box_tree.getEscapeNodeIndex(nodeindex);
    }

    public function getNodeTriangle( nodeindex:Int, triangle:PrimitiveTriangle):Void
	{
        primitive_manager.get_primitive_triangle(getNodeData(nodeindex), triangle);
    }

    public function get_node_pointer():BvhTreeNodeArray
	{
        return box_tree.get_node_pointer();
    }

    private static function _node_collision(boxset0:GImpactBvh, boxset1:GImpactBvh, trans_cache_1to0:BoxBoxTransformCache, 
											node0:Int, node1:Int, complete_primitive_tests:Bool):Bool
	{
        var box0:AABB = new AABB();
        boxset0.getNodeBound(node0, box0);
        var box1:AABB = new AABB();
        boxset1.getNodeBound(node1, box1);

        return box0.overlapping_trans_cache(box1, trans_cache_1to0, complete_primitive_tests);
        //box1.appy_transform_trans_cache(trans_cache_1to0);
        //return box0.has_collision(box1);
    }

    /**
     * Stackless recursive collision routine.
     */
    private static function _find_collision_pairs_recursive(boxset0:GImpactBvh, boxset1:GImpactBvh, collision_pairs:PairSet, trans_cache_1to0:BoxBoxTransformCache, node0:Int, node1:Int, complete_primitive_tests:Bool):Void
	{
        if (_node_collision(
                boxset0, boxset1, trans_cache_1to0,
                node0, node1, complete_primitive_tests) == false) 
		{
            return;//avoid colliding internal nodes
        }
        if (boxset0.isLeafNode(node0)) 
		{
            if (boxset1.isLeafNode(node1))
			{
                // collision result
                collision_pairs.push_pair(boxset0.getNodeData(node0), boxset1.getNodeData(node1));
                return;
            } 
			else
			{
                // collide left recursive
                _find_collision_pairs_recursive(
                        boxset0, boxset1,
                        collision_pairs, trans_cache_1to0,
                        node0, boxset1.getLeftNode(node1), false);

                // collide right recursive
                _find_collision_pairs_recursive(
                        boxset0, boxset1,
                        collision_pairs, trans_cache_1to0,
                        node0, boxset1.getRightNode(node1), false);
            }
        }
		else
		{
            if (boxset1.isLeafNode(node1))
			{
                // collide left recursive
                _find_collision_pairs_recursive(
                        boxset0, boxset1,
                        collision_pairs, trans_cache_1to0,
                        boxset0.getLeftNode(node0), node1, false);


                // collide right recursive
                _find_collision_pairs_recursive(
                        boxset0, boxset1,
                        collision_pairs, trans_cache_1to0,
                        boxset0.getRightNode(node0), node1, false);
            }
			else
			{
                // collide left0 left1
                _find_collision_pairs_recursive(
                        boxset0, boxset1,
                        collision_pairs, trans_cache_1to0,
                        boxset0.getLeftNode(node0), boxset1.getLeftNode(node1), false);

                // collide left0 right1
                _find_collision_pairs_recursive(
                        boxset0, boxset1,
                        collision_pairs, trans_cache_1to0,
                        boxset0.getLeftNode(node0), boxset1.getRightNode(node1), false);

                // collide right0 left1
                _find_collision_pairs_recursive(
                        boxset0, boxset1,
                        collision_pairs, trans_cache_1to0,
                        boxset0.getRightNode(node0), boxset1.getLeftNode(node1), false);

                // collide right0 right1
                _find_collision_pairs_recursive(
                        boxset0, boxset1,
                        collision_pairs, trans_cache_1to0,
                        boxset0.getRightNode(node0), boxset1.getRightNode(node1), false);

            } // else if node1 is not a leaf
        } // else if node0 is not a leaf
    }

    //public static float getAverageTreeCollisionTime();

    public static function find_collision(boxset0:GImpactBvh, trans0:Transform, boxset1:GImpactBvh, trans1:Transform, collision_pairs:PairSet):Void
	{
        if (boxset0.getNodeCount() == 0 || boxset1.getNodeCount() == 0) 
		{
            return;
        }
        var trans_cache_1to0:BoxBoxTransformCache = new BoxBoxTransformCache();

        trans_cache_1to0.calc_from_homogenic(trans0, trans1);

        //#ifdef TRI_COLLISION_PROFILING
        //bt_begin_gim02_tree_time();
        //#endif //TRI_COLLISION_PROFILING

        _find_collision_pairs_recursive(
                boxset0, boxset1,
                collision_pairs, trans_cache_1to0, 0, 0, true);

        //#ifdef TRI_COLLISION_PROFILING
        //bt_end_gim02_tree_time();
        //#endif //TRI_COLLISION_PROFILING
    }
	
}