Scriptname vSS_PlayerLoadGameAliasScript extends ReferenceAlias
{Attach to Player alias. Enables the quest to receive the OnGameReload event.}

; === [ vSS_PlayerLoadGameAliasScript.psc ] ==============================---
; Enables the owning vSS_BaseQuest to receive the OnGameReload event.
; ========================================================---

;=== Events ===--

Event OnPlayerLoadGame()
{Send OnGameReload event to the owning quest.}
	(GetOwningQuest() as vSS_BaseQuest).OnGameReload()
EndEvent
