Scriptname vSS_StashCreator extends ActiveMagicEffect
{Spell to turn the target object into a Stash.}

; === [ vSS_StashCreator.psc ] =============================================---
; Spell to turn the target object into a Stash.
; ========================================================---

Import Game
Import Utility

;=== Properties ===--

Actor 				Property PlayerREF					Auto

vSS_StashManager 	Property StashManager 				Auto

ReferenceAlias 		Property ActiveContainer 			Auto

;=== Events ===--

Event OnEffectStart(Actor akTarget, Actor akCaster)
	ObjectReference kStashRef = GetCurrentCrosshairRef()
	Debug.Trace("vSS/StashCreator: Called on " + kStashRef + "!")
	If !(kStashRef.GetType() == 28 || kStashRef.GetBaseObject().GetType() == 28) || akCaster != PlayerREF
		Debug.Trace("vSS/StashCreator: Object not a container, or player is not caster. Aborting!")
		Return
	EndIf
	If (vSS_API_Stash.IsStashRef(kStashRef))
		Debug.Trace("vSS/StashCreator: Object is already a Stash! Aborting!")
		Return
	EndIf
	Debug.Trace("vSS/StashCreator: Creating a stash with " + kStashRef + "!")
	ActiveContainer.Clear()
	WaitMenuMode(0.1)
	ActiveContainer.ForceRefTo(kStashRef)
	WaitMenuMode(0.1)
	(ActiveContainer as vSS_ActiveContainer).OnStashCreate()
EndEvent
