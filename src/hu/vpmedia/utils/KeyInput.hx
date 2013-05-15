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

import flash.events.KeyboardEvent;
import flash.events.TouchEvent;
import flash.Lib;
#if mobile
import flash.ui.Acceleration;
import flash.ui.Accelerometer;        
import flash.ui.Multitouch;
import flash.ui.MultitouchInputMode;
#end

class KeyInput {

    static inline public var JUST_PRESSED:Int = 0;
    static inline public var DOWN:Int = 1;
    static inline public var JUST_RELEASED:Int = 2;
    static inline public var UP:Int = 3;

    public var enabled(get_enabled, set_enabled):Bool;
    public var jumpTouch(get_jumpTouch, null):Bool;
    public var accelerometerXDirection(get_accelerometerXDirection, null):String;

    private var _keys:Map<Int, Int>;
    private var _keysReleased:Array<Int>;
    private var _isInitialized:Bool;

    #if mobile
        private var _acceleration:Acceleration;
    #end

    private var _firstJumpTouch:Bool;

    var _enabled:Bool;
    var _jumpTouch:Bool;
    var _accelerometerXDirection:String;

    public function new() {

        #if mobile
        Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
        #end        

        _keys = new Map();
        _keysReleased = new Array<Int>();
        initialize();
    }

    public function initialize():Void {

        if (_isInitialized)
            return;

        _isInitialized = true;
                                 
        set_enabled(true);
    }
    
    public function dispose():Void 
    {       
        set_enabled(false);
    }

    public function step(timeDelta:Float):Void {

        if (!_enabled)
            return;

        #if mobile

            _acceleration =  Accelerometer.get();

            if (_acceleration != null) {

                #if landscape

                    if (_acceleration.y > 0.3)
                        _accelerometerXDirection = "right";
                    else if (_acceleration.y < -0.3)
                        _accelerometerXDirection = "left";
                    else
                        _accelerometerXDirection = "immobile";

                #elseif portrait 

                    if (_acceleration.x > 0.3)
                        _accelerometerXDirection = "right";
                    else if (_acceleration.x < -0.3)
                        _accelerometerXDirection = "left";
                    else
                        _accelerometerXDirection = "immobile";

                #end
            }

        #elseif (flash || desktop)

            for (key in _keys.keys()) {

                if (_keys.get(key) == JUST_PRESSED) {
                    _keys.set(key, DOWN);
                }
            }

            _keysReleased = [];

        #end
    }

    /**
     * @param keyCode a "code" representing a key on the keyboard. Use haXe NME's Keyboard class constants if you please.
     * @return Says YES! if the key you requested is being pressed. Says no if not.
     */
    public function isDown(keyCode:Int):Bool {
        return _keys.get(keyCode) == DOWN;
    }

    /**
     * @param keyCode a "code" representing a key on the keyboard. Use haXe NME's Keyboard class constants if you please.
     * @return Says YES! if the key you requested was pressed between last tick and this tick. Says no if not.
     */
     public function justPressed(keyCode:Int):Bool {
         return _keys.get(keyCode) == JUST_PRESSED;
     }

     /**
     * @param keyCode a "code" representing a key on the keyboard. Use haXe NME's Keyboard class constants if you please.
     * @return Says YES! if the key you requested was released between last keick and this tick. Says no if not.
     */
     public function justReleased(keyCode:Int):Bool {
         return Lambda.indexOf(_keysReleased, keyCode) != -1;
     }

     /**
      * @return Says Yes if the user just pressed on the phone
      */
     public function justJumpTouched():Bool {

        if (_jumpTouch && _firstJumpTouch) {

            _firstJumpTouch = false;
            return true;
        }

        return false;
    }

    /**
     * @return Says Yes if the user still press on his phone
     */
    public function get_jumpTouch():Bool {
        return _jumpTouch;
    }

    /**
     * @return a string with the X direction guessed by the accelerometer
     */
    public function get_accelerometerXDirection():String {
        return _accelerometerXDirection;
    }

    function _onKeyDown(kEvt:KeyboardEvent):Void {

        if (_keys.get(kEvt.keyCode) == null) {
            _keys.set(kEvt.keyCode, JUST_PRESSED);
        }
            
    }

    function _onKeyUp(kEvt:KeyboardEvent):Void {

        _keys.remove(kEvt.keyCode);
        _keysReleased.push(kEvt.keyCode);
    }

    function _touchBegin(tEvt:TouchEvent):Void {
        _firstJumpTouch = _jumpTouch = true;
    }

    function _touchEnd(tEvt:TouchEvent):Void {
        _firstJumpTouch = _jumpTouch = false;
    }

    /**
     * Sets and determines whether or not keypresses will be
     * registered through the Input class. 
     */
    public function get_enabled():Bool {
        return _enabled;
    }

    public function set_enabled(value:Bool):Bool {

        if (_enabled == value)
            return _enabled;

        _enabled = value;

        if (_enabled) {

            #if (flash || desktop)
                Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown, false, 0, true);
                Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, _onKeyUp, false, 0, true);

            #elseif mobile
                Lib.current.stage.addEventListener(TouchEvent.TOUCH_BEGIN, _touchBegin, false, 0, true);
                Lib.current.stage.addEventListener(TouchEvent.TOUCH_END, _touchEnd, false, 0, true);
                
            #end

        } else {

            #if (flash || desktop)
                Lib.current.stage.removeEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown);
                Lib.current.stage.removeEventListener(KeyboardEvent.KEY_UP, _onKeyUp);

            #elseif mobile
                Lib.current.stage.removeEventListener(TouchEvent.TOUCH_BEGIN, _touchBegin);
                Lib.current.stage.removeEventListener(TouchEvent.TOUCH_END, _touchEnd);
                
            #end
        }

        return _enabled;
    }
}