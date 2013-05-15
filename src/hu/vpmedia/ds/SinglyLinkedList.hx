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
class SinglyLinkedList<T:ISinglyLinkedListNode<T>>
{
    public var head:T;

    public function new() 
    {
        
    }

    public function add( node : T ) : Void
    {
        node.next = head;
        head = node;
    }       

    public function remove( node : T ) : Bool
    {
        var prev:T;
        var n:T = node;
    
        if (n == head) {
            head = node.next;
            //n.next = null; 
            return true;
        }
        prev = n;
        n = n.next;

        while (n != null) {
            if (n== node) {
                
                break;
            }
            prev = n;
            n = n.next;
        }
        if (n == null) return false;
        
        prev.next = n.next;
        //n.next = null; 
        return true;
    }
    
    public function removeAll() : Void
    {
        while( head!=null )
        {
            var node : T = head;
            head = node.next;
            node.next = null;
        }
    }
    
}