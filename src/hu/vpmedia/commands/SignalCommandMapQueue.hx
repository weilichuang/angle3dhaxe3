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

class SignalCommandMapQueue extends SignalCommandMap
{
private var _sequencer:SequenceCommand;

public function new(dispatcher:Signal)
{
    super(dispatcher);
}

override function initialize():Void
{
    _sequencer=new SequenceCommand(true);
    _sequencer.signal.add(commandHandler);
    super.initialize();
}

override function executeCommand(code:String, level:String, data:Dynamic, source:Dynamic):Void
{
    var commandKey:String=getCommandKey(code, level);
    /* if (isRunningCommand(commandKey))
     {
     return;
     }*/
    var commandItem:SignalCommandMapItem=getCommand(code, level);
    if (commandItem != null)
    {
        /*if (commandItem.args != null)
        {
            commandItem.args=[0, data];
        }
        else if (commandItem.args.length > 0 && data)
        {
            commandItem.args[1]=data;
        }*/
        var command:IBaseCommand=Type.createInstance(commandItem.type, commandItem.args);
        // command.signal.addOnce(commandHandler);
        _runningCommands.set(command,commandKey);
        _sequencer.addCommand(command);
        if (!_sequencer.isRunning)
        {
            _sequencer.start();
        }
        //command.start(data);
    }
}

override function commandHandler(code:String, level:String, data:Dynamic, source:Dynamic):Void
{
    if (code == MacroCommand.ITEM_COMPLETE)
    {
        //_dispatcher.dispatch(code, data, level, source);
        var command:IBaseCommand=Std.instance(source,IBaseCommand);
        var commandKey:String = _runningCommands.get(command);
                
        if (_mappedCommands.exists(commandKey) && _mappedCommands.get(commandKey).isOnceCommand)
        {
            _mappedCommands.remove(commandKey);
        }    
        
        _runningCommands.remove(command);
        command.dispose();
        command=null;
    }
}

public var sequencer(get_sequencer, null):SequenceCommand;
     function get_sequencer():SequenceCommand
{
    return _sequencer;
}
}