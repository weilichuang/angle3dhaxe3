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
package hu.vpmedia.stm.hfsm;

import hu.vpmedia.signals.SignalLite;

/*
 * Original AS3 port: https://github.com/cassiozen/AS3-State-Machine (MIT License)
 * Haxe port and modifications (Event -> Signal) by Andras Csizmadia <andras@vpmedia.eu>
 */
class StateMachine
{    
    /**
     * Stores previous state name
     */       
    private var _prevState:String; 
    
    /**
     * Stores current state name 
     */       
    private var _currentState:String;  
    
    /**
     * State map 
     */ 
    private var _states:Map<String, IState>;
    
    /**
     * Signal 
     */           
    public var entered:Signal;
    
    /**
     * Signal 
     */
    public var exited:Signal;
    
    /**
     * Signal 
     */
    public var started:Signal;
    
    /**
     * Signal 
     */
    public var completed:Signal;
    
    /**
     * Signal 
     */
    public var denied:Signal;
            
    /**
     * Creates a generic StateMachine. 
     */
    public function new()
    {
        _states=new Map();

        entered = new Signal();
        exited = new Signal();
        started = new Signal();
        completed = new Signal();
        denied = new Signal();
    }
    
    /**
     * Will add a new state
     * @param state
     * @param parentName
     */
    public function addState(state:IState, ?parentName:String = null):Void
    {          
        if(parentName != null)
        {
            var parentState:IState = _states.get(parentName);
            state.parent = parentState;
        }        
        _states.set(state.name, state );
    }
    
    /**
     * Will set the first state, calls enter callback and dispatches TRANSITION_COMPLETE
     * @param stateName    The name of the State
     */
    public function setInitialState(stateName:String):Void
    {
        if (_currentState == null && _states.exists(stateName))
        {
            _currentState=stateName;            
            if (_states.get(_currentState).root != null)
            {
                var parentStates:Array<IState>=_states.get(_currentState).parents;
                for (j in (parentStates.length - 1)...0)
                {
                    if (parentStates[j].enter != null)
                    {
                        // from, current, to
                        parentStates[j].enter(null, parentStates[j].name, stateName);
                        entered.dispatch([ null, parentStates[j].name, stateName ]);
                    }
                }
            } 
            if (_states.get(_currentState).enter != null)
            {
                // from, current, to
                _states.get(_currentState).enter(null, _currentState, stateName);
                entered.dispatch([ null, _currentState, stateName ]);
            }
            completed.dispatch([stateName]);
        }
    }
        
    /**
     * Discovers the how many "exits" and how many "enters" are there between two
     * given states and returns an array with these two integers
     * @param stateFrom The state to exit
     * @param stateTo The state to enter
     */
    public function findPath(stateFrom:String, stateTo:String):Array<Int>
    {
        // Verifies if the states are in the same "branch" or have a common parent
        var fromState:IState = null;
        if(stateFrom != null)
        {
            fromState=_states.get(stateFrom);
        }
        var c:Int=0;
        var d:Int=0;
        while (fromState != null)
        {
            d=0;
            var toState:IState=_states.get(stateTo);
            while (toState != null)
            {
                if (fromState == toState)
                {
                    // They are in the same brach or have a common parent Common parent
                    return [c, d];
                }
                d++;
                toState=toState.parent;
            }
            c++;
            fromState=fromState.parent;
        }
        // No direct path, no commom parent: exit until root then enter until element
        return [c, d];
    }
    
    /**
     * Changes the current state
     * This will only be done if the intended state allows the transition from the current state
     * Changing states will call the exit callback for the exiting state and enter callback for the entering state
     * @param stateTo    The name of the state to transition to
     */
    public function changeState(stateTo:String):Bool
    {
        // If there is no state that maches stateTo
        if (!(_states.exists(stateTo)))
        {
            //trace("[StateMachine]",id,"Cannot make transition: State "+ stateTo +" is not defined");
            denied.dispatch([stateTo]);
            return false;
        }
        // If current state is not allowed to make this transition
        if (!canChangeStateTo(stateTo))
        {
            //trace("[StateMachine]",id,"Transition to "+ stateTo +" denied");
            denied.dispatch([stateTo]);
            return false;
        }
        
        //allowedStates=_states.get(stateTo).from;
        started.dispatch([_currentState,stateTo]);
        
        // call exit and enter callbacks (if they exits)
        var path:Array<Int>=findPath(_currentState, stateTo);
        if (path[0] > 0)
        {            
            if (_states.get(_currentState).exit != null)
            {
                // from, current, to
                _states.get(_currentState).exit(_currentState, _currentState, stateTo);                
            }
            exited.dispatch([_currentState, _currentState, stateTo]);
            var parentState:IState=_states.get(_currentState);
            for (i in 0...(path[0] - 1))
            {
                parentState=parentState.parent;
                if (parentState.exit != null)
                {
                    // from, current, to
                    parentState.exit(_currentState, parentState.name, stateTo);                    
                }
                exited.dispatch([_currentState, parentState.name, stateTo]);
            }
        }
        var oldState:String=_currentState;
        _currentState=stateTo;
        if (path[1] > 0)
        {
            if (_states.get(stateTo).root != null)
            {
                var parentStates:Array<IState>=_states.get(stateTo).parents;
                var n:Int = path[1] - 2;            
                while (n>=0)
                {
                    if (parentStates[n] != null && parentStates[n].enter != null)
                    {
                        parentStates[n].enter(oldState, parentStates[n].name, stateTo);
                    }
                    entered.dispatch([oldState, parentStates[n].name, stateTo]);
                    n--;
                }
            }
            if (_states.get(_currentState).enter != null)
            {
                _states.get(_currentState).enter(oldState, _currentState, stateTo);
                entered.dispatch([oldState, _currentState, stateTo]);
            }
        }
        //trace("[StateMachine]",id,"State Changed to " + _currentState);
        _prevState = oldState;
        completed.dispatch([stateTo]);
        
        return true;
    }
    
    /**
     * TBD
     */
    public function hasState(stateName:String):Bool
    {
        return _states.exists(stateName);
    }
        
    /**
     * TBD
     */
    public function getStateName():String
    {
        return _currentState;
    }
      
    /**
     * TBD
     */  
    public function getState():IState
    {
        return getStateByName(_currentState);
    }
    
    /**
     * TBD
     */
    public function getPrevStateName():String
    {
        return _prevState;
    }
    
    /**
     * TBD
     */
    public function getPrevState():IState
    {
        return getStateByName(_prevState);
    }
      
    /**
     * TBD
     */  
    public function getStates():Map<String, IState>
    {
        return _states;
    }
    
    /**
     * TBD
     */
    public function getStateByName(stateName:String):IState
    {
        return _states.get(stateName);
    }
    
    /**
     * TBD
     */
    public function canChangeStateTo(stateName:String):Bool
    {
        var s:IState = _states.get(stateName);
        return ( stateName != _currentState && hasState(stateName) && ( s.isStateAccepted(_currentState) || s.isAllStatesAccepted() ) );
    }
}