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
       
import hu.vpmedia.signals.SignalLite;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */
class BaseView<M:IBaseTransmitter,C:IBaseController> extends BaseDisplayObject implements IBaseView
{   
    public var controller:C;
    public var model:M;
    public var parentView:IBaseView;  
    
    public var transitionInStart:Signal; 
    public var transitionOutStart:Signal;   
    public var transitionInComplete:Signal; 
    public var transitionOutComplete:Signal;  
            
    //----------------------------------
    //  Constructor
    //----------------------------------
    
    public function new() 
    {
        super();
        transitionInStart=new Signal();
        transitionOutStart=new Signal();
        transitionInComplete=new Signal();
        transitionOutComplete=new Signal();        
    }
    
    //----------------------------------
    //  Event management
    //----------------------------------
    
    override function addChilds():Void
    {     
        initialize();
        controller.initialize();
    }
    
    override function removeChilds():Void
    {              
        dispose();
        controller.dispose();        
        super.removeChilds();
    }
    
    //----------------------------------
    //  Lifecycle management
    //----------------------------------
        
    public function initialize():Void
    {            
        // abstract
    }
    
    public function dispose():Void
    {        
        // abstract
    }
    
    //----------------------------------
    //  Transition management
    //----------------------------------
    
    public function transitionIn():Void
    {        
        // abstract
        transitionInStart.dispatch();
        transitionInComplete.dispatch();
    }
    
    public function transitionOut():Void
    {        
        // abstract
        transitionOutStart.dispatch();
        transitionOutComplete.dispatch();
    }
}