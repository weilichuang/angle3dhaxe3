////////////////////////////////////////////////////////////////////////////////
//=BEGIN MIT LICENSE
//
// The MIT License
// 
// Copyright (c) 2012-2013 Andras Csizmadia
// http://www.vpmedia.eu
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//=END MIT LICENSE
////////////////////////////////////////////////////////////////////////////////

package hu.vpmedia.ds;

@:generic
class DoublyLinkedList<T:IDoublyLinkedListNode<T>>
{
    public var head:T;
    public var tail:T;

    public function new() 
    {
    }
      
    public function add( node : T ) : Void
    {
        if(  head != null )
        {
            tail.next = node;
            node.prev = tail;
            node.next = null;
            tail = node;
        }
        else
        {
            head = tail = node;
            node.next = node.prev = null;
        }
    }
    
    public function remove( node : T ) : Void
    {
        if ( head == node) head = head.next;
        if ( tail == node) tail = tail.prev;
    
        if (node.prev != null) node.prev.next = node.next;
        if (node.next != null) node.next.prev = node.prev;
    }
        

    public function removeAll() : Void
    {
        while( head!=null )
        {
            var node : T = head;
            head = node.next;
            
            node.prev = null;
            node.next = null;
        }
        tail = null;
    }
    
    public function iterator() : Iterator<T>
    {
        return new DoublyLinkedListIterator(head);
    }

    
    
    
}