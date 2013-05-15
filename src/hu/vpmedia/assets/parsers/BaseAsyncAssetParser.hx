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
package hu.vpmedia.assets.parsers;

import flash.utils.ByteArray;
import hu.vpmedia.signals.SignalLite;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */
class BaseAsyncAssetParser extends BaseAssetParser
{
    public var completed:Signal;
    
    public var progressed:Signal;
    
    public var failed:Signal;
            
    private var _progress:Float=0;
    
    public function new()
    {
        completed=new Signal();
        progressed=new Signal();
        failed=new Signal();
        super();
    }
    
    public function parseAsync(value:ByteArray, params:Dynamic):Void
    {
    }
    
    public var progress(get, null):Float;
     private function get_progress():Float
    {
        return _progress;
    }
    
    override public function dispose():Void
    {
        super.dispose();
        
        if(completed != null)
            completed.removeAll();
        completed=null;
        
        if(progressed != null)
            progressed.removeAll();
        progressed=null;
        
        if(failed != null)
            failed.removeAll();
        failed=null;
    }
}