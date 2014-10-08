package com.bulletphysics.collision.dispatch;
import com.bulletphysics.linearmath.MiscUtil;
import com.bulletphysics.util.ObjectArrayList;

class Element {
	public var id:Int;
	public var sz:Int;
	
	public function new()
	{
		
	}
}
/**
 * UnionFind calculates connected subsets. Implements weighted Quick Union with
 * path compression.
 * @author weilichuang
 */
class UnionFind
{
	public static function elementComparator(o1:Element, o2:Element):Int
	{
		return o1.id < o2.id ? -1 : 1;
	}

	private var elements:ObjectArrayList<Element> = new ObjectArrayList<Element>();

    /**
     * This is a special operation, destroying the content of UnionFind.
     * It sorts the elements, based on island id, in order to make it easy to iterate over islands.
     */
    public function sortIslands():Void
	{
        // first store the original body index, and islandId
        var numElements:Int = elements.size();

        for (i in 0...numElements)
		{
            elements.getQuick(i).id = find(i);
            elements.getQuick(i).sz = i;
        }

        // Sort the vector using predicate and std::sort
        //std::sort(m_elements.begin(), m_elements.end(), btUnionFindElementSortPredicate);
        //perhaps use radix sort?
        //elements.heapSort(btUnionFindElementSortPredicate());

        //Collections.sort(elements);
        elements.quickSort(UnionFind.elementComparator);
    }

    public function reset(N:Int):Void
	{
        allocate(N);

        for (i in 0...N) 
		{
            elements.getQuick(i).id = i;
            elements.getQuick(i).sz = 1;
        }
    }

    public function getNumElements():Int
	{
        return elements.size();
    }

    public function isRoot(x:Int):Bool
	{
        return (x == elements.getQuick(x).id);
    }

    public function getElement(index:Int):Element
	{
        return elements.getQuick(index);
    }

    public function allocate(N:Int):Void
	{
        elements.resize(N, Element);
    }

    public function free():Void
	{
        elements.clear();
    }

    public function find2(p:Int, q:Int):Int
	{
        return (find(p) == find(q)) ? 1 : 0;
    }

    public function unite( p:Int, q:Int):Void
	{
        var i:Int = find(p);
		var j:Int = find(q);
        if (i == j) 
		{
            return;
        }

        //#ifndef USE_PATH_COMPRESSION
        ////weighted quick union, this keeps the 'trees' balanced, and keeps performance of unite O( log(n) )
        //if (m_elements[i].m_sz < m_elements[j].m_sz)
        //{
        //	m_elements[i].m_id = j; m_elements[j].m_sz += m_elements[i].m_sz;
        //}
        //else
        //{
        //	m_elements[j].m_id = i; m_elements[i].m_sz += m_elements[j].m_sz;
        //}
        //#else
        elements.getQuick(i).id = j;
        elements.getQuick(j).sz += elements.getQuick(i).sz;
        //#endif //USE_PATH_COMPRESSION
    }

    public function find(x:Int):Int
	{
        //assert(x < m_N);
        //assert(x >= 0);

        while (x != elements.getQuick(x).id)
		{
            // not really a reason not to use path compression, and it flattens the trees/improves find performance dramatically

            //#ifdef USE_PATH_COMPRESSION
            elements.getQuick(x).id = elements.getQuick(elements.getQuick(x).id).id;
            //#endif //
            x = elements.getQuick(x).id;
            //assert(x < m_N);
            //assert(x >= 0);
        }
        return x;
    }
	
}