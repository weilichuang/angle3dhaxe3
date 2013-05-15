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
package hu.vpmedia.utils;

import flash.display.Stage;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.Lib;

/**
 * Manages mouse input.
 */
class MouseInput 
{
    public var mouseDown:Bool;    
    public var mousePressed:Bool;
    public var mouseUp:Bool;
    public var mouseReleased:Bool;    
    public var mousePosition:Point;    
    public var mouseDelta:Int;    
    private var _isInitialized:Bool;
    
    public function new() {
        mouseUp=true;
        mouseDelta = 0;
        initialize();
    }
    public function initialize():Void 
    {
        if (_isInitialized) 
        {
            return;
        }
        
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel ,false, 0, true);
        
        mousePosition = new Point();
                        
        _isInitialized = true;
    }
    
    public function dispose():Void 
    {
        Lib.current.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        Lib.current.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        Lib.current.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
    }
        
    public var mouseX(get_mouseX, null):Int;
    
    public function get_mouseX():Int 
    {
        return Math.floor(mousePosition.x);
    }
            
    public var mouseY(get_mouseY, null):Int;
    
    public function get_mouseY():Int 
    {
        return Math.floor(mousePosition.y);
    }
        
    function onMouseDown(e:MouseEvent):Void 
    {
        if (!mouseDown) 
        {
            mouseDown = true;
            mouseUp = false;
            mousePressed = true;
            mouseReleased = false;
        }
    }
    
    function onMouseUp(e:MouseEvent):Void 
    {
        mouseDown = false;
        mouseUp = true;
        mousePressed = false;
        mouseReleased = true;
    }
    
    function onMouseWheel(e:MouseEvent):Void 
    {
        mouseDelta += e.delta;
    }
    
    public function reset():Void 
    {        
        mouseDown = false;
        mousePressed = false;
        mouseUp = true;
        mouseReleased = false;
    }
    
    public function step(timeDelta:Float):Void 
    {
        mousePosition.x = Lib.current.stage.mouseX;
        mousePosition.y = Lib.current.stage.mouseY;
    }
    
    public function afterUpdate():Void 
    {
        if (mousePressed)
        {
            mousePressed = false;
        }
        if (mouseReleased)
        {
            mouseReleased = false;
        }
        
        mouseDelta = 0;
    }
    

}