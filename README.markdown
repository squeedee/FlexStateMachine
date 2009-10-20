# Flex State Machine

# Introduction: A best approximation of a DSL.
This is a heavy WIP, nonetheless it works well in our production code.
To make the state machine as 'DSL' like as possible i've tried to take 
advantage of mixins to allow one class to 'act_as' a state machine. This part 
hasn't worked out so well, but it is my intention to make it happen if
at all possible.

At the outset I must tell you, none of the code on this page is tested. I'll do that some other time :P

All code is under the MIT license.

# TODO
  * MXML Markup support? maybe? We don't have a specific use for this.
  * Mixin behaviour so that it can 'act_as'
  * Multiple to/from states in one even definition (still creates multiple transitions)

# An example
This is lifted from production code, I think it's elegant but I do invite criticism.

    static public const IDLE:String = "idle";
    static public const COMMITTING:String = "committing";
    static public const EDITING:String = "editing";

    private function configureStateMachine():void {
      machine = new StateMachine();
      
      machine.addState(
          COMMITTING,
          {entry:setBusy,exit:clearBusy}
      );
      machine.addState(EDITING);
      machine.addState(IDLE);
      
      machine.select = 
        {fromState:IDLE, toState:IDLE, actions:select};
      
      machine.idle = 
        {fromState:COMMITTING, toState:IDLE, actions:clearEdit};
      machine.idle = 
        {fromState:EDITING, toState:IDLE, actions:clearEdit};
      
      machine.construct = 
        {fromState:IDLE, toState:EDITING, actions:construct};
      
      machine.edit = 
        {fromState:IDLE, toState:EDITING, actions:edit, guards:selectedResourceExists};
      machine.edit = 
        {fromState:EDITING, toState:IDLE, guards:selectedResourceExists};
      machine.edit = 
        {fromState:COMMITTING, toState:IDLE, guards:selectedResourceExists};
      
      machine.dispose = 
        {fromState:IDLE, toState:COMMITTING, actions:dispose, guards:selectedResourceExists};
      machine.dispose = 
        {fromState:EDITING, toState:IDLE, guards:selectedResourceExists};
      machine.dispose = 
        {fromState:COMMITTING, toState:IDLE, guards:selectedResourceExists};

      machine.disposeSelected = 
        {fromState:IDLE, toState:COMMITTING, actions:disposeSelected, guards:selectedResourceExists};
      
      machine.editSelected = 
        {fromState:IDLE, toState:EDITING, actions:editSelected, guards:selectedResourceExists};

      machine.save = 
        {fromState:EDITING, toState:COMMITTING, actions:saveEdit};
      
      machine.follow(this,'synchronousStatus');
      
      machine.setInitialState(IDLE);
    }

# Tutorial
I assume you know how state machines work, and know what a 'State', 'Event', 'Transition', 'Action' and 'Guard' are. 

Normally all your prep of the state machine will be done in one method. Dynamic state machines are too hard to keep track of :)

## Instance the machine
    machine = new StateMachine();

## States

### Define states
    machine.addState("start");
    machine.addState("running");

### Now Do it Right

You know, with constants.

    static const START:String = "start";
    static const RUNNING:String = "running";
    ... later ...
    machine.addState(START);
    machine.addState(RUNNING);

### Set an initial state

    machine.setInitialState(START);

### States support entry and exit actions
Entry and exit actions support parameters, see **Actions support parameters**.

    machine.addState(
        COMMITTING,
        {entry:setBusy,exit:clearBusy}
    );

### entry and exit actions can stack

    machine.addState(
        COMMITTING,
        {
          entry:[setBusy,clearScreen],
          exit:[clearBusy,populateScreen]
        }
    );

## Events
### A simple event
    machine.begin = {fromState:START, toState:RUNNING};

Creates an event "begin", which triggers a transition from *START* to *RUNNING*

### Events can trigger multiple transitions
    machine.toggle = {fromState:A, toState:B};
    machine.toggle = {fromState:B, toState:A};

#### No shortcut for multiple fromStates
You may find you want to do this:

    machine.quit = {
      fromState:[WAITING,MENU,FIRING], 
      toState:FINISHED
    };

But alas that's not supported yet. You need:

    machine.quit = {fromState:WAITING, toState:FINISHED};
    machine.quit = {fromState:MENU, toState:FINISHED};
    machine.quit = {fromState:FIRING, toState:FINISHED};

### Calling an event
Trigger a transition by calling the event. First the event is defined:

    machine.quit = {fromState:WAITING, toState:FINISHED};

If the current state is *WAITING*, then calling:

    var success:Boolean = machine.quit();
    
causes state to change from *WAITING* to *FINISHED*.

Transitions do not occur if the current state does not match a fromState for the 
event being called. In this case, for example, if the state was *RUNNING*, calling *quit()* does nothing.

Success is shown in the result of the event trigger.

## Transition Actions

### Calling an action on a transition

    machine.quit = {fromState:WAITING, toState:FINISHED, actions:_quit};
    ...later...
    private function _quit():void {
      ... 
        called when the transition occurs (state changes)
      ...
    }
    
*_quit* is only called if the event can cause the transition.

### More than one action

    machine.quit = {fromState:WAITING, toState:FINISHED, actions:[_quit,_other]};
    ...later...
    private function _quit():void {
      ... do stuff ...
    }
    private function _other():void {
      ... then this ...
    }

### Actions support parameters
You can call an event with parameters which are passed to actions.

    machine.quit = {fromState:WAITING, toState:FINISHED, actions:_quit};
    ...later...
    private function _quit(message:String = null):void {
      trace("Quitting with: " + message);
    }

Called with

    machine.quit("You Lose");
    
will output

    Quitting with: You Lose

## Guards
    machine.disposeSelected = {}
      fromState:IDLE, 
      toState:COMMITTING, 
      actions:disposeSelected, 
      guards:selectedResourceExists
    };

*selectedReesourceExists* must return true or false. If it returns true, and the 
*fromState* is *true*, the transition will occur.

Guards support parameters, see **Actions support parameters**.

### Guards can stack
    machine.disposeSelected = {}
      fromState:IDLE, 
      toState:COMMITTING, 
      actions:disposeSelected, 
      guards:[selectedResourceExists,selectedResourceValid]
    };

## Tests (cans)
You can test if an event would cause a transition with 'cans':

Assume the *quit* event is declared:

    machine.quit = {fromState:WAITING, toState:FINISHED};

You can check if calling *quit()* will cause a transition with

    trace(machine.quit);

or preferably:

    trace(machine.canQuit)

See how these are not method calls, just property inspection. I prefer *canQuit*, 
it reads a lot better than *quit*.

'cans' return *true* if the transition will complete.

### 'Cans' and guards

Be aware, guards are included in the 'can'.

### 'Cans' are [bindable]

Common use case for 'cans' are as flags to enbable UI elements. for example:

    <mx:Button label="Quit" enabled="{machine.canQuit}" >  

***
Rasheed Abdul-Aziz,
Visfleet.

