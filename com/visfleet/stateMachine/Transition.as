package com.visfleet.stateMachine {
	import iv.ArrayHelper;

	final internal class Transition {
		public function Transition(machine:StateMachine, fromState:State, toState:State, guards:* = null, actions:* = null) {
			this.fromState = fromState;
			this.toState = toState;
			this.machine = machine;
			
			this.guards = ArrayHelper.arrayIfNotArray(guards);
			this.actions = ArrayHelper.arrayIfNotArray(actions);
		}

		public var machine:StateMachine;
		public var fromState:State;
		public var toState:State;
		public var guards:Array = [];
		public var actions:Array = [];
		
		public function execute(testOnly:Boolean,args:Array = null):Boolean {
			if (!allowed()) {
				return false;
			}
			
			if (!testOnly) {
				ArrayHelper.executeEach(actions,args);
			}
			return true;
		}

		private function allowed():Boolean {
			return guards.every(executesTrue);
		}

		private function executesTrue(item:*,index:int,array:Array):Boolean {
			return item();
		}

		public static function fromObject(machine:StateMachine,value:*):Transition {
			return new Transition(
				machine,
				machine.getState(value.fromState),
				machine.getState(value.toState),
				value.guards,
				value.actions
			);
		}
	}
}