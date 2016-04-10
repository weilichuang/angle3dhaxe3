package com.bulletphysics.collision.gimpact ;
import com.bulletphysics.collision.gimpact.BoxCollision.AABB;
import com.bulletphysics.linearmath.LinearMathUtil;
import de.polygonal.ds.error.Assert;
import org.angle3d.math.Vector3f;

/**
 * ...
 
 */
class BvhTree
{

	private var num_nodes:Int = 0;
    private var node_array:BvhTreeNodeArray = new BvhTreeNodeArray();
	
	public function new()
	{
		
	}

    private function _calc_splitting_axis(primitive_boxes:BvhDataArray, startIndex:Int, endIndex:Int):Int
	{
        var means:Vector3f = new Vector3f();
        means.setTo(0, 0, 0);
        var variance:Vector3f = new Vector3f();
        variance.setTo(0, 0, 0);

        var numIndices:Int = endIndex - startIndex;

        var center:Vector3f = new Vector3f();
        var diff2:Vector3f = new Vector3f();

        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        for (i in startIndex...endIndex)
		{
            primitive_boxes.getBoundMax(i, tmp1);
            primitive_boxes.getBoundMin(i, tmp2);
            center.addBy(tmp1, tmp2);
            center.scaleLocal(0.5);
            means.addLocal(center);
        }
        means.scaleLocal(1 / numIndices);

        for (i in startIndex...endIndex)
		{
            primitive_boxes.getBoundMax(i, tmp1);
            primitive_boxes.getBoundMin(i, tmp2);
            center.addBy(tmp1, tmp2);
            center.scaleLocal(0.5);
            diff2.subtractBy(center, means);
            LinearMathUtil.mul(diff2, diff2, diff2);
            variance.addLocal(diff2);
        }
        variance.scaleLocal(1 / (numIndices - 1));

        return LinearMathUtil.maxAxis(variance);
    }

    private function _sort_and_calc_splitting_index(primitive_boxes:BvhDataArray, startIndex:Int, endIndex:Int, splitAxis:Int):Int
	{
        var splitIndex:Int = startIndex;
        var numIndices:Int = endIndex - startIndex;

        // average of centers
        var splitValue:Float = 0.0;

        var means:Vector3f = new Vector3f();
        means.setTo(0, 0, 0);

        var center:Vector3f = new Vector3f();

        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        for (i in startIndex...endIndex)
		{
            primitive_boxes.getBoundMax(i, tmp1);
            primitive_boxes.getBoundMin(i, tmp2);
            center.addBy(tmp1, tmp2);
            center.scaleLocal(0.5);
            means.addLocal(center);
        }
        means.scaleLocal(1 / numIndices);

        splitValue = LinearMathUtil.getCoord(means, splitAxis);

        // sort leafNodes so all values larger then splitValue comes first, and smaller values start from 'splitIndex'.
        for (i in startIndex...endIndex)
		{
            primitive_boxes.getBoundMax(i, tmp1);
            primitive_boxes.getBoundMin(i, tmp2);
            center.addBy(tmp1, tmp2);
            center.scaleLocal(0.5);

            if (LinearMathUtil.getCoord(center, splitAxis) > splitValue) 
			{
                // swap
                primitive_boxes.swap(i, splitIndex);
                //swapLeafNodes(i,splitIndex);
                splitIndex++;
            }
        }

        // if the splitIndex causes unbalanced trees, fix this by using the center in between startIndex and endIndex
        // otherwise the tree-building might fail due to stack-overflows in certain cases.
        // unbalanced1 is unsafe: it can cause stack overflows
        //bool unbalanced1 = ((splitIndex==startIndex) || (splitIndex == (endIndex-1)));

        // unbalanced2 should work too: always use center (perfect balanced trees)
        //bool unbalanced2 = true;

        // this should be safe too:
        var rangeBalancedIndices:Int = Std.int(numIndices / 3);
        var unbalanced:Bool = ((splitIndex <= (startIndex + rangeBalancedIndices)) || (splitIndex >= (endIndex - 1 - rangeBalancedIndices)));

        if (unbalanced)
		{
            splitIndex = startIndex + (numIndices >> 1);
        }

        var unbal:Bool = (splitIndex == startIndex) || (splitIndex == (endIndex));
        Assert.assert (!unbal);

        return splitIndex;
    }

    private function _build_sub_tree(primitive_boxes:BvhDataArray, startIndex:Int, endIndex:Int):Void
	{
        var curIndex:Int = num_nodes;
        num_nodes++;

        Assert.assert ((endIndex - startIndex) > 0);

        if ((endIndex - startIndex) == 1)
		{
            // We have a leaf node
            //setNodeBound(curIndex,primitive_boxes[startIndex].m_bound);
            //m_node_array[curIndex].setDataIndex(primitive_boxes[startIndex].m_data);
            node_array.setDataArray(curIndex, primitive_boxes, startIndex);

            return;
        }
        // calculate Best Splitting Axis and where to split it. Sort the incoming 'leafNodes' array within range 'startIndex/endIndex'.

        // split axis
        var splitIndex:Int = _calc_splitting_axis(primitive_boxes, startIndex, endIndex);

        splitIndex = _sort_and_calc_splitting_index(primitive_boxes, startIndex, endIndex, splitIndex);

        //calc this node bounding box

        var node_bound:AABB = new AABB();
        var tmpAABB:AABB = new AABB();

        node_bound.invalidate();

        for (i in startIndex...endIndex)
		{
            primitive_boxes.getBound(i, tmpAABB);
            node_bound.merge(tmpAABB);
        }

        setNodeBound(curIndex, node_bound);

        // build left branch
        _build_sub_tree(primitive_boxes, startIndex, splitIndex);

        // build right branch
        _build_sub_tree(primitive_boxes, splitIndex, endIndex);

        node_array.setEscapeIndex(curIndex, num_nodes - curIndex);
    }

    public function build_tree(primitive_boxes:BvhDataArray):Void
	{
        // initialize node count to 0
        num_nodes = 0;
        // allocate nodes
        node_array.resize(primitive_boxes.size() * 2);

        _build_sub_tree(primitive_boxes, 0, primitive_boxes.size());
    }

    public function clearNodes():Void
	{
        node_array.clear();
        num_nodes = 0;
    }

    public function getNodeCount():Int 
	{
        return num_nodes;
    }

    /**
     * Tells if the node is a leaf.
     */
    public function isLeafNode(nodeindex:Int):Bool 
	{
        return node_array.isLeafNode(nodeindex);
    }

    public function getNodeData(nodeindex:Int):Int
	{
        return node_array.getDataIndex(nodeindex);
    }

    public function getNodeBound(nodeindex:Int,bound:AABB):Void 
	{
        node_array.getBound(nodeindex, bound);
    }

    public function setNodeBound(nodeindex:Int, bound:AABB):Void 
	{
        node_array.setBound(nodeindex, bound);
    }

    public function getLeftNode(nodeindex:Int):Int
	{
        return nodeindex + 1;
    }

    public function getRightNode(nodeindex:Int):Int 
	{
        if (node_array.isLeafNode(nodeindex + 1)) 
		{
            return nodeindex + 2;
        }
        return nodeindex + 1 + node_array.getEscapeIndex(nodeindex + 1);
    }

    public function getEscapeNodeIndex(nodeindex:Int):Int 
	{
        return node_array.getEscapeIndex(nodeindex);
    }

    public function get_node_pointer():BvhTreeNodeArray
	{
        return node_array;
    }
	
}