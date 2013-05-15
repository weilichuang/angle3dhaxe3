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

import flash.Lib;
import hu.vpmedia.assets.loaders.AssetLoaderType;
import hu.vpmedia.assets.loaders.BaseAssetLoader;
import hu.vpmedia.assets.loaders.BinaryLoader;
import hu.vpmedia.assets.loaders.DisplayLoader;
import hu.vpmedia.assets.loaders.SoundLoader;
import hu.vpmedia.assets.loaders.TextLoader;
import hu.vpmedia.assets.loaders.VideoLoader;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */
class AssetLoaderFactory
{    
    /**
     * TBD
     */
    public static function createByUrl(url:String):BaseAssetLoader
    {
        return createByType(AssetLoaderPlugin.getParserByUrl(url).loaderType);
    }
            
    /**
     * TBD
     */
    public static function createByType(type:String):BaseAssetLoader
    {
        var result:BaseAssetLoader = null;
        switch(type)
        {
            case AssetLoaderType.BINARY_LOADER:
            {
                result = new BinaryLoader();
            }
            case AssetLoaderType.DISPLAY_LOADER:
            {
                result = new DisplayLoader();
            }
            case AssetLoaderType.SOUND_LOADER:
            {
                result = new SoundLoader();
            }
            case AssetLoaderType.TEXT_LOADER:
            {
                result = new TextLoader();
            }
            case AssetLoaderType.VIDEO_LOADER:
            {
                result = new VideoLoader();
            }
            default:
            {
                Lib.trace("Unknown loader type:" + type);
            }
        }
        return result;
    }
}