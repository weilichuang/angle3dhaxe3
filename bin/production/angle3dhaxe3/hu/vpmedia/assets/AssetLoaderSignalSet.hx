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
package hu.vpmedia.assets;

import hu.vpmedia.signals.SignalLite;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */
class AssetLoaderSignalSet
{
    /**
     * Will dispatch load started signals
     */
    public var started:Signal;
    
    /**
     * Will dispatch load completed signals
     */
    public var completed:Signal;
    
    /**
     * Will dispatch load progressed signals
     */
    public var progressed:Signal;
    
    /**
     * Will dispatch load failed signals
     */
    public var failed:Signal;
    
    /**
     * Constructor
     */
    public function new()
    {
        started=new Signal();
        completed=new Signal();
        progressed=new Signal();
        failed=new Signal();
    }
    
    public function dispose():Void
    {
        started.removeAll();
        completed.removeAll();
        progressed.removeAll();
        failed.removeAll();
        started=null;
        completed=null;
        progressed=null;
        failed=null;
    }
}