package com.visfleet.stateMachine {
	
	import com.visfleet.core.isNull;
	
	import flash.utils.flash_proxy;
	
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	import mx.utils.ObjectProxy;
	use namespace flash_proxy;

	/**
	 * StateMachine tries to provide a DSL for describing a state machine in flex.
	 * 
	 * @author Rasheed
	 */
	dynamic public class StateMachine extends ObjectProxy {

		public function StateMachine() {
		}

		public function setInitialState(state:String):void {
			if (currentState != null) {
				throw new Error("Initial state already set!",12654129);
			}
			forceNewState(state);
		}

		public function forceNewState(state:String):void {
			if (state != null) {
				currentState = getState(state);
				broadcastTests();
			}
		}

		public function addState(name:String, opts:Object = null):void {
			if (opts == null) { 
				opts = {}
			}
			
			if (states[name] == null) {
				opts.name = name;
				states[name] = State.fromObject(opts);
			} else { 
				throw new Error("State: " + name + " already exists",89723489613);
			}
		}

		internal function getState(name:String):State {
			if (states[name] != null) {
				return states[name];
			} 
			throw new Error("State not declared: " + name, 897234692);
		}
		
		private var states:Object = {};
		
		/**
		 * @readonly 
		 */
		[Bindable]
		public function set currentState(value:State):void {
			if (_currentState != value) {
				_currentState = value;
				state = value.name;
			}
		}

		public function get currentState():State {
			return _currentState;
		}
		
		private var _currentState:State;
		
		[Bindable]
		/**
		 * @readonly 
		 */
		public var state:String; // follows currentstate 

		// a list of tests that may be observed.
		private var tests:Object = {};

		private function doEvent(name:String,testOnly:Boolean = false, ...rest):Boolean {
			if (currentState == null) {
				throw new Error("Cannot run event: " + name + ", initial state not set",124987614); 
			}

			var transitions:Array = _events[name] 
			
			for each (var transition:Transition in transitions) {
				if (
					(transition.fromState == currentState) && 
					(transition.execute(testOnly,rest))
				) {
					if (!testOnly) {
						currentState.exit();
						
						currentState = transition.toState;
						
						currentState.enter();
						broadcastTests();
					}
					
					return true;
					
				}
			} 


			trace("Warning: State Machine could not transition from '" + currentState.name + "' on event '" + name + "'");			
			return false;			
		}
		
		private function broadcastTests():void {
			for (var testName:String in tests) {
				dispatchEvent(
					new PropertyChangeEvent(
						PropertyChangeEvent.PROPERTY_CHANGE,
						false, false,
						PropertyChangeEventKind.UPDATE,
						testName
					)
				);
			}
		}


		public function addTransition(eventName:String,opts:*):void {
			// @TODO: add support for a matrx of to/from 
			if (_events[eventName] == null) {
				_events[eventName] = [];
			}
			
			_events[eventName].push(Transition.fromObject(this,opts));
		}

		private var _events:Object = {};

		override flash_proxy function getProperty(name:*):* {
			name = getGuardTestName(name);
			
			if (isNull(tests[name])) {
				tests[name] = 1; 
			} 
			
			return doEvent(name,true);
		}

		override flash_proxy function callProperty(name:*, ...rest):* {
			name = getNameFromPossibleQName(name);

			return doEvent.apply(this,[name,false].concat(rest));
			
		}

		override flash_proxy function hasProperty(name:*):Boolean {
			return (getNameFromPossibleQName(name) in _events);
		}

		override flash_proxy function setProperty(name:*, value:*):void {
			addTransition(
				getNameFromPossibleQName(name),
				value
			);
						
		}
		
		private function getGuardTestName(name:*):String {
			var realName:String = getNameFromPossibleQName(name);
			if (realName.search(/^can.+/) < 0)
				return realName;
			
			return realName.substr(3);
		}
		
		private function getNameFromPossibleQName(name:*):String {
			return (name is QName) ? QName(name).localName : name;
			
		}

		/**
		 * 
		 * @param followTarget
		 * @param followProperty
		 * @param bidirectional
		 * @return Returns the StateFollower instance created. You do not need to keep this reference. 
		 * 
		 */
		public function follow(followTarget:*,followProperty:String, bidirectional:Boolean = false):StateFollower {
			return new StateFollower(this,followTarget,followProperty,bidirectional);
		}

	}
}