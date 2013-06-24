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
package hu.vpmedia.commands;

import hu.vpmedia.signals.SignalLite;

class SignalCommandMap
{
    private var _mappedCommands:Map<String, SignalCommandMapItem>; //K:commandkey-V:class
    private var _runningCommands:Map<IBaseCommand,String>; //K:instance-V:commandkey
    private var _dispatcher:Signal;

    public function new(dispatcher:Signal)
    {
        //trace(this, "SignalCommandMap", dispatcher);
        this.dispatcher=dispatcher;
        initialize();
    }

    public function initialize():Void
    {
        _mappedCommands=new Map();
        _runningCommands=new Map();
    }

    function set_dispatcher(value:Signal):Signal
    {
        if (_dispatcher != null)
        {
        _dispatcher.remove(executeCommand);
        }
        _dispatcher=value;
        _dispatcher.add(executeCommand);
        return _dispatcher;
    }

    public var dispatcher(get_dispatcher, set_dispatcher):Signal;
    function get_dispatcher():Signal
    {
        return _dispatcher;
    }

    public function dispose():Void
    {
        _dispatcher.remove(executeCommand);
        _dispatcher=null;
        initialize();
    }

    function getCommandKey(commandName:String, commandLevel:String=null):String
    {
        //trace(this, "getCommandKey", commandName, commandLevel);
        var result:String;
        if (commandLevel != null)
        {
            result=commandLevel + "::" + commandName;
        }
        else
        {
            result=commandName;
        }
        return result;
    }

    function getCommand(commandName:String, commandLevel:String=null):SignalCommandMapItem
    {
        var commandKey:String=getCommandKey(commandName, commandLevel);
        var result:SignalCommandMapItem=_mappedCommands.get(commandKey);
        return result;
    }

    public function addCommand(commandClass:Class<Dynamic>, commandName:String, commandLevel:String=null, commandParams:Array<Dynamic>=null, isOnceCommand:Bool=false):Void
    {
        var commandKey:String=getCommandKey(commandName, commandLevel);
        _mappedCommands.set(commandKey,new SignalCommandMapItem(commandClass, commandParams, isOnceCommand));
    }

    public function removeCommand(commandName:String, commandLevel:String=null):Void
    {
        var commandKey:String=getCommandKey(commandName, commandLevel);
        _mappedCommands.remove(commandKey);
    }

    function isRunningCommand(commandKey:String):Bool
    {
        for (p in _runningCommands)
        {
            if (p == commandKey)
            {
                return true;
            }
        }
        return false;
    }

    function executeCommand(code:String, level:String, data:Dynamic, source:Dynamic):Void
    {
        var commandKey:String=getCommandKey(code, level);
        if (isRunningCommand(commandKey))
        {
            return;
        }
        var commandItem:SignalCommandMapItem=getCommand(code, level);
        if (commandItem != null)
        {
            var command:IBaseCommand=Type.createInstance(commandItem.type, commandItem.args);
            command.signal.addOnce(commandHandler);
            _runningCommands.set(command,commandKey);
            command.start(data);
        }
    }

    function commandHandler(code:String, level:String, data:Dynamic, source:Dynamic):Void
    {
        //trace(this, "commandHandler", command);
        //_dispatcher.dispatch(code, data, level, source);
        var command:IBaseCommand=Std.instance(source,IBaseCommand);
        var commandKey:String = _runningCommands.get(command);
        if (_mappedCommands.exists(commandKey) && _mappedCommands.get(commandKey).isOnceCommand)
        {
            //trace("\t", "deleting:", commandKey);
            _mappedCommands.remove(commandKey);
        }    
        if (command != null)
        {
            command.dispose();
        }
        if (_runningCommands.exists(command))
        {
            _runningCommands.remove(command);
        }
    }
}