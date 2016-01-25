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

ObjectReference		Property 	vSS_StashContainerFX 		Auto

Sound 				Property 	vSS_StashDoneLPSM 			Auto

;=== Variables ===--

Bool _bIsSack

Int _iThreadCount = 0

Int _iSoundInstance = 0

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

Event OnStashCreate()
	_SelfRef = Self.GetReference()
	DebugTrace("OnStashCreate()")
	String sStashID
	PlaceFX(_SelfRef)
	If !vSS_API_Stash.IsStashRef(_SelfRef)
		DebugTrace("Not a StashRef, calling CreateStashRef..")
		vSS_API_Stash.CreateStashRef(_SelfRef)
		sStashID = vSS_API_Stash.GetUUIDForStashRef(_SelfRef)
		DebugTrace("My Stash UUID is " + sStashID)
	EndIf
	PlayFX()
	Int iCount = vSS_API_Stash.UpdateStashData(sStashID)
	vSS_API_Stash.ExportStash(sStashID)
	Clear()
	StopFX()
EndEvent

Event OnStashOpen()
	DebugTrace("OnStashOpen()")
	_SelfRef = Self.GetReference()

	If !vSS_API_Stash.IsStashRef(_SelfRef)
		DebugTrace("Not a Stash!")
		Return
		;vSS_API_Stash.CreateStash(_SelfRef)
	EndIf
	PlaceFX(_SelfRef)
	Utility.WaitMenuMode(1)
	While UI.IsMenuOpen("ContainerMenu")
		Utility.Wait(0.2)
	EndWhile
	PlayFX()
	String sStashID = vSS_API_Stash.GetUUIDForStashRef(_SelfRef)
	Int iCount = vSS_API_Stash.UpdateStashData(sStashID)
	vSS_API_Stash.ExportStash(sStashID)
	Clear()
	StopFX()
EndEvent

Function PlaceFX(ObjectReference akStashRef)
	;vSS_StashContainerFX.DisableNoWait()
	If StringUtil.Find(akStashRef.GetBaseObject().GetName(),"sack") > -1
		DebugTrace(_SelfRef + " is a sack!")
		_bIsSack = True
	EndIf
	; If _bIsSack
	;  	vSS_StashContainerFX.MoveTo(akStashRef,0,0,-akStashRef.GetHeight() * 0.75)
	; Else
	;  	vSS_StashContainerFX.MoveTo(akStashRef,0,0,-akStashRef.GetHeight() * 0.5)
	; EndIf
	
	; vSS_StashContainerFX.MoveTo(akStashRef,0,0,akStashRef.GetHeight() * 0.25)

	; Float fW = akStashRef.GetWidth()
	; Float fH = akStashRef.GetHeight()
	; Float fL = akStashRef.GetLength()
	; Float fSize = fW
	; If fH > fSize
	; 	fSize = fH
	; EndIf
	; If fL > fSize
	; 	fSize = fL
	; EndIf
	; Float fScale = fSize / 1300
	; DebugTrace("fScale is "+fScale)
	; vSS_StashContainerFX.SetScale(fScale)
	; vSS_StashContainerFX.EnableNoWait(True)
	_iSoundInstance = vSS_StashDoneLPSM.Play(akStashRef)
EndFunction

Function PlayFX()
	;;vSS_StashContainerFX.SetAnimationVariableFloat("fmagicburnamount", 0.25)
	; If _bIsSack
	; 	vSS_StashContainerFX.TranslateTo(_SelfRef.GetPositionX(),_SelfRef.GetPositionY(),_SelfRef.GetPositionZ() + _SelfRef.GetHeight(),_SelfRef.GetAngleX(),_SelfRef.GetAngleY(),_SelfRef.GetAngleZ(),_SelfRef.GetHeight() / 2.25,0)
	; Else
	; 	vSS_StashContainerFX.TranslateTo(_SelfRef.GetPositionX(),_SelfRef.GetPositionY(),_SelfRef.GetPositionZ() + _SelfRef.GetHeight() * 0.5,_SelfRef.GetAngleX(),_SelfRef.GetAngleY(),_SelfRef.GetAngleZ(),_SelfRef.GetHeight() / 2,0)
	; EndIf
	;vSS_StashContainerFX.PlayGamebryoAnimation("SpecialIdle_AreaEffect",True)
	;;_kGlow.PlayGamebryoAnimation("mReady",abStartOver = False, afEaseInTime = 5.0)
EndFunction

Function StopFX()
	;;vSS_StashContainerFX.SetAnimationVariableFloat("fmagicburnamount", 0.0)
	Sound.StopInstance(_iSoundInstance)
	; Wait(2)
	; vSS_StashContainerFX.StopTranslation()
	; vSS_StashContainerFX.Disable(True)
	; vSS_StashContainerFX.MoveToMyEditorLocation()
EndFunction

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
