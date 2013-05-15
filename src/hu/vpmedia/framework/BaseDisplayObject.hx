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
package hu.vpmedia.framework;

import flash.display.DisplayObject;
import flash.display.Stage;
import flash.display.Sprite;
import flash.events.Event;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */
class BaseDisplayObject implements IBaseTransformable
{
    var _width:Float;
    var _height:Float;    
    var _canvas:Sprite;
    
    public var stage(get_stage, null):Stage;
    public var width(get_width, set_width):Float;
    public var height(get_height, set_height):Float;
    public var rotation(get_rotation, set_rotation):Float;
    public var canvas(get_canvas, null):Sprite;
    public var x(get_x, set_x):Float;
    public var y(get_y, set_y):Float;
    
    //----------------------------------
    //  Constructor
    //----------------------------------
    
    public function new()
    {
        _canvas = new Sprite();
        _canvas.addEventListener(Event.ADDED_TO_STAGE, onAdded, false, 0, true);
    }  
    
  public function onAdded(event:Event):Void
  {
        _canvas.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
        _canvas.addEventListener(Event.REMOVED_FROM_STAGE, onRemoved, false, 0, true);
        addChilds();
  }
  
  public function onRemoved(event:Event):Void
  {
        _canvas.removeEventListener(Event.ADDED_TO_STAGE, onRemoved);
        removeChilds();
  }
    
    //----------------------------------
    //  getter/setter
    //----------------------------------
  
  public function get_canvas():Sprite
  {
      return _canvas;
  }
      
  public function addChild(child:DisplayObject):DisplayObject
  {
      return _canvas.addChild(child);
  }      
  
  public function removeChild(child:DisplayObject):Void
  {
      _canvas.removeChild(child);
  }      
    
  public function addEventListener(type:String, handler:Dynamic->Void):Void
  {
      _canvas.addEventListener(type,handler,false,0,true);
  }
  
  public function removeEventListener(type:String, handler:Dynamic->Void):Void
  {
      _canvas.removeEventListener(type,handler);
  }
  
  public function addStageEventListener(type:String, handler:Dynamic->Void):Void
  {
      _canvas.stage.addEventListener(type,handler,false,0,true);
  }
  
  public function removeStageEventListener(type:String, handler:Dynamic->Void):Void
  {
      _canvas.stage.removeEventListener(type,handler);
  }
      
  public function move(x:Float,y:Float):Void
  {  
    _canvas.x = x;
    _canvas.y = y;        
  }
  
  public function setSize(width:Float,height:Float):Void
  {  
    this.width = width;
    this.height = height;  
    //invalidate(ComponentChange.SIZE);
  }
  
  public function addChilds():Void
  {
      //abstract
  }
  
  public function removeChilds():Void
  {  
      while (_canvas.numChildren > 0)
      {
          _canvas.removeChildAt(0);
      } 
  }
  
  public function removeFromParent():Bool
  {
      if (_canvas.parent != null && _canvas.parent.contains(_canvas))
      {
          _canvas.parent.removeChild(_canvas);
          return true;
      }
      return false;
  }      
  
  function get_width():Float
  {
    return _width;
  }
  
  function set_width(value:Float):Float
  {
    //invalidate(ComponentChange.SIZE);
    return _width=value;
  }
  
  //
  function get_height():Float
  {
    return _height;
  }
  
  function set_height(value:Float):Float
  {
    //invalidate(ComponentChange.SIZE);
    return _height=value;
  }
  
  //
    
    function get_x ():Float 
    {        
        return canvas.x;        
    }    
    
    function set_x (value:Float):Float 
    {        
        canvas.x = value;        
        return canvas.x;        
    }    
    
    function get_y ():Float 
    {        
        return canvas.y;        
    }
    
    function set_y (value:Float):Float {
        
        canvas.y = value;        
        return canvas.y;        
    }
    
    function get_rotation ():Float 
    {        
        return canvas.rotation;        
    }
    
    function set_rotation (value:Float):Float {
        
        canvas.rotation = value;        
        return canvas.rotation;        
    }
    
    function get_stage ():Stage 
    {    
        return _canvas.stage;
    }
    
}