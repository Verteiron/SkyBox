Scriptname vSS_PlayerTracker extends ReferenceAlias
{Tracks player's inventory, stats, etc in the background to save time while saving.}
;=== Imports ===--

Import Utility
Import Game
Import vSS_Registry
Import vSS_Session

;=== Properties ===--

Int					Property	MaxThreadCount = 8 	AutoReadOnly Hidden

Bool				Property	Busy				Auto	Hidden

Actor 				Property	PlayerREF			Auto

;=== Variables ===--



;=== Events ===--

Event OnInit()
	If GetOwningQuest().IsRunning()
		GotoState("Sleeping")
		RegisterForModEvents()
		Busy = True
	EndIf
EndEvent

Event OnPlayerLoadGame()
	RegisterForModEvents()
EndEvent

Event OnPlayerTrackerStart(string eventName, string strArg, float numArg, Form sender)
	GoToState("Scanning")
EndEvent

Event OnPlayerTrackerStop(string eventName, string strArg, float numArg, Form sender)
	GoToState("Sleeping")
EndEvent

Function RegisterForModEvents()
	RegisterForModEvent("vSS_PlayerTrackerStart","OnPlayerTrackerStart")
	RegisterForModEvent("vSS_PlayerTrackerStop","OnPlayerTrackerStop")
EndFunction

Auto State Sleeping

	Event OnUpdate()
	EndEvent

	Event OnPlayerTrackerStart(string eventName, string strArg, float numArg, Form sender)
		GoToState("Scanning")
	EndEvent

	Event OnPlayerTrackerStop(string eventName, string strArg, float numArg, Form sender)
	EndEvent

EndState

State Scanning

	Event OnBeginState()
		DebugTrace("Background scanning cell data...")
	EndEvent

	Event OnUpdate()
		If PlayerREF.IsInCombat() ; Don't do this while in combat, it may slow down other more important scripts
			RegisterForSingleUpdate(5)
			Return
		EndIf
		
		Busy = False
		RegisterForSingleUpdate(5)
	EndEvent

	Event OnPlayerTrackerStart(string eventName, string strArg, float numArg, Form sender)
	EndEvent

	Event OnPlayerTrackerStop(string eventName, string strArg, float numArg, Form sender)
		GoToState("Sleeping")
	EndEvent

EndState ;Scanning

State Refreshing

	Event OnPlayerTrackerStart(string eventName, string strArg, float numArg, Form sender)
		GoToState("Scanning")
	EndEvent

	Event OnPlayerTrackerStop(string eventName, string strArg, float numArg, Form sender)
		GoToState("Sleeping")
	EndEvent

EndState ; Refreshing

Function StartTimer(String sTimerLabel)
	Float fTime = GetCurrentRealTime()
	;Debug.Trace("TimerStart(" + sTimerLabel + ") " + fTime)
	SetSessionFlt("Timers." + sTimerLabel,fTime)
EndFunction

Function StopTimer(String sTimerLabel)
	Float fTime = GetCurrentRealTime()
	;Debug.Trace("TimerStop (" + sTimerLabel + ") " + fTime)
	DebugTrace("Timer: " + (fTime - GetSessionFlt("Timers." + sTimerLabel)) + " for " + sTimerLabel)
	ClearSessionKey("Timers." + sTimerLabel)
EndFunction

Function DebugTrace(String sDebugString, Int iSeverity = 0)
	Debug.Trace("vSS/PlayerTracker: " + sDebugString,iSeverity)
EndFunction
