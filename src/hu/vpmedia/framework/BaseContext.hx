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
             
import hu.vpmedia.framework.IBaseTransmitter;
import hu.vpmedia.framework.BaseTransmitter;
import flash.events.Event;
import flash.display.DisplayObjectContainer;
import hu.vpmedia.signals.SignalLite;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */                      
class BaseContext<M:IBaseTransmitter,V:BaseView<M,C>,C:BaseController<M,V>> implements IBaseContext implements IBaseTransmitter
{       
    public var context:DisplayObjectContainer;  
    public var model:M;
    public var view:V;
    public var controller:C; 
    public var parent:BaseContext<Dynamic,Dynamic,Dynamic>;
    public var signal:Signal;
        
    //----------------------------------
    //  Constructor
    //----------------------------------
    
    public function new(context:DisplayObjectContainer,model:M,view:V,controller:C)
    {                   
        this.context = context;    
        this.model = model;    
        this.view = view;    
        this.controller = controller;
        view.model = model;    // view listens to model changes    
        view.controller = controller; // view connected to controller
        controller.view = view; // controller connected to view 
        controller.model = model; // controller connected to model
        signal = model.signal; // shared signal bus
    }
    
    public function dispose()
    {        
        if (signal != null)
        {
            signal.removeAll();
            signal = null;
        }
        view.removeFromParent();
    } 
        
    public function initialize()
    {         
        if (context != null && view != null)
        {
            context.addChild(view.canvas);
        }
    } 
}
