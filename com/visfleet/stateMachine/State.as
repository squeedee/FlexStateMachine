package com.visfleet.stateMachine {
	import iv.ArrayHelper;

	internal final class State {

		public function State(name:String, entry:* = null, exit:* = null) {
			this.name = name;
			
			_entry = ArrayHelper.arrayIfNotArray(entry);
			_exit = ArrayHelper.arrayIfNotArray(exit);
		}
		
		public var name:String;
		
		public function enter():void {
			ArrayHelper.executeEach(_entry);
		}

		public function exit():void {
			ArrayHelper.executeEach(_exit);
		}
		
		private var _entry:Array = [];
		
		private var _exit:Array = [];

		static public function fromObject(hash:Object):State {
			return new State(hash.name,hash.entry,hash.exit);
		}
	}
}