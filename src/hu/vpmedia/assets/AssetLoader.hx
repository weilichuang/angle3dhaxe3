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

import flash.errors.IllegalOperationError;
import flash.utils.ByteArray;

import hu.vpmedia.assets.loaders.BaseAssetLoader;
import hu.vpmedia.assets.parsers.BaseAssetParser;
import hu.vpmedia.assets.parsers.BaseAsyncAssetParser;

import flash.Lib;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */
class AssetLoader implements IAssetLoader
{
    /**
     * @private
     */
    private var _progress:Float;
    
    /**
     * @private
     */
    private var _currentProgress:Float;
    
    /**
     * @private
     */
    private var _itemsToLoad:Array<AssetLoaderVO>;
    
    /**
     * @private
     */
    private var _failedToLoad:Array<AssetLoaderVO>;
    
    /**
     * @private
     */
    private var _itemsLoaded:Array<AssetLoaderVO>;
    
    /**
     * @private
     */
    private var _loaderList:Array<BaseAssetLoader>;
    
    /**
     * Will return the loader objects name
     */
    public var name:String;
    
    /**
     * Will return the signal set collection
     */
    public var signalSet:AssetLoaderSignalSet;
    
    
    //----------------------------------
    //  Constructor
    //----------------------------------
    
    /**
     * Constructor.
     */
    public function new()
    {
        _itemsToLoad=new Array<AssetLoaderVO>();
        _failedToLoad=new Array<AssetLoaderVO>();
        _itemsLoaded=new Array<AssetLoaderVO>();
        _loaderList = new Array<BaseAssetLoader>();
        signalSet = new AssetLoaderSignalSet();
    }
    
    //----------------------------------
    //  API
    //----------------------------------
    
    /**
     * Will add an item Into the loading queue
     */
    public function add(url:String, loaderType:String = "", paserType:String = "", priority:Int = 0):AssetLoaderVO
    {
        if(url==null)
        {
            return null;
        }
        
        var vo:AssetLoaderVO = new AssetLoaderVO(url, priority, null, loaderType, paserType);
        
        if(!has(url))
        {
            _itemsToLoad.push(vo);
            _itemsToLoad.sort(AssetLoaderVO.compareByPriority);
        }
        else
        {
            Lib.trace("Already loaded: " + url);
        }
        return vo;
    }
    
    /**
     * Will cache a loaded item
     */
    public function get(url:String):Dynamic
    {
        if(url==null)
        {
            return null;
        }
        for(i in 0..._itemsLoaded.length)
        {
            if(_itemsLoaded[i].url==url)
            {
                return _itemsLoaded[i];
            }
        }
        return null;
    }
    
    /**
     * Will cache an url with data
     */
    public function cache(url:String, data:Dynamic):Bool
    {
        if(!has(url))
        {
            _itemsLoaded.push(new AssetLoaderVO(url, 0, data));
            return true;
        }
        return false;
    }
    
    /**
     * Will return if loader has the url cached
     */
    public function has(url:String):Dynamic
    {
        return get(url)!=null;
    }
    
    /**
     * Will start loading the queue
     */
    public function execute():Void
    {
        _currentProgress=0;
        _progress=0;
        
        loadNext();
    }
    
    /**
     * Will close loading the queue
     */
    public function close():Void
    {
        if(_loaderList != null && _loaderList.length != 0)
        {
            _loaderList[0].close();
        }
    }
    
    /**
     * Will release the object members
     */
    public function reset():Void
    {
        _currentProgress=0;
        _progress=0;
        
        _itemsToLoad=[];
        _failedToLoad=[];
        _itemsLoaded=[];
        _loaderList=[];
    }
    
    /**
     * Will destroy the object
     */
    public function dispose():Void
    {
        signalSet.dispose();
        signalSet=null;
        _itemsToLoad=null;
        _failedToLoad=null;
        _itemsLoaded=null;
        _loaderList=null;
        name=null;
    }
    
    /**
     * Will return the object as a string
     */
    public function toString():String
    {
        return "[AssetLoader" + " name=" + name + "]";
    }
    
    //----------------------------------
    //  Getters
    //----------------------------------
    
    /**
     * Will return the number of processed items
     */
    public var numProcessed(get, null):Int;
     private function get_numProcessed():Int
    {
        return(_itemsLoaded.length + _failedToLoad.length);
    }
    
    /**
     * Will return the number of total items
     */
    public var numTotal(get, null):Int;
     private function get_numTotal():Int
    {
        return(_itemsToLoad.length + _itemsLoaded.length + _failedToLoad.length);
    }
    
    /**
     * Will return the total progress of loading in percentage
     */
    public var progress(get, null):Float;
     private function get_progress():Float
    {
        _progress=(numProcessed / numTotal)* 100;
        return _progress + currentProgress;
    }
    
    /**
     * Will return the current progress of loading in percentage
     */
    public var currentProgress(get, null):Float;
     private function get_currentProgress():Float
    {
        return _currentProgress / numTotal;
    }
    
    /**
     * Will return the loaded item value object list
     */
    public var itemsLoaded(get, null):Array<AssetLoaderVO>;
     private function get_itemsLoaded():Array<AssetLoaderVO>
    {
        return _itemsLoaded;
    }
    
    //----------------------------------
    //  Private Methods
    //----------------------------------
    
    /**
     * @private
     */
    private function loadNext():Void
    {
        var finishedLoader:BaseAssetLoader=_loaderList.shift();
        
        if(finishedLoader != null)
            finishedLoader.dispose();
        
        _currentProgress=0;
        updateProgress();
        
        if(_itemsToLoad.length == 0)
        {
            Lib.trace("COMPLETED");
            signalSet.completed.dispatch([this]);
            //flush();
            //reset();
            return;
        }
        var vo:AssetLoaderVO=_itemsToLoad[0];
        
        Lib.trace("loadNext:" + vo);
        
        var loader:BaseAssetLoader = AssetLoaderFactory.createByLoaderVO(vo);
        _loaderList.push(loader);
        loader.completed.add(loaderCompletedHandler);
        loader.progressed.add(loaderProgressedHandler);
        loader.failed.add(loaderFailedHandler);
        loader.load(vo.urlRequest);
    }
    
    /**
     * @private
     */
    private function addItemData(data:Dynamic):Void
    {
        var vo:AssetLoaderVO=_itemsToLoad.shift();
        
        Lib.trace("addItemData: " + vo);
        
        if(data==null)
        {
            //Lib.trace("\t", "WARNING", "Adding a null object:" + data);
        }
        
        if(Std.is(data, Array))
        {
            var n:Int=data.length;
            for(i in 0...n)
            {
                _itemsLoaded.push(data[i]);
            }
        }
        else if(Std.is(data, AssetLoaderVO))
        {
            _itemsLoaded.push(data);
        }
        else if(vo != null)
        {
            vo.data=data;
            _itemsLoaded.push(vo);
        }
        
        loadNext();
    }
    
    /**
     * @private
     */
    private function updateProgress():Void
    {
        signalSet.progressed.dispatch([this]);
    }
    
    //----------------------------------
    //  Loader Event Handlers
    //----------------------------------
    
    /**
     * @private
     */
    private function loaderCompletedHandler(item:BaseAssetLoader):Void
    {
        Lib.trace("loaderCompletedHandler:" + item + "(" + progress + "%)");
        
        var parser:BaseAssetParser = AssetLoaderPlugin.getParserByLoader(item);
        _itemsToLoad[0].type = parser.type;
        
        if(Std.is(parser, BaseAsyncAssetParser) && Std.is(item.data, ByteArray))
        {
            var asyncParser:BaseAsyncAssetParser=Std.instance(parser,BaseAsyncAssetParser);
            asyncParser.completed.add(parserCompletedHandler);
            asyncParser.progressed.add(parserProgressedHandler);
            asyncParser.failed.add(parserFailedHandler);
            asyncParser.parseAsync(item.data, item.urlRequest.url);
        }
        else
        {
            var data:Dynamic=null;
            try
            {
                data = parser.parse(item.data);
            }
            catch(error:Dynamic)
            {
                // TODO:handle failed parse
                Lib.trace(error);
            }
            addItemData(data);
        }
    }
    
    /**
     * @private
     */
    private function loaderFailedHandler(item:BaseAssetLoader):Void
    {
        Lib.trace("loaderFailedHandler:" + item);
        
        _failedToLoad.push(_itemsToLoad.shift());
        
        loadNext();
    }
    
    /**
     * @private
     */
    private function loaderProgressedHandler(item:BaseAssetLoader):Void
    {
        _currentProgress=item.progress;
        
        updateProgress();
    }
    
    //----------------------------------
    //  Parser Event Handlers
    //----------------------------------
    
    /**
     * @private
     */
    private function parserCompletedHandler(item:BaseAssetParser, data:Dynamic):Void
    {
        Lib.trace("parserCompletedHandler:" + item + "(" + progress + "%)");
        
        addItemData(data);
        
        item.dispose();
    }
    
    /**
     * @private
     */
    private function parserFailedHandler(item:BaseAssetParser):Void
    {
        Lib.trace("parserFailedHandler:" + item + "(" + progress + "%)");
        
        addItemData(null);
        
        item.dispose();
    
    }
    
    /**
     * @private
     */
    private function parserProgressedHandler(item:BaseAssetParser):Void
    {
        _currentProgress=Std.instance(item,BaseAsyncAssetParser).progress;
        
        updateProgress();
    }
}