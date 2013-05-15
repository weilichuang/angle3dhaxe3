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
package hu.vpmedia.stm.fsm;

import hu.vpmedia.signals.SignalLite;

/**
 * State machine
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
     * State hash map 
     */ 
    private var _states:Map<String, IState>;
      
    /**
     * Creates a generic StateMachine. 
     */
    public function new()
    {
        _states=new Map();
    }
    
    /**
     * Will add a new state
     * @param state
     */
    public function addState(state:IState):Void
    {            
        _states.set(state.name, state );
    } 
    
    /**
     * TBD
     */
    public function setInitialState(stateName:String):Void
    {
        _currentState = stateName;
    }
        
    /**
     * TBD
     */
    public function changeState(stateName:String):Bool
    {          
        if (!hasState(stateName))
        {
            return false;
        }
        
        _prevState = _currentState;
        _currentState = stateName;
        
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
}