package com.bulletphysics.collision.dispatch;
import com.bulletphysics.linearmath.MiscUtil;
import com.bulletphysics.util.ObjectArrayList;
import de.polygonal.ds.error.Assert.assert;

@:final class Element 
{
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
	public function elementComparator(o1:Element, o2:Element):Int
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

		var element:Element;
        for (i in 0...numElements)
		{
			element = elements.getQuick(i);
            element.id = find(i);
            element.sz = i;
        }

        //看看有没有更快的排序
        elements.quickSort(elementComparator);
    }

    public function reset(N:Int):Void
	{
        allocate(N);

		var element:Element;
        for (i in 0...N) 
		{
			element = elements.getQuick(i);
            element.id = i;
            element.sz = 1;
        }
    }

    public inline function getNumElements():Int
	{
        return elements.size();
    }

    public inline function isRoot(x:Int):Bool
	{
        return (x == elements.getQuick(x).id);
    }

    public inline function getElement(index:Int):Element
	{
        return elements.getQuick(index);
    }

    public inline function allocate(N:Int):Void
	{
        elements.resize(N, Element);
    }

    public inline function free():Void
	{
        elements.clear();
    }

    public inline function find2(p:Int, q:Int):Int
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
		#if debug
        //assert(x < m_N);
        assert(x >= 0);
		#end
		
		var element:Element = elements.getQuick(x);
        while (x != element.id)
		{
            // not really a reason not to use path compression, and it flattens the trees/improves find performance dramatically

            //#ifdef USE_PATH_COMPRESSION
            element.id = elements.getQuick(element.id).id;
            //#endif //
            x = element.id;
			element = elements.getQuick(x);
			
			#if debug
            //assert(x < m_N);
            assert(x >= 0);
			#end
        }
        return x;
    }
	
}