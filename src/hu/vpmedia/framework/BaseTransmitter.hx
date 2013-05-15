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
class BaseTransmitter implements IBaseTransmitter
{        
    public var signal:Signal;
     
    //----------------------------------
    //  Constructor
    //----------------------------------
    /**
     * Constructor.
     */
    public function new()
    {   
        signal = new Signal(); 
    } 
    
    public function initialize():Void
    { 
    }
    
    public function dispose():Void
    {  
        if (signal != null)
        {
            signal.removeAll();
            signal = null;
        }
    }
    
    public function sendTransmission(code:String, ?data:Dynamic=null, ?level:String=null, ?source:IBaseTransmitter=null):Void
    {
        if(source == null)
        {
            source = this; // TODO: test this
        }
        signal.dispatch([ code, data, level, source ]);
    }
}