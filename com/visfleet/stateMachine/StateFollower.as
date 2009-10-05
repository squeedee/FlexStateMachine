package com.visfleet.stateMachine {
	import flash.events.IEventDispatcher;
	
	import mx.events.PropertyChangeEvent;
	
	public final class StateFollower {
		
		public function StateFollower(stateMachine:StateMachine,followTarget:*,followProperty:String, bidirectional:Boolean = false) {
			machine = stateMachine;
			property = followProperty;
			target = followTarget;	
			establishListeners(bidirectional);			
		}
		
		private var target:*;

		private var property:String;

		private var machine:StateMachine;

		private function establishListeners(bidirectional:Boolean = false):void {
			// dies with the machine, this means you do not need to keep a reference to your StateFollower
			machine.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE,machineChangeHandler,false,0,false);
			
			if (bidirectional) {
				establishBidirectionalListener();
			}
		}
		
		private function establishBidirectionalListener():void {
			if (!(target is IEventDispatcher)) {
				throw new Error("Cannot set bidirectional with a target that's not an EventDispatcher",678953263); 
			}
			
			IEventDispatcher(target).addEventListener(PropertyChangeEvent.PROPERTY_CHANGE,targetChangeHandler,false,0,true);
		} 

		private function machineChangeHandler(event:PropertyChangeEvent):void {
			if (event.property == 'state') {
				syncTargetToMachine();				
			}
		}
		
		private function syncTargetToMachine():void {
			if (target != null) {
				target[property] = machine.state;
			}
		}

		private function targetChangeHandler(event:PropertyChangeEvent):void {
			if (event.property == property) {
				syncMachineToTarget();
			}
		}

		public function syncMachineToTarget():void {
			machine.forceNewState(target[property]);			
		}

	}
}