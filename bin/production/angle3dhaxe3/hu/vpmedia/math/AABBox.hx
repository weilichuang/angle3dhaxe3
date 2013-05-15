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
package hu.vpmedia.math;

class AABBox
{
    public var left:Float;
    public var right:Float;
    public var top:Float;
    public var bottom:Float;
    public var width:Float;
    public var height:Float;
    public var halfWidth:Float;
    public var halfHeight:Float;
    public var topLeft:Vector2D;
    public var topRight:Vector2D;
    public var bottomRight:Vector2D;
    public var bottomLeft:Vector2D;
    public var center:Vector2D;
    
    public function new(center:Vector2D, width:Float, height:Float)
    {
        this.center=new Vector2D(center.x, center.y);
        this.width=width;
        this.height=height;
        halfWidth=width / 2;
        halfHeight=height / 2;
        left=center.x - halfWidth;
        right=center.x + halfWidth;
        top=center.y - halfHeight;
        bottom=center.y + halfHeight;
        topLeft=new Vector2D(left, top);
        topRight=new Vector2D(right, top);
        bottomRight=new Vector2D(right, bottom);
        bottomLeft=new Vector2D(left, bottom);
    }
    
    public function setAll(center:Vector2D, width:Float, height:Float):Void
    {
        this.center=center.copy();
        setSize(width, height);
    }
    
    public function setSize(width:Float, height:Float):Void
    {
        this.width=width;
        this.height=height;
        halfWidth=width * 0.5; // ? >> 1
        halfHeight=height * 0.5;
        updateBounds();
    }
    
    public function moveTo(point:Vector2D):Void
    {
        center.x=point.x;
        center.y=point.y;
        updateBounds();
    }
    
    public function isOverlapping(box:AABBox):Bool
    {
        return !((box.top > bottom) || (box.bottom < top) || (box.left > right) || (box.right < left));
    }
    
    function updateBounds():Void
    {
        left=center.x - halfWidth;
        right=center.x + halfWidth;
        top=center.y - halfHeight;
        bottom=center.y + halfHeight;
        topLeft.x=left;
        topLeft.y=top;
        topRight.x=right;
        topRight.y=top;
        bottomRight.x=right;
        bottomRight.y=bottom;
        bottomLeft.x=left;
        bottomLeft.y=bottom;
    }
}