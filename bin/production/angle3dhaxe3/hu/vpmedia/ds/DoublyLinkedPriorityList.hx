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
class DoublyLinkedPriorityList<T:(IDoublyLinkedListNode<T>,IPriorityListNode)>
{
    public var head:T;
    public var tail:T;

    public function new() 
    {
        
    }                

    public function add( data : T ) : Void
    {
            if( head == null )
            {
                head = tail = data;
                data.next = data.prev = null;
            }
            else
            {
                var node:T = tail;
                while( node!=null  )
                {
                    if( node.priority <= data.priority )
                    {
                        break;
                    }
                    node = node.prev;
                }
                if( node == tail )
                {
                    tail.next = data;
                    data.prev = tail;
                    data.next = null;
                    tail = data;
                }
                else if( node == null )
                {
                    data.next = head;
                    data.prev = null;
                    head.prev = data;
                    head = data;
                }
                else
                {
                    data.next = node.next;
                    data.prev = node;
                    node.next.prev = data;
                    node.next = data;
                }
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
    
        
    
}