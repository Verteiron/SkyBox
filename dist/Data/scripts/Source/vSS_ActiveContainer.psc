Scriptname vSS_ActiveContainer extends ReferenceAlias
{Adds some events to the container the player is current using.}
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

Int _iThreadCount = 0

;=== Events ===--

Event OnInit()
	DebugTrace("OnInit! I am " + GetReference() + "!")
EndEvent

; Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
; 	DebugTrace("OnItemAdded(" + akBaseItem + "," + aiItemCount + "," + akItemReference + "," + akSourceContainer + ")")	
; 	Busy = True
; 	If _iThreadCount == MaxThreadCount
; 		GotoState("Overloaded")
; 	EndIf
; 	_iThreadCount += 1
; 	Int iType = akBaseItem.GetType()

; 	If aiItemCount > 0 
	
; 	EndIf

; 	_iThreadCount -= 1
; 	Busy = False
; EndEvent

; Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
; 	DebugTrace("OnItemRemoved(" + akBaseItem + "," + aiItemCount + "," + akItemReference + "," + akDestContainer + ")")	
; 	Busy = True
; 	If _iThreadCount == MaxThreadCount
; 		GotoState("Overloaded")
; 	EndIf
; 	_iThreadCount += 1
; 	Int iType = akBaseItem.GetType()

; 	If aiItemCount > 0 
	
; 	EndIf

; 	_iThreadCount -= 1
; 	Busy = False
; EndEvent

Event OnOpen(ObjectReference akActionRef)
	DebugTrace("OnOpen(" + akActionRef + ")")
	
	If !vSS_API_Stash.IsStash(Self.GetReference())
		vSS_API_Stash.CreateStash(Self.GetReference())
	EndIf

EndEvent

Event OnClose(ObjectReference akActionRef)
	DebugTrace("OnClose(" + akActionRef + ")")
	Int iCount = vSS_API_Stash.ExportStashItems(Self.GetReference())
	
EndEvent

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
	Debug.Trace("vSS/ActiveContainer/" + Self.GetReference() + ": " + sDebugString,iSeverity)
EndFunction
