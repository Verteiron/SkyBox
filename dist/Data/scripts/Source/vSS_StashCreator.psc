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
	Debug.Trace("vSS/StashCreator: Creating a stash with " + kStashRef + "!")
	ActiveContainer.Clear()
	ActiveContainer.ForceRefTo(kStashRef)
	(ActiveContainer as vSS_ActiveContainer).OnStashCreate()
	
EndEvent
