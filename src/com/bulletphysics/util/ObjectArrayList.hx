package com.bulletphysics.util;
import haxe.ds.Vector;

/**
 * ...
 * @author weilichuang
 */
@:generic
class ObjectArrayList<T>
{
	private var array:Vector<T>;
	private var _size:Int;

	public function new(initialCapacity:Int = 16) 
	{
		this.array = new Vector<T>(initialCapacity);
		this._size = 0;
	}
	
	public function resize(newSize:Int, valueCls:Class<T>):Void
	{
		while (this.size() < newSize)
		{
			this.add(valueCls != null ? Type.createInstance(valueCls, []) : null);
		}
		
		while (this.size() > newSize)
		{
			this.removeQuick(this.size() - 1);
		}
	}
	
	public function downHeap(k:Int, n:Int, comparator:T->T->Int):Void
	{
		// PRE: a[k+1..N] is a heap 
		// POST:  a[k..N]  is a heap 
		var temp:T = this.getQuick(k - 1);
		//k has child(s) 
		while (k <= n / 2) 
		{
			var child:Int = 2 * k;
			if ((child < n) && comparator(this.getQuick(child - 1), this.getQuick(child)) < 0) 
				child++;
				
			// pick larger child 
			if (comparator(temp, this.getQuick(child - 1)) < 0) 
			{
				//  move child up 
				this.setQuick(k - 1, this.getQuick(child - 1));
				k = child;
			} 			
			else 
			{
				break;
			}
		}
		this.setQuick(k - 1, temp);
	}
	
	/**
     * Sorts list using heap sort.<p>
     * <p/>
     * Implementation from: http://www.csse.monash.edu.au/~lloyd/tildeAlgDS/Sort/Heap/
     */
	public function heapSort(comparator:T->T->Int):Void
	{
		/* sort a[0..N-1],  N.B. 0 to N-1 */
        
        var n:Int = this.size();
		var k:Int = Std.int(n / 2);
        while (k > 0) 
		{
            downHeap(k, n, comparator);
			k--;
        }

		/* a[1..N] is now a heap */
        while (n >= 1) 
		{
            swap(0, n - 1); /* largest of a[0..n-1] */

            n = n - 1;
			/* restore a[1..i-1] heap */
            downHeap(1, n, comparator);
        }
	}
	
	public function quickSort(comparator:T->T->Int):Void
	{
		//dont sort 0 or 1 elements
		if (this.size() > 1)
		{
			quickSortInternal(comparator, 0, this.size() - 1);
		}
	}
	
	public function quickSortInternal(comparator:T->T->Int, lo:Int, hi:Int):Void
	{
		// lo is the lower index, hi is the upper index
        // of the region of array a that is to be sorted
        var i:Int = lo, j:Int = hi;
        var x:T = this.getQuick(Std.int((lo + hi) / 2));

        // partition
        do 
		{
            while (comparator(this.getQuick(i), x) < 0) i++;
            while (comparator(x, this.getQuick(j)) < 0) j--;

            if (i <= j)
			{
                swap(i, j);
                i++;
                j--;
            }
        } while (i <= j);

        // recursion
        if (lo < j)
		{
            quickSortInternal(comparator, lo, j);
        }
		
        if (i < hi)
		{
            quickSortInternal(comparator, i, hi);
        }
	}
	
	public function swap(index0:Int, index1:Int):Void
	{
		var temp:T = this.getQuick(index0);
        this.setQuick(index0, this.getQuick(index1));
        this.setQuick(index1, temp);
	}
	
	public function add(value:T):Bool
	{
		if (_size == array.length)
		{
			expand();
		}
		
		array[_size++] = value;
		return true;
	}
	
	public function insert(index:Int, value:T):Void
	{
		if (_size == array.length)
		{
			expand();
		}
		
		var num:Int = _size - index;
		if (num > 0)
		{
			Vector.blit(array, index, array, index + 1, num);
		}
		
		array[index] = value;
		_size++;
	}
	
	private function expand():Void
	{
		var newArray:Vector<T> = new Vector<T>(array.length << 1);
		Vector.blit(array, 0, newArray, 0, array.length);
		array = newArray;
	}
	
	public function removeObject(object:T):Void
	{
		var index:Int = -1;
		for (i in 0..._size)
		{
			if (array[i] == object)
			{
				index = i;
				break;
			}
		}
		
		if (index != -1)
			remove(index);
	}
	
	public function remove(index:Int):T
	{
		if (index < 0 || index >= _size) 
			throw "IndexOutOfBoundsException";
		
		var prev:T = array[index];
		
		Vector.blit(array, index + 1, array, index, _size - index - 1);
		array[_size-1] = null;
		_size--;
		return prev;
	}
	
	public function removeQuick(index:Int):Void
	{
		Vector.blit(array, index + 1, array, index, _size - index - 1);
		array[_size-1] = null;
		_size--;
	}
	
	public function get(index:Int):T
	{
		if (index < 0 || index >= _size) 
			throw "IndexOutOfBoundsException";
		return array[index];
	}
	
	public function getQuick(index:Int):T
	{
		return array[index];
	}
	
	public function set(index:Int, value:T):T
	{
		if (index < 0 || index >= _size) 
			throw "IndexOutOfBoundsException";
			
		var old:T = array[index];
		array[index] = value;
		return old;
	}
	
	public function setQuick(index:Int, value:T):Void
	{
		array[index] = value;
	}
	
	public function size():Int
	{
		return _size;
	}
	
	public function capacity():Int
	{
		return array.length;
	}
	
	//TODO clear不清除元素的吗？
	public function clear():Void
	{
		_size = 0;
	}
	
	public function indexOf(obj:T):Int
	{
        for (i in 0..._size) 
		{
            if (obj == null ? array[i] == null : (obj == array[i]))
			{
                return i;
            }
        }
        return -1;
	}
	
}