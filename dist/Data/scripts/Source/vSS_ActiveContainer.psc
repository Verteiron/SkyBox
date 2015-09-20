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

Sound 				Property 	vSS_StashDoneLPSM 			Auto

;=== Variables ===--

Int _iThreadCount = 0

ObjectReference _SelfRef

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
	_SelfRef = Self.GetReference()

	If !vSS_API_Stash.IsStash(_SelfRef)
		vSS_API_Stash.CreateStash(_SelfRef)
	EndIf
	_kGlow = _SelfRef.PlaceAtMe(dunKagrenzelFXActivator, abInitiallyDisabled = True)
	_kGlow.MoveTo(_SelfRef,0,0,_SelfRef.GetHeight() * 0.6)
	Float fW = _SelfRef.GetWidth()
	Float fH = _SelfRef.GetHeight()
	Float fL = _SelfRef.GetLength()
	Float fSize = fW
	If fH > fSize
		fSize = fH
	EndIf
	If fL > fSize
		fSize = fL
	EndIf
	Float fScale = fSize / 18.0
	_kGlow.SetScale(fScale)
	_kGlow.EnableNoWait(True)
	Utility.WaitMenuMode(1)
	While UI.IsMenuOpen("ContainerMenu")
		Utility.Wait(0.2)
	EndWhile
	Int iSoundInstance = vSS_StashDoneLPSM.Play(_SelfRef)
	_kGlow.PlayGamebryoAnimation("mReady",abStartOver = False, afEaseInTime = 5.0)
	Int iCount = vSS_API_Stash.ExportStashItems(_SelfRef)
	_kGlow.PlayGamebryoAnimation("mCast")
	Sound.StopInstance(iSoundInstance)
	Clear()
	WaitMenuMode(0.5)
	_kGlow.Disable(True)
	_kGlow.Delete()
EndEvent

; Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
; 	_iThreadCount += 1
; 	If _iThreadCount >= MaxThreadCount
; 		GoToState("ItemMovement")
; 	EndIf
; 	;DebugTrace("OnItemAdded!")
; 	vSS_API_Stash.AddStashItem(_SelfRef,akBaseItem, aiItemCount, akItemReference)
; 	;GoToState("")
; 	_iThreadCount -= 1
; EndEvent

; Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
; 	_iThreadCount += 1
; 	If _iThreadCount >= MaxThreadCount
; 		GoToState("ItemMovement")
; 	EndIf
; 	;GoToState("ItemMovement")
; 	;GoToState("ItemMovement")
; 	;DebugTrace("OnItemRemoved!")
; 	vSS_API_Stash.RemoveStashItem(_SelfRef,akBaseItem, aiItemCount, akItemReference)
; 	;GoToState("")
; 	_iThreadCount -= 1
; EndEvent

; State ItemMovement

; 	Event OnBeginState()
; 		RegisterForSingleUpdate(1)
; 	EndEvent

; 	Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
		
; 	EndEvent

; 	Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
		
; 	EndEvent

; 	Event OnUpdate()
; 		_iThreadCount = 0
; 		GoToState("")
; 	EndEvent

; EndState

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
	Debug.Trace("vSS/ActiveContainer/" + _SelfRef + ": " + sDebugString,iSeverity)
EndFunction
