;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 8
Scriptname PRKF_vSS_StashCheckPerk_010012D4 Extends Perk Hidden

;BEGIN FRAGMENT Fragment_1
Function Fragment_1(ObjectReference akTargetRef, Actor akActor)
;BEGIN CODE
Debug.Trace("vSS/StashCheckPerk: Activate!")
If !vSS_API_Stash.IsStash(akTargetRef)
vSS_API_Stash.CreateStash(akTargetRef)
EndIf
Utility.Wait(1)
While UI.IsMenuOpen("ContainerMenu")
Utility.Wait(0.2)
EndWhile
Int iCount = vSS_API_Stash.UpdateStashItems(akTargetRef)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment


vSS_StashManager Property StashManager Auto
