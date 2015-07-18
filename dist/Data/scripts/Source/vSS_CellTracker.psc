Scriptname vSS_CellTracker extends ActiveMagicEffect
{Track when the player changes cells.}

; === [ vSS_CellTracker.psc ] ==============================================---
; Track when the player changes cells.
; ========================================================---

Import Game
Import Utility

;=== Properties ===--

Actor 				Property PlayerREF				Auto

ObjectReference 	Property TrackerObject	 		Auto

vSS_StashManager 	Property StashManager 			Auto

;=== Events ===--

Event OnEffectStart(Actor akTarget, Actor akCaster)
	Debug.Trace("vSS/CellTracker: Player changed cells!")
	vSS_API_Stash.LoadStashesForCell(PlayerREF.GetParentCell())
	TrackerObject.Moveto(PlayerREF)
EndEvent
