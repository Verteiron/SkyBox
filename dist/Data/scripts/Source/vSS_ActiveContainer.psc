Scriptname vSS_ActiveContainer extends ReferenceAlias
{Adds some events to the container the player is current using.}
;=== Imports ===--

Import Utility
Import Game
Import vSS_Registry
Import vSS_Session

;=== Properties ===--

Int					Property	MaxThreadCount = 8 			AutoReadOnly Hidden

Bool				Property	Busy						Auto	Hidden

Actor 				Property	PlayerREF					Auto

Form 				Property 	MGAugurFX01Static 			Auto

Activator 			Property 	dunKagrenzelFXActivator 	Auto

;=== Variables ===--

Int _iThreadCount = 0

ObjectReference _kGlow

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

Event OnActivate(ObjectReference akActionRef)
	DebugTrace("OnActivate(" + akActionRef + ")")
EndEvent

Event OnStashOpen()
	DebugTrace("OnStashOpen()")
	If !vSS_API_Stash.IsStash(Self.GetReference())
		vSS_API_Stash.CreateStash(Self.GetReference())
	EndIf
	_kGlow = Self.GetReference().PlaceAtMe(dunKagrenzelFXActivator, abInitiallyDisabled = True)
	_kGlow.MoveTo(Self.GetReference(),0,0,Self.GetReference().GetHeight() * 0.6)
	_kGlow.SetScale(5)
	_kGlow.EnableNoWait(True)
	Utility.Wait(1)
	While UI.IsMenuOpen("ContainerMenu")
		Utility.Wait(0.2)
	EndWhile
	_kGlow.PlayGamebryoAnimation("mReady",abStartOver = False, afEaseInTime = 5.0)
	Int iCount = vSS_API_Stash.ExportStashItems(Self.GetReference())
	_kGlow.PlayGamebryoAnimation("mCast")
	Clear()
	WaitMenuMode(0.5)
	_kGlow.Disable(True)
	_kGlow.Delete()
EndEvent

Event OnOpen(ObjectReference akActionRef)
	DebugTrace("OnOpen(" + akActionRef + ")")
EndEvent

Event OnClose(ObjectReference akActionRef)
	DebugTrace("OnClose(" + akActionRef + ")")
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
