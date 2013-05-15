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

import hu.vpmedia.stm.hfsm.State;
import hu.vpmedia.stm.hfsm.StateMachine;
import hu.vpmedia.framework.IBaseTransmitter;
import hu.vpmedia.framework.BaseTransmitter;
import hu.vpmedia.framework.IBaseView;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */

class RouterItem {
    public function new()
    {        
    }
    public var view:Class<Dynamic>;
    public var url:String;
}

class Router extends BaseTransmitter
{
    
public static inline var ROUTE_CHANGE_START:String="routeChangeStart";
public static inline var ROUTE_CHANGE_COMPLETE:String="routeChangeComplete";
public static inline var ROUTE_NOT_FOUND:String="routeNotFound";

//public static inline var CONTENT_CREATION_COMPLETE:String="contentCreationComplete";
//public static inline var CONTENT_DISPOSE_START:String="contentDisposeStart";
//public static const CONTENT_DISPOSE_COMPLETE:String="contentDisposeComplete";
public static inline var TRANSITION_IN_START:String="transitionInStart";
public static inline var TRANSITION_IN_COMPLETE:String="transitionInComplete";
public static inline var TRANSITION_OUT_START:String="transitionOutStart";
public static inline var TRANSITION_OUT_COMPLETE:String="transitionOutComplete";

private var _targetContext:Dynamic;
private var _nextStateURL:String;
private var _nextStateQueue:Array<Dynamic>;
private var _urlStateMap:Map<String, RouterItem>;
private var _contextStateMap:Map<String, BaseContext<Dynamic, Dynamic, Dynamic>>;
private var _stateMachine:StateMachine;
private var _inTransition:Bool;

/**
 * Router
 * @param model
 * @param target
 * @param states
 */
public function new(targetContext:Dynamic, states:Array<RouterItem>=null)
{    
    _targetContext=targetContext;
    super();
    initialize();
    addStates(states);
}

override function initialize():Void
{
    _nextStateQueue = new Array();
    _urlStateMap=new Map();
    _contextStateMap=new Map();
    _stateMachine=new StateMachine();
    _stateMachine.completed.add(stateMachineCompletedHandler);
}
    
//----------------------------------
//  View States
//---------------------------------- 
function addStates(value:Array<RouterItem>):Void
{
    if (value == null)
    {
        return;
    }
    var n:Int=value.length;
    for (i in 0...n)
    {
        addState(value[i]);
    }
}

/**
 * addState
 * @param state
 */
public function addState(state:RouterItem):Void
{
    _urlStateMap.set(state.url,state);
    
    var parentPath:String=getParentPath(state.url);
    if (!_stateMachine.canChangeStateTo(parentPath))
    {
        parentPath = null;
    }
    _stateMachine.addState(new State(state.url, null, stateMachineEnteredHandler, stateMachineExitedHandler), parentPath);
}

/**
 * setValue
 * @param url
 */
public function setState(url:String):Void
{
    /*#if debug
    flash.Lib.trace("setState:"+url);
    #end*/
    
    if (!_stateMachine.canChangeStateTo(url) || _stateMachine.getStateName() == url)
    {
    sendTransmission(ROUTE_NOT_FOUND, null, url, this);
    return;
    }
    sendTransmission(ROUTE_CHANGE_START, null, url, this);
    // trace(parentPathNames == null, parentPath == null)
    _nextStateURL=url;
    _stateMachine.changeState(_nextStateURL);
}

/**
 * clearState
 */
function clearState(url:String):Void
{
    /*#if debug
    flash.Lib.trace("clearState:"+url);
    #end*/
    
    var isActiveContext:Bool=_contextStateMap.exists(url);
    if (isActiveContext)
    {        
        var context:IBaseContext=_contextStateMap.get(url);
        context.dispose();
        _contextStateMap.remove(url);
        //delete _contextStateMap[url];
    }
}

/**
 * nextState
 */
function nextState(url:String):Void
{
    /*#if debug
    flash.Lib.trace("nextState:"+url);
    #end*/
    
    if (_contextStateMap.exists(url))
    {
        //trace(this, "nextState", "ERROR", "already exists");
        return;
    }
    // var pathNames:Array=getPathNames(url);        
    //var parentPathNames:Array=getParentPathNames(url);
    //var firstSegment:String=(pathNames[0]);
    var parentPath:String=getParentPath(url);
    var currentState:RouterItem=_urlStateMap.get(url);
    var currentStateContext:BaseContext<Dynamic,Dynamic,Dynamic> = Type.createInstance(currentState.view,[_targetContext.view.canvas,_targetContext.model]);
    var currentStateView:IBaseView=currentStateContext.view;
    _contextStateMap.set(url,currentStateContext);
    if (_contextStateMap.exists(parentPath))
    {
        var parentContext:BaseContext<Dynamic,Dynamic,Dynamic>=_contextStateMap.get(parentPath);
        currentStateContext.parent = parentContext;
        currentStateView.parentView=parentContext.view;
    }
    if(currentStateView.parentView == null)
    {
        currentStateView.parentView=_targetContext.view;
    }
    // trace("\tparentView:", currentStateView.parentView);
    currentStateView.parentView.canvas.addChild(currentStateView.canvas);
    currentStateView.transitionInComplete.addOnce(viewTransitionInHandler);
    currentStateView.transitionOutComplete.addOnce(viewTransitionOutHandler);
    //_targetContext.setState(url);
    /*if (currentStateView is DynamicContainer)
    {
    DynamicContainer(currentStateView).setState(url);
    }*/
    sendTransmission(TRANSITION_IN_START, null, url, this);
    currentStateView.transitionIn();
}

//----------------------------------
//  Event handlers
//----------------------------------

function stateMachineEnteredHandler(fromState:String, currentState:String, toState:String):Void
{    
    _nextStateQueue.push({type:"enter", fromState: fromState, currentState: currentState, toState: toState});
}

function stateMachineExitedHandler(fromState:String, currentState:String, toState:String):Void
{    
    _nextStateQueue.push({type:"exit", fromState: fromState, currentState: currentState, toState: toState});
}

function stateMachineCompletedHandler(state:String):Void
{
    if (!_inTransition)
    {
        startTransition();
    }
}

function startTransition():Void
{
    /*#if debug
    flash.Lib.trace("startTransition:" + _nextStateQueue.length+_nextStateQueue);
    #end*/
    
    if (_nextStateQueue.length == 0)
    {
        nextState(_nextStateURL);
    }
    else
    {
        _inTransition=true;
        doTransition();
    }
}

function endTransition():Void
{
    sendTransmission(ROUTE_CHANGE_COMPLETE, null, _stateMachine.getStateName(), this);
    _inTransition=false;
}

function doTransition():Void
{
    var item:Dynamic=_nextStateQueue[0];
    var view:IBaseView;
    var currentState:String=item.currentState;
    /*if (item.fromState == item.currentState)
    {
    currentState=item.toState;
    }*/
    
    /*#if debug
    flash.Lib.trace("doTransition:"+item.type);
    #end*/
    
    if (item.type == "exit")
    {
        view=_contextStateMap.get(currentState).view;
        sendTransmission(TRANSITION_OUT_START, null, currentState, this);
        view.transitionOut();
    }
    else if (item.type == "enter")
    {
        nextState(currentState);
    }
}

function nextTransition():Void
{    
    _nextStateQueue.shift();
    /*#if debug
    flash.Lib.trace("nextTransition:"+_nextStateQueue.length + " => " + (_nextStateQueue.length - 1));
    #end*/
    if (_nextStateQueue.length > 0)
    {
        doTransition();
    }
    else
    {
        endTransition();
    }
}

function stopTransition():Void
{
    /*#if debug
    flash.Lib.trace("stopTransition");
    #end*/
    _nextStateQueue = new Array();
}

function getTransitionURL():String
{
    if (_nextStateQueue.length > 0)
    {
    return _nextStateQueue[0].currentState;
    }
    return _nextStateURL;
}

/**
 * viewInHandler
 * @param medium
 */
function viewTransitionInHandler():Void
{
    /*#if debug
    flash.Lib.trace("viewTransitionInHandler");
    #end*/
    sendTransmission(TRANSITION_IN_COMPLETE, null, getTransitionURL(), this);
    nextTransition();
}

/**
 * viewOutHandler
 * @param medium
 */
function viewTransitionOutHandler():Void
{
    /*#if debug
    flash.Lib.trace("viewTransitionOutHandler:"+getTransitionURL());
    #end*/
    sendTransmission(TRANSITION_OUT_COMPLETE, null, getTransitionURL(), this);
    if (_nextStateQueue.length > 0)
    {
        var item:Dynamic=_nextStateQueue[0];
        clearState(item.currentState);
    }
    nextTransition();
}

//----------------------------------
//  Getters
//----------------------------------    
/**
 * stateMachine
 * @return StateMachine
 */
public function getStateMachine():StateMachine
{
    return _stateMachine;
}

public function inTransition():Bool
{
    return _inTransition;
}


/**
 * getViewPath
 * @return Array<BaseView>
 */
public function getViewPath(target:IBaseView):Array<IBaseView>
{
    var result:Array<IBaseView>=new Array();
    while (target != null)
    {
        result.push(target);
        target=target.parentView;
    }
    return result;
}

/**
 * formatPath
 * @param path
 */
public function formatPath(path:String):String
{
    var result:String=path;
    if (path != null && path.length > 1)
    {
        result="/" + path + "/";
    }
    return result;
}

/**
 * getPathNames
 * @param path
 */
public function getPathNames(path:String):Array<String>
{
    if (path == null || path.length <= 1)
    {
    return ["/"];
    }
    var result:Array<String>=path.split("/");
    if (path.substr(0, 1) == "/" || path.length == 0)
    {
    result.splice(0, 1);
    }
    if (path.substr(path.length - 1, 1) == "/")
    {
    result.splice(result.length - 1, 1);
    }
    return result;
}

public function getParentPathNames(path:String):Array<String>
{
    var result:Array<String>=getPathNames(path);
    result.pop();
    if (result.length == 0)
    {
    result=null;
    }
    return result;
}

public function getParentPath(path:String):String
{
    var result:String="";
    var parentPathNames:Array<String>=getParentPathNames(path);
    var parentPath:String;
    if (parentPathNames != null)
    {
        parentPath=parentPathNames.toString().split(",").join("/");
        result=formatPath(parentPath);
    }
    return result;
}

}