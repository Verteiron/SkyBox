Scriptname vSS_MCMConfigQuestScript extends vSS_MCMPanelNav
{MCM config script for SuperStash.}

; === [ vSS_MCMConfigQuestScript.psc ] ===================================---
; MCM config script. 
; ========================================================---

; === Imports ===--

Import vSS_Registry
Import vSS_Session

; === Constants ===--

; === Enums ===--

; === Properties ===--

vSS_MetaQuestScript 	Property MetaQuest 						Auto
vSS_StashManager 		Property StashManager 					Auto

String 					Property CurrentStashName 				Auto Hidden
String 					Property CurrentStashUUID 				Auto Hidden

; === Variables ===--

String[] 	_sStashNames

Int[] 		_iHistoryOptions

; === Events/Functions ===--

Int Function GetVersion()
    return 1
EndFunction

Event OnVersionUpdate(int a_version)
	If CurrentVersion < 1
		OnConfigInit()
		DebugTrace("Updating script to version 1...")
	EndIf
EndEvent

Event OnConfigInit()
	ModName = "$SkyBox"
	Pages = New String[8]
	Pages[0] = "$Manage Stashes"
	Pages[1] = "$Global Options"
	Pages[7] = "$Debugging"

	CreatePanel("PANEL_STASH_PICKER","$Stash Picker")
	CreatePanel("PANEL_STASH_OPTIONS","$Stash Options","PANEL_STASH_PICKER")
	CreatePanel("PANEL_STASH_INFO","$Stash Info","PANEL_STASH_PICKER")
	CreatePanel("PANEL_STASH_HISTORY","$Stash History","PANEL_STASH_PICKER")
EndEvent

Event OnConfigOpen()
	DoInit()
EndEvent

Event OnPageReset(string a_page)
	
	; === Handle Logo ===--
	If (a_page == "")
        LoadCustomContent("vSS_logo.dds")
        Return
    Else
        UnloadCustomContent()
    EndIf

	; === Handle other pages ===--
	If a_page == Pages[0]
		SetTitleText(Pages[0])
		If !TopPanel()
			PushPanel("PANEL_STASH_PICKER")
			PushPanel("PANEL_STASH_INFO")
		EndIf
		DisplayPanels()
	ElseIf a_page == Pages[7]
		; AddTextOptionST("OPTION_TEXT_PLAYER_SAVE", "Save player", "right now!")
	Else

	EndIf
EndEvent

; === Panel display functions ===--

State PANEL_STASH_PICKER

	Event OnPanelAdd(Int aiLeftRight)
		SetCursorFillMode(TOP_TO_BOTTOM)
		
		SetCursorPosition(aiLeftRight)
		If !CurrentStashUUID
			AddMenuOptionST("OPTION_MENU_STASH_PICKER","$Select a stash from the list",CurrentStashName)
		Else
			AddMenuOptionST("OPTION_MENU_STASH_PICKER","",CurrentStashName)
		EndIf

		If !CurrentStashUUID
			DebugTrace("No Stash selected!")
			Return
		EndIf

		SetTitleText("$Properties for " + CurrentStashName)

		AddHeaderOption(CurrentStashName)

		Int jStashData = GetRegObj("Stashes." + CurrentStashUUID)

		ObjectReference kStashRef = JMap.GetForm(jStashData,"Form") as ObjectReference
		Int iEntryCount = JArray.Count(JMap.GetObj(jStashData,"containerEntries")) + JArray.Count(JMap.GetObj(jStashData,"entryDataList"))

		SetCursorPosition(aiLeftRight + 4)
		AddInputOptionST("OPTION_INPUT_STASH_NAME","$Stash name",JMap.GetStr(jStashData,"StashName"))
		AddTextOption("$Parent Cell",JMap.GetStr(jStashData,"CellName"))
		AddTextOption("$Form ID",JMap.GetStr(jStashData,"FormIDString") + " (" + JMap.GetStr(jStashData,"Source") + ")")

		String sStatus = "$Not loaded"
		If kStashRef
			sStatus = "$Loaded"
		EndIf

		AddTextOption("$Status",sStatus)
		AddTextOption("$Item entries",iEntryCount)
		AddTextOption("$Last accessed by", JMap.GetStr(jStashData,"LastCharacterName"))
		AddPanelLinkOption("PANEL_STASH_HISTORY","$History")

		; AddTextOption("Health: " + (vSS_API_Character.GetCharacterAV(CurrentSID,"Health") as Int) + \
		; 				", Stamina:" + (vSS_API_Character.GetCharacterAV(CurrentSID,"Stamina") as Int) + \
		; 				", Magicka:" + (vSS_API_Character.GetCharacterAV(CurrentSID,"Magicka") as Int), "",OPTION_FLAG_DISABLED)

		; String sWeaponName = vSS_API_Item.GetItemName(vSS_API_Character.GetCharacterEquippedFormID(CurrentSID,1))
		; String sLWeaponName = vSS_API_Item.GetItemName(vSS_API_Character.GetCharacterEquippedFormID(CurrentSID,0))
		; If sLWeaponName && sLWeaponName != sWeaponName
		; 	sWeaponName += " and " + sLWeaponName
		; ElseIf sLWeaponName && sLWeaponName == sWeaponName
		; 	sWeaponName += " (Both)"
		; EndIf
		; AddTextOption("Wielding " + sWeaponName,"",OPTION_FLAG_DISABLED)
		; ; AddEmptyOption()
		; ; String sActorBaseString = "Not loaded"
		; ; String sActorString 	= "Not loaded"
		; ; Actor kActor = vSS_API_Doppelganger.GetActorForSID(CurrentSID)
		; ; If kActor 
		; ; 	sActorBaseString 	= GetFormIDString(kActor.GetActorBase())
		; ; 	sActorString 		= GetFormIDString(kActor)
		; ; EndIf
		; ; AddTextOption("ActorBase: " + sActorBaseString,"",OPTION_FLAG_DISABLED)
		; ; AddTextOption("Actor: " + sActorString,"",OPTION_FLAG_DISABLED)
		
		; AddPanelLinkOption("PANEL_STASH_OPTIONS_BEHAVIOR","$Faction and behavior")
		; AddPanelLinkOption("PANEL_STASH_OPTIONS_STATS","$Skills and stats")
		
		
		; If !vSS_API_Doppelganger.GetActorForSID(CurrentSID)
		; 	AddEmptyOption()
		; 	AddTextOptionST("OPTION_TEXT_STASH_SUMMON", "Summon me", "right now!")
		; EndIf
	EndEvent
EndState

State PANEL_STASH_OPTIONS

	Event OnPanelAdd(Int aiLeftRight)

		; SetCursorFillMode(TOP_TO_BOTTOM)
		
		; SetCursorPosition(aiLeftRight)

		; Int OptionFlags = 0

		; AddHeaderOption(CurrentCharacterName + " Options")

		; ;AddToggleOptionST("OPTION_TOGGLE_STASH_TRACKING","$Track this character", GetCharConfigBool(CurrentSID,"Tracking",abUseDefault = True))
		; AddEmptyOption()
		
		; OptionFlags = 0

	EndEvent

EndState

State PANEL_STASH_INFO

	Event OnPanelAdd(Int aiLeftRight)
; === Begin info column ===--
		; If !CurrentSID 
		; 	Return
		; EndIf
		; SetCursorPosition(aiLeftRight + 6)
		
		; String[] sSex 	= New String[2]
		; sSex[0] 		= "Male"
		; sSex[1] 		= "Female"

		; AddTextOption("Level " + (vSS_API_Character.GetCharacterLevel(CurrentSID) as Int) + " " + (vSS_API_Character.GetCharacterStr(CurrentSID,".Info.RaceText")) + " " + sSex[vSS_API_Character.GetCharacterSex(CurrentSID)],"",OPTION_FLAG_DISABLED)

		; AddTextOption("Health: " + (vSS_API_Character.GetCharacterAV(CurrentSID,"Health") as Int) + \
		; 				", Stamina:" + (vSS_API_Character.GetCharacterAV(CurrentSID,"Stamina") as Int) + \
		; 				", Magicka:" + (vSS_API_Character.GetCharacterAV(CurrentSID,"Magicka") as Int), "",OPTION_FLAG_DISABLED)

		; String sWeaponName = vSS_API_Item.GetItemName(vSS_API_Character.GetCharacterEquippedFormID(CurrentSID,1))
		; String sLWeaponName = vSS_API_Item.GetItemName(vSS_API_Character.GetCharacterEquippedFormID(CurrentSID,0))
		; If sLWeaponName && sLWeaponName != sWeaponName
		; 	sWeaponName += " and " + sLWeaponName
		; ElseIf sLWeaponName && sLWeaponName == sWeaponName
		; 	sWeaponName += " (Both)"
		; EndIf
		; AddTextOption("Wielding " + sWeaponName,"",OPTION_FLAG_DISABLED)
		; AddEmptyOption()
		; String sActorBaseString = "Not loaded"
		; String sActorString 	= "Not loaded"
		; Actor kActor = vSS_API_Doppelganger.GetActorForSID(CurrentSID)
		; If kActor 
		; 	sActorBaseString 	= GetFormIDString(kActor.GetActorBase())
		; 	sActorString 		= GetFormIDString(kActor)
		; EndIf
		; AddTextOption("ActorBase: " + sActorBaseString,"",OPTION_FLAG_DISABLED)
		; AddTextOption("Actor: " + sActorString,"",OPTION_FLAG_DISABLED)

		
		;===== END info column =============----
	EndEvent

EndState

State PANEL_STASH_HISTORY

	Event OnPanelAdd(Int aiLeftRight)
		SetCursorFillMode(TOP_TO_BOTTOM)
		
		SetCursorPosition(aiLeftRight)

		AddHeaderOption("$Backup history")
	
		If !CurrentStashUUID
			DebugTrace("No Stash selected!")
			Return
		EndIf

		SetCursorPosition(aiLeftRight + 4)

		_iHistoryOptions = New Int[10]

		Int i = 1
		While i < 10
			Int jStashData = vSS_API_Stash.GetStashBackupJMap(CurrentStashUUID,i)
			If jStashData
				If i > 1
					;AddEmptyOption()
				EndIf
				_iHistoryOptions[i] = AddTextOption("Ver: " + JMap.GetInt(jStashData,"DataSerial") + ", $Entries: " + JMap.GetInt(jStashData,"ItemEntryCount") + ", saved by " + JMap.GetStr(jStashData,"LastCharacterName"),"")
			EndIf
			i += 1
		EndWhile
	EndEvent

EndState

State OPTION_MENU_STASH_PICKER

	Event OnMenuOpenST()
		SetMenuDialogOptions(_sStashNames)
		Int iStashNameIdx = _sStashNames.Find(CurrentStashName)
		If iStashNameIdx < 0
			iStashNameIdx = 0
		EndIf
		SetMenuDialogStartIndex(iStashNameIdx)
		SetMenuDialogDefaultIndex(iStashNameIdx)
	EndEvent

	Event OnMenuAcceptST(Int aiIndex)
		String sStashName = _sStashNames[aiIndex]
		If sStashName
			CurrentStashName = sStashName
			CurrentStashUUID = GetSessionStr("MCMMap.NameMap." + sStashName)
		Else
			DebugTrace("OPTION_MENU_STASH_PICKER: No stash name found for index " + aiIndex + "!")
		EndIf
		ForcePageReset()
	EndEvent

EndState

State OPTION_INPUT_STASH_NAME

	Event OnInputOpenST()
		SetInputDialogStartText(GetRegStr("Stashes." + CurrentStashUUID + ".StashName"))
	EndEvent

	Event OnInputAcceptST(string a_input)
		If a_input != GetRegStr("Stashes." + CurrentStashUUID + ".StashName")
			CurrentStashName = a_input
			SetRegStr("Stashes." + CurrentStashUUID + ".StashName",a_input)
			SetTitleText("$Properties for " + CurrentStashName)
			UpdateMCMNames()
			vSS_API_Stash.ExportStash(CurrentStashUUID,abSkipBackup = True)
			ForcePageReset()
		EndIf
	EndEvent

EndState

Event OnOptionSelect(int a_option)
	;A few options really aren't suited for states, so handle them here
	If _iHistoryOptions.Find(a_option) > -1
		;History option was picked!
		Int iRevision = _iHistoryOptions.Find(a_option)
		If iRevision <= 0
			DebugTrace("Error: Invalid revision " + iRevision + "!",2)
			Return
		EndIF
		If ShowMessage("$Revert to this state? You may lose any items currently in this Stash!", True)
			vSS_API_Stash.RevertToBackup(CurrentStashUUID,iRevision)
			ForcePageReset()
		EndIf
	EndIf
EndEvent

Function DoInit()
	FillEnums()
	UpdateMCMNames()

	_iHistoryOptions = New Int[10]
EndFunction

Function UpdateMCMNames()
	vSS_API_Stash.CreateMCMLists()
	_sStashNames = vSS_API_Stash.GetMCMNames()
EndFunction

Function FillEnums()

	; ENUM_STASH_ARMORCHECK 				= New String[3]
	; ENUM_STASH_ARMORCHECK[0]					= "$When missing"
	; ENUM_STASH_ARMORCHECK[1]					= "$Always"
	; ENUM_STASH_ARMORCHECK[2]					= "$Disable"

	; ENUM_GLOBAL_MAGIC_OVERRIDES			= New String[3]
	; ENUM_GLOBAL_MAGIC_OVERRIDES[0]			= "$None"
	; ENUM_GLOBAL_MAGIC_OVERRIDES[1]			= "$Healing"
	; ENUM_GLOBAL_MAGIC_OVERRIDES[2]			= "$Healing/Defense"

	; ENUM_GLOBAL_MAGIC_ALLOWFROMMODS		= New String[3]
	; ENUM_GLOBAL_MAGIC_ALLOWFROMMODS[0]		= "$Vanilla only"
	; ENUM_GLOBAL_MAGIC_ALLOWFROMMODS[1]		= "$Select mods"
	; ENUM_GLOBAL_MAGIC_ALLOWFROMMODS[2]		= "$All mods"
	
	; ENUM_GLOBAL_SHOUTS_HANDLING			= New String[5]
	; ENUM_GLOBAL_SHOUTS_HANDLING[0]			= "$All"
	; ENUM_GLOBAL_SHOUTS_HANDLING[1]			= "$All but CS"
	; ENUM_GLOBAL_SHOUTS_HANDLING[2]			= "$All but DA"
	; ENUM_GLOBAL_SHOUTS_HANDLING[3]			= "$All but CS/DA"
	; ENUM_GLOBAL_SHOUTS_HANDLING[4]			= "$No Shouts"
	
	; ENUM_GLOBAL_FILE_LOCATION			= New String[2]
	; ENUM_GLOBAL_FILE_LOCATION[0]			= "$Data/vSS"
	; ENUM_GLOBAL_FILE_LOCATION[1]			= "$My Games/Skyrim"
	

	; ENUM_STASH_PLAYERRELATIONSHIP		= New String[5]
	; ENUM_STASH_PLAYERRELATIONSHIP[0]			= "$Archenemy"
	; ENUM_STASH_PLAYERRELATIONSHIP[1]			= "$Neutral"
	; ENUM_STASH_PLAYERRELATIONSHIP[2]			= "$Friendly"
	; ENUM_STASH_PLAYERRELATIONSHIP[3]			= "$Follower"
	; ENUM_STASH_PLAYERRELATIONSHIP[4]			= "$CanMarry"

	; ENUM_STASH_CONFIDENCE				= New String[5]
	; ENUM_STASH_CONFIDENCE[0]					= "$Coward"
	; ENUM_STASH_CONFIDENCE[1]					= "$Cautious"
	; ENUM_STASH_CONFIDENCE[2]					= "$Average"
	; ENUM_STASH_CONFIDENCE[3]					= "$Brave"
	; ENUM_STASH_CONFIDENCE[4]					= "$Foolhardy"

	; ENUM_STASH_AGGRESSION				= New String[4]
	; ENUM_STASH_AGGRESSION[0]					= "$Passive"
	; ENUM_STASH_AGGRESSION[1]					= "$Aggressive"
	; ENUM_STASH_AGGRESSION[2]					= "$Very Aggressive"
	; ENUM_STASH_AGGRESSION[3]					= "$Frenzied"

	; ENUM_STASH_ASSISTANCE				= New String[3]
	; ENUM_STASH_ASSISTANCE[0]					= "$Helps nobody"
	; ENUM_STASH_ASSISTANCE[1]					= "$Helps friends"
	; ENUM_STASH_ASSISTANCE[2]					= "$Helps friends/allies"
EndFunction

; === Utility functions ===--

Function DebugTrace(String sDebugString, Int iSeverity = 0)
	Debug.Trace("vSS/MCMPanel: " + sDebugString,iSeverity)
EndFunction

String Function GetFormIDString(Form kForm)
	String sResult
	sResult = kForm as String ; [FormName < (FF000000)>]
	sResult = StringUtil.SubString(sResult,StringUtil.Find(sResult,"(") + 1,8)
	Return sResult
EndFunction

String Function GetPrettyTime(String asTimeInMinutes)
	Float fTimeInMinutes = asTimeInMinutes as Float
	Int iMinutes = Math.Floor(fTimeInMinutes)
	Int iSeconds = Math.Floor((fTimeInMinutes - iMinutes) * 60)
	String sZero = ""
	If iSeconds < 10
		sZero = "0"
	EndIf
	String sPrettyTime = iMinutes + ":" + sZero + iSeconds
	Return sPrettyTime
EndFunction
