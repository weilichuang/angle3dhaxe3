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
	private var arraySize:Int;
	
	private var _size:Int;

	public function new(initialCapacity:Int = 16) 
	{
		this.array = new Vector<T>(initialCapacity);
		this.arraySize = initialCapacity;
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
			removeQuick(this.size() - 1);
		}
	}
	
	public function downHeap(k:Int, n:Int, comparator:T->T->Int):Void
	{
		// PRE: a[k+1..N] is a heap 
		// POST:  a[k..N]  is a heap 
		var temp:T = getQuick(k - 1);
		//k has child(s) 
		while (k <= n / 2) 
		{
			var child:Int = 2 * k;
			if ((child < n) && comparator(getQuick(child - 1), getQuick(child)) < 0) 
				child++;
				
			// pick larger child 
			if (comparator(temp, getQuick(child - 1)) < 0) 
			{
				//  move child up 
				setQuick(k - 1, getQuick(child - 1));
				k = child;
			} 			
			else 
			{
				break;
			}
		}
		setQuick(k - 1, temp);
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
        var x:T = array[Std.int((lo + hi) * 0.5)];

        // partition
        do 
		{
            while (comparator(array[i], x) < 0) i++;
            while (comparator(x, array[j]) < 0) j--;

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
	
	public inline function swap(index0:Int, index1:Int):Void
	{
		var temp:T = getQuick(index0);
        setQuick(index0, getQuick(index1));
        setQuick(index1, temp);
	}
	
	public function add(value:T):Bool
	{
		if (_size == arraySize)
		{
			expand();
		}
		
		array[_size++] = value;
		return true;
	}
	
	public function insert(index:Int, value:T):Void
	{
		if (_size == arraySize)
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
		var oldLen:Int = array.length;
		arraySize = oldLen << 1;
		var newArray:Vector<T> = new Vector<T>(arraySize);
		Vector.blit(array, 0, newArray, 0, oldLen);
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
		#if debug
		if (index < 0 || index >= _size) 
			throw "IndexOutOfBoundsException";
		#end
		
		var prev:T = array[index];
		
		Vector.blit(array, index + 1, array, index, _size - index - 1);
		array[_size - 1] = null;
		_size--;
		return prev;
	}
	
	public function removeQuick(index:Int):Void
	{
		Vector.blit(array, index + 1, array, index, _size - index - 1);
		array[_size-1] = null;
		_size--;
	}
	
	public inline function get(index:Int):T
	{
		#if debug
		if (index < 0 || index >= _size) 
			throw "IndexOutOfBoundsException";
		#end
		return array[index];
	}
	
	public inline function getQuick(index:Int):T
	{
		return array[index];
	}
	
	public inline function set(index:Int, value:T):T
	{
		#if debug
		if (index < 0 || index >= _size) 
			throw "IndexOutOfBoundsException";
		#end
			
		var old:T = array[index];
		array[index] = value;
		return old;
	}
	
	public inline function setQuick(index:Int, value:T):Void
	{
		array[index] = value;
	}
	
	public inline function size():Int
	{
		return _size;
	}
	
	public inline function capacity():Int
	{
		return arraySize;
	}
	
	//TODO clear不清除元素的吗？
	public inline function clear():Void
	{
		_size = 0;
	}
	
	public function contains(obj:T):Bool
	{
		if (obj == null)
			return false;
			
		var index:Int = -1;
		for (i in 0..._size) 
		{
            if (obj == array[i])
			{
                index = i;
				break;
            }
        }
        return index != -1;
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